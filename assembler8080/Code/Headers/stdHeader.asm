; stdHeader.asm
; standard equates

TRUE			EQU		-1		;not false
FALSE			EQU		0000H
ON				EQU		-1		
OFF				EQU		0000H

BYTE			EQU		1		;number of bytes for "byte" type
WORD			EQU		2		;number of bytes for "word" type


ASCII_MASK		EQU		7FH			; Ascii mask 7 bits
ZERO			EQU		00H			; Zero
EndOfMessage	EQU		00H

CTRL_C			EQU		03H			; ETX
CTRL_E			EQU		05H			; physical eol
CTRL_H			EQU		08H			; backspace
CTRL_K			EQU		0BH			; VT - Vertical tab
CTRL_L			EQU		0CH			; FF - Form feed
CTRL_P			EQU		10H			; prnt toggle
CTRL_R			EQU		12H			; repeat line
CTRL_S			EQU		13H			; X-OFF stop/start screen
CTRL_U			EQU		15H			; line delete
CTRL_X			EQU		18H			; =ctl-u
CTRL_Z			EQU		1AH			; end of file

NULL				EQU		00H			; Null
SOH				EQU		01H			; Start of Heading
BELL				EQU		07H			; Bell
TAB				EQU		09H			; Tab
LF				EQU		0AH			; Line Feed
CR				EQU		0DH			; Carriage Return
SPACE			EQU		20H			; Space
EXCLAIM_POINT		EQU		21H			; Exclamtion Point
HASH_TAG			EQU		23H			; Sharp sign #
DOLLAR			EQU		24H			; Dollar Sign
PERCENT			EQU		25H			; Percent Sign
ASTERISK			EQU		2AH			; Asterisk *
PERIOD			EQU		2EH			; Period
SLASH			EQU		2FH			; /
ASCII_ZERO		EQU		30H			; zero
COLON			EQU		3AH			; Colon

SEMICOLON			EQU		3BH			; Semi Colon
LESS_THAN			EQU		3CH			; Less Than <
EQUAL_SIGN		EQU		3DH			; Equal Sign
GREATER_THAN		EQU		3EH			; Greater Than >
QMARK			EQU		3FH			; Question Mark
UNDER_SCORE		EQU		5FH			; under score _
RUBOUT			EQU		7FH			; Delete Key	


ASCII_A			EQU		'A'	
ASCII_C			EQU		'C'	
ASCII_R			EQU		'R'	
ASCII_K			EQU		'K'
ASCII_Y			EQU		'Y'
CARET			EQU		'^'
ASCII_LO_A		EQU		'a'
ASCII_LO_K		EQU		'K'
ASCII_LO_P		EQU		'p'
LEFT_CURLY		EQU		'{'			; Left curly Bracket	
