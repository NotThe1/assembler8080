; SYSRPT.asm    System report
; Set up the EQUates to use

PERIOD			EQU		'.'		; Period

LF				EQU		0AH			; Line Feed
;CTRL_K			EQU		0BH			; VT - Vertical tab
;CTRL_L			EQU		0CH			; FF - Form feed
CR				EQU		0DH			; Carriage Return
SPACE			EQU		20H			; Space
ASCII_OFFSET	EQU		30H			; base to make binary decimal number ascii

ASCII_A			EQU		'A'			; upper A
ASCII_H			EQU		'H'			; upper H
ASCII_M			EQU		'M'			; upper M
ASCII_R			EQU		'R'			; upper R


SYS_RESET		EQU		000H	; System reset		
SYS_CONOUT		EQU		002H	; Console out , char in E		
SYS_GET_IOB		EQU		007H	; get IOByte , Acc returns IOByte		
SYS_STRING_OUT	EQU		009H	; Print String, DE points at $ terminated String		
SYS_GET_VER		EQU		00CH	; get version number, HL returns Version		
SYS_GET_LOGINV	EQU		018H	; get logged in Vector, HL returns Vector (Acc =L)		
SYS_GET_CUR_DRV	EQU		019H	; get Current Drive, Acc returns with current Drive		
SYS_GET_ALLOC	EQU		01BH	; get allocation , HL returns vector address		
;SYS_GET_VER	EQU		00CH	; get version number, HL returns Version		

MASK_HI_NIBBLE	EQU		0F0H	; mask for high nibble		
MASK_LO_NIBBLE	EQU		00FH	; mask for low  nibble		

true			EQU		0ffffh	; true EQUate.

BDOS			EQU		05H		; BDOS EQUate.



RONLY			EQU		29		; RETURNS READ ONLY VECTOR
DPARA			EQU		31		; RETURNS DISK PARAMETER BLK
PRUSER			EQU		32		; RETURNS PRESENT USER


				ORG		0100H
TPAstart:

CodeStart:

start:			; Actual program start

	LXI		H,0			; Clear HL
	DAD		SP			; Get SP from CCP
	SHLD	OLDSP		; Save it
	LXI		SP,STACK	; Point to our stack

	MVI		C,SYS_GET_VER	; get CP/M, MP/M version.
	CALL	BDOS
	MOV		A,H			; see if MP/M.
	STA		mpmFlag		; save it.
	MOV		A,L			; version number CP/M 1.x or 2.x.
	STA		cpmVersion	; save it.

	CALL	clearDisplay

; start interrogating the system
	LXI		D,MSG0
	CALL	displayString
	LDA		cpmVersion		; get cpm version.
	ANI		MASK_HI_NIBBLE	; leave upper nibble.
	RAR						; rotate right four times.
	RAR	
	RAR
	RAR						; to put it in low nibble; 
	ADI		ASCII_OFFSET	; add ascii offset.
	CALL	charDisplay		; output first number.
	MVI		A,PERIOD		; now the seprator.
	CALL	charDisplay		; out put it.
	LDA		cpmVersion		; now the lower version number.
	ANI		MASK_LO_NIBBLE	; Leave Low nibble.
	ADI		ASCII_OFFSET	; add ascii offset.
	CALL	charDisplay		; go print it.
	LXI		D,MSG19			; trailing end of message.
	CALL	displayString
	CALL	displayCRLF			; go do cr,lf.

;memHeader:
	LXI		D,MSG1
	CALL	displayString

; This is the start of the memory map

	LXI	H,0000H		; Start memory map

memProfile:
	MVI		A,-1
	CMP		M		; Memory = -1?
	JZ		missing	; skip it may not be there
	MOV		B,M		; Save memory value
	MOV		M,A		; move -1 to memory
	MOV		A,M		; move mem value to Acc
	CMP		B		; if it is same as original - must be
	JZ		ROM		;     ROM

RAM:
	MOV		M,B		; Replace original byte
	MVI		B,ASCII_M	; set for display of M for RAM
	JMP		SHWBY	; go do the display

ROM:
	MVI		B,ASCII_R	; set for display of R for ROM
	JMP		SHWBY

missing:
	MVI		A,80H		; Double check W/new value
	MOV		B,M
	MOV		M,A
	MOV		A,M
	CMP		B		
	JNZ		RAM		; jump if the original value in Mem was -1
	MVI		B,PERIOD	; set for display of PERIOD for MISSING Memory

