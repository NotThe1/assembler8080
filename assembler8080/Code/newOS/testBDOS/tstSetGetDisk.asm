;tstSetGetDisk.asm
;

;$Include$$ ../../Headers/stdHeader.asm
BIOS		EQU		0F600H
BDOSEntry	EQU		0E806H

CodeStart:
		ORG		0100H

		LXI		SP, $		
		LXI		HL, messBegin
		CALL	x_displayMessage
		
;		CALL	TwoDrives
		CALL	test
;		
		LXI		HL, messOK
		CALL	x_displayMessage
		HLT
	;
TwoDrives:
		MVI		E,1
		MVI		C,0EH
		CALL	BDOSEntry	; set  disk B

		MVI		E,0
		MVI		C,0EH
		CALL	BDOSEntry	; set  disk A
		RET

		
		;		
test:
	
		MVI		B,04H		; max disk Number + 1
test1:
		DCR		B
		RM					; exit of done (B = -1)
; show the disK		
		LXI		HL,messPart1
		CALL	x_displayMessage
		MOV		A,B
		CALL	x_showRegA
		LXI		HL,messPart2
		CALL	x_displayMessage
		
; set the disk		
		PUSH	BC				; save disk number
		MOV		E,B
		MVI		C,0EH
		CALL	BDOSEntry		; set the disk
		
; get the FCB		
		LXI		HL,messDPB
		CALL	x_displayMessage
		MVI		C,01FH
		CALL	BDOSEntry		; get the Disk Parameter Block
		CALL	x_displayHL		; display the DPB
		CALL	x_CRLF
		
; get the Logged Vector
		LXI		HL,messLoginV
		CALL	x_displayMessage
		MVI		C,018H
		CALL	BDOSEntry		; get the login Vector
		CALL	x_displayHL		; display the Vector
		CALL	x_CRLF
		
; get the Allocation vector address
		LXI		HL,messAlloc
		CALL	x_displayMessage
		MVI		C,01BH
		CALL	BDOSEntry		; get the Allocation Vector address
		CALL	x_displayHL		; display the address
		CALL	x_CRLF



		
		MVI		C,019H
		CALL	BDOSEntry	; get current disk
							; A = current disk
		POP		BC			; B = what we set it to
		CMP		B			; are they the same?
		JZ		test1		; keep going if yes
		
		
		LXI		HL,messBAD
		CALL	x_displayMessage
		HLT


messBegin:	DB		'Starting the test.',xx_CR,xx_LF,xx_EOM	
messOK:		DB		'the test was a success !',xx_CR,xx_LF,xx_EOM	
messBAD:	DB		'the test was a FAILURE !',xx_CR,xx_LF,xx_EOM
messPart1:	DB		'Disk ',xx_EOM
messPart2:	DB		':',xx_CR,xx_LF,xx_EOM
messDPB:	DB		'   DPB: ',xx_EOM
messLoginV:	DB		'   loggedDrives: ',xx_EOM
messAlloc:	DB		'   Allocation Address: ',xx_EOM

	
;------------------------------------------
		$Include ../../Headers/debug1Header.asm
				
CodeEnd:
