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
; INICIALIZAÇÃO E CONFIGURAÇÃO
; ==============================================================================
ArquivoIni := A_ScriptDir . "\settings.ini"

; Tenta ler a pasta. Se der erro ou vazio, retorna "ERRO"
PastaVideos := IniRead(ArquivoIni, "Geral", "PastaAlvo", "ERRO")
ExtensoesPermitidas := IniRead(ArquivoIni, "Geral", "Extensoes", "mkv,mp4,mov")

; LÓGICA DE BOAS-VINDAS INTELIGENTE
if (PastaVideos = "ERRO" or !DirExist(PastaVideos)) {
    ; Cenário 1: Primeira vez ou pasta apagada. Força a escolha.
    MsgBox("Bem-vindo ao GRAVI!`n`nPara começar, selecione a pasta onde seus vídeos são salvos.", "Configuração Inicial")
    ConfigurarPasta()
} else {
    ; Cenário 2: Já configurado. Dá 3 segundos para mudar, senão segue o baile.
    Resultado := MsgBox("GRAVI ATIVO!`nMonitorando: " . PastaVideos . "`n`nDeseja alterar a pasta monitorada?", "Gravi", "YesNo T7 Iconi")
    
    if (Resultado = "Yes")
        ConfigurarPasta()
}

; Função para selecionar e salvar
ConfigurarPasta() {
    global PastaVideos, ArquivoIni
    
    ; MUDANÇA AQUI: Substituímos 'PastaVideos' por "" (aspas vazias).
    ; Isso reseta a janela para "Meu Computador", permitindo escolher qualquer lugar.
    NovaPasta := DirSelect("", 3, "Selecione a pasta de gravações do OBS")
    
    if (NovaPasta = "") {
        MsgBox("Nenhuma pasta selecionada. O Gravi será encerrado.", "Erro")
        ExitApp
    }
    
    PastaVideos := NovaPasta
    IniWrite(PastaVideos, ArquivoIni, "Geral", "PastaAlvo")
    IniWrite("mkv,mp4,mov", ArquivoIni, "Geral", "Extensoes") 
    MsgBox("Configuração salva com sucesso!`nMonitorando: " . PastaVideos, "Gravi")
}

; Adiciona opção ao Menu da Bandeja (Backup para o usuário avançado)
A_TrayMenu.Add() ; Separador
A_TrayMenu.Add("Alterar Pasta Monitorada", (*) => ConfigurarPasta())

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