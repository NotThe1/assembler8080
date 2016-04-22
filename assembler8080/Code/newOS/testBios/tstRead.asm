;tstRead.asm
;
		$Include ../../Headers/osHeader.asm


BIOS	EQU		0F600H
SELDSK	EQU		BIOS + ( 3 * 09H)
SETTRK	EQU		BIOS + ( 3 * 0AH)
SETSEC	EQU		BIOS + ( 3 * 0BH)
SETDMA	EQU		BIOS + ( 3 * 0CH)

READ	EQU		BIOS + ( 3 * 0DH)

CodeStart:
		ORG		0100H
		JMP		Start
		DS		20H
Start:
		LXI		SP, $		
		LXI		HL, messBegin
		CALL	x_displayMessage
		
		CALL	test
;		
		LXI		HL, messOK
		CALL	x_displayMessage
		HLT
;
;DISK	EQU		0		; Disk A
;TRACK	EQU		0000H	; Track 00
;SECTOR	EQU		00		; Sector 0
PhySecSize	EQU	0080H	;

test:
		CALL	FillDMABuffer		; put 0FFH into Disk Buffer
		MVI		D,00H				; Disk
		MVI		E,00H				; Sector
		LXI		BC,0000H			; Track
		CALL	Setup				; set up Disk, Track and Sector
		
		CALL	READ

		MVI		C,01H
		CALL	SETSEC				; point at next sector
		CALL	READ
		
		MVI		C,08H
		CALL	SETSEC				; point at next Physical sector
		CALL	READ

			
		
		RET
Setup:
		PUSH	DE
		PUSH	DE					; Save Disk(D) And Sector(E)

		CALL	SETTRK				; Set track
		POP		BC					; C has sector
		CALL	SETSEC				; Set sector 01
		POP		BC
		MOV		C,B					; put disk in C
		CALL	SELDSK				; select the disk A

		LXI		BC,DMABuffer
		CALL	SETDMA				; Set buffer 0080H
		RET
		
; fill DMABuffer with 0FFH
FillDMABuffer:
		MVI		A,-1				; fill Character
		LXI		HL,DMABuffer		; Location to fill
		MVI		B,PhySecSize		; Number of bytes to fill
; callable here. Just set up A B and HL
FillBuffer:
		MOV		M,A
		INX		HL
		DCR		B
		JNZ		FillBuffer
		RET


messBegin:	DB		'Starting the READ test.',xx_CR,xx_LF,xx_EOM	
messOK:	DB		'the test was a success !',xx_CR,xx_LF,xx_EOM	

	
;------------------------------------------
		$Include ../../Headers/debug1Header.asm
				
CodeEnd:
