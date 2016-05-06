;tstWPdisk.asm
;

;Include ../../Headers/stdHeader.asm
BIOS		EQU		0F600H
BDOSEntry	EQU		0E806H

CodeStart:
		ORG		0100H

		LXI	SP, $		
		LXI	HL, messBegin
		CALL	x_displayMessage
		
		CALL	test
		
		LXI	HL, messOK
		CALL	x_displayMessage

		HLT
;		
;		
test:
		MVI	E,00
		MVI	C,0EH
		CALL	BDOSEntry		; select disk A
		
		LXI	DE,myFCB
		MVI	C,0FH
		CALL	BDOSEntry		; open file
		
		MVI	C,1CH
		CALL	BDOSEntry		; set disk Read Only
		
		MVI	C,1DH
		CALL	BDOSEntry		; get Read Only Vector int HL
		
		MOV	A,L
		CPI	01
		JNZ	NotGood
		MOV	A,H
		CPI	00
		RZ			; exit ok
NotGood:		
		LXI	HL, messBad
		CALL	x_displayMessage
		HLT
		
		
;		LXI	DE,myFCB
;		MVI	C,13H
;		CALL	BDOSEntry
;		RET


messBegin:	DB		'Starting the test.',xx_CR,xx_LF,xx_EOM	
messOK:		DB		'the test was a success !',xx_CR,xx_LF,xx_EOM
messBad:		DB		'the test was a Failure !',xx_CR,xx_LF,xx_EOM	
myFCB:		DB		0,'DOG.COM'
	
;------------------------------------------
		$Include ../../Headers/debug1Header.asm
				
CodeEnd:
