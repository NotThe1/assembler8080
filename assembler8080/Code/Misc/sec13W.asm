; sec13W.asm
;
BDOS		EQU		005H
BUFF		EQU		080H					; default dma buffer
LIMIT		EQU		028H					; loop limit
	ORG 0100H
Start:
	LXI		SP,1000H
;	CALL	displayRecordInfo
;	JMP 0000
	
	CALL	cpmResetDiskSystem	
	CALL	cpmDeleteFile	
	CALL	cpmMakeFile			; Make and Open File	
	

	MVI		B,00H
	PUSH	BC
Loop:
	POP		BC
	INR		B
	MOV		A,B
	CPI		LIMIT 					; are we done?
	JNC		EndLoop
	PUSH	BC
	CALL	FillBuffer
	LDA		BUFF
	CALL	PrintARegBinary
	CALL	PrintCRLF
	
	CALL	cpmWriteSeq
	JMP		Loop
	

EndLoop:
	CALL	cpmWriteSeq
	CALL	cpmWriteSeq
	
	CALL	cpmCloseFile
	
	JMP		0000				; warm boot
	
; Reg A	has value to use to fill the buffer (default DMA)
FillBuffer:
	LXI		HL,BUFF			; point to start of Buffer
	MVI		B, 080H			; get the count
FillBuffer1:
	MOV		M,A				; put value in Buffer
	INX		HL				; bump pointer
	DCR		B
	JNZ		FillBuffer1		; loop tile filled
	RET

;---------------------------------------------------------
; Read Sequential
cpmPrintString:
	MVI	C,09H			; Print String
	CALL	BDOS
	RET;

; Read Sequential
cpmCloseFile:
	LXI		DE,MyFCB
	MVI		C,10			; close file
	CALL	BDOS
	RET;
	
; Read Sequential
cpmReadSeq:
	LXI		DE,MyFCB
	MVI		C,14H		; Read seq
	CALL	BDOS
	RET;
	
; Write Sequential
cpmWriteSeq:
	LXI		DE,MyFCB
	MVI		C,15H			; Write
	CALL	BDOS
	CALL displayRecordInfo
	RET
	
; Create and Open file
cpmMakeFile:
	LXI		DE,MyFCB
	MVI		C,16H			; Make File
	CALL	BDOS
	RET
	
; Delete file if there is one
cpmDeleteFile:
	LXI		DE,MyFCB
	MVI		C,13H			; Delete File
	CALL	BDOS
	RET
	
; Only dive A is Selected	
cpmResetDiskSystem:
	MVI		C,0DH
	CALL	BDOS
	RET
;---------------------------------------------------------
displayRecordInfo:
		PUSH	AF				; save the acc
		LXI		DE,msgRegA
		CALL	cpmPrintString
		POP		AF
		CALL	PrintARegBinary
;		CALL	PrintCRLF
		
		LXI		DE,msgRC
		CALL	cpmPrintString
		LDA		MyFCB + 0FH
		CALL	PrintARegBinary
;		CALL	PrintCRLF
		
		LXI		DE,msgNext
		CALL	cpmPrintString
		LDA		MyFCB + 20H
		CALL	PrintARegBinary
		CALL	PrintCRLF
		RET
;..........................
msgRegA:	DB 'Reg A = $'
msgRC:		DB TAB,'RC = $'
msgNext:	DB TAB,'Next = $'
;---------------------------------------------------------	


	ORG		0200H
	
MyFCB:
	DB		00
Name:							; MyFCB + 1
	DB		'TEST'
	DB		SPACE,SPACE,SPACE,SPACE
Type:							; MyFCB + 9
	DB		'TST'

	
;---------------------------------------------------------
; Utilities	
SPACE		EQU		020H	
LF			EQU		0AH						; Line Feed
CR			EQU		0DH						; Carriage Return
DOLLAR		EQU		024H					; Dollar Sign
TAB			EQU		009H					; Tab character

;---------------------------------------------------------	
	ORG (($+0100H)/0100H) * 0100H
	
PrintARegBinary:
	PUSH	PSW					; save A
	CALL	PrintARegBinary1		; focus on high nibble
	CALL	PrintAReg
	POP		PSW					; want thelow nibble
	
	CALL	PrintARegBinary2
	CALL	PrintAReg
	RET
	
PrintARegBinary1:
	RRC
	RRC
	RRC
	RRC
PrintARegBinary2:
	ANI		0FH
	CPI		0AH					; 10 decimal
	JM		PrintARegBinary3
	ADI		07H					; skip Punctuation
PrintARegBinary3:
	ADI		030H				; Ascii Zero
	RET
	
	
PrintAReg:
	MOV		E,A
	MVI		C,02H			; Console Out
	CALL	BDOS
	RET
;-----------------------------------------

PrintHLBinary:
	PUSH	HL
	MOV		A,H				; Hi Byte
	CALL 	PrintARegBinary
	POP		HL
	MOV		A,L				; LOW Byte
	CALL	PrintARegBinary
	RET
;-----------------------------------------
PrintCRLF:
	PUSH	DE
	LXI		DE,msgCRLF
	CALL	cpmPrintString
	POP		DE
	RET
	
msgCRLF:
	DB	CR,LF,DOLLAR
;-----------------------------------------
	