SHWBY:
	MOV		A,B				; load display char into Acc
	CALL	charDisplay		; Output ROM, RAM, or empty
	INR		H
	INR		H
	INR		H
	INR		H
	JNZ		memProfile		; 1 K increments / loop thru 64K
	CALL	displayCRLF

; Now we fill in the storage bytes with the proper
; values which are dependent on each particular system.


	LHLD	BDOS+1			; Get start of BDOS
	MOV		A,L				; get starting page into Acc
	SUI		6
	MOV		L,A				; just needed to load L with 00 to get start of BDOS in HL
	SHLD	startBDOS		; Store it
	LXI		D,0F700H
	LHLD	startBDOS
	DAD		D				; Add wrap around offset
	SHLD	netTPA			; resolves to available TPA without displacing CCP
	LXI		D,TPAstart		; get the address of the TPA start
	LHLD	netTPA			;
	DAD		D
	SHLD	startCCP		; Store CCP= -TPAstart(100H) of netTPA
	MVI		C,SYS_GET_IOB
	CALL	BDOS
	STA		IOBYT		; Store the I/O byte


	LDA		cpmVersion		; if 00, before 2.0 else 2x
	ANI		MASK_HI_NIBBLE	; see if 1.x version.
	JZ		osDisplay		; skip if not at least rel 2.0 of cp/m

;mpmaloc:
	MVI		C,SYS_GET_ALLOC
	CALL	BDOS
	SHLD	allocVector


; Now we must output the gathered information
; to the console

; Get the CCP address and print it

osDisplay:
	LXI		D,MSG2
	CALL	displayString
	LHLD	startCCP
	CALL	displayHL
	CALL	displayCRLF

; Next get the BDOS address and print it

	LXI		D,MSG3
	CALL	displayString
	LHLD	startBDOS
	CALL	displayHL
	CALL	displayCRLF

; Next get address of BIOS and print it

	LXI		D,MSG15
	CALL	displayString
	LXI		D,0E00H
	LHLD	startBDOS
	DAD		D
	CALL	displayHL
	CALL	displayCRLF

; Already computed netTPA without killing CCP and print it

	LXI		D,MSG13
	CALL	displayString
	LHLD	netTPA
	CALL	displayHL
	LXI		D,MSG11
	CALL	displayString
	CALL	displayCRLF


	LXI		D,MSG17
	CALL	displayString
	MVI		C,SYS_GET_CUR_DRV
	CALL	BDOS
	ADI		ASCII_A				; adjust for ascii output 0=A,1=B...
	STA		currentDrive
	CALL	charDisplay			; send to display to finish message 18
	MVI		A,PERIOD
	CALL	charDisplay
	CALL	displayCRLF			;skip a line for next section

	LXI		D,MSG5
	CALL	displayString
	LDA		currentDrive
	CALL	charDisplay		; display the drive for message 5
	LXI		D,MSG6
	CALL	displayString
	LHLD	allocVector
	CALL	displayHL
	MVI		A,ASCII_H		; show that address is Hex
	CALL	charDisplay
	CALL	displayCRLF

; Find out which drives are logged in and print them

	MVI		C,SYS_GET_LOGINV
	CALL	BDOS
	ANI		MASK_LO_NIBBLE		; leave low nibble. Assumes Number of drives LE 8
	STA		activeDrives		; save bitmap of logged in drives lsb = A.. ...msb = H
	LXI		D,MSG4				; current logged in drives -
	CALL	displayString
	LDA		activeDrives		; get bitmap
	RRC
	STA	activeDrives
	LXI	D,MSG7
	CC	displayString
	LDA	activeDrives
	RRC
	STA	activeDrives
	LXI	D,MSG8
	CC	displayString
	LDA	activeDrives
	RRC
	STA	activeDrives
	LXI	D,MSG9
	CC	displayString
	LDA	activeDrives
	RRC
	LXI	D,MSG10
	CC	displayString
	CALL	displayCRLF

; Find and show the read only vectors

	MVI	C,RONLY
	CALL	BDOS
	ANI	MASK_LO_NIBBLE		; leave low nibble.
	STA	activeDrives
	LXI	D,MSG14
	CALL	displayString
	LDA	activeDrives
	ORA	A
	LXI	D,MSG16
	CZ	displayString
	LDA	activeDrives
	RRC
	STA	activeDrives
	LXI	D,MSG7
	CC	displayString
	LDA	activeDrives
	RRC
	STA	activeDrives
	LXI	D,MSG8
	CC	displayString
	LDA	activeDrives
	RRC
	STA	activeDrives
	LXI	D,MSG9
	CC	displayString
	LDA	activeDrives
	RRC
	LXI	D,MSG10
	CC	displayString
	CALL	displayCRLF

