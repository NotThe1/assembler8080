;tstScratch.asm
;


BIOS	EQU		0F600H
;SETTRK	EQU		BIOS + ( 3 * 0AH)

CodeStart:
		ORG		0100H

		LXI		SP, $
		CALL	appInit
Start:
		CALL	displayPosition	; 0
		CALL	incSector
		JMP		Start


		
;		LXI		HL, messBegin
;		CALL	x_displayMessage
		
;		CALL	test
;		
;		LXI		HL, messOK
;		CALL	x_displayMessage
		HLT
;		
test:
		RET
; sets Di
appInit:
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

messBegin:		DB		'Starting the test.',xx_CR,xx_LF,xx_EOM	
messOK:			DB		'the test was a success !',xx_CR,xx_LF,xx_EOM	
messTrack:		DB		'Current: Track = ',xx_EOM	
messHead:		DB		' Head = ',xx_EOM	
messSector:		DB		' Sector = ',xx_EOM	


	
;------------------------------------------
		$Include ../../Headers/debug1Header.asm
				
CodeEnd:
