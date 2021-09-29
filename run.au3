#NoTrayIcon
#include "remove.au3"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TraySetIcon("shell32.dll", 40)

If _Singleton("multithread", 1) = 0 Then
	MsgBox($MB_SYSTEMMODAL, "Warning", "Program is already running!", 5)
    Exit
EndIf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Local $timeout = 30
Local $threads = 8
Local $parametrs[$timeout]

For $i = 0 To $timeout - 1
    $parametrs[$i] = $i
Next

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