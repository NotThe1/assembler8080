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


SELDSK	EQU	BIOS + (3 * 9)
CodeStart:

		ORG		0100H

		LXI		SP, $
		
		CALL	tstSeldsk
		CALL	tstConsole
		HLT
		
;----------------------------------------------------				
tstSeldsk:
		MVI		C,5				; number of disks + 1
		CALL	SELDSK
		MOV		A,H				; if HL = 0000 There is an error
		ORA		L
		JZ		tstSeldsk1		; works correctly found error
		; did not detect bad disk number
		PUSH	HL				; save bad result
		LXI		HL, mess3
		CALL	x_displayMessage
		POP		HL				; get returned value
		CALL	x_displayHL
		HLT

tstSeldsk1:
		MVI		C,1				; point at disk A
		CALL	SELDSK
		MOV		A,H
		ORA		L
		JNZ		tstSeldsk2
		
		LXI		HL, mess4
		CALL	x_displayMessage
		HLT

tstSeldsk2:
		LXI		HL,mess2
		CALL	x_displayMessage
		RET
		
mess2:	DB	'tstSeldsk concluded !',xx_LF,xx_CR,xx_LF,xx_CR,xx_EOM
mess3:	DB	'Did not detectect bad disk number'
		DB	' in Select Disk.',xx_LF,xx_CR
		DB	'HL was not 00 it was:',xx_LF,xx_CR,xx_EOM
mess4:	DB	'Did not detectect good disk number'
		DB	' in Select Disk.',xx_LF,xx_CR,xx_EOM

;----------------------------------------------------		
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
		
;---------
		$Include ../Headers/debug1Header.asm
				
CodeEnd:
