#include "scheduler_helper.au3"
#include "wd_core.au3"
#include "wd_helper.au3"
#include <GuiComboBoxEx.au3>
#include <GUIConstantsEx.au3>
#include <ButtonConstants.au3>
#include <WindowsConstants.au3>
#include <StringConstants.au3>
#include <Array.au3>
#include <File.au3>
#include <Excel.au3>
#include <Misc.au3>
#include <WinAPIFiles.au3>
#include <MsgBoxConstants.au3>
#include <ExcelConstants.au3>
#include <MsgBoxConstants.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global Enum Step -1  _
$EXIT_SUCCESS   = 1, _ ; Successful work result
$ERROR_SUCCESS  = 0, _ ; Success response execution
$EXIT_FAILURE,       _ ; Failure work result
$ERROR_REGISTER,     _ ; Error register function
$ERROR_PROCESS,      _ ; Runtime error
$ERROR_INIT,         _ ; Error initialize
$ERROR_DISPOSE,      _ ; Error dispose
$ERROR_TIMEOUT,      _ ; Error runtime timeout
$ERROR_INDEXING,     _ ; Error value range exceeded
$ERROR_WORKER          ; Error call result procedure

Local Const $scheduler_period = 1000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Integer values
Local $scheduler_threads
Local $scheduler_timeout
Local $scheduler_time
Local $scheduler_stageQty
; Arrays
Local $scheduler_sessions
Local $scheduler_progress
Local $scheduler_counters
Local $scheduler_handlers
; Maps
Local $scheduler_callbacks
Local $scheduler_pointers
; callbacks
Local $scheduler_error_handler
Local $scheduler_round_handler
Local $scheduler_dispose_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; HANDLERS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _scheduler_error_handler($i)
    MsgBox($MB_ICONINFORMATION, "Error", "Error timeout #" & $i)
	Return status($ERROR_TIMEOUT)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _scheduler_round_handler()
    Return status($ERROR_SUCCESS)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _scheduler_dispose_handler()
    Return status($ERROR_SUCCESS)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; HELPERS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func status($_error)
    Global $error = $_error
    Return $error
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func check($i)
    If $i < $scheduler_threads Then Return status($ERROR_SUCCESS)
	MsgBox($MB_ICONINFORMATION, "Error", "Invalid index '" & $i & "' value!", $scheduler_timeout)
    Return $ERROR_INDEXING
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func clear()
	Local $titles = [ _
	    "[REGEXPTITLE:^data:, - Google Chrome$; CLASS:Chrome_WidgetWin_1]", _
		"[REGEXPTITLE:^www - Google Chrome$; CLASS:Chrome_WidgetWin_1]" _
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
			    closeWindows($title)
			Next
		EndIf
	EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SCHEDULER API
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func init()
    If $scheduler_threads <= 0 Or $scheduler_stageQty <= 0 Or $scheduler_timeout < 0 Then
        Return status($ERROR_INIT)
    EndIf
	clear()
	_WD_Option('Driver', 'chromedriver.exe')
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--silent --disable-gpu --log-path="' & @ScriptDir & '\chrome.log"')
	_WD_Option('DefaultTimeout', Round($scheduler_period  / $scheduler_threads))
	Local $timeout = $scheduler_timeout * $scheduler_period 
	; $_WD_HTTPTimeOuts[4] = [0, $timeout, $timeout, $timeout]
	$_WD_HTTPTimeOuts[1] = $timeout
	$_WD_HTTPTimeOuts[2] = $timeout
	$_WD_HTTPTimeOuts[3] = $timeout
	_WD_Option('HTTPTimeouts', True)
	Local $options = '{"capabilities": {"alwaysMatch": {"goog:chromeOptions": {"w3c": true, "excludeSwitches": [ "enable-automation"], "prefs":{"download":{"prompt_for_download":true}, "credentials_enable_service": false, "profile": {"password_manager_enabled": false}}}}}}'
    _WD_Startup()
    If Not @error = $_WD_ERROR_Success Then
        Return status($ERROR_INIT)
    EndIf
    For $i = 0 To $scheduler_threads - 1
        $scheduler_sessions[$i] = _WD_CreateSession($options)
        If Not @error = $_WD_ERROR_Success Then
            _WD_Shutdown()
            Return status($ERROR_INIT)
        EndIf
		$title = "data:, - Google Chrome"
        Local $handler = WinWaitActive($title, "", $scheduler_timeout) 
        If $handler Then
            $scheduler_handlers[$i] = $handler
		Else
		    _WD_Shutdown()
            Return status($ERROR_INIT)
        EndIf
    Next
    Return status($ERROR_SUCCESS)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func dispose()
	For $session In $scheduler_sessions
		If $session Then 
			_WD_DeleteSession($session)
			If Not @error = $_WD_ERROR_Success Then
				Return status($ERROR_DISPOSE)
			EndIf
		EndIf
    Next
    _WD_Shutdown()
    For $handler In $scheduler_handlers
        If $handler Then
            WinClose($handler)
        EndIf
    Next
	Local $_response = $scheduler_dispose_handler()
	If $_response < $ERROR_SUCCESS Then
		Return status($_response)
	EndIf
    Return status($ERROR_SUCCESS)
EndFunc 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func scheduler()
    If init() Then Return $error
    Local $_error = $ERROR_SUCCESS
    If process() Then 
        $_error = $error
    EndIf
    If dispose() Then 
        Return $error
    EndIf
    Return status($_error)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func register($names, $threads = 1, $timeout = 15, _
    $error_handler = _scheduler_error_handler, _
	$round_handler = _scheduler_round_handler, _ 
	$dispose_handler = _scheduler_dispose_handler)
    Local $id = 0
    Local $_callbacks[]
    Local $_pointers[]
    For $name In $names
        If Not IsFunc($name) Then
            Return status($ERROR_REGISTER)
        Else
		    ; MsgBox($MB_ICONINFORMATION, "Initialization", "name: " & FuncName($name) & ", id: " & $id)
            $_callbacks[$id] = $name
            $_pointers[FuncName($name)] = $id
            $id += 1
        EndIf
    Next
    $scheduler_stageQty = $id
    $scheduler_threads = $threads
    $scheduler_timeout = $timeout
    $scheduler_callbacks = $_callbacks
    $scheduler_pointers = $_pointers
    Local $_sessions[$threads]
    Local $_progress[$threads]
    Local $_counters[$threads]
    Local $_handlers[$threads]
    $scheduler_progress = $_progress
    $scheduler_counters = $_counters
    $scheduler_sessions = $_sessions
    $scheduler_handlers = $_handlers
	$scheduler_error_handler = $error_handler
	$scheduler_round_handler = $round_handler
	$scheduler_dispose_handler = $dispose_handler
    Return status($ERROR_SUCCESS)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func process()
    Local $response[$scheduler_threads]
    If $scheduler_stageQty <= 0 Then
        Return status($ERROR_PROCESS)
    EndIf
    Do
        Local $repeat = False
        $scheduler_time = TimerInit()
        For $i = 0 To $scheduler_threads - 1
            If $response[$i] = $ERROR_SUCCESS Then
                $response[$i] = worker($i)
                If $error = $ERROR_SUCCESS Then
                    $repeat = True
				EndIf
            EndIf
        Next
		Local $_response = $scheduler_round_handler()
		If $_response < $ERROR_SUCCESS Then
		    Return status($_response)
		EndIf
        Local $diff = TimerDiff($scheduler_time)
        If $diff < $scheduler_period And $repeat Then
            Sleep($scheduler_period - $diff)
        EndIf
    Until Not $repeat
    For $i = 0 To $scheduler_threads - 1
        If $response[$i] < $ERROR_SUCCESS Then
            Return status($response[$i])
        EndIf
    Next
    Return status($ERROR_SUCCESS)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func stepIt($i, $step = 1)
	If check($i) Then Return $error
	If IsFunc($step) Then
	    Local $name = FuncName($step)
        Local $id = $scheduler_pointers[$name]
        $scheduler_progress[$i] = $id
    Else
        $scheduler_progress[$i] += $step
    EndIf
    If $scheduler_progress[$i] > $scheduler_stageQty Then
        $scheduler_progress[$i] = $scheduler_stageQty
    ElseIf $scheduler_progress[$i] < 0 Then
        $scheduler_progress[$i] = 0
    EndIf
    $scheduler_counters[$i] = 0
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func worker($i)
	If $scheduler_counters[$i] > $scheduler_timeout Then
		$scheduler_counters[$i] = 0
		Return $scheduler_error_handler($i)
    Else
	    $scheduler_counters[$i] += 1
    EndIf
	Local $id = Int($scheduler_progress[$i])
	Local $response = Int($scheduler_callbacks[$id]($i))
	Return status($response)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;