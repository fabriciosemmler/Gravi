#Requires AutoHotkey v2.0
#SingleInstance Force

/*
    PROJECT: GRAVI
    VERSION: 1.0.0
    AUTHOR: Semmler Micro-Automações
    DESCRIPTION:
        Um monitor de gravação minimalista para OBS Studio.
        Detecta a criação e crescimento de arquivos de vídeo em tempo real
        e exibe um indicador visual na tela.
        
    LICENSE: MIT (Open Source)
*/

; ==============================================================================
; INICIALIZAÇÃO E CONFIGURAÇÃO
; ==============================================================================
PastaConfig := A_AppData . "\Gravi"
if !DirExist(PastaConfig)
    DirCreate(PastaConfig)

ArquivoIni := PastaConfig . "\settings.ini"

; --- INTERVENÇÃO CIRÚRGICA AQUI ---
; Define o padrão como a pasta de Vídeos do usuário atual
CaminhoPadrao := "C:\Users\" . A_UserName . "\Videos"

; Lê o INI. Se não existir, usa o CaminhoPadrao
PastaVideos := IniRead(ArquivoIni, "Geral", "PastaAlvo", CaminhoPadrao)
ExtensoesPermitidas := IniRead(ArquivoIni, "Geral", "Extensoes", "mkv,mp4,mov")

; Lógica de Verificação
if (!DirExist(PastaVideos)) {
    ; Se nem a pasta configurada nem a padrão existirem (raro), pede ajuda
    MsgBox("Bem-vindo ao GRAVI!`n`nNão encontrei sua pasta de Vídeos.`nPor favor, selecione onde salvar suas gravações.", "Configuração Inicial")
    ConfigurarPasta()
} else {
    ; Se for a primeira vez (INI não existe), cria ele silenciosamente com o padrão
    if !FileExist(ArquivoIni) {
        IniWrite(PastaVideos, ArquivoIni, "Geral", "PastaAlvo")
        IniWrite(ExtensoesPermitidas, ArquivoIni, "Geral", "Extensoes")
        MsgBox("Bem-vindo ao GRAVI!`n`nIniciado automaticamente em:`n" . PastaVideos, "Gravi")
    } else {
        ; Execução normal
        Resultado := MsgBox("GRAVI ATIVO!`nMonitorando: " . PastaVideos . "`n`nDeseja alterar a pasta monitorada?", "Gravi", "YesNo T7 Iconi")
        if (Resultado = "Yes")
            ConfigurarPasta()
    }
}
; ----------------------------------

; Função para selecionar e salvar
ConfigurarPasta() {
    global PastaVideos, ArquivoIni
    
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

A_TrayMenu.Add()
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
SetTimer MonitorarDisco, 500

MonitorarDisco() {
    global PastaVideos, ExtensoesPermitidas
    
    static UltimoTamanho := 0
    static ContadorParada := 0
    
    ArquivoMaisRecente := ""
    HoraMaisRecente := 0 
    
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

    EhRecente := (DateDiff(A_Now, HoraMaisRecente, "Seconds") < 2)
    
    try {
        TamanhoAtual := FileGetSize(ArquivoMaisRecente)
    } catch {
        TamanhoAtual := UltimoTamanho 
    }
    Cresceu := (TamanhoAtual > UltimoTamanho)
    UltimoTamanho := TamanhoAtual 

    if (EhRecente || Cresceu) {
        MostrarLuz(true)
        ContadorParada := 0 
    } 
    else {
        ContadorParada += 1
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