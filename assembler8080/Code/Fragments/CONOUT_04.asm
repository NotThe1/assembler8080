; CONOUT_04.asm  CONOUT f886 - 0300
;
CONOUT:
	; Console output, entered directly from BIOS JMP Vector. it outputs the 
	; character in the C register to the appropriate device according to
	; bits 1,0 of IOBYTE
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
			; Vectors to device routines
			;*******
						TerminalOutput:
								LXI		H,TerminalTable			;HL-> control table
								JMP		OutputData				; use of JMP, InputStatus will execute thr RETurn			
										OutputData:							; data in Register C is output
												PUSH	H					; save control table pointer
												CALL	OutputStatus
														OutputStatus:						; return - A = 00H not ready
																MOV		A,M
																STA		OutputStatusPort
																DB		INopCode			; IN opcode
														OutputStatusPort:
																DB		00H					; <- set from above
																INX		H					;HL , Output status mask
																INX		H
																ANA		M					; mask with output status, 00 = Not ready
												POP		H					; restore table pointer
												JZ		OutputData			; wait until incoming data
												INX		H					; HL <- data port
												MOV		A,M					; get data port
												STA		OutputDataPort		; store it here Modify the code
												MOV		A,C					; get the data to output
												DB		OUTopCode			; Do the I/O here !!
										OutputDataPort:
												DB		00H					; <- set from above
												RET
	DW		TTYOutput			; 00 <- IOBYTE bits 1,0
	DW		TerminalOutput		; 01
	DW		CommunicationOutput	; 10
	DW		DummyOutput			; 11
	