; Get the disk parameter block and display it

	LXI	D,MSG12
	CALL	displayString
	MVI	C,DPARA
	CALL	BDOS
	CALL	displayHL
	MVI	A,48H
	CALL	charDisplay
	CALL	displayCRLF

; Determine the present USER, and print the result

	LXI	D,MSG18
	CALL	displayString
	MVI	E,0FFH
	MVI	C,PRUSER
	CALL	BDOS
	CALL	displayAcc
	MVI	A,48H
	CALL	charDisplay
	CALL	displayCRLF
	
	
; end the program
	MVI		C,SYS_RESET		; system reset
	CALL	BDOS

;---------------------------------------------------------
;
; DE points to $ terminated string to display
;
displayString:
	MVI		C,SYS_STRING_OUT
	CALL	BDOS
	RET

charDisplay:				; Character output
	PUSH	B
	PUSH	D
	PUSH	H
	MOV		E,A
	MVI		C,SYS_CONOUT
	CALL	BDOS
	POP		H
	POP		D
	POP		B
	RET

; The following routine will print the value of
; HL to the console. If entered at displayAcc, it will
; only print the value of Acc

displayHL:					; Output HL to console
	MOV		A,H				; H is first
	CALL	displayAcc		; display ascci value
	MOV		A,L				; L is next
; display ascii value of Acc	
displayAcc:
	MOV		C,A				; Save it
	RRC
	RRC
	RRC
	RRC						; move MSN to LSN
	CALL	displayAcc1		; Put it out
	MOV		A,C				; restore original value
displayAcc1:
	ANI		MASK_LO_NIBBLE	; leave low nibble.
	ADI		ASCII_OFFSET	; get ascii EQUivalent
	CPI		03AH			; 0-9?
	JC		OUTCH			; skip if decimal digit
	ADI		07H				;   else make it a letter

OUTCH:
	CALL	charDisplay
	RET
;

clearDisplay:				; Clear console
	MVI		C,25			; number of display lines + 1
	MVI		A,CR		; C/R
	CALL	charDisplay

clearDisplay1:
	MVI		A,LF		; Linefeed
	CALL	charDisplay
	DCR		C
	JNZ		clearDisplay1		; Loop for 25 LF
	RET

displayCRLF:				; Send C/R, LF
	MVI		A,CR
	CALL	charDisplay
	MVI		A,LF
	CALL	charDisplay
	RET

displaySpace:
	MVI		A,SPACE
	CALL	charDisplay
	RET

; PROGRAM MESSAGES

MSG0:	db	'Status report CP/M version $'
MSG1:	DB	'    M=RAM memory           R=ROM memory'
		DB	'          .=no memory',CR,LF
		DB	'0   1   2   3   4   5   6   7   8   9'
		DB	'   A   B   C   D   E   F'
		DB	CR,LF,'$'
MSG2:	DB	'CCP starts at $'
MSG3:	DB	'BDOS starts at $'
MSG4:	DB	'Current logged in drives -  $'
MSG5:	DB	'The Allocation address of drive $'
MSG6:	DB	'- is $'
MSG7:	DB	'A$'
MSG8:	DB	' - B$'
MSG9:	DB	' - C$'
MSG10:	DB	' - D$'
MSG11:	DB	' bytes$'
MSG12:	DB	'The address of the disk '
		DB	'parameter block is $'
MSG13:	DB	'Available TPA without '
		DB	'killing the CCP is $'
MSG14:	DB	'These drives are vectored'
		DB	' as read only.  $'
MSG15:	DB	'BIOS starts at $'
MSG16:	DB	'None$'
MSG17:	DB	'Current drive in use is $'
MSG18:	DB	'The present USER number is $'

MSG19:	DB	' system',CR,LF
		DB	'              - Program Version 1.8'
		; version as of (05-Jan-84)
		DB	CR,LF,LF,'$'


	DS	80H		; Set up a stack area
STACK		EQU	$

startBDOS:	DS	2		; memory location of start of BDOS
netTPA:		DS	2		; available TPA without displacing the CCP
startCCP:	DS	2		; CCP starting address
OLDSP:	DS	2
IOBYT:	DS	1
activeDrives:	DS	2
currentDrive:	DS	1
allocVector:	DS	2	; address for allocation table
mpmFlag:	DS	1		; non-zero if MP/M
cpmVersion:	DS	1		; Current version

CodeEnd:
	END
