;tstConsole.asm
;

$Include ../../Headers/stdHeader.asm
BIOS	EQU		0F600H
BDOSEntry	EQU		0E806H

;SETTRK	EQU		BIOS + ( 3 * 0AH)

CodeStart:
		ORG		0100H

		LXI		SP, $		
		LXI		HL, messBegin
		CALL	x_displayMessage
		
		CALL	testConsoleOut
		CALL	testConsoleIn
		CALL	testDirectConsole
		CALL	testStringIO
;		
		LXI		HL, messOK
		CALL	x_displayMessage
		HLT
;*************************************;
testStringIO:
		LXI		DE,consoleBuffer
		MVI		C,0AH
		CALL	BDOSEntry

;		LXI		DE,messPrintString
		LXI		DE,consoleBuffer
		MVI		C,09
		CALL	BDOSEntry
		RET
;----------------------		
testDirectConsole:
		LXI		HL,messDirectOut
testDirectConsoleOut:
		MOV		E,M
		PUSH	HL
		MVI		C,06
		CALL	BDOSEntry
		POP		HL
		INX		HL
		MOV		A,M
		CPI		DOLLAR
		JNZ		testDirectConsoleOut
		
testDirectConsoleIn:
		LXI		HL, messIn1
		CALL	x_displayMessage
testDirectConsoleIn1:
		MVI		E,0FFH
		MVI		C,06
		CALL	BDOSEntry
		CPI		CTRL_Z
		RZ						; exit if CNTRL_Z 1A
		MOV		E,A
		MVI		C,02
		CALL	BDOSEntry
		JMP		testDirectConsoleIn1
;--------------
testConsoleIn:
		LXI		HL, messIn1
		CALL	x_displayMessage
testConsoleIn1:		
		MVI		C,01
		CALL	BDOSEntry
		CPI		CTRL_Z
		JNZ		testConsoleIn1
		RET
;--------------
testConsoleOut:
; test A Tab A
		MVI		E,ASCII_A
		MVI		C,02
		CALL	BDOSEntry
		MVI		E,TAB
		MVI		E,ASCII_A
		MVI		C,02
		CALL	BDOSEntry
		CALL	x_CRLF
		
		MVI		B,1
testConsoleOut1:			; test WholeLine:
		PUSH	BC			; save the count
		MOV		A,B			; get the count
		DAA
		ANI		00001111B	; only want lsn
		ADI		ASCII_ZERO	; make it printable 0 to 9
		
		MOV		E,A			
		MVI		C,02
		CALL	BDOSEntry
		POP		BC
		INR		B
		JNZ		testConsoleOut1
		
		RET


messBegin:	DB		'Starting the test.',xx_CR,xx_LF,xx_EOM	
messOK:		DB		xx_CR,xx_LF,'the test was a success !',xx_CR,xx_LF,xx_EOM
messIn1:	DB		xx_CR,xx_LF,'Type Characters Terminate with CONTRL_Z ',xx_CR,xx_LF,xx_EOM
messDirectOut:	DB	CR,LF,'Direct Console Out',CR,LF,DOLLAR	
messPrintString:	DB	CR,LF,'This is a BDOS Print String',CR,LF,DOLLAR

consoleBuffer:	DS	80	
	

	
;------------------------------------------
		$Include ../../Headers/debug1Header.asm
				
CodeEnd:
