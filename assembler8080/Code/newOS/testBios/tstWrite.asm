;tstWrite.asm
;
;		$Include ../../Headers/osHeader.asm

TESTCOUNT	EQU		256
BIOS	EQU		0F600H
SELDSK	EQU		BIOS + ( 3 * 09H)
SETTRK	EQU		BIOS + ( 3 * 0AH)
SETSEC	EQU		BIOS + ( 3 * 0BH)
SETDMA	EQU		BIOS + ( 3 * 0CH)

READ	EQU		BIOS + ( 3 * 0DH)
WRITE	EQU		BIOS + ( 3 * 0EH)

CodeStart:
		ORG		0100H
		JMP		Start
;		DS		20H
		ORG		(($+0100H)/0100H) * 0100H
Start:
		LXI		SP, $
		CALL	appInit				; init the applications variable
		LXI		HL, messBegin
		CALL	x_displayMessage
		
		CALL	test
;		
		LXI		HL, messOK
		CALL	x_displayMessage
		HLT

test:
		LDA		Disk
		MOV		C,A					; get disk into C for Call
		CALL	SELDSK
		MOV		A,L
		ANA		H					; if HL = 0000 SelDsk faile
;		MVI		B,TESTCOUNT			;**************************************##########
;		PUSH	BC					;**************************************##########
		JNZ		test1				; skip if ok HL <> 0000h
		LXI		HL,messBadSELDSK
		CALL	x_displayMessage
		HLT							; STOP !
		
test1:		
		CALL	SetUpBuffer			; put in Track Head Sector Disk .....
		CALL	SetUpDiskLocation	; make calls to set Track Head Sector Disk and DMA
		MVI		C,WriteAllocated	; assume its not a new physical sector
		LDA		Sector				; get the CPM sector
		ANI		03H					; Block size is 4
		JNZ		test2				; skip if assumption correct
;		LXI		HL,messWriteUnAll	;**************************************##########
;		CALL	x_displayMessage	;**************************************##########
		MVI		C,WriteUnallocated	; otherwise correct assumption
test2:
		CALL	WRITE				; write the data Out
;		CALL	displayPosition		;**************************************##########
		CALL	incSector			; up the sector count
;		POP		BC					;**************************************##########		
;		DCR		B					;**************************************##########
;		PUSH	BC					;**************************************##########		
;		JNZ		test1				;**************************************##########
		JMP		test1
;		POP		BC					;**************************************##########
		RET
;set Track Head Sector Disk and DMA
SetUpDiskLocation:
		LDA		Head
		ANA		A					; is this the first head
		LDA		Sector				; get the sector
		JZ		SetUpDiskLocation1	; skip if yes
		ADI		MaxSector + 1		; BIOS figures out correct head
SetUpDiskLocation1:
		MOV		C,A					; put Sector number in B
		CALL	SETSEC				; Call Bios to set Sector

		LDA		Track
		MOV		C,A
		MVI		B,0					; Track is in BC 
		CALL	SETTRK				; Call Bios to set Track
		
		LXI		BC,myBuffer
		CALL	SETDMA				; Call Bios to set DMA address
		RET
; builds buffer of Track Head Sector Disk repeating		
SetUpBuffer:
;*********************************************************
		LXI		HL,myBuffer			; point at buffer
		LDA		Track
		MOV		M,A					; put in Track
		INX		HL
		LDA		Head
		MOV		M,A					; put in Head
		INX		HL
		LDA		Sector
		ANI		11111100B			; strip the 2 lsb
		RRC
		RRC							; divide by four to get Physical sector
		MOV		M,A					; put in Physical Sector
		INX		HL
		LDA		Sector
		MOV		M,A					; put in CPM sector
		INX		HL
		
		LXI		DE,myBuffer
		MVI		B,CPMSecSize -4		; number of bytes to move
SetUpBuffer1:
		LDAX	DE
		MOV		M,A					; move byte
		DCR		B
		RZ							; exit when all bytes have been moved
		INX		DE
		INX		HL					; bump the pointers
		JMP		SetUpBuffer1		

