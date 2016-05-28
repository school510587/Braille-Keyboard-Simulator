#include <MsgBoxConstants.au3>
#include <StructureConstants.au3>
#include <WinAPI.au3>
#include <WindowsConstants.au3>
#include <WinAPIvkeysConstants.au3>

Global Enum Step *2 _; Flags for keyboard states (dots, the space bar, menu keys).
    $DOT_1 = 1, _
    $DOT_2, _
    $DOT_3, _
    $DOT_4, _
    $DOT_5, _
    $DOT_6, _
    $DOT_7, _
    $DOT_8, _
    $SPACE_BAR, _
    $LMENU_PRESSED, _
    $RMENU_PRESSED, _
    $SIX_DOTS_MASK = BitOR($DOT_1, $DOT_2, $DOT_3, $DOT_4, $DOT_5, $DOT_6)
    $EIGHT_DOTS_MASK = BitOR($SIX_DOTS_MASK, $DOT_7, $DOT_8)
    $BRL_MASK = BitOR($EIGHT_DOTS_MASK, $SPACE_BAR)
    $LRMENU_MASK = BitOr($LMENU_PRESSED, $RMENU_PRESSED)
Global $g_hHook, $g_hStub_KeyProc

Example()

Func Example()
    OnAutoItExitRegister("Cleanup")

    Local $hMod

    $g_hStub_KeyProc = DllCallbackRegister("_KeyProc", "long", "int;wparam;lparam")
    $hMod = _WinAPI_GetModuleHandle(0)
    $g_hHook = _WinAPI_SetWindowsHookEx($WH_KEYBOARD_LL, DllCallbackGetPtr($g_hStub_KeyProc), $hMod)

    Run("notepad.exe")
    WinWait("[CLASS:Notepad]")
    WinActivate("[CLASS:Notepad]")

    While 1
        Sleep(10)
    WEnd
EndFunc

Func _KeyProc($nCode, $wParam, $lParam)
    Local Enum $KB_NORMAL = 0, $KB_BRL_ENGLISH, $KB_BRL_CHINESE
    Static $dots = 0, $state[] = [0, 0], $mode = $KB_NORMAL
    If $nCode < 0 Then Return _WinAPI_CallNextHookEx($g_hHook, $nCode, $wParam, $lParam)
    Local $tKEYHOOKS = DllStructCreate($tagKBDLLHOOKSTRUCT, $lParam)
    Local $iFlags = DllStructGetData($tKEYHOOKS, "flags")
    If BitAND($iFlags, $LLKHF_INJECTED) Then Return _WinAPI_CallNextHookEx($g_hHook, $nCode, $wParam, $lParam)
    Local $vkCode = DllStructGetData($tKEYHOOKS, "vkCode")
    Local $k = IsBRLKey($vkCode)
    If $wParam = $WM_KEYUP Then
        If $k Then
            $state[1] = BitAND($state[1], BitNOT($k))
            If BitAND($state[0], $BRL_MASK) And Not BitAND($state[1], $BRL_MASK) Then
                If $state[0] = $SPACE_BAR Then; Single space bar.
                    If $mode Then Send("{SPACE}")
                ElseIf BitAND($state[0], $SPACE_BAR) Then
                    Switch BitAND($state[0], $EIGHT_DOTS_MASK)
                      Case BitOR($DOT_1, $DOT_2, $DOT_3)
                        $mode = BitXOR($mode, $KB_BRL_ENGLISH)
                      Case Else
                        _WinAPI_MessageBeep(4)
                    EndSwitch
                ElseIf $mode Then; It is in BRL mode.
                    $dots = BRL2Chr(BitAND($state[0], $BRL_MASK))
                    If $dots Then; Valid BRL inputs.
                        Send($dots, 1)
                    Else
                        _WinAPI_MessageBeep()
                    EndIf
                EndIf
                $state[0] = BitAND($state[0], BitNOT($BRL_MASK))
            EndIf
            If $mode Then Return 1
        ElseIf $vkCode = $VK_LCONTROL Then
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
                  Case Else
                    Send("{LCTRL}")
                EndSwitch
                $state[0] = BitAND($state[0], BitNOT($LRMENU_MASK))
            EndIf
            Return 1
        ElseIf $vkCode = $VK_RCONTROL Then
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
                  Case Else
                    Send("{RCTRL}")
                EndSwitch
                $state[0] = BitAND($state[0], BitNOT($LRMENU_MASK))
            EndIf
            Return 1
        ElseIf $vkCode = $VK_ESCAPE Then
            Exit
        EndIf
    ElseIf $wParam = $WM_KEYDOWN Then
        If $k Then
            $state[1] = BitOR($state[1], $k)
            $state[0] = BitOR($state[0], $k)
            If $mode Then Return 1
        ElseIf $vkCode = $VK_LCONTROL Then
            $state[1] = BitOr($state[1], $LMENU_PRESSED)
            If Not BitAND($state[0], $LRMENU_MASK) And BitAND($state[1], $RMENU_PRESSED) Then $state[0] = BitOr($state[0], $RMENU_PRESSED)
            Return 1
        ElseIf $vkCode = $VK_RCONTROL Then
            $state[1] = BitOr($state[1], $RMENU_PRESSED)
            If Not BitAND($state[0], $LRMENU_MASK) And BitAND($state[1], $LMENU_PRESSED) Then $state[0] = BitOr($state[0], $LMENU_PRESSED)
            Return 1
        EndIf
    EndIf
    Return _WinAPI_CallNextHookEx($g_hHook, $nCode, $wParam, $lParam)
EndFunc

Func BRL2Chr($iBRL); BRL to character, except the space.
    Static $raw = "a1b'k2l`cif/msp""e3h9o6r~djg>ntq,*5<-u8v.%{$+x!&;:4|0z7(_?w}#y)="; It must be constant.
    Local $c = StringMid($raw, BitAND($iBRL, $SIX_DOTS_MASK), 1)
    If BitAND($iBRL, $DOT_7) Then
        $c = Asc($c)
        Switch $c
          Case Asc("`") To Asc("~")
            $c = Chr($c - 32)
        Case Else
            $c = ""
        EndSwitch
    EndIf
    Return $c
EndFunc

Func Cleanup()
    _WinAPI_UnhookWindowsHookEx($g_hHook)
    DllCallbackFree($g_hStub_KeyProc)
EndFunc

Func IsBRLKey($iKeycode)
    Switch $iKeycode
      Case $VK_A
        Return $DOT_7
      Case $VK_D
        Return $DOT_2
      Case $VK_F
        Return $DOT_1
      Case $VK_J
        Return $DOT_4
      Case $VK_K
        Return $DOT_5
      Case $VK_L
        Return $DOT_6
      Case $VK_S
        Return $DOT_3
      Case $VK_SPACE
        Return $SPACE_BAR
    EndSwitch
    Return 0; Not a BRL key.
EndFunc
