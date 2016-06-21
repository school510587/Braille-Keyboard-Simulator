#include-once
#include <Array.au3>
#include <AutoItConstants.au3>
#include <File.au3>

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

Func BRL2Bopomofo($sBRL, $bReload = False)
    Static $table = Null
    If $bReload Or Not IsArray($table) Then
        Local $bopomofo_list
        _FileReadToArray("bopomofo.txt", $table, $FRTA_NOCOUNT, @TAB)
        If @error Then
            $table = Null
            Return SetError($EOF, 0, "")
        EndIf
        For $i = 0 To UBound($table, $UBOUND_ROWS) - 1
            $table[$i][0] = Digits2BRL($table[$i][0])
            $bopomofo_list = StringSplit($table[$i][1], "-")
            For $j = 1 To $bopomofo_list[0]
                $bopomofo_list[$j] = Dec($bopomofo_list[$j])
            Next
            $table[$i][1] = StringFromASCIIArray($bopomofo_list, 1)
        Next
        _ArraySort($table)
    EndIf
    Local $pos = _ArraySearch($table, "^\Q" & $sBRL, 0, 0, 1, 3); Prefix test.
    If @error Then Return SetError(1, 0, ""); Not found.
    $pos = _ArraySearch($table, $sBRL, $pos, 0, 1); Exact matching.
    Return SetError(0, 0, @error ? "" : $table[$pos][1]); Either prefix or a match.
EndFunc

Func BRL2Chr($iBRL); BRL to character, except the space.
    Static $raw = " a1b'k2l`cif/msp""e3h9o6r~djg>ntq,*5<-u8v.%{$+x!&;:4|0z7(_?w}#y)="; It must be constant.
    Local $c = StringMid($raw, BitAND($iBRL, $SIX_DOTS_MASK) + 1, 1)
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

Func Digits2BRL($str)
    Local $cell_list = StringSplit($str, "-"), $dots
    For $i = 1 To $cell_list[0]
        $dots = 0x2800
        If $cell_list[$i] <> "0" Then
            For $d In StringSplit($cell_list[$i], "", $STR_NOCOUNT)
                $dots = BitOR($dots, Eval("DOT_" & $d))
            Next
        EndIf
        $cell_list[$i] = Asc(BRL2Chr($dots))
    Next
    Return StringFromASCIIArray($cell_list, 1)
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

Func BRL2Key($sBRL, $hKL)
    Static $data[][] = [[0x04040404, Null]]
    Local $t = _ArraySearch($data, $hKL)
    If @error Then; The specified $hKL is currently not found.
        Local $row[][UBound($data, $UBOUND_COLUMNS)] = [[$hKL]], $pos = 0
        _FileReadToArray("Keyboard-Layouts\" & Hex($hKL, 8) & ".txt", $t, $FRTA_NOCOUNT, @TAB)
        If @error Then Return SetError($EOF, 0, $sBRL)
        For $i = 0 To UBound($t, $UBOUND_ROWS) - 1
            $t[$i][0] = Dec($t[$i][0])
        Next
        _ArraySort($t)
        $row[0][1] = $t
        _ArrayAdd($data, $row)
    Else
        $t = $data[$t][1]; To read out the embedded array.
        If Not IsArray($t) Then Return SetError(0, 0, StringRegExpReplace($sBRL, "([!#+\^{}])", "\{${1}\}")); The default keyboard layout.
    EndIf
    $sBRL = BRL2Bopomofo($sBRL)
    If Not $sBRL Then Return SetError(@error, @extended, $sBRL)
    Local $answer = "", $p
    For $c In StringToASCIIArray($sBRL)
        $p = _ArrayBinarySearch($t, $c)
        $answer &= @error ? $c : $t[$p][1]
    Next
    Return SetError(0, 0, $answer)
EndFunc
