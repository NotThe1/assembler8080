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
		
		
;,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.	
cpuOK:
	LXI		H,OKMessage	;
	CALL	messageOut
	JMP		WBOOT	;EXIT TO CP/M WARM BOOT
;,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.			
		;MESSAGE OUTPUT ROUTINE
; HL points to the message
;,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.			

messageOut:
	PUSH	D		; Save D REG.
	XCHG			; put pointer into DE for sys call
	MVI		C,9		; Print string vector
	CALL	BDOS
	POP	D			; Restore D REG.
	RET
;,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.			
;
;CHARACTER OUTPUT ROUTINE
; char in Acc
carOut:
	MVI		C,2		; console out vector
	CALL	BDOS
	RET
;,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.			

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
;,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.			
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
;,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.			

OKMessage:
	DB	CTRL_L,CR,LF,' CPU IS OPERATIONAL$'
	DB	00;
;
failedMessage:
	DB	CTRL_L,CR,LF,' CPU HAS FAILED!    ERROR EXIT=$'
	DB	00;
	
mess:
	DB	'a$',00
;,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.			
	
;------------------------------------
returnAddress:
	DS	2				; place to save Return Address in error message
;------------------------------------

test_ret:
	RET		; return
	CALL	cpuError
	HLT
test_rc:
	STC		; set the carry
	RC		; return if Carry
	CALL	cpuError
	HLT
test_rnc:
	MVI		A,01H		; set one bit
	ANA		A			; resets all flags

	RNC		; return if No Carry
	CALL	cpuError
	HLT
test_rz:
	MVI		A,ZERO
	XRA		A			; set Z & P	
	RZ		; return if Zero
	CALL	cpuError
	HLT
test_rnz:
	MVI		A,01H		; set one bit
	ANA		A			; resets all flags

	RNZ		; return if Not Zero
	CALL	cpuError
	HLT
test_rm:
	MVI		A,ONES_B	;
	ANA		A			; set s & P	

	RM		; return if Minus, S = 1
	CALL	cpuError
	HLT
test_rp:
	MVI		A,01H		; set one bit
	ANA		A			; resets all flags

	RP		; return if Plus, S = 0
	CALL	cpuError
	HLT
test_rpe:
	MVI		A,ONES_B	;
	ANA		A			; set s & P	


	RPE		; return if Parity even, P = 1
	CALL	cpuError
	HLT
test_rpo:
	MVI		A,01H		; set one bit
	ANA		A			; resets all flags

	RPO		; return if Parity odd, P = 0
	CALL	cpuError
	HLT
	
	
	
;<><><><><><><><><><><><><><><><><><><><><><><>
init:
	LXI		SP,TPA		; initalize the stack
; test Flags and Conditional Calls
	MVI		A,ZERO		; put 00 into Acc
	XRA		A			; really clear it out
						; Z & P = 1, rest = 0
	CC		cpuError	; CY is force clear by a XRA
	CPO		cpuError	; Parity should be even, set to 1
	
	CM		cpuError	; sign should be reset
	CNZ		cpuError	; Z should be set
	
	MVI		A,ONES_B	; set all ones
	ANA		A			; set S & P flags
	
	STC					; force carry flag
	CNC		cpuError	; CY is set
	CP		cpuError	; S flag should be set
	CZ		cpuError	; Z flag should be reset
	
	MVI		A,01H		; set one bit
	ANA		A			; resets all flags
	CPE		cpuError	; parity should be odd
	
; test FLags and Conditional Jumps
	MVI		A,01H		; set one bit
	ANA		A			; resets all flags
	JP		jump01		; S = 0
	CALL	cpuError
jump01:
	JNZ		jump02		; Z = 0
	CALL	cpuError
jump02:
	JPO		jump03		; P = 0
	CALL	cpuError
jump03:
	JNC		jump04		; CY = 0
	CALL	cpuError
jump04:

	STC
	JC		jump05		; CY = 1
	CALL	cpuError
jump05:

	MVI		A,00H		; 
	XRA		A			; Set Z & P
	JZ		jump06		; Z = 1
	CALL	cpuError
jump06:
	JPE		jump07		; P = 1
	CALL	cpuError
jump07:

	MVI		A,ONES_B	; set all ones
	ANA		A			; set S & P flags
	JM		jump08		; S = 1
	CALL	cpuError
jump08:

; test for Conditional returns

	CALL	test_ret
	CALL	test_rc
	CALL	test_rnc
	CALL	test_rz
	CALL	test_rnz
	CALL	test_rm
	CALL	test_rp
	CALL	test_rpe
	CALL	test_rpo
	
; test for Comparisons
	MVI		A,ZERO
	SBI		ZERO 
	
	MVI		A,ZERO
	CPI		ZERO
	





;,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.	
; fall thru for success
	JMP		cpuOK		; end on a good note!

	
;	
CodeEnd: