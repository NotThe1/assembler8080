;tstCCPcommand.asm
;

;Include ../../Headers/stdHeader.asm
BIOS		EQU		0F600H
BDOSEntry	EQU		0E806H
CCPEntry	EQU		0E000H

CodeStart:
		ORG		0100H

		LXI		SP, $		
		LXI		HL, messBegin
		CALL	x_displayMessage
		
		CALL	test
		MVI		E,000H	; set e = 0 for disk A
		MVI		C,0EH
		CALL		BDOSEntry		; select disk A
		
		MVI		C,019H
		CALL		BDOSEntry		; get selected disk into A
		MOV		C,A			; move it to c before calling CCP
		STA		0004H		; shove it into page 0
		CALL		CCPEntry
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
		$Include ../../Headers/debug1Header.asm
				
CodeEnd:
