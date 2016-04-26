;tstVersion.asm
;

;$Include ../../Headers/stdHeader.asm
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
		MVI		C,0CH
		CALL	BDOSEntry
		MOV		A,H
		CPI		00H			; H sould be 00 for CP/M
		JNZ		testBadH
		MOV		A,L
		CPI		20H			; L shoud be hex 20 for version 2.0
		JNZ		testBadL
		RET
testBadH:
		LXI		HL, messBadH
		CALL	x_displayMessage
		HLT
testBadL:
		LXI		HL, messBadL
		CALL	x_displayMessage
		HLT

messBegin:	DB		'Starting the test.',xx_CR,xx_LF,xx_EOM	
messOK:		DB		'the test was a success !',xx_CR,xx_LF,xx_EOM	
messBadH:	DB		'the test was a FAILURE Bad H!',xx_CR,xx_LF,xx_EOM	
messBadL:	DB		'the test was a FAILURE Bad L !',xx_CR,xx_LF,xx_EOM	

	
;------------------------------------------
		$Include ../../Headers/debug1Header.asm
				
CodeEnd:
