#Requires AutoHotkey v2.0
#SingleInstance Force

; [NOVO] AUTO-ELEVAR PARA ADMINISTRADOR
; Necessário para desenhar sobre jogos e interagir com o OBS
if not A_IsAdmin {
    try {
        Run "*RunAs " A_ScriptFullPath
    }
    ExitApp
}

/*
    PROJECT: GRAVI
    VERSION: 1.1.0 (Fixed Overlay)
    AUTHOR: Semmler Micro-Automações
*/

; ==============================================================================
; INICIALIZAÇÃO E CONFIGURAÇÃO
; ==============================================================================
PastaConfig := A_AppData . "\Gravi"
if !DirExist(PastaConfig)
    DirCreate(PastaConfig)

ArquivoIni := PastaConfig . "\settings.ini"

CaminhoPadrao := "C:\Users\" . A_UserName . "\Videos"
PastaVideos := IniRead(ArquivoIni, "Geral", "PastaAlvo", CaminhoPadrao)
ExtensoesPermitidas := IniRead(ArquivoIni, "Geral", "Extensoes", "mkv,mp4,mov")

if (!DirExist(PastaVideos)) {
    MsgBox("Bem-vindo ao GRAVI!`n`nNão encontrei sua pasta de Vídeos.`nPor favor, selecione onde salvar suas gravações.", "Configuração Inicial")
    ConfigurarPasta()
} else {
    if !FileExist(ArquivoIni) {
        IniWrite(PastaVideos, ArquivoIni, "Geral", "PastaAlvo")
        IniWrite(ExtensoesPermitidas, ArquivoIni, "Geral", "Extensoes")
        MsgBox("Bem-vindo ao GRAVI!`n`nIniciado automaticamente em:`n" . PastaVideos, "Gravi")
    } else {
        Resultado := MsgBox("GRAVI ATIVO!`nMonitorando: " . PastaVideos . "`n`nDeseja alterar a pasta monitorada?", "Gravi", "YesNo T7 Iconi")
        if (Resultado = "Yes")
            ConfigurarPasta()
    }
}

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
; Adicionado +Owner para garantir que não roube foco do jogo
GuiRec := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Owner")
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
    
    ; Removemos a verificação "if (Ligado != EstadoAtual)" para forçar 
    ; o redesenho sobre o jogo constantemente se estiver gravando.
    
    if (Ligado) {
        X_Pos := A_ScreenWidth - 300
        Y_Pos := 30
        
        ; [CORREÇÃO] Força o topo explicitamente a cada ciclo
        GuiRec.Show("x" X_Pos " y" Y_Pos " NoActivate") 
        try WinSetAlwaysOnTop(1, GuiRec.Hwnd)
        
    } else {
        if (EstadoAtual != 0) { ; Só esconde se já não estiver escondido
            GuiRec.Hide()
        }
    }
    EstadoAtual := Ligado
}