; fill myBuffer with 00H
ClearMyBuffer:
		XRA		A
		LXI		HL,myBuffer		; Location to fill
		MVI		B,CPMSecSize		; Number of bytes to fill
		JMP		FillBuffer
; fill DMABuffer with 00H
ClearDMABuffer:
		XRA		A					; set A = 00h
		JMP		FillDMABuffer1
; fill DMABuffer with 0FFH
FillDMABuffer:
		MVI		A,-1				; fill Character
FillDMABuffer1:
		LXI		HL,DMABuffer		; Location to fill
		MVI		B,CPMSecSize		; Number of bytes to fill
; callable here. Just set up A B and HL
FillBuffer:
		MOV		M,A
		INX		HL
		DCR		B
		JNZ		FillBuffer
		RET
		
		
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
appInit:
		CALL	ClearMyBuffer
		XRA		A
		STA		Disk
		STA		Head
		STA		Track
		STA		Sector
		RET

incSector:
		LXI		HL,Sector		;
		MVI		A,MaxSector
		CMP		M
		JZ		adjustSectorUp	; maxed out the sector, adjust head ...
		
		INR		M				; just increment the sector
		RET
		
adjustSectorUp:
		XRA		A
		STA		Sector			; reset sector to 00H
		LXI		HL,Head	
		MVI		A, HeadCount - 1
		CMP		M
		JZ		adjustHeadUp

		LXI		HL, Head	
		INR		M				; just increment the head
		RET
		
adjustHeadUp:
		XRA		A
		STA		Sector			; reset sector to 00H
		STA		Head			; reset the head to 00H
		LXI		HL,Track
		MVI		A,TrackCount - 1
		CMP		M
		JZ		adjustTrackUp
		INR		M
		RET

adjustTrackUp:
		LXI		HL, messOK
		CALL	x_displayMessage
		HLT
		
displayPosition:
		LXI		HL,messTrack
		CALL	x_displayMessage
		LDA		Track
		CALL	x_showRegA
		
		LXI		HL,messHead
		CALL	x_displayMessage
		LDA		Head
		CALL	x_showRegA
		
		LXI		HL,messSector
		CALL	x_displayMessage
		LDA		Sector
		CALL	x_showRegA
		
		CALL	x_CRLF
		RET
		
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>		
		
; metrics for a 5.25 inch disk
TrackCount		EQU		40		; Tacks/Head
SectorCount		EQU		09		; Sectors/Track(/Head)
HeadCount		EQU		02		; Number of heads
CPMSecSize		EQU		0080H	; CPMs idea of a sector
BlockSize		EQU		4		; Number of CPM sectors peer physical sector
MaxSector		EQU		(SectorCount * BlockSize) -1

;WriteAllocated			EQU		00H
;WriteDirectory			EQU		01H
;WriteUnallocated		EQU		02H

;......................		
Disk:			DB		00H		; Disk A
Head:			DB		00		; Head 0
Track:			DB		00H		; Track 0000H
Sector:			DB		00H		; Sector
;LogicalSector	DW		0000H

; Messages .......
messBegin:		DB		'Starting the Write test.',xx_CR,xx_LF,xx_EOM	
messOK:			DB		'the test was a success !',xx_CR,xx_LF,xx_EOM
messTrack:		DB		'Current: Track = ',xx_EOM	
messHead:		DB		' Head = ',xx_EOM	
messSector:		DB		' Sector = ',xx_EOM
messBadSELDSK:	DB		'Failed to correcty perfom Select Disk. ',xx_CR,xx_LF,xx_EOM
messWriteUnAll:	DB		'Write Unallocated Sector. ',xx_CR,xx_LF,xx_EOM
	
		ORG		(($+10H)/10H) * 10H
myBuffer:
				DS		CPMSecSize
myBufferEnd:
				DS		CPMSecSize
		ORG		(($+10H)/10H) * 10H
				
;------------------------------------------
		$Include ../../Headers/debug1Header.asm
				
CodeEnd:
