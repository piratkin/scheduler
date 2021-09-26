#NoTrayIcon
#include "remove.au3"

TraySetIcon("shell32.dll", 40)

Global $timeout = 3
Global $threads = 10

If _Singleton("multithread", 1) = 0 Then
	MsgBox($MB_SYSTEMMODAL, "Warning", "Program is already running!", 5)
    Exit
EndIf

run_remove($threads)
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

