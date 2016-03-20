;tstConsole.asm
;


BIOS	EQU		0F600H
;SETTRK	EQU		BIOS + ( 3 * 0AH)

CodeStart:
		ORG		0100H

		LXI		SP, $		
		CALL	tstConsole
		
		HLT
;		
tstConsole:			
		MVI		A,45H
		CALL 	xx_PCHAR
		CALL	x_CRLF
	
		MVI		C,00
		LXI		H,0110H
		CALL	x_showAddress1
		
		MVI		C,00
		LXI		H,0110H
		CALL	x_showAddress2
				
		CALL	x_displayHL
		CALL	x_CRLF
		LXI		HL,mess1
		CALL	x_displayMessage
		RET
		
mess1:	DB	'tstConsole concluded !',xx_LF,xx_CR,xx_LF,xx_CR,xx_EOM

;------------------------------------------
		$Include ../Headers/debug1Header.asm
				
CodeEnd:
