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
$ERROR_SESSION,      _ ; Error use webdriver session
$ERROR_HANDLER,      _ ; Error use window handler
$ERROR_WORKER          ; Error call result procedure

Local Const $scheduler_period = 1000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Integer values
Local $scheduler_threads
Local $scheduler_timeout
Local $scheduler_time
Local $scheduler_tasks_qty
; Arrays
Local $scheduler_progress
Local $scheduler_counters
; Maps
Local $scheduler_callbacks
Local $scheduler_tasks
Local $scheduler_converse

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; HANDLERS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _scheduler_handler()
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
; SCHEDULER API
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func init()
    If $scheduler_threads <= 0 Or $scheduler_tasks_qty <= 0 Or $scheduler_timeout < 0 Then
        Return status($ERROR_INIT)
    EndIf
	Local $_response = $scheduler_callbacks['init']()
	If $_response < $ERROR_SUCCESS Then
		Return status($_response)
	EndIf
    Return status($ERROR_SUCCESS)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func dispose()
	Local $_response = $scheduler_callbacks['dispose']()
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

Func register($names, $threads = 1, $timeout = 15, $callbacks = [])
    $scheduler_timeout = $timeout
    $scheduler_threads = $threads
	$scheduler_tasks_qty = 0
    Local $_tasks[]
    Local $_converse[]
    For $name In $names
        If Not IsFunc($name) Then
            Return status($ERROR_REGISTER)
        Else
		    $_tasks[$scheduler_tasks_qty] = $name
            $_converse[FuncName($name)] = $scheduler_tasks_qty
            $scheduler_tasks_qty += 1
        EndIf
    Next
    $scheduler_tasks = $_tasks
	$scheduler_converse = $_converse
    Local $_progress[$scheduler_threads]
    Local $_counters[$scheduler_threads]
    $scheduler_progress = $_progress
    $scheduler_counters = $_counters
	Local $_callbacks[]
	$_callbacks['round'] = _scheduler_handler
	$_callbacks['timeout'] = _scheduler_handler
	$_callbacks['init'] = _scheduler_handler
	$_callbacks['dispose'] = _scheduler_handler
	For $key In MapKeys($callbacks)
	    $_callbacks[$key] = $callbacks[$key] 
	Next
	$scheduler_callbacks = $_callbacks
    Return status($ERROR_SUCCESS)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func process()
    Local $response[$scheduler_threads]
    If $scheduler_tasks_qty <= 0 Then
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
		Local $_response = $scheduler_callbacks['round']()
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
        Local $id = $scheduler_converse[$name]
        $scheduler_progress[$i] = $id
    Else
        $scheduler_progress[$i] += $step
    EndIf
    If $scheduler_progress[$i] > $scheduler_tasks_qty Then
        $scheduler_progress[$i] = $scheduler_tasks_qty
    ElseIf $scheduler_progress[$i] < 0 Then
        $scheduler_progress[$i] = 0
    EndIf
    $scheduler_counters[$i] = 0
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func worker($i)
	If $scheduler_counters[$i] > $scheduler_timeout Then
		$scheduler_counters[$i] = 0
		Return $scheduler_callbacks['timeout']($i)
    Else
	    $scheduler_counters[$i] += 1
    EndIf
	Local $id = Int($scheduler_progress[$i])
	Local $response = Int($scheduler_tasks[$id]($i))
	Return status($response)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;