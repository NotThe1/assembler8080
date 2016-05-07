; debug1Header.asm
;
;
; x_displayMessage - (HL) points to 00 terminated string
; x_CRLF - Print CR LF
;
;	Display Ascii values of :
; x_showAddress1 - (HL) address
; x_showAddress2 - (HL) address
; x_showRegA     - (A) 
; x_displayHL	  HL value to display



;BIOS	EQU	0F600H
xx_EOM	EQU	00H
xx_LF	EQU	0AH
xx_CR	EQU	0DH

xx_BIOS	EQU	0F600H
xx_CONOUT	EQU	xx_BIOS + (3 * 4)

	ORG	(($+0100H)/0100H) * 0100H


;--------------Show address1 & Show Address2-------------
; will display the address and contenets pointed to by HL.
; x_showAddress1 -  displays: abcd = nn	
; x_showAddress2 -  displays: abcd = nnmm	

x_showAddress1:
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	
	CALL	xx_SA0
	CALL	xx_CRLF
	JMP	xx_FullExit			; restore registers and return
	
x_showAddress2:
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	
	PUSH	HL
	CALL	xx_SA0
	POP	HL
	INX	HL
	MOV	A,M
	CALL	x_showRegA
	CALL	xx_CRLF
	JMP	xx_FullExit			; restore registers and return

xx_SA0:
	PUSH	HL
	CALL	x_displayHL
	LXI	HL,xx_MEQUALS
	CALL	x_displayMessage
	POP	HL
	MOV	A,M
	CALL	x_showRegA
	RET
;
xx_MEQUALS:
	DB ' = ',xx_EOM

;--------------Show address1 & Show Address2-------------
x_showRegAcomma:
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	CALL	x_showRegA
	MVI	C,2CH
	CALL	xx_CONOUT
	JMP	xx_FullExit			; restore registers and return
;---------------------   x_showRegA  -------------------

; Display the contents of A
x_showRegA:
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	
	PUSH	PSW
	CALL	xx_SRA1
;	MOV	E,A
	CALL	xx_PCHAR
	POP	PSW
	CALL	xx_SRA2
;	MOV	E,A
	CALL	xx_PCHAR
	JMP	xx_FullExit			; restore registers and return

xx_SRA1:
	RRC
	RRC
	RRC
	RRC
xx_SRA2:
	ANI	0FH
	CPI	0AH
	JM	xx_SRA3
	ADI	7
xx_SRA3:
	ADI	30H
	RET
;------------------------- x_showRegA  --------------------

;---------------------  x_displayMessage  -----------------
; Display Message (HL) points to 00 terminated string
x_displayMessage:
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
xx_DM:
	MOV	A,M				; get next message byte
	ORA	A				; terminator (a = 0)?
	JZ	xx_FullExit			; restore registers and return
	
	MOV	C,A				; prepare for output
	PUSH	HL				; save message pointer
	CALL	xx_CONOUT				; go to main console output routine	*******
	POP	H
	INX	H 				; point at next character
	JMP	xx_DM				; loop till done
;-------------------------  x_displayMessage --------------------
;------------------------  x_displayHL -------------------------
x_displayHL:
	PUSH	HL
	MOV	A,H
	CALL	x_showRegA
	POP	HL
	MOV	A,L
	CALL	x_showRegA
	RET
;------------------------  x_displayHL -------------------------

;------------------------     x_CRLF   -------------------------
x_CRLF:
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	CALL	xx_CRLF	; call routine
	JMP	xx_FullExit	; restore registers and return
;------------------------     x_CRLF   -------------------------


;------------------------     xx_CRLF   -------------------------
xx_CRLF:
	LXI	HL,xx_MCRLF
	CALL	x_displayMessage
	RET
xx_MCRLF:
	DB	xx_CR,xx_LF,xx_EOM
;------------------------     xx_CRLF   -------------------------
;------------------------     xx_PCHAR  -------------------------
;CHARACTER OUTPUT ROUTINE
;
xx_PCHAR:
	MOV	C,A
	CALL	xx_CONOUT
	RET	
;------------------------     xx_PCHAR  -------------------------


;
;-------------------- xx_FullExit ---------------------
; restores all the registeres and returns
; should be called by a JMP Statement
xx_FullExit:
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	RET

;=========================