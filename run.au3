#NoTrayIcon
#include "remove.au3"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INIT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TraySetIcon("shell32.dll", 40)

If _Singleton("multithread", 1) = 0 Then
	MsgBox($MB_SYSTEMMODAL, "Warning", "Program is already running!", 5)
    Exit
EndIf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; START LOGGINING
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $logfile = FileOpen(@ScriptDir & "\remove_" & @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC & ".log", 1)
_FileWriteLog($logfile, "Start 'remove' logging")		
If @error Then
	MsgBox($MB_ICONINFORMATION, "Error", "Unable write file: " & $logfile)
	Exit
EndIf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Local $timeout = 5
Local $threads = 8
Local $parametrs[$threads]

For $i = 0 To $threads - 1
    $parametrs[$i] = Mod($i, $timeout)
Next

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EXECUTE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

run_remove($parametrs, $threads, $timeout)
Select
    Case $error = $ERROR_SUCCESS
        MsgBox($MB_ICONINFORMATION, "Information", "Well done!")
    Case $error = $ERROR_INIT
        MsgBox($MB_ICONINFORMATION, "Error", "Initialization error!")
    Case $error = $ERROR_DISPOSE
        MsgBox($MB_ICONINFORMATION, "Error", "Dispose error!")
    Case Else
        MsgBox($MB_ICONINFORMATION, "Warning", "Runtime error: " & $error)
EndSelect

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; END LOGGINING
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_FileWriteLog($logfile, "End 'remove' logging")
If FileClose($logfile) = 0 Then
	MsgBox($MB_ICONINFORMATION, "Error", "Unable close logfile")
EndIf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;