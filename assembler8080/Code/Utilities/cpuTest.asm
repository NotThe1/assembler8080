;	cpuTest.asm
;
BDOS	EQU		0005H		; BDOS entry point
WBOOT	EQU		0000H		; CP/M war boot vector
TPA		EQU		0100H		; Transient Program Area
LF		EQU		0AH			; Line Feed
CTRL_K	EQU		0BH			; VT - Vertical tab
CTRL_L	EQU		0CH			; FF - Form feed
CR		EQU		0DH			; Carriage Return

ZERO	EQU		00H			; zero
ONES_W	EQU		0FFFFH		; all ones - word
ONES_B	EQU		0FFH		; all ones - byte
ONES_LN	EQU		00FH		; all ones lo nibble
ONES_HN	EQU		0F0H		; all ones hi nibble

CodeStart:
		ORG		TPA
		JMP		init
		
		
		
		;MESSAGE OUTPUT ROUTINE
; HL points to the message

messageOut:
	PUSH	D		; Save D REG.
	XCHG			; put pointer into DE for sys call
	MVI		C,9		; Print string vector
	CALL	BDOS
	POP	D			; Restore D REG.
	RET
;
;
;
;CHARACTER OUTPUT ROUTINE
; char in Acc
carOut:
	MVI		C,2		; console out vector
	CALL	BDOS
	RET
;


cpuError:
	XTHL					; get the return address into HL
	SHLD	returnAddress	; save it for later
	LXI		H,failedMessage  
	CALL	messageOut
	LDA		returnAddress + 1	; get MSB of return address
	CALL	showAscii	; show hi byte of failing address
	LDA		returnAddress	; get LSB of return address
	CALL	showAscii	; show lo byte of failing address
	JMP		WBOOT	; exit via MDOS
;
; send ascii value of Acc to console
;
showAscii:
	PUSH	PSW
	CALL	doHiNibble
	MOV	E,A
	CALL	carOut
	POP	PSW
	CALL	doLoNibble
	MOV	E,A
	JMP	carOut
doHiNibble:
	RRC
	RRC
	RRC
	RRC
doLoNibble:
	ANI	0FH
	CPI	0AH
	JM	nibbleOK
	ADI	7
nibbleOK:
	ADI	30H
	RET
;
;


OKMessage:
	DB	CTRL_L,CR,LF,' CPU IS OPERATIONAL$'
	DB	00;
;
failedMessage:
	DB	CTRL_L,CR,LF,' CPU HAS FAILED!    ERROR EXIT=$'
	DB	00;
	
mess:
	DB	'a$',00
	
;------------------------------------
returnAddress:
	DS	2				; place to save Return Address in error message

init:
	LXI		SP,TPA		; initalize the stack
; test Flags and flag jumps
	MVI		A,ZERO		; put 00 into Acc
	XRA		A			; really clear it out
	CC		cpuError	; CY is force clear by a XRA
	CM		cpuError	; sign should be reset
	CNZ		cpuError	; Z should be set
	CZ		cpuError
;,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.	
cpuOK:
	LXI		H,OKMessage	;
	CALL	messageOut
	JMP		WBOOT	;EXIT TO CP/M WARM BOOT
;	
CodeEnd: