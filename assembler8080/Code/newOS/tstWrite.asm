;tstWrite.asm
;
		$Include ../Headers/osHeader.asm


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
		DS		20H
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
		CALL	SetUpBuffer			; put in Track Head Sector Disk .....
		LDA		Disk
		MOV		C,A					; get disk into C for Call
		CALL	SELDSK
		MOV		A,L
		ANA		H
		JNZ		test1				; if HL = 0000 SelDsk failed
		LXI		HL,messBadSELDSK
		CALL	x_displayMessage
		HLT							; STOP !
		
test1:		
		CALL	SetUpDiskLocation	; make calls to set Track Head Sector Disk and DMA
		CALL	WRITE				; write the data Out
;		CALL	Setup				; set up Disk, Track and Sector
;		
;		CALL	READ
;
;		MVI		C,01H
;		CALL	SETSEC				; point at next sector
;		CALL	READ
;		
;		MVI		C,08H
;		CALL	SETSEC				; point at next Physical sector
;		CALL	READ
		
		RET
;set Track Head Sector Disk and DMA
SetUpDiskLocation:
		LDA		Head
		CPI		1					; is this the second head
		LDA		Sector				; get the sector
		JZ		SetUpDiskLocation1
		ADI		SectorCount-1		; BIOS figures out correct head
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
		MVI		A,1
		STA		Track
		INR		A
		STA		Head
		INR		A
		STA		Sector
;*********************************************************
		LXI		HL,myBuffer			; point at buffer
		LDA		Track
		MOV		M,A					; put in Track
		INX		HL
		LDA		Head
		MOV		M,A					; put in Head
		INX		HL
		LDA		Sector
		MOV		M,A					; put in Sector
		INX		HL
		LDA		Disk
		MOV		M,A					; put in Disk
		INX		HL
		
		LXI		DE,myBuffer
;		XCHG						; DE => start of myBuffer HL = DE+4
		MVI		B,PhySecSize -4		; number of bytes to move
SetUpBuffer1:
		LDAX	DE
		MOV		M,A					; move byte
		DCR		B
		RZ							; exit when all bytes have been moved
		INX		DE
		INX		HL					; bump the pointers
		JMP		SetUpBuffer1		

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
		

; fill myBuffer with 00H
ClearMyBuffer:
		XRA		A
		LXI		HL,myBuffer		; Location to fill
		MVI		B,PhySecSize		; Number of bytes to fill
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
		MVI		B,PhySecSize		; Number of bytes to fill
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
nextSector:
		RET
incSector:
		LXI		HL,Sector		;
		MVI		A,SectorCount -1
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
		
		
;......................		
Disk:			DB		00H		; Disk A
Head:			DB		00		; Head 0
Track:			DB		00H		; Track 0000H
Sector:			DB		00H		; Sector
LogicalSector	DW		0000H

; metrics for a 5.25 inch disk
TrackCount		EQU		03			;40		; Tacks/Head
SectorCount		EQU		09		; Sectors/Track(/Head)
HeadCount		EQU		02		; Number of heads
PhySecSize		EQU		0080H	;

messBegin:		DB		'Starting the Write test.',xx_CR,xx_LF,xx_EOM	
messOK:			DB		'the test was a success !',xx_CR,xx_LF,xx_EOM
messTrack:		DB		'Current: Track = ',xx_EOM	
messHead:		DB		' Head = ',xx_EOM	
messSector:		DB		' Sector = ',xx_EOM
messBadSELDSK:	DB		'Failed to correcty perfom Select Disk. ',xx_CR,xx_LF,xx_EOM
	
ORG		(($+10H)/10H) * 10H
myBuffer:
				DS		PhySecSize
;------------------------------------------
		$Include ../Headers/debug1Header.asm
				
CodeEnd:
