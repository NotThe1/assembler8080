;tstReset.asm
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
		MVI		C,0DH
		CALL	BDOSEntry
		RET


messBegin:	DB		'Starting the test.',xx_CR,xx_LF,xx_EOM	
messOK:	DB		'the test was a success !',xx_CR,xx_LF,xx_EOM	

	
;------------------------------------------
		$Include ../../Headers/debug1Header.asm
				
CodeEnd:
