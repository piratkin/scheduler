#include "scheduler.au3"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Local $timer
Local $waitTimeout

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func run_remove($threads = 4)
    $waitTimeout = 3000
    Local $_timer[$threads]
    $timer = $_timer
    Local $handlers = [ stepBegin, step1, step2, step3, stepEnd ]
    If register($handlers, $threads, $timeout) Then Return $error
    If scheduler() Then Return $error
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func stepBegin($i)
    MsgBox($MB_SYSTEMMODAL, "Info", "Instance #" & $i & ". Begin", 1)
    $timer[$i] = TimerInit()
    stepIt($i)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func step1($i)
    If TimerDiff($timer[$i]) >= $waitTimeout Then
        MsgBox($MB_SYSTEMMODAL, "Info", "Instance: " & $i & ". Step #1", 1)
        $timer[$i] = TimerInit()
        stepIt($i)
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func step2($i)
    If TimerDiff($timer[$i]) >= $waitTimeout Then
        MsgBox($MB_SYSTEMMODAL, "Info", "Instance: " & $i & ". Step #2", 1)
        $timer[$i] = TimerInit()
        stepIt($i)
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func step3($i)
    If TimerDiff($timer[$i]) >= $waitTimeout Then
        MsgBox($MB_SYSTEMMODAL, "Info", "Instance: " & $i & ". Step #3", 1)
        $timer[$i] = TimerInit()
        stepIt($i)
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func stepEnd($i)
    Local $diff = TimerDiff($timer[$i])
    If $diff >= $waitTimeout Then
        MsgBox($MB_SYSTEMMODAL, "Info", "Instance #" & $i & ". Diff: " & $diff & ". End")
        Return $EXIT_SUCCESS
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;