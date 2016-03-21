;tstTemplate.asm
;


BIOS	EQU		0F600H
;SETTRK	EQU		BIOS + ( 3 * 0AH)

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
		RET


messBegin:	DB		'Starting the test.',xx_CR,xx_LF,xx_EOM	
messOK:	DB		'the test was a success !',xx_CR,xx_LF,xx_EOM	

	
;------------------------------------------
		$Include ../Headers/debug1Header.asm
				
CodeEnd:
