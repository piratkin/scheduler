#include "wd_core.au3"
#include "wd_helper.au3"
#include <MsgBoxConstants.au3>
#include <ExcelConstants.au3>
#include <GUIConstantsEx.au3>
#include <ButtonConstants.au3>
#include <WindowsConstants.au3>
#include <StringConstants.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Local $handlers
Local $sessions

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SCHEDULER HELPERS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func remainingTime($i)
    If check($i) Then Return $error
    Local $timer = 0
	If $scheduler_counters[$i] < $scheduler_timeout Then
	    $timer = Int($scheduler_timeout - $scheduler_counters[$i])
	EndIf
    Return $timer
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WEBDRIVER HELPERS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func closeSession($i)
	If $scheduler_threads > $i Then
		If _WD_DeleteSession($sessions[$i]) Then
			Return status($ERROR_SUCCESS)
		EndIf
	EndIf
	Return status($ERROR_SESSION)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func findTags($i, $tag)
    If check($i) Then Return $error
    Local $s = $sessions[$i]
	Local $e = _WD_FindElement($s, $_WD_LOCATOR_ByXPath, $tag, "", True)
	If @error = $_WD_ERROR_Success Then
		Return Ubound($e)
	EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func clickTagEx($i, $tag)
    If check($i) Then Return $error
    Local $s = $sessions[$i]
	Local $e = _WD_FindElement($s, $_WD_LOCATOR_ByXPath, $tag)
	If @error = $_WD_ERROR_Success Then
	    _WD_ElementActionEx($s, $e, "hover")
		_WD_ElementActionEx($s, $e, 'clickandhold')
		If @error = $_WD_ERROR_Success Then
		    Return True
		EndIf
	EndIf
	Return False
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func clickTag($i, $tag)
    If check($i) Then Return $error
    Local $s = $sessions[$i]
	Local $e = _WD_FindElement($s, $_WD_LOCATOR_ByXPath, $tag)
	If @error = $_WD_ERROR_Success Then
		_WD_ElementAction($s, $e, 'click')
		If @error = $_WD_ERROR_Success Then
		    Return True
		EndIf
	EndIf
	Return False
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func inputTag($i, $tag, $value)
    If check($i) Then Return $error
    Local $s = $sessions[$i]
	Local $e = _WD_FindElement($s, $_WD_LOCATOR_ByXPath, $tag)
	If @error = $_WD_ERROR_Success Then
	    _WD_ElementAction($s, $e, "clear")
		_WD_SetElementValue($s, $e, $value, $_WD_OPTION_Advanced)
		If @error = $_WD_ERROR_Success Then
			Return True
		EndIf
	EndIf
	Return False
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func openUrl($i, $url, $timeout = 15)
	Local $s = $sessions[$i]
	Local $response = _WD_Timeouts($s)
	Local $json = Json_Decode($response)
	Local $_timeout = Json_Encode(Json_Get($json, "[value]"))
	_WD_Timeouts($s, '{"pageLoad":' & $timeout * 1000 & '}')
	_WD_Timeouts($s)
	_WD_Navigate($s, $url)
	_WD_Timeouts($s, $_timeout)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; AUTOIT HELPERS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func closeAllWindows($title, $text = "", $timeout = 15)
    Local $counter = 0
    Local $windows = WinList($title, $text)
	For $i = 1 To $windows[0][0]
	    Local $handler = $windows[$i][1]
		WinClose($handler)
		; WinWaitClose($handler, $text, $timeout)
		$counter += 1
	Next
	Return $counter
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func closeWindow($i)
    If $scheduler_threads > $i And $handlers[$i] Then
		If WinClose($handlers[$i]) Then
		    $handlers[$i] = 0
			Return status($ERROR_SUCCESS)
		EndIf
	EndIf
	Return status($ERROR_HANDLER)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func clickAnywhere($i)
    If $scheduler_threads > $i And $handlers[$i] Then
		Opt("MouseCoordMode", 0)
		If ControlClick($handlers[$i], "", "", "left", 1, 10, 100) Then
			Return status($ERROR_SUCCESS)
		EndIf
	EndIf
	Return status($ERROR_HANDLER)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;