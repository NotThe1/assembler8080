; testNewOS.asm
;
;
;
;	Display Ascii values of :
; showAddress1 (HL) address
; showAddress2 (HL) address
; showRegA     (A) 

CodeStart:

;BIOS	EQU		0F600H
xx_EOM		EQU		00H
xx_LF		EQU		0AH
xx_CR		EQU		0DH

xx_BIOS	EQU		0F600H
xx_CONOUT	EQU	xx_BIOS + (3 * 4)

;		ORG		(($+0100H)/0100H) * 0100H

		ORG		0100H

		LXI		SP, $
		
		MVI		A,45H
		CALL 	xx_PCHAR
		CALL	CRLF
		
		
		MVI		C,00
		LXI		H,0110H
		CALL	showAddress1
		
		MVI		C,00
		LXI		H,0110H
		CALL	showAddress2
		

				
;		CALL	displayHL
;		CALL	CRLF
		HLT
		
		
;--------------Show address1 & Show Address2-------------
; will display the address and contenets pointed to by HL.
; showAddress1 -  displays: abcd = nn		
; showAddress2 -  displays: abcd = nnmm		

showAddress1:
		PUSH	AF
		PUSH	BC
		PUSH	DE
		PUSH	HL
		
		CALL	xx_SA0
		CALL	CRLF
		JMP		xx_FullExit		; restore registers and return
		
showAddress2:
		PUSH	AF
		PUSH	BC
		PUSH	DE
		PUSH	HL
		
		PUSH	HL
		CALL	xx_SA0
		POP		HL
		INX		HL
		MOV		A,M
		CALL	showRegA
		CALL	CRLF
		JMP		xx_FullExit		; restore registers and return

xx_SA0:
		PUSH	HL
		CALL	displayHL
		LXI		HL,MessEquals
		CALL	DisplayMessage
		POP		HL
		MOV		A,M
		CALL	showRegA
		RET
;--------------Show address1 & Show Address2-------------

;--------------             showRegA        -------------

;	Display the contents of A
showRegA:
		PUSH	AF
		PUSH	BC
		PUSH	DE
		PUSH	HL
		
		PUSH	PSW
		CALL	xx_SRA1
;		MOV		E,A
		CALL	xx_PCHAR
		POP		PSW
		CALL	xx_SRA2
;		MOV		E,A
		CALL	xx_PCHAR
		JMP		xx_FullExit		; restore registers and return

xx_SRA1:
		RRC
		RRC
		RRC
		RRC
xx_SRA2:
		ANI		0FH
		CPI		0AH
		JM		xx_SRA3
		ADI		7
xx_SRA3:
		ADI		30H
		RET
;--------------             showRegA        -------------

;--------------             xx_PCHAR           -------------
;CHARACTER OUTPUT ROUTINE
;
xx_PCHAR:
		MOV		C,A
		CALL	xx_CONOUT
		RET		
;--------------             xx_PCHAR           -------------

MessEquals:
		DB ' = ',xx_EOM
CRLF:
		LXI		HL,MessCRLF
		CALL	DisplayMessage
		RET
MessCRLF:
		DB	xx_CR,xx_LF,xx_EOM
		
; Display Message (HL) points to )) terminated string
DisplayMessage:
		MOV		A,M					; get next message byte
		ORA		A					; terminator (a = 0)?
		RZ							; Yes, thes return to caller
	
		MOV		C,A					; prepare for output
		PUSH	HL					; save message pointer
		CALL	xx_CONOUT				; go to main console output routine	*******
		POP		H
		INX		H 					; point at next character
		JMP		DisplayMessage		; loop till done

displayHL:
		PUSH	HL
		MOV		A,H
		CALL	showRegA
		POP		HL
		MOV		A,L
		CALL	showRegA
		RET

;
;-------------------- xx_FullExit ---------------------
; restores all the registeres and returns
; should be called by a JMP Statement
xx_FullExit:
		POP		HL
		POP		DE
		POP		BC
		POP		AF
		RET
CodeEnd: