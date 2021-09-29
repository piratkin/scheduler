#include "scheduler.au3"
#include <Date.au3>
#include <MsgBoxConstants.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Local $head
Local $sleep_timeout

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Local $pull
Local $objects

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LOGGINING
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $logfile = @ScriptDir & "\remove_" & @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC & ".log"
_FileWriteLog($logfile, "Start 'remove' logging")		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; HANDLERS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func timeout_handler($i)
	_FileWriteLog($logfile, "ERROR: #" & $i & ", TIMEOUT_HANDLER, count: " & $scheduler_counters[$i])
	MsgBox($MB_ICONINFORMATION, "Error", "Error timeout #" & $i, $scheduler_timeout)
	stepIt($i, stepBegin)
	Return status($ERROR_SUCCESS)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func dispose_handler($i)
    _FileWriteLog($logfile, "End 'remove' logging")
	FileClose($logfile)	
	Return status($ERROR_SUCCESS)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func round_handler()
    Local $diff = TimerDiff($scheduler_time)
	_FileWriteLog($logfile, "round_handler, scheduler_time: " & $scheduler_time & ", TimerDiff: " & $diff & " ms")
    Return status($ERROR_SUCCESS)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MAIN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func run_remove($parametrs, $threads = 8, $timeout = 30)
    Local $handlers = [ _
	    schedulerTasks, stepBegin, _
	    step1, step2, step3, _
		step4, step5, step6, step7, _
		step8, step9, _
		step10, step11, _
        stepEnd _
	]
	$head = 0
	$pull = $parametrs
	Local $objectSize = UBound($parametrs)
	If $threads <= 0 Or $objectSize <= 0 Then
	    Return $EXIT_FAILURE
	ElseIf $threads > $objectSize Then
	    $threads = $objectSize
	EndIf
	Local $_objects[$threads]
	$objects = $_objects
	$sleep_timeout = Floor($scheduler_period / $scheduler_threads)
    If register($handlers, $threads, $timeout, _
	    timeout_handler, round_handler, _
		dispose_handler) Then Return $error
    If scheduler() Then Return $error
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; HELPERS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; BEGINNIG
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func schedulerTasks($i)
    Local $_timer = TimerInit()
	Sleep($sleep_timeout)
	If $head < UBound($objects) Then
	    $objects[$i] = $pull[$head]
		$head += 1
		stepIt($i)
	Else
		_FileWriteLog($logfile, "ERROR: #" & $i & ", Clolse Task, count: " & $scheduler_counters[$i])
	    stepIt($i, stepEnd)
	EndIf
	_FileWriteLog($logfile, "#" & $i & ", schedulerTasks, count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func stepBegin($i)
    Local $_timer = TimerInit()
	Sleep($sleep_timeout)
	If remainingTime($i) = $objects[$i] Then
	    stepIt($i)
	EndIf
	_FileWriteLog($logfile, "#" & $i & ", stepBegin, wait: " & $objects[$i] & ", count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
EndFunc

Func step1($i)
    Local $_timer = TimerInit()
	Sleep($sleep_timeout)
	If remainingTime($i) = $objects[$i] Then
	    stepIt($i)
	EndIf
	_FileWriteLog($logfile, "#" & $i & ", step1, wait: " & $objects[$i] & ", count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
EndFunc

Func step2($i)
    Local $_timer = TimerInit()
	Sleep($sleep_timeout)
	If remainingTime($i) = $objects[$i] Then
	    stepIt($i)
	EndIf
	_FileWriteLog($logfile, "#" & $i & ", step2, wait: " & $objects[$i] & ", count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
EndFunc

Func step3($i)
    Local $_timer = TimerInit()
	Sleep($sleep_timeout)
	If remainingTime($i) = $objects[$i] Then
	    stepIt($i)
	EndIf
	_FileWriteLog($logfile, "#" & $i & ", step3, wait: " & $objects[$i] & ", count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
EndFunc

Func step4($i)
    Local $_timer = TimerInit()
	Sleep($sleep_timeout)
	If remainingTime($i) = $objects[$i] Then
	    stepIt($i)
	EndIf
	_FileWriteLog($logfile, "#" & $i & ", step4, wait: " & $objects[$i] & ", count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
EndFunc

Func step5($i)
    Local $_timer = TimerInit()
	Sleep($sleep_timeout)
	If remainingTime($i) = $objects[$i] Then
	    stepIt($i)
	EndIf
	_FileWriteLog($logfile, "#" & $i & ", step5, wait: " & $objects[$i] & ", count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
EndFunc

Func step6($i)
    Local $_timer = TimerInit()
	Sleep($sleep_timeout)
	If remainingTime($i) = $objects[$i] Then
	    stepIt($i)
	EndIf
	_FileWriteLog($logfile, "#" & $i & ", step6, wait: " & $objects[$i] & ", count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
EndFunc

Func step7($i)
    Local $_timer = TimerInit()
	Sleep($sleep_timeout)
	If remainingTime($i) = $objects[$i] Then
	    stepIt($i)
	EndIf
	_FileWriteLog($logfile, "#" & $i & ", step7, wait: " & $objects[$i] & ", count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
EndFunc

Func step8($i)
    Local $_timer = TimerInit()
	Sleep($sleep_timeout)
	If remainingTime($i) = $objects[$i] Then
	    stepIt($i)
	EndIf
	_FileWriteLog($logfile, "#" & $i & ", step8, wait: " & $objects[$i] & ", count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
EndFunc

Func step9($i)
    Local $_timer = TimerInit()
	Sleep($sleep_timeout)
	If remainingTime($i) = $objects[$i] Then
	    stepIt($i)
	EndIf
	_FileWriteLog($logfile, "#" & $i & ", step9, wait: " & $objects[$i] & ", count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
EndFunc

Func step10($i)
    Local $_timer = TimerInit()
	Sleep($sleep_timeout)
	If remainingTime($i) = $objects[$i] Then
	    stepIt($i)
	EndIf
	_FileWriteLog($logfile, "#" & $i & ", step10, wait: " & $objects[$i] & ", count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
EndFunc

Func step11($i)
    Local $_timer = TimerInit()
	Sleep($sleep_timeout)
	If remainingTime($i) = $objects[$i] Then
	    stepIt($i, schedulerTasks)
	EndIf
	_FileWriteLog($logfile, "#" & $i & ", step11, wait: " & $objects[$i] & ", count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func stepEnd($i)
    Local $_timer = TimerInit()
	Sleep($sleep_timeout)
    MsgBox($MB_ICONINFORMATION, "Debug", "Task #" & $i & " done!", 30)
	$s = session($i)
	_WD_DeleteSession($s)
	_FileWriteLog($logfile, "#" & $i & ", stepEnd, count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
    Return $EXIT_SUCCESS
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;