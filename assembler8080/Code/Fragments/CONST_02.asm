; CONST_02.asm   CONST - F862 - 0265

--------------------CONST----------------------------
	; Entered directly from BIOS JMP vector
	; returns Register A
	; 00H -> No data
	; 0FFH -> there is data
CONST:
	CALL	GetConsoleStatus	; return A= zero or not zero
			GetConsoleStatus:
				LDA		IOBYTE		; Get IO redirection byte
				CALL	SelectRoutine	; these routines return to the caller of GetConsoleStatus
						SelectRoutine:	
								; SelectRoutine. When called, the calling code has a vector table immediately following it.
								; it is used to get the correct physical routine determined by the IOBYTE bits for the
								; logical device. (00,01,10,11). 
								; It will transfer control to a specified address following its calling address
								; according to the values in bits 1, 0 in A.		
						
							RLC				; Shift select values into bits 2,1 in order to do word arithmetic
						SelectRoutine21:	; entry point if bits already in 2,1
							ANI		06H		; isolate bits 2 and 1
							XTHL			; HL-> first word of address after CALL instruction
							MOV		E,A		; Add on selection value to address table base
							MVI		D,00H
							DAD		D		; HL-> now has the selected routine
							MOV		A,M		; LS Byte
							INX		H		; HL-> MS byte
							MOV		H,M		; MS byte
							MOV		L,A		; HL->routine
							XTHL			; top of stack -> routine
							RET				; transfer control to the selected routine
						; ******
								TerminalInStatus:
										LXI		H,TerminalTable			;HL-> control table
										JMP		InputStatus				; use of JMP, InputStatus will execute thr RETurn
												InputStatus:				; return- A = 00H no incoming data
													MOV		A,M			; get status port
													STA		InputStatusPort	;** self modifying code
													DB		INopCode		; IN opcode
												InputStatusPort:
													DB		00H			; <- set from above
													INX		H			; move HL to point to input data mask
													INX		H
													INX		H
													ANA		M			; mask with input status
													RET
				DW		TTYInStatus				; 00  <- IOBYTE bits 1,0
				DW		TerminalInStatus		; 01
				DW		CommunicationInStatus	; 10
				DW		DummyInStatus			; 11
			
	ORA		A
	RZ					; if 0 no returning data
	MVI		A,0FFH		; else indicate there is data
	RET
