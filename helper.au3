#include-once

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
    $CAPSLOCK_PRESSED, _
    $INSERT_PRESSED, _
    $LWIN_PRESSED, _
    $RWIN_PRESSED, _
    $NUMPAD0_PRESSED, _
    $LSHIFT_PRESSED, _
    $RSHIFT_PRESSED, _
    $LCONTROL_PRESSED, _
    $RCONTROL_PRESSED, _
    $LMENU_PRESSED, _
    $RMENU_PRESSED, _
    $SIX_DOTS_MASK = BitOR($DOT_1, $DOT_2, $DOT_3, $DOT_4, $DOT_5, $DOT_6), _
    $EIGHT_DOTS_MASK = BitOR($SIX_DOTS_MASK, $DOT_7, $DOT_8), _
    $BRL_MASK = BitOR($EIGHT_DOTS_MASK, $SPACE_BAR), _
    $MODIFIER_KEY_MASK = BitOR($CAPSLOCK_PRESSED, $INSERT_PRESSED, $LWIN_PRESSED, $RWIN_PRESSED, $NUMPAD0_PRESSED, _
        $LSHIFT_PRESSED, $RSHIFT_PRESSED, $LCONTROL_PRESSED, $RCONTROL_PRESSED), _
    $LRMENU_MASK = BitOr($LMENU_PRESSED, $RMENU_PRESSED)

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

Func ModifierKey2Flag($vkCode)
    Switch $vkCode
      Case $VK_CAPITAL
        Return $CAPSLOCK_PRESSED
      Case $VK_INSERT
        Return $INSERT_PRESSED
      Case $VK_LWIN
        Return $LWIN_PRESSED
      Case $VK_RWIN
        Return $RWIN_PRESSED
      Case $VK_NUMPAD0
        Return $NUMPAD0_PRESSED
      Case $VK_LSHIFT
        Return $LSHIFT_PRESSED
      Case $VK_RSHIFT
        Return $RSHIFT_PRESSED
      Case $VK_LCONTROL
        Return $LCONTROL_PRESSED
      Case $VK_RCONTROL
        Return $RCONTROL_PRESSED
    EndSwitch
    Return 0; Null flag.
EndFunc
