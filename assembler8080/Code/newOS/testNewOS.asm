; testNewOS.asm
;
;
; displayMessage - (HL) points to 00 terminated string
;
;	Display Ascii values of :
; showAddress1 - (HL) address
; showAddress2 - (HL) address
; showRegA     - (A) 
; displayHL		  HL value to display



BIOS	EQU		0F600H
;xx_EOM		EQU		00H
;xx_LF		EQU		0AH
;xx_CR		EQU		0DH

SELDSK	EQU	BIOS + (3 * 9)
CodeStart:

		ORG		0100H

		LXI		SP, $
		
		LXI		HL,mess1
		CALL	x_displayMessage
;		HLT
		
		MVI		A,45H
		CALL 	xx_PCHAR
		HLT
		CALL	xx_CRLF
		
		HLT
		
		
;		MVI		C,00
		LXI		H,0110H
		CALL	x_showAddress1
		
;		MVI		C,00
		LXI		H,0110H
		CALL	x_showAddress2
		

				
		CALL	x_displayHL
		CALL	xx_CRLF
		HLT
		
mess1:	DB	'My Message',xx_LF,xx_CR,xx_EOM
		
;---------
		$Include ../Headers/debug1Header.asm
				
CodeEnd:
