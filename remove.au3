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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Local $pull
Local $objects

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MAIN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func run_remove($parametrs, $threads = 8, $timeout = 30)
    Local $_handlers = [ _
	    schedulerTasks, stepBegin, _
	    step1, step2, step3, _
        stepEnd _
	]
	$head = 0
	$pull = $parametrs
	Local $parametrs_size = UBound($parametrs)
	If $threads <= 0 Or $parametrs_size <= 0 Then
	    Return $EXIT_FAILURE
	ElseIf $threads > $parametrs_size Then
	    $threads = $parametrs_size
	EndIf
	Local $threads_pull[$threads]
	$objects = $threads_pull
	Local $callbacks[]
	$callbacks["init"] = init_handler
	$callbacks["dispose"] = dispose_handler
	$callbacks["round"] = round_handler
	$callbacks["timeout"] = timeout_handler
    If register($_handlers, $threads, $timeout, $callbacks) Then Return $error
    If scheduler() Then Return $error
	Return status($ERROR_SUCCESS)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; HELPERS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func wait()
    Local $timeout = Floor($scheduler_period / $scheduler_timeout)
    Sleep($timeout)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func clear_unclosed_session()
	Local $titles = [ _
	    "[REGEXPTITLE:^data:, - Google Chrome$; CLASS:Chrome_WidgetWin_1]" _
	]
	Local $window_check_exist = False
	For $title In $titles
	    If WinExists($title) Then
		    $window_check_exist = True
		EndIf
	Next
	If $window_check_exist Then
	    Local $resp = MsgBox($MB_YESNO + $MB_ICONQUESTION, _
		    'Question', 'Clean previous session?', $scheduler_timeout)
	    If $resp = 6 Or $resp = -1 Then
			For $title In $titles
			    closeAllWindows($title)
			Next
		EndIf
	EndIf
EndFunc


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

Func init_handler()
	clear_unclosed_session()
	_WD_Option('Driver', 'chromedriver.exe')
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--silent --disable-gpu --log-path="' & @ScriptDir & '\chrome.log"')
	_WD_Option('DefaultTimeout', Round($scheduler_period  / $scheduler_threads))
	Local $timeout = $scheduler_timeout * $scheduler_period 
	$_WD_HTTPTimeOuts[1] = $timeout
	$_WD_HTTPTimeOuts[2] = $timeout
	$_WD_HTTPTimeOuts[3] = $timeout
	_WD_Option('HTTPTimeouts', True)
	Local $options = '{"capabilities": {"alwaysMatch": {"goog:chromeOptions": {"w3c": true, "excludeSwitches": [ "enable-automation"], "prefs":{"download":{"prompt_for_download":true}, "credentials_enable_service": false, "profile": {"password_manager_enabled": false}}}}}}'
    _WD_Startup()
    If Not @error = $_WD_ERROR_Success Then
        Return status($ERROR_INIT)
    EndIf
	Local $_handlers[$scheduler_threads]
	Local $_sessions[$scheduler_threads]
    For $i = 0 To $scheduler_threads - 1
        $_sessions[$i] = _WD_CreateSession($options)
        If Not @error = $_WD_ERROR_Success Then
            _WD_Shutdown()
            Return status($ERROR_INIT)
        EndIf
		$title = "data:, - Google Chrome"
        Local $handler = WinWaitActive($title, "", $scheduler_timeout) 
        If $handler Then
            $_handlers[$i] = $handler
		Else
		    _WD_Shutdown()
            Return status($ERROR_INIT)
        EndIf
    Next
	$handlers = $_handlers
	$sessions = $_sessions
	Return status($ERROR_SUCCESS)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func dispose_handler()
	_WD_Shutdown()
	Return status($ERROR_SUCCESS)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func round_handler()
    Local $diff = TimerDiff($scheduler_time)
	_FileWriteLog($logfile, "round_handler, scheduler_time: " & $scheduler_time & ", TimerDiff: " & $diff & " ms")
    Return status($ERROR_SUCCESS)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; BEGINNIG
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func schedulerTasks($i)
    Local $_timer = TimerInit()
	wait()
	If $head < Ubound($pull) Then
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
	If remainingTime($i) = $objects[$i] Then
	    wait()
	    stepIt($i)
	EndIf
	_FileWriteLog($logfile, "#" & $i & ", stepBegin, wait: " & $objects[$i] & ", count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func step1($i)
    Local $_timer = TimerInit()
	If remainingTime($i) = $objects[$i] Then
	    wait()
	    stepIt($i)
	EndIf
	_FileWriteLog($logfile, "#" & $i & ", step1, wait: " & $objects[$i] & ", count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
EndFunc

Func step2($i)
    Local $_timer = TimerInit()
	If remainingTime($i) = $objects[$i] Then
	    wait()
	    stepIt($i)
	EndIf
	_FileWriteLog($logfile, "#" & $i & ", step2, wait: " & $objects[$i] & ", count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
EndFunc

Func step3($i)
    Local $_timer = TimerInit()
	If remainingTime($i) = $objects[$i] Then
	    wait()
	    stepIt($i)
	EndIf
	_FileWriteLog($logfile, "#" & $i & ", step3, wait: " & $objects[$i] & ", count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func stepEnd($i)
    Local $_timer = TimerInit()
	wait()
    MsgBox($MB_ICONINFORMATION, "Debug", "Task #" & $i & " done!", 1)
	If closeSession($i) Then Return $error
	_FileWriteLog($logfile, "#" & $i & ", stepEnd, count: " & $scheduler_counters[$i] & ", diff: " & TimerDiff($_timer) & " ms")
    Return $EXIT_SUCCESS
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;