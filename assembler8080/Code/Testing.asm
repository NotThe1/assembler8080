
					; listing starts on page 165/493 FIgure 6-4
					; in Programmers CPM Handbook by
					; Andy Johnston-Laird

INopCode	EQU		0DBH
OUTopCode	EQU		0D3H
; programmers CPM Handbook by Andy Johnson

VERSION		EQU	'01'
MONTH		EQU	'07'
DAY			EQU '08'
Year		EQU	'15'

MemorySize	EQU 64

BIOSLength	EQU 0900H

CCPLength	EQU 0800H	; Constant
BDOSLength	EQU 0E00H	; Constant

OverallLength	EQU ((CCPLength + BDOSLength + BIOSLength) /1024) + 1
;CCPEntry	EQU 0800H
CCPEntry	EQU	((MemorySize - OverallLength) * (0 + 1024))
BDOSEntry	EQU	CCPEntry + CCPLength + 6
BIOSEntry	EQU	CCPENtry + CCPLength + BDOSLength

PageZero:	ORG 0000H		; Start of page Zero
	JMP		WarmBootEntry	; warm start
IOBYTE:
	DB		01H				; IOBYTE- Console is assigned the CRT device
	DB		00H				; Current default drive (A)
	JMP		BDOSEntry		; jump to BDOS entry
	DS		028H			; interrupt locations 1-5 not used
	DS		008H			; interrupt location 6 is reserved
	JMP		0000H			; rst 7 used only by DDT & SID programs
	DS		005H			; not currently used
	DS		010H			; reserved for scratch by CBIOS- not used by CP/M
	DS		00CH			; not currently used
FCB:
	DS		021H			; Default FCB for transient programs
RandomRecordPosition:
	DS		003H			; optional random record position
DefaultDiskBuffer:
	DS		080H			; default 128- byte disk buffer,
							; also filled with the command line from CCP
	


	ORG		BIOSEntry		; Assemble code at BIOS address
		
		; BIOS jum Vector
		
	JMP	BOOT			; NOT YET CODED
WarmBootEntry:
	JMP	WBOOT			; NOT YET CODED
	JMP	CONST			; CODED
	JMP	CONIN			; CODED
	JMP	CONOUT			; CODED		     495   F95B: OutputStatusPort:
	JMP	LIST			; CODED
	JMP	PUNCH			; CODED
	JMP	READER			; CODED
	JMP	HOME			; CODED			302		FBD3
	JMP	SELDSK			; CODED			168		FB2B
	JMP	SETTRK			; CODED			211		FB58
	JMP	SETSEC			; CODED			221		FB5E
	JMP	SETDMA			; CODED			230		FB65
	JMP	READ			; CODED			398		FBFB
	JMP	WRITE			; CODED			426		FC15
	JMP	LISTST			; CODED
	JMP	SECTRAN			; CODED
	
PhysicalSectorSize	EQU	512			; for the 5.25" disk the 8" size is 128, 
DiskBuffer:
	DS	PhysicalSectorSize	
AfterDiskBuffer		EQU	$

		ORG		DiskBuffer		; wind the location counter back

InitializeStream:		; used by the initialization subroutine. Layout:
						;	DB	Port number to be initialized
						;	DB	Number of bytes to be output
						;	DB	xx.xx.xx.xx.xx.xx data to be output
						;	:
						;	:
						;	DB	Port numbe of 00H terminator
						;	Console does not need to be initalized. it was done in the PROM

		DB	CommunicationStatusPort	; intel 8251 ?
		DB	06H		; number of bytes
		DB	0		; get chip ready by sending data out to it
		DB	0
		DB	0
		DB	042H;	; Reset and raise data terminal ready
		DB	06Eh	; 1 stop bit, no parity, 8bits/char baud rate / 16
		DB	025H	;Raise request to send, and enable transmit and receive
		
		DB	CommunicationBaudMode;	Intel 8253 time
		DB	01H		; number of bytes
		DB	0B6H	; select counter2, load LS Byte
		
		DB	CommunicationBaudRate
		DB	02H		; number of bytes
		DW	0038H	; 1200 baud rate
		
		DB	0		; port number of 0 terminates
		
;  Equates for the sign in message

CR		EQU	0DH		; Carriage Return
LF		EQU	0AH		; Line Feed

SignOnMessage:		; Main sign on message
		DB	43H,50H,2FH,4DH,20H		; CP/M 2.2.
		DB	32H,2EH,32H,2EH			;(2.2.)
		DW	VERSION		; VERSION
		DB	20H
		DB	30H,37H		; MONTH
		DB	2FH			; /
		DB	31H,35H		; DAY
		DB	2FH			; /
		DB	38H,32H		; YEAR
		DB	CR,LF,LF
		
		DB	53H,69H,6DH,70H,6CH		;Simple BIOS
		DB	65H,20H,42H,49H,4fH,53H
		DB	CR,LF,LF
		
		DB	44H,69H,73H,6BH,20H		; Disk configuration :
		DB 	63H,6FH,6EH,66H,69H
		DB	67H,75H,72H,61H,74H
		DB	69H,6FH,6EH,20H,3Ah
		DB	CR,LF,LF
		
		DB	20H,20H,20H,20H,20H		; A: 0.35 Mbyte 5" Floppy' 
		DB	41H,3AH,20H,30H,2EH,33H,35H
		DB	20H,4DH,62H,79H,74H,65H
		DB	20H,35H,22H,20H
		DB	46H,6CH,6FH,70H,70H,79H
		DB	CR,LF
		
		DB	20H,20H,20H,20H,20H		; B: 0.35 Mbyte 5" Floppy'
		DB	42H,3AH,20H,30H,2EH,33H,35H
		DB	20H,4DH,62H,79H,74H,65H
		DB	20H,35H,22H,20H
		DB	46H,6CH,6FH,70H,70H,79H
		DB	CR,LF,LF
		
		DB	20H,20H,20H,20H,20H		; C: 0.24 Mbyte 8" Floppy
		DB	43H,3AH,20H,30H,2EH,32H,34H
		DB	20H,4DH,62H,79H,74H,65H
		DB	20H,35H,22H,20H
		DB	46H,6CH,6FH,70H,70H,79H
		DB	CR,LF
		
		DB	20H,20H,20H,20H,20H		; D: 0.24 Mbyte 8" Floppy
		DB	44H,3AH,20H,30H,2EH,32H,34H
		DB	20H,4DH,62H,79H,74H,65H
		DB	20H,35H,22H,20H
		DB	46H,6CH,6FH,70H,70H,79H
		DB	CR,LF
		
;		DB	20H,20H,20H,20H,20H
;		DB	20H,20H,20H,20H,20H
;		DB	20H,20H,20H,20H,20H
;		DB	20H,20H,20H,20H,20H
		
;		DS	84H		; 132  sign on message goes here
		
		DB	00
		
	DefaultDisk	EQU	0004H
	
;219--------------------BOOT-----------------------------	
	
	BOOT:		; entered directly from the BIOS JMP vector
				; Control transfered by the CP/M bootstrap loader
				; initial state will be determined by the PROM
				
				; setting up 8251 & 8253 --
	DI
	LXI	H,InitializeStream		;HL-> Data stream
;
InitializeLoop:
	MOV	A,M		; get port #
	ORA A		; if 00H then done
	JZ	InitializeComplete
	
	STA	InitializePort	; set up OUT instruction
	INX	H		; HL -> count # of bytes to output
	MOV	C,M		; get byte count
	
InitializeNextByte:
	INX	H	
	MOV	A,M		; get next byte
	DB OUTopCode		; OUT instruction output to correct port
	
InitializePort:
	DB	0		; set by above code (self modifying code!!!!!)
	DCR	C		; Count down
	JNZ	InitializeNextByte
	INX	H		; HL-> next port number
	JMP InitializeLoop	; go back for more
	
InitializeComplete:
	MVI	A,01H	; set up for terminal to be console
	STA	IOBYTE
	
	LXI	H,SignonMessage
	CALL	DisplayMessage
	
	XRA	A		; Set default disk to A:
	STA	DefaultDisk
	EI			; enable the interrupts
	
	JMP	EnterCPM	; Complete initialization and enter CP/M
					; by going to the Console Command Processor
;
;271---------------End of Cold Boot Initialization Code--------------

		ORG AfterDiskBuffer		; reset Location Counter
DisplayMessage:
	MOV		A,M		; get next message byte
	ORA		A		; check if terminator
	RZ			; Yes, thes return to caller
	
	MOV		C,A		; prepare for output
	PUSH	HL		; save message pointer
	CALL	CONOUT	; go to main console output routine	*********************************************
	POP		H
	INX		H 		; point at next character
	JMP		DisplayMessage	; loop till done
	
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
	
	EI
	LDA		DefaultDisk		; Transfer current default disk to
	MOV		C,A			; Console Command Processor
	JMP		CCPEntry	; transfer to CCP
		
		
		
;IOBYTE	EQU		0003H		;I/O redirection byte

;333--------------------CONST----------------------------
	; Entered directly from BIOS JMP vector
	; returns Register A
	; 00H -> No data
	; 0FFH -> there is data
CONST:
	CALL	GetConsoleStatus	; return A= zero or not zero
	ORA		A
	RZ					; if 0 no returning data
	MVI		A,0FFH		; else indicate there is data
	RET
	
GetConsoleStatus:
	LDA		IOBYTE		; Get IO redirection byte
	CALL	SelectRoutine	; these routines return to the caller of GetConsoleStatus
	DW		TTYInStatus				; 00  <- IOBYTE bits 1,0
	DW		TerminalInStatus		; 01
	DW		CommunicationInStatus	; 10
	DW		DummyInStatus			; 11
	
CONIN:
						; get console Input character
						; entered directly from the BIOS jmp Vector
						; return the character from the console in the A register.
						; most significant bit will be 0. except when "reader" (communication)
						; port has input , all 8 bits are reurned
						;
						; normally this follows a call to CONST. it indicates a char is ready.
						; this is a blocking call
	LDA		IOBYTE			; get i/o redirection byte
	CALL 	SelectRoutine
	DW		TTYInput			; 00 <- IOBYTE bits 1,0
	DW		TerminalInput		; 01
	DW		CommunicationInput	; 10
	DW		DummyInput			; 11
	
CONOUT:
						; Console output
						; entered directly from BIOS JMP Vector
						; outputs the data character in the C register
						; to the appropriate device according to bits 1,0 of IOBYTE
	LDA		IOBYTE			; get i/o redirection byte
	CALL 	SelectRoutine
	DW		TTYOutput			; 00 <- IOBYTE bits 1,0
	DW		TerminalOutput		; 01
	DW		CommunicationOutput	; 10
	DW		DummyOutput			; 11
	
LISTST:					; List Device (output) status
						; entered directly from the BIOS JMP Vector
						; returns in A the list device status that indicates
						; if the device will accept another character
						; the IOBYTE's bits 7,6 determin the physical device
						;
						; A = 00H (zero flag set): cannot accpet data
						; A = 0FFH ( zero flag cleared): can accept data
	CALL	GetListStatus	; return  A = 0 or non-zero
	
	ORA		A				; set flags
	RZ						; exit if not ready
	MVI		a,0FFH			; else set retuen value for ok
	RET	
	; exit
GetListStatus:
	LDA		IOBYTE
	RLC						; move bits 7,6
	RLC						; to 1,0
	CALL	SelectRoutine
	DW		TTYOutStatus			; 00 <- IOBYTE bits 1,0
	DW		TerminalOutStatus		; 01
	DW		CommunicationOutStatus	; 10
	DW		DummyOutStatus			; 11
	
LIST:					; List output
						; entered directly from the BIOS JMP Vector
						; outputs the data in Register C
	LDA		IOBYTE
	RLC						; move bits 7,6
	RLC						; to 1,0
	CALL	SelectRoutine
	DW		TTYOutput			; 00 <- IOBYTE bits 1,0
	DW		TerminalOutput		; 01
	DW		CommunicationOutput	; 10
	DW		DummyOutput			; 11
	
PUNCH:					; Punch output
						; entered directly from the BIOS JMP Vector
						; outputs the data in Register C
	LDA		IOBYTE
	RLC						; move bits 5,4
	RLC
	RLC						; to 1,0
	CALL	SelectRoutine
	DW		TTYOutput			; 00 <- IOBYTE bits 1,0
	DW		DummyOutput			; 01
	DW		CommunicationOutput	; 10
	DW		TerminalOutput		; 11
	
READER:					; Reader Input
						; entered directly from the BIOS JMP Vector
						; inputs data into the A register
	LDA		IOBYTE
	RLC						; move bits 3,2  to 1,0
	CALL	SelectRoutine
	DW		TTYOutput			; 00 <- IOBYTE bits 1,0
	DW		DummyOutput			; 01
	DW		CommunicationOutput	; 10
	DW		TerminalOutput		; 11
	
	
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

	
;------------------------- Input/Output Equates---------------------------------------

TTYStatusPort				EQU	0EDH
TTYDataPort					EQU	0ECH
TTYOutputReady				EQU	01H		; Status Mask
TTYInputReady				EQU	02H		; Status Mask

TerminalStatusPort			EQU	02H
TerminalDataPort			EQU	01H
TerminalOutputReady			EQU	80H		; Status Mask - ready for output
TerminalInputReady			EQU	07FH	; Status Mask - bytes yet to have been read

CommunicationStatusPort		EQU	0EDH
CommunicationDataPort		EQU	0ECH
CommunicationOutputReady	EQU	01H		; Status Mask
CommunicationInputReady		EQU	02H		; Status Mask

CommunicationBaudMode		EQU	0DFH
CommunicationBaudRate		EQU	0DEH

TTYTable:
		DB		TTYStatusPort
		DB		TTYDataPort
		DB		TTYOutputReady
		DB		TTYInputReady
TerminalTable:
		DB		TerminalStatusPort
		DB		TerminalDataPort
		DB		TerminalOutputReady
		DB		TerminalInputReady
CommunicationTable:
		DB		CommunicationStatusPort
		DB		CommunicationDataPort
		DB		CommunicationOutputReady
		DB		CommunicationInputReady
;------------------------- Input/Output Equates---------------------------------------


;590----------------------routines called by SelectRoutine----------------------------
TTYInStatus:
		LXI		H,TTYTable		;HL-> control table
		JMP		InputStatus		; use of JMP, InputStatus will execute thr RETurn
TerminalInStatus:
		LXI		H,TerminalTable	;HL-> control table
		JMP		InputStatus		; use of JMP, InputStatus will execute thr RETurn
CommunicationInStatus:
		LXI		H,CommunicationTable	;HL-> control table
		JMP		InputStatus		; use of JMP, InputStatus will execute thr RETurn
DummyInStatus:
		MVI		A,0FFH			; Dummy always indicates data ready
		RET
		
TTYOutStatus:
		LXI		H,TTYTable		;HL-> control table
		JMP		OutputStatus		; use of JMP, OutputStatus will execute thr RETurn
TerminalOutStatus:
		LXI		H,TerminalTable	;HL-> control table
		JMP		OutputStatus		; use of JMP, OutputStatus will execute thr RETurn
CommunicationOutStatus:
		LXI		H,CommunicationTable	;HL-> control table
		JMP		OutputStatus		; use of JMP, OutputStatus will execute thr RETurn
DummyOutStatus:
		MVI		A,0FFH			; Dummy always indicates ready to output data
		RET

TTYInput:
		LXI		H,TTYTable		;HL-> control table
		JMP		InputData		; use of JMP, InputStatus will execute thr RETurn
TerminalInput:
		LXI		H,TerminalTable	;HL-> control table
		CALL	InputData		;** special **
		ANI		07FH			; Strip off high order bit
		RET	
CommunicationInput:
		LXI		H,CommunicationTable	;HL-> control table
		JMP		InputData		; use of JMP, InputStatus will execute thr RETurn
DummyInput:
		MVI		A,01AH			; Dummy always returns EOF
		RET
		
TTYOutput:
		LXI		H,TTYTable		;HL-> control table
		JMP		OutputData		; use of JMP, InputStatus will execute thr RETurn
TerminalOutput:
		LXI		H,TerminalTable	;HL-> control table
		JMP		OutputData		; use of JMP, InputStatus will execute thr RETurn
CommunicationOutput:
		LXI		H,CommunicationTable	;HL-> control table
		JMP		OutputData		; use of JMP, InputStatus will execute thr RETurn
DummyOutput:
		RET						; Dummy always discards the data

;680---------------------General purpose low-level drivers-------------------

; On entry, HL points to appropriate control table, for output Register C contains the data to output

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
		
InputData:					; return with next character
		PUSH	H			; save control table pointer
		CALL	InputStatus
		POP		H
		JZ		InputData	; wait until incoming data
		INX		H			; HL <- data port
		MOV		A,M			; get data port
		STA		InputDataPort
		DB		INopCode
InputDataPort:
		DB		00H			; <- set from above
		RET
		
OutputData:					; data in Register C is output
		PUSH	H			; save control table pointer
		CALL	OutputStatus
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
		
;746,795  page 175 -----------------High Level Diskette drivers--------------------		
;-------------------------------------------- TEMP Labels---------------------
;BOOT:			; CODED
WBOOT:			; NOT YET CODED
;CONST:			; CODED
;CONIN:			; CODED
;CONOUT:		; CODED     495   F95B: OutputStatusPort:
;LIST:			; CODED
;PUNCH:			; CODED
;READER:		; CODED
HOME:			; NOT YET CODED
SELDSK:			; NOT YET CODED
SETTRK:			; NOT YET CODED
SETSEC:			; NOT YET CODED
SETDMA:			; NOT YET CODED
READ:			; NOT YET CODED
WRITE:			; NOT YET CODED
;LISTST:		; CODED
SECTRAN:		; NOT YET CODED