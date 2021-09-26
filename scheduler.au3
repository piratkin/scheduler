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

Global Enum Step -1  _
$EXIT_SUCCESS   = 1, _ ; Successful work result
$ERROR_SUCCESS  = 0, _ ; Success response execution
$EXIT_FAILURE,       _ ; Failure work result
$ERROR_REGISTER,     _ ; Error register function
$ERROR_PROCESS,      _ ; Runtime error
$ERROR_INIT,         _ ; Error initialize
$ERROR_DISPOSE,      _ ; Error dispose
$ERROR_TIMEOUT,      _ ; Error runtime timeout
$ERROR_WORKER            ; Error call result procedure
            
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func status($id)
    Global $error = $id
    Return $error
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func init()
    If $scheduler_threads <= 0 Or $scheduler_stageQty <= 0 Or $scheduler_timeout < 0 Then
        Return status($ERROR_INIT)
    EndIf
	_WD_Option('Driver', 'chromedriver.exe')
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--silent --disable-gpu --log-path="' & @ScriptDir & '\chrome.log"')
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
        Local $title = "data:, - Google Chrome"
        Local $handler = WinWaitActive($title, "", $scheduler_timeout) 
        If $handler Then
            $scheduler_handlers[$i] = $handler
        EndIf
    Next
    Return status($ERROR_SUCCESS)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func dispose()
    For $session In $scheduler_sessions
        _WD_DeleteSession($session)
        If Not @error = $_WD_ERROR_Success Then
            Return status($ERROR_DISPOSE)
        EndIf
    Next
    _WD_Shutdown()
    For $handler In $scheduler_handlers
        If $handler Then
            WinClose($handler)
        EndIf
    Next
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

Func register($names, $threads = 1, $timeout = 15)
    Local $id = 0
    Local $_callbacks[]
    Local $_pointers[]
    For $name In $names
        If Not IsFunc($name) Then
            Return status($ERROR_REGISTER)
        Else
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
                If $response[$i] = $ERROR_SUCCESS Then
                    $repeat = True
                EndIf
            EndIf
        Next
        Local $diff = TimerDiff($scheduler_time)
        If $diff < 1000 And $repeat Then
            Sleep(1000 - $diff)
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
    If IsFunc($step) Then
        $step = $scheduler_pointers[FuncName($step)]
        $scheduler_progress[$i] = $step
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

Func countIt($i) 
    Global $stepId = $scheduler_progress[$i]
    If $scheduler_counters[$i] <= $scheduler_timeout Then
        $scheduler_counters[$i] += 1
    Else
        $scheduler_progress[$i] = $scheduler_stageQty
    EndIf
    Return Int($scheduler_progress[$i])
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func worker($i)
    Local $_error = $ERROR_SUCCESS
    Local $id = countIt($i)
    If $id = $scheduler_stageQty Then
        $_error = $ERROR_TIMEOUT
    ElseIf $id < $scheduler_stageQty Then
        $_error = $scheduler_callbacks[$id]($i)
    Else
        $_error = $ERROR_WORKER
    EndIf
    Return status($_error)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;