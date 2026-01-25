#Requires AutoHotkey v2.0
#SingleInstance Force

/*
    PROJECT: GRAVI
    VERSION: 1.0.0
    AUTHOR: Semmler Micro-Automações
    DESCRIPTION:
        Um monitor de gravação minimalista para OBS Studio.
        Detecta a criação e crescimento de arquivos de vídeo em tempo real
        e exibe um indicador visual (Tally Light) na tela.
        
    LICENSE: MIT (Open Source)
*/

; ==============================================================================
; CONFIGURAÇÃO (MODO COMERCIAL)
; ==============================================================================
; Define o arquivo de configuração ao lado do script
ArquivoIni := A_ScriptDir . "\settings.ini"

; Se o arquivo não existir, cria um padrão (Primeira execução do cliente)
if !FileExist(ArquivoIni) {
    IniWrite(A_MyDocuments, ArquivoIni, "Geral", "PastaAlvo")
    IniWrite("mkv,mp4,mov", ArquivoIni, "Geral", "Extensoes")
    MsgBox("Bem-vindo ao GRAVI!`n`nConfigurei a pasta 'Documentos' como padrão.`nPara alterar, edite o arquivo 'settings.ini' criado na pasta.", "Configuração Inicial")
}

; Lê as configurações do arquivo (O cliente tem controle agora)
global PastaVideos := IniRead(ArquivoIni, "Geral", "PastaAlvo", A_MyDocuments)
global ExtensoesPermitidas := IniRead(ArquivoIni, "Geral", "Extensoes", "mkv,mp4,mov")

; ==============================================================================
; INTERFACE VISUAL
; ==============================================================================
GuiRec := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
GuiRec.BackColor := "101010"
GuiRec.SetFont("s16 bold", "Segoe UI")
WinSetTransColor("101010", GuiRec)
GuiRec.Add("Text", "cFF0000", "🔴 REC")

; ==============================================================================
; MOTOR HÍBRIDO
; ==============================================================================
; Verificação rápida (500ms)
SetTimer MonitorarDisco, 500

MonitorarDisco() {
    global PastaVideos, ExtensoesPermitidas
    
    static UltimoTamanho := 0
    static ContadorParada := 0
    
    ArquivoMaisRecente := ""
    HoraMaisRecente := 0 
    
    ; 1. Varredura
    Loop Files, PastaVideos . "\*.*" 
    {
        if InStr(ExtensoesPermitidas, A_LoopFileExt)
        {
            if (A_LoopFileTimeModified > HoraMaisRecente) {
                HoraMaisRecente := A_LoopFileTimeModified
                ArquivoMaisRecente := A_LoopFileFullPath
            }
        }
    }
    
    if (ArquivoMaisRecente = "") {
        MostrarLuz(false)
        return
    }

    ; 2. ANÁLISE HÍBRIDA (O Segredo)
    
    ; Critério A: Horário (Para INÍCIO Rápido)
    ; Se o arquivo foi tocado nos últimos 2 segundos, considere gravando.
    EhRecente := (DateDiff(A_Now, HoraMaisRecente, "Seconds") < 2)
    
    ; Critério B: Tamanho (Para FIM Preciso)
    try {
        TamanhoAtual := FileGetSize(ArquivoMaisRecente)
    } catch {
        TamanhoAtual := UltimoTamanho ; Evita erro de leitura
    }
    Cresceu := (TamanhoAtual > UltimoTamanho)
    UltimoTamanho := TamanhoAtual ; Atualiza para a próxima volta

    ; 3. DECISÃO
    ; Se é recente (Início rápido) OU Se está crescendo (Gravação contínua)
    if (EhRecente || Cresceu) {
        MostrarLuz(true)
        ContadorParada := 0 ; Zera a contagem de desligamento
    } 
    else {
        ; Se não é recente E não cresceu, começa a contar para desligar
        ContadorParada += 1
        
        ; Espera 4 ciclos (2 segundos) sem atividade para desligar
        ; Isso evita que a luz pisque se o HD engasgar
        if (ContadorParada >= 4) {
            MostrarLuz(false)
        }
    }
}

; ==============================================================================
; CONTROLE DE VISIBILIDADE
; ==============================================================================
MostrarLuz(Ligado) {
    static EstadoAtual := -1
    
    if (Ligado != EstadoAtual) {
        if (Ligado) {
            X_Pos := A_ScreenWidth - 300
            Y_Pos := 30
            GuiRec.Show("x" X_Pos " y" Y_Pos " NoActivate") 
        } else {
            GuiRec.Hide()
        }
        EstadoAtual := Ligado
    }
}