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
		
		CALL	test
;		
		LXI		HL, messOK
		CALL	x_displayMessage
		HLT
;		
test:
		MVI		B,04H		; max disk Number + 1
test1:
		DCR		B
		RM					; exit of done (B = -1)
		PUSH	BC			; save disk number
		MOV		E,B
		MVI		C,0EH
		CALL	BDOSEntry	; set the disk
		
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
messOK:	DB		'the test was a success !',xx_CR,xx_LF,xx_EOM	
messBAD:	DB		'the test was a FAILURE !',xx_CR,xx_LF,xx_EOM	

	
;------------------------------------------
		$Include ../../Headers/debug1Header.asm
				
CodeEnd:
