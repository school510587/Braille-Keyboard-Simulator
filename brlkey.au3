#include <Array.au3>
#include <MsgBoxConstants.au3>
#include <StructureConstants.au3>
#include <WinAPI.au3>
#include <WindowsConstants.au3>
#include <WinAPISys.au3>
#include <WinAPIvkeysConstants.au3>
#include "helper.au3"

Global $g_hHook, $g_hStub_KeyProc

Example()

Func Example()
    OnAutoItExitRegister("Cleanup")

    Local $hMod

    $g_hStub_KeyProc = DllCallbackRegister("_KeyProc", "long", "int;wparam;lparam")
    $hMod = _WinAPI_GetModuleHandle(0)
    $g_hHook = _WinAPI_SetWindowsHookEx($WH_KEYBOARD_LL, DllCallbackGetPtr($g_hStub_KeyProc), $hMod)

    Local $pid = Run("notepad.exe")
    WinWait("[CLASS:Notepad]")
    WinActivate("[CLASS:Notepad]")

    While ProcessExists($pid)
        Sleep(10)
    WEnd
EndFunc

Func _KeyProc($nCode, $wParam, $lParam)
    Local Enum $KB_NORMAL = 0, $KB_BRL_ENGLISH, $KB_BRL_CHINESE
    Static $dots[9] = [0], $state[] = [0, 0], $mode = $KB_NORMAL, $buffer = "", $hKL = 0
    If $nCode < 0 Then Return _WinAPI_CallNextHookEx($g_hHook, $nCode, $wParam, $lParam)
    Local $tKEYHOOKS = DllStructCreate($tagKBDLLHOOKSTRUCT, $lParam)
    Local $iFlags = DllStructGetData($tKEYHOOKS, "flags")
    If BitAND($iFlags, $LLKHF_INJECTED) Then Return _WinAPI_CallNextHookEx($g_hHook, $nCode, $wParam, $lParam)
    Local $hKL_current = _WinAPI_GetKeyboardLayout(_WinAPI_GetForegroundWindow())
    If $hKL_current <> $hKL Then $buffer = ""
    $hKL = $hKL_current
    Local $vkCode = DllStructGetData($tKEYHOOKS, "vkCode")
    Switch $wParam
      Case $WM_KEYUP
        Switch $vkCode
          Case $VK_LMENU
            $state[1] = BitAND($state[1], BitNOT($LMENU_PRESSED))
            If Not BitAND($state[1], $LRMENU_MASK) Then
                Switch BitAND($state[0], $LRMENU_MASK)
                  Case $RMENU_PRESSED
                    _WinAPI_MessageBeep(2)
                    $mode = $KB_NORMAL
                    ;_WinAPI_MessageBeep()
                  Case $LMENU_PRESSED
                    $mode = $KB_BRL_ENGLISH
                    _WinAPI_MessageBeep()
                  Case 0; Single LALT press.
                    Send("{LALT}")
                  Case Else
                    Send("{ALT up}")
                EndSwitch
                $state[0] = BitAND($state[0], BitNOT($LRMENU_MASK))
            EndIf
            Return 1
          Case $VK_RMENU
            $state[1] = BitAND($state[1], BitNOT($RMENU_PRESSED))
            If Not BitAND($state[1], $LRMENU_MASK) Then
                Switch BitAND($state[0], $LRMENU_MASK)
                  Case $RMENU_PRESSED
                    _WinAPI_MessageBeep(2)
                    $mode = $KB_NORMAL
                    ;_WinAPI_MessageBeep()
                  Case $LMENU_PRESSED
                    $mode = $KB_BRL_ENGLISH
                    _WinAPI_MessageBeep()
                  Case 0; Single RALT press.
                    Send("{RALT}")
                  Case Else
                    Send("{ALT up}")
                EndSwitch
                $state[0] = BitAND($state[0], BitNOT($LRMENU_MASK))
            EndIf
            Return 1
        EndSwitch
        Local $k = IsBRLKey($vkCode)
        If $k Then
            If BitAND($state[1], $k) Then
                $state[1] = BitAND($state[1], BitNOT($k))
                If BitAND($state[0], $BRL_MASK) And Not BitAND($state[1], $BRL_MASK) Then
                    If $state[0] = $SPACE_BAR Then; Single space bar.
                        $buffer &= " "
                    ElseIf BitAND($state[0], $SPACE_BAR) Then
                        Switch BitAND($state[0], $EIGHT_DOTS_MASK)
                          Case BitOR($DOT_1, $DOT_2, $DOT_3)
                            $mode = BitXOR($mode, $KB_BRL_ENGLISH)
                          Case BitOR($DOT_2, $DOT_4, $DOT_5)
                            $buffer = ""
                          Case Else
                            _WinAPI_MessageBeep(4)
                        EndSwitch
                        $buffer = ""
                    ElseIf $mode Then; It is in BRL mode.
                        $dots[0] = BRL2Chr(BitAND($state[0], $BRL_MASK))
                        If $dots[0] Then; Valid BRL input.
                            $buffer &= $dots[0]
                        Else
                            _WinAPI_MessageBeep()
                        EndIf
                    Else
                        $dots[0] = _ArrayToString($dots, "", 1, $dots[0])
                        $dots[0] = StringLower($dots[0])
                        Send($dots[0], 1)
                        $buffer = ""
                    EndIf
                    If $buffer Then; Non-empty buffer.
                        $dots[0] = BRL2Key($buffer, $hKL)
                        If $dots[0] Then; Valid BRL string.
                            If StringIsAlpha($dots[0]) Then
                                $dots[0] = StringLower($dots[0])
                                If BitXOR((BitAND($state[0], $DOT_7)) ? 1 : 0, _WinAPI_GetKeyState($VK_CAPITAL)) Then $dots[0] = "+" & $dots[0]
                                Send($dots[0], 0)
                            Else
                                Send($dots[0], 1)
                            EndIf
                            $buffer = ""
                        ElseIf @error Then
                            _WinAPI_MessageBeep()
                        EndIf
                    EndIf
                    $dots[0] = 0
                    $state[0] = BitAND($state[0], BitNOT($BRL_MASK))
                EndIf
                Return 1
            EndIf
        Else
            $state[1] = BitAND($state[1], BitNOT(ModifierKey2Flag($vkCode)))
        EndIf
      Case $WM_KEYDOWN
        Local $k = IsBRLKey($vkCode)
        If $k Then
            If Not BitAND($state[1], $MODIFIER_KEY_MASK) Then
                If Not BitAND($state[0], $k) Then
                    $dots[0] += 1
                    $dots[$dots[0]] = Chr($vkCode)
                EndIf
                $state[1] = BitOR($state[1], $k)
                $state[0] = BitOR($state[0], $k)
                Return 1
            EndIf
        Else
            $state[1] = BitOR($state[1], ModifierKey2Flag($vkCode))
        EndIf
      Case $WM_SYSKEYDOWN
        If $vkCode = $VK_LMENU Then
            $state[1] = BitOr($state[1], $LMENU_PRESSED)
            If Not BitAND($state[0], $LRMENU_MASK) And BitAND($state[1], $RMENU_PRESSED) Then $state[0] = BitOr($state[0], $RMENU_PRESSED)
            Return 1
        ElseIf $vkCode = $VK_RMENU Then
            $state[1] = BitOr($state[1], $RMENU_PRESSED)
            If Not BitAND($state[0], $LRMENU_MASK) And BitAND($state[1], $LMENU_PRESSED) Then $state[0] = BitOr($state[0], $LMENU_PRESSED)
            Return 1
        Else; Let The keydown message go without additional one ALT press.
            Send("{ALT down}")
            $state[0] = BitOR($state[0], $LRMENU_MASK)
        EndIf
    EndSwitch
    Return _WinAPI_CallNextHookEx($g_hHook, $nCode, $wParam, $lParam)
EndFunc

Func Cleanup()
    _WinAPI_UnhookWindowsHookEx($g_hHook)
    DllCallbackFree($g_hStub_KeyProc)
EndFunc
