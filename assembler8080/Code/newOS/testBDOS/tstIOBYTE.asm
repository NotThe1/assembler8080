;tstIOBYTE.asm
;

IOBYTE		EQU		0003H
defaultIOB	EQU		01000001B	; IOBYTE- Console & List is assigned the CRT device
testIOB		EQU		01111101B	; test value
BIOS		EQU		0F600H
BDOSEntry	EQU		0E806H
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
		MVI		C,07
		CALL	BDOSEntry
		CPI		defaultIOB ; is it the default value?
		JZ		test1
		LXI		HL,messBadDefault
		CALL	x_displayMessage
		RET							; we are done !
test1:
		MVI		E,testIOB			; get test value
		MVI		C,08
		CALL	BDOSEntry
		
		MVI		C,07
		CALL	BDOSEntry
		CPI		testIOB ; is it the test value?
		JZ		test2
		LXI		HL,messBadTestValue
		CALL	x_displayMessage
		RET							; we are done !
		
test2:
		MVI		E,defaultIOB			; get test value
		MVI		C,08
		CALL	BDOSEntry
		
		MVI		C,07
		CALL	BDOSEntry
		CPI		defaultIOB ; is it the default value?
		RZ
		LXI		HL,messBadReset
		CALL	x_displayMessage
		RET	
		


messBegin:		DB	'Starting the test.',xx_CR,xx_LF,xx_EOM	
messOK:			DB	'the test was a success !',xx_CR,xx_LF,xx_EOM
messBadDefault:	DB	'IOBYTE initial value is bad.',xx_CR,xx_LF,xx_EOM	
messBadTestValue:	DB	'IOBYTE test value is bad.',xx_CR,xx_LF,xx_EOM	
messBadReset:	DB	'IOBYTE reset value is bad.',xx_CR,xx_LF,xx_EOM
	
;------------------------------------------
		$Include ../../Headers/debug1Header.asm
				
CodeEnd:
