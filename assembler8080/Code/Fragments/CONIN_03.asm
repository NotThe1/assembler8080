;CONIN_03.asm  CONIN F878 - 0286
;
CONIN:
	; Get console Input character entered directly from the BIOS jmp Vector
	; return the character from the console in the A register.
	; most significant bit will be 0. except when "reader" (communication)
	; port has input , all 8 bits are reurned
	;
	; normally this follows a call to CONST ( a blocking call) to indicates a char is ready.
	LDA		IOBYTE				; get i/o redirection byte
	CALL 	SelectRoutine
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
				
			;****
				TerminalInput:
						LXI		H,TerminalTable			;HL-> control table
						CALL	InputData				;** special **
								InputData:					; return with next character
										PUSH	H			; save control table pointer
										CALL	InputStatus
												InputStatus:					; return- A = 00H no incoming data
														MOV		A,M				; get status port
														STA		InputStatusPort	;** self modifying code
														DB		INopCode		; IN opcode
												InputStatusPort:
														DB		00H				; <- set from above
														INX		H			; move HL to point to input data mask
														INX		H
														INX		H
														ANA		M				; mask with input status
														RET		
										POP		H
										JZ		InputData	; wait until incoming data
										INX		H			; HL <- data port
										MOV		A,M			; get data port
										STA		InputDataPort
										DB		INopCode
								InputDataPort:
										DB		00H			; <- set from above
										RET
						ANI		07FH					; Strip off high order bit
						RET	
				

			; Vectors to device routines
	DW		TTYInput			; 00 <- IOBYTE bits 1,0
	DW		TerminalInput		; 01
	DW		CommunicationInput	; 10
	DW		DummyInput			; 11
