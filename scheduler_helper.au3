#include "wd_core.au3"
#include "wd_helper.au3"
#include <MsgBoxConstants.au3>
#include <ExcelConstants.au3>
#include <GUIConstantsEx.au3>
#include <ButtonConstants.au3>
#include <WindowsConstants.au3>
#include <StringConstants.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SCHEDULER HELPERS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func session($i)
    Return $scheduler_sessions[$i]
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func handler($i)
    Return $scheduler_handlers[$i]
EndFunc

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

Func clickAnywhere($i)
    If check($i) Then Return $error
    Opt("MouseCoordMode", 0)
	Local $s = $scheduler_handlers[$i]
	If Not $s Then
		return False
	EndIf
	Return ControlClick($s, "", "", "left", 1, 10, 100)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func findTags($i, $tag)
    If check($i) Then Return $error
    Local $s = $scheduler_sessions[$i]
	Local $e = _WD_FindElement($s, $_WD_LOCATOR_ByXPath, $tag, "", True)
	If @error = $_WD_ERROR_Success Then
		Return Ubound($e)
	EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func clickTagEx($i, $tag)
    If check($i) Then Return $error
    Local $s = $scheduler_sessions[$i]
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
    Local $s = $scheduler_sessions[$i]
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
    Local $s = $scheduler_sessions[$i]
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

Func openUrl($i, $url, $timeout = 15)
	Local $s = $scheduler_sessions[$i]
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

Func closeWindows($title, $text = "", $timeout = 15)
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