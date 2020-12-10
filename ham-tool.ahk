;================================================================================
;   DIRECTIVES, ETC.
;================================================================================
#NoEnv ; Recommended for performance and compatibility 
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Persistent ; Keeps a script running (until closed).
#SingleInstance FORCE ; automatically replaces an old version of the script
SetBatchLines, -1
FileEncoding, UTF-8

;================================================================================
;   GLOBALS, ONEXIT, ETC.
;================================================================================
Global REGEX_VALID_HOSTNAME   := "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$"
Global REGEX_POWERSHELL       := "O)([A-Za-z0-9\.-]*)\s+([A-Za-z0-9\.-]*)\s+([0-9]{1,4})\s+([A-Z][a-z]*)"
Global REGEX_QWINSTA          := "O)\s([A-Za-z0-9#-]*)\s+([A-Za-z\.]+)\s+(\d{1,3})\s{2}([A-Z]\w+)"
Global SERVERS      := []
Global JOBS_RUNNING := {}
Global SESSIONS     := []
Global shell        := new ShellExecutor()
Global sw           := new Stopwatch()

;================================================================================
;   INIT
;================================================================================
; FileInstall, ham-tool-async.ps1, %A_Temp%\ham-tool-async.ps1, 1
FileInstall, ham-tool.cfg, ham-tool.cfg, 0
Loop, Read, ham-tool.cfg ; read in the configuration file line-by-line
{
  If (A_LoopReadLine) {
    If (InStr(A_LoopReadLine, ";") != 1) {
      SERVERS.Push(A_LoopReadLine)
    }
  } 
}
FileCreateDir, %A_WorkingDir%/servers

;================================================================================
;   MAIN
;================================================================================
Gui gui_handle: Destroy
Gui gui_handle: Default
Gui gui_handle: +LastFound +E0x20 +Hwndhwnd_gui
; Gui gui_handle: Color, White, White
Gui gui_handle: Margin, 8, 8
Gui gui_handle: Add, Button, Default w80 vbutton_refresh, % "Refresh"
; add stop refreshing button--or change refresh button to stop button
Gui gui_handle: Font, s8 Normal
Gui gui_handle: Add, Text, w384 ym+5 vtext_refresh, % "Initializing..."
Gui gui_handle: Font, s11 Normal
Gui gui_handle: Add, ListView, r20 w480 gGuiEvent xm section -Multi Grid Sort +hwndlv_session, User|Server|Id|State
LV_ModifyCol(3, "Integer")
Gui gui_handle: Show, % "NoActivate" ; display the GUI
Gosub, gui_handleButtonRefresh
Return

;===============================================================================
;   INCLUDES
;===============================================================================
#Include, ham-tool-functions.ahk
#Include, ham-tool-classes.ahk
#Include, ham-tool-labels.ahk