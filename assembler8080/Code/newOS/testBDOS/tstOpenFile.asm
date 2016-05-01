;tstOpenFile.asm
;

;Include ../../Headers/stdHeader.asm
BIOS		EQU		0F600H
BDOSEntry	EQU		0E806H

CodeStart:
		ORG		0100H
Start:
		LXI		SP, $		
		LXI		HL, messBegin
		CALL	x_displayMessage
		
		CALL	test
		JMP		Start
;		
		LXI		HL, messOK
		CALL	x_displayMessage
		HLT
;		
test:
		LXI		DE,FCB				; fcb
		MVI		C,0FH
		CALL	BDOSEntry			; open file
		RET


messBegin:	DB		'Starting the test.',xx_CR,xx_LF,xx_EOM	
messOK:	DB		'the test was a success !',xx_CR,xx_LF,xx_EOM

ORG		(($+0100H)/0100H) * 0100H
FCB:	DB	01,'TEXT.TXT'	

	
;------------------------------------------
		$Include ../../Headers/debug1Header.asm
				
CodeEnd:
