;219--------------------BOOT-----------------------------	
	
	BOOT:		; entered directly from the BIOS JMP vector
				; Control transfered by the CP/M bootstrap loader
				; initial state will be determined by the PROM
				
				; setting up 8251 & 8253 --
	DI
					; on this system the console is already initialized so the
					; InitializeStream is not used here
	LXI		H,InitializeStream		;HL-> Data stream
;
InitializeLoop:
	MOV		A,M					; get port #
	ORA		A					; if 00H then done
	JZ		InitializeComplete
	
	STA		InitializePort		; set up OUT instruction
	INX		H					; HL -> count # of bytes to output
	MOV		C,M					; get byte count
InitializeNextByte:
	INX		H	
	MOV		A,M					; get next byte
	DB		OUTopCode			; OUT instruction output to correct port
InitializePort:
	DB		0					; set by above code (self modifying code!!!!!)
	DCR		C					; Count down
	JNZ		InitializeNextByte
	INX		H					; HL-> next port number
	JMP InitializeLoop			; go back for more
;----------- above not needed with the console ------------------------	
InitializeComplete:
	MVI		A,01H				; set up for terminal to be console
	STA		IOBYTE
	LXI		H,SignonMessage
	CALL	DisplayMessage		; display the signon message
		DisplayMessage:
			MOV		A,M		; get next message byte
			ORA		A		; check if terminator
			RZ			; Yes, thes return to caller
			
			MOV		C,A		; prepare for output
			PUSH	HL		; save message pointer
			CALL	CONOUT	; go to main console output routine
				CONOUT:
										; Console output
										; entered directly from BIOS JMP Vector
										; outputs the data character in the C register
										; to the appropriate device according to bits 1,0 of IOBYTE
					LDA		IOBYTE			; get i/o redirection byte
					CALL 	SelectRoutine			
								; SelectRoutine
								; Transfer control to a specified address following its calling address
								; according to the values in bits 1, 0 in A.	
						SelectRoutine:
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
							RET				; transfer to selected routine
						;** this example uses Terminal Output so it will resolve to "TerminalOutput"
						; below
								TerminalOutput:
										LXI		H,TerminalTable	;HL-> control table
											;TerminalTable:
													;DB		TerminalStatusPort
													;DB		TerminalDataPort
													;DB		TerminalOutputReady
													;DB		TerminalInputReady

										JMP		OutputData		; use of JMP, InputStatus will execute thr RETurn
												OutputData:					; data in Register C is output
														PUSH	H			; save control table pointer
														CALL	OutputStatus
																OutputStatus:				; return - A = 00H not ready
																		MOV		A,M
																		STA		OutputStatusPort
																		DB		INopCode		; IN opcode
																OutputStatusPort:
																		DB		00H			; <- set from above
																		INX		H			;HL , Output status mask
																		INX		H
																		ANA		M			; mask with output status
																		RET
																
														POP		H
														JZ		OutputData	; wait until incoming data
														INX		H			; HL <- data port
														MOV		A,M			; get data port
														STA		OutputDataPort
														MOV		A,C			; get the data to output
														DB		OUTopCode
												OutputDataPort:
														DB		00H			; <- set from above
														RET

					DW		TTYOutput			; 00 <- IOBYTE bits 1,0
					DW		TerminalOutput		; 01
					DW		CommunicationOutput	; 10
					DW		DummyOutput			; 11
			POP		H
			INX		H 		; point at next character
			JMP		DisplayMessage	; loop till done
	XRA		A					; Set default disk to A: (0)
	STA		DefaultDisk
	EI							; enable the interrupts
	
	JMP		EnterCPM			; Complete initialization and enter CP/M
								; by going to the Console Command Processor
					EnterCPM:
						MVI		A,0C3H		; JMP op code
						STA		0000H		; set up the jump in location 0000H
						STA		0005H		; and at location 0005H
						
						LXI		H,WarmBootEntry	; get BIOS vector address
						SHLD	0001H		; put address in location 1
						
						LXI		H,BDOSEntry	; Get BDOS entry point address
						SHLD	0006H		; put address at location 5
						
						LXI		B,80H		; set disk I/O address to default
						CALL	SETDMA		; use normal BIOS routine		****************************************************************
								SETDMA:
									MOV		L,C					; select address in BC on entry
									MOV		H,B
									SHLD	DMAAddress		; save for low level driver	
									RET
									
						EI
						LDA		DefaultDisk		; Transfer current default disk to
						MOV		C,A			; Console Command Processor
						JMP		CCPEntry	; transfer to CCP
					
;271---------------End of Cold Boot Initialization Code--------------