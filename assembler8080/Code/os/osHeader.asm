; osHeader.asm


RAM				EQU		0			; Start of RAM ( and the Base page)

WarmBoot		EQU		RAM + 0		; Contains a JMP instruction to warm boot in BIOS
BIOSPAGE		EQU		RAM + 2		; BIOS Jump Vector Page
IOBYTE			EQU		RAM + 3		; Input/Output redirection byte
		
CurUser			EQU		RAM + 4		; Current user ( bits 7-4)
CurDisk			EQU		CurUser		; Default logical disk (bits 0-3)

BDOSE			EQU		RAM + 5		; Contains a JMP to BDOS entry
TopRAM			EQU		BDOSE+2		; Top page of usable RAM
				
FCB1			EQU		RAM + 05CH	; File Control Block #1
	; Note. If you use it here you will overwrite FCB2 below
FCB2			EQU		FCB1 + 16	; File Control Block #2
	; You must move it before using. see above
			
ComTail			EQU		RAM + 080H	; Complete command tail
ComTailCount	EQU 	ComTail + 1	; Count of the number of char in tail
ComTailChars	EQU		ComTailCount + 1	; Complete Command tail up-cased, w/o trailing CR

			
DMABuffer		EQU		RAM + 080H	; Default "DMA" address used as buffer

TPA				EQU		RAM + 0100H		; Start of Transient program Area
											; where programs are loaded and executed

MemorySize		EQU		64

CCPLength		EQU		0800H	; Constant
BDOSLength		EQU		0E00H	; Constant	0E00H
BIOSLength		EQU		0A00H	; Constant 0900H

LengthInK		EQU		((CCPLength + BDOSLength + BIOSLength) /1024) + 1
LengthInBytes	EQU		CCPLength + BDOSLength + BIOSLength


CCPEntry		EQU		(MemorySize * 1024) - (CCPLength + BDOSLength + BIOSLength)
;CCPEntry		EQU		0E000H		; forced calculation

;;rats			EQU		0100

BDOSBase		EQU		CCPEntry + CCPLength
BDOSEntry		EQU		BDOSBase + 6
BIOSBase		EQU		BDOSBase + BDOSLength
BIOSEntry		EQU		CCPEntry + CCPLength + BDOSLength

;TPA				EQU		0100H	; Transient Program Address




CR				EQU		0DH		; Carriage Return
LF				EQU		0AH		; Line Feed
EndOfMessage	EQU		00H

ASCII_MASK		EQU		7FH			; Ascii mask 7 bits
ZERO			EQU		00H			; Zero

NULL			EQU		00H			; Null
SOH				EQU		01H			; Start of Heading
CTRL_C			EQU		03H			; ETX
BELL			EQU		07H			; Bell
LF				EQU		0AH			; Line Feed
CTRL_K			EQU		0BH			; VT - Vertical tab
CTRL_L			EQU		0CH			; FF - Form feed
CR				EQU		0DH			; Carriage Return
CTRL_S			EQU		13H			; X-OFF
SPACE			EQU		20H			; Space
EXCLAIM_POINT	EQU		21H			; Exclamtion Point
DOLLAR			EQU		24H			; Dollar Sign
PERCENT			EQU		25H			; Percent Sign
ASTERISK		EQU		2AH			; Asterisk *
PERIOD			EQU		2EH			; Period
SLASH			EQU		2FH			; /
ASCII_ZERO		EQU		30H			; zero
COLON			EQU		3AH			; Colon

SEMICOLON		EQU		3BH			; Semi Colon
LESS_THAN		EQU		3CH			; Less Than <
EQUAL_SIGN		EQU		3DH			; Equal Sign
GREATER_THAN	EQU		3EH			; Greater Than >
QMARK			EQU		3FH			; Question Mark
ASCII_A			EQU		'A'	
ASCII_C			EQU		'C'	
ASCII_R			EQU		'R'	
ASCII_K			EQU		'K'
ASCII_Y			EQU		'Y'
ASCII_LO_A		EQU		'a'
ASCII_LO_K		EQU		'K'
ASCII_LO_P		EQU		'p'
LEFT_CURLY		EQU		'{'			; Left curly Bracket	
DEL				EQU		7FH			; Delete Key	
