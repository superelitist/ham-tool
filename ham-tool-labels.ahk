;===============================================================================
;   LABELS
;===============================================================================
Refresh:
  refreshing := True
  Gui gui_handle: Default
  LV_Delete()
  GuiControl, Text, button_refresh, % "Cancel"
  GuiControl, Text, text_refresh, % "Refreshing sessions, please wait..."
  then := sw.Milliseconds()
  For _, host_name in SERVERS {
    Run, %ComSpec% /c qwinsta /server:%host_name% > %A_Temp%/%host_name%.txt, , Hide, pid ; this actually starts the "jobs"
    JOBS_RUNNING[host_name] := pid
  }
  SetTimer, RefreshLoop, -33
  Return

RefreshLoop:
  If (!refreshing) {
    return
  }
  Gui gui_handle: Default
  host_names_remaining := ""
  for host_name, _ in JOBS_RUNNING {
    host_names_remaining := host_names_remaining . host_name . " "
  }
  GuiControl, Text, text_refresh, % JOBS_RUNNING.Count() . " servers remaining: " . host_names_remaining
  For host_name, pid in JOBS_RUNNING {
    If (!ProcessExist(pid)) {
      JOBS_RUNNING.Delete(host_name) ; remove pair from array
      Loop, Read, % (A_Temp . "\" . host_name . ".txt") ; get content of associated file
      {
        If (A_LoopReadLine) {
          If (RegExMatch(A_LoopReadLine, REGEX_QWINSTA, match)) {
            LV_Add("", match[2], host_name, match[3], match[4])
          }
        }
      }
    }
  }
  LV_ModifyCol()
  If (JOBS_RUNNING.Count()) {
    SetTimer, RefreshLoop, -33
  } Else {
    refreshing := False
    elapsed := sw.Milliseconds() - then
    GuiControl, Text, button_refresh, % "Refresh"
    GuiControl, Text, text_refresh, % "Finished in " . Round(elapsed/1000, 2) . " seconds."
  }
  Return

gui_handleButtonRefresh:
  if (!refreshing) {
    Gosub, Refresh
  } else {
    refreshing := False
    elapsed := sw.Milliseconds() - then
    GuiControl, Text, button_refresh, % "Refresh"
    GuiControl, Text, text_refresh, % "Canceled at " . Round(elapsed/1000, 2) . " seconds."
  }
  Return

GuiEvent:
  if (A_GuiEvent = "DoubleClick") {
    LV_GetText(ses_usr, A_EventInfo, 1)
    LV_GetText(ses_svr, A_EventInfo, 2)
    LV_GetText(ses_id, A_EventInfo, 3)
    MsgBox, 52, Kill Session, Do you want to kill the session for %ses_usr% on %ses_svr%?
    kill_session := False
    IfMsgBox, Yes
      kill_session := True
    If (kill_session) {
      Gui gui_handle: +Disabled
      Runwait, %ComSpec% /c rwinsta %ses_id% /server:%ses_svr%, , Hide UseErrorLevel
      If (ErrorLevel > 0) {
        MsgBox % "rwinsta exitcode was not 0, the session was probably not reset. stderr: `n" . res[3]
      } Else {
        MsgBox % "Session was reset."
        LV_Delete(A_EventInfo)
      }
      Gui gui_handle: -Disabled
    }
  }
  Return

gui_handleGuiClose:  ; Indicate that the script should exit automatically when the window is closed.
  ExitApp