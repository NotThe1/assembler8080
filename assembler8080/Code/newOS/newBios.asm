; newBios.asm
; part of newOS
; 2014-03-14  :  Frank Martyn

		$Include ../Headers/osHeader.asm
		$Include ../Headers/stdHeader.asm
INopCode	EQU		0DBH
OUTopCode	EQU		0D3H


		;;;	DefaultDisk	EQU	0004H
PageZero:	ORG 0000H		; Start of page Zero
	JMP		WarmBootEntry	; warm start
;IOBYTE:
	DB		01000001B		; IOBYTE- Console & List is assigned the CRT device
DefaultDisk:
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
	

CodeStart:
	ORG		BIOSEntry		; Assemble code at BIOS address		
		; BIOS jum Vector
		
	JMP	BOOT			; 00  Not Yet Checked
WarmBootEntry:
	JMP	WBOOT			; 01 Not Yet Checked
	JMP	CONST			; 02 Checked
	JMP	CONIN			; 03 Checked
	JMP	CONOUT			; 04 Checked
	JMP	LIST			; 05 Checked
	JMP	PUNCH			; 06 Not Yet Checked *
	JMP	READER			; 07 Not Yet Checked *
	JMP	HOME			; 08 Not Yet Checked
	JMP	SELDSK			; 09 Checked	
	JMP	SETTRK			; 0A Not Yet Checked
	JMP	SETSEC			; 0B Not Yet Checked
	JMP	SETDMA			; 0C Not Yet Checked
	JMP	READ			; 0D Not Yet Checked
	JMP	WRITE			; 0E Not Yet Checked
	JMP	LISTST			; 0F Not Yet Checked
	JMP	SECTRAN			; 10 Not Yet Checked
;-------------------------------------------------
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

;CommunicationBaudMode		EQU	0DFH
;CommunicationBaudRate		EQU	0DEH
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
;----------------------routines called by SelectRoutine----------------------------	
TTYInStatus:
		LXI		H,TTYTable				;HL-> control table
		JMP		InputStatus				; use of JMP, InputStatus will execute thr RETurn
TerminalInStatus:
		LXI		H,TerminalTable			;HL-> control table
		JMP		InputStatus				; use of JMP, InputStatus will execute thr RETurn
CommunicationInStatus:
		LXI		H,CommunicationTable	;HL-> control table
		JMP		InputStatus				; use of JMP, InputStatus will execute thr RETurn
DummyInStatus:
		MVI		A,0FFH					; Dummy always indicates data ready
		RET
;--------------------------------------------------------------------------------	
TTYInput:
		LXI		H,TTYTable				;HL-> control table
		JMP		InputData				; use of JMP, InputStatus will execute thr RETurn
TerminalInput:
		LXI		H,TerminalTable			;HL-> control table
		CALL	InputData				;** special **
		ANI		07FH					; Strip off high order bit
		RET	
CommunicationInput:
		LXI		H,CommunicationTable	;HL-> control table
		JMP		InputData				; use of JMP, InputStatus will execute thr RETurn
DummyInput:
		MVI		A,01AH					; Dummy always returns EOF
		RET
;---------------------------------------------------------------------------
InputStatus:							; return- A = 00H no incoming data
		MOV		A,M						; get status port
		STA		InputStatusPort			;** self modifying code
		DB		INopCode				; IN opcode
InputStatusPort:
		DB		00H						; <- set from above
		INX		H						; move HL to point to input data mask
		INX		H
		INX		H
		ANA		M						; mask with input status
		RET								; return with status (00 nothing, FF - data available)
;---------------------------------------------------------------------------
InputData:							; return with next character
		PUSH	H					; save control table pointer
		CALL	InputStatus
		POP		H					; restore the control table
		JZ		InputData			; wait until incoming data
		INX		H					; HL <- data port
		MOV		A,M					; get data port
		STA		InputDataPort		; modify code here
		DB		INopCode			; do the actual I/O
InputDataPort:
		DB		00H					; <- set from above
		RET							; return with data in A
;---------------------------------------------------------------------------
OutputStatus:						; return - A = 00H not ready
		MOV		A,M
		STA		OutputStatusPort
		DB		INopCode			; IN opcode
OutputStatusPort:
		DB		00H					; <- set from above
		INX		H					;HL , Output status mask
		INX		H
		ANA		M					; mask with output status, 00 = Not ready
		RET
;---------------------------------------------------------------------------
OutputData:							; data in Register C is output
		PUSH	H					; save control table pointer
		CALL	OutputStatus
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
;---------------------------------------------------------------------------
TTYOutput:
		LXI		H,TTYTable				;HL-> control table
		JMP		OutputData				; use of JMP, InputStatus will execute thr RETurn
TerminalOutput:
		LXI		H,TerminalTable			;HL-> control table
		JMP		OutputData				; use of JMP, InputStatus will execute thr RETurn
CommunicationOutput:
		LXI		H,CommunicationTable	;HL-> control table
		JMP		OutputData				; use of JMP, InputStatus will execute thr RETurn
DummyOutput:
		RET						; Dummy always discards the data
;---------------------------------------------------------------------------
		
DisplayMessage:
	MOV		A,M					; get next message byte
	ORA		A					; terminator (a = 0)?
	RZ							; Yes, thes return to caller
	
	MOV		C,A					; prepare for output
	PUSH	HL					; save message pointer
	CALL	CONOUT				; go to main console output routine	*******
	POP		H
	INX		H 					; point at next character
	JMP		DisplayMessage		; loop till done

;---------------------------------------------------------------------------
;	Console Status  BIOS 02
; Entered directly from BIOS JMP vector, returns Register A
; 00H -> No data ,  0FFH -> there is data
;

CONST:
	CALL	GetConsoleStatus	; return A= zero or not zero
	ORA		A
	RZ							; if 0 no returning data
	MVI		A,0FFH				; else indicate there is data
	RET
;---------------------------------------------------------------------------
GetConsoleStatus:
	LDA		IOBYTE		; Get IO redirection byte
	CALL	SelectRoutine	; these routines return to the caller of GetConsoleStatus
	DW		TTYInStatus				; 00  <- IOBYTE bits 1,0
	DW		TerminalInStatus		; 01
	DW		CommunicationInStatus	; 10
	DW		DummyInStatus			; 11

;---------------------------------------------------------------------------
;	Console In  BIOS 03
; Get console Input character entered directly from the BIOS jmp Vector
; return the character from the console in the A register.
; most significant bit will be 0. except when "reader" (communication)
; port has input , all 8 bits are reurned

CONIN:
	; normally this follows a call to CONST ( a blocking call) to indicates a char is ready.
	LDA		IOBYTE				; get i/o redirection byte
	CALL 	SelectRoutine
			; Vectors to device routines
	DW		TTYInput			; 00 <- IOBYTE bits 1,0
	DW		TerminalInput		; 01
	DW		CommunicationInput	; 10
	DW		DummyInput			; 11

;---------------------------------------------------------------------------
;	Console Out  BIOS 04
;  entered directly from BIOS JMP Vector. it outputs the 
; character in the C register to the appropriate device according to
; bits 1,0 of IOBYTE
CONOUT:
	LDA		IOBYTE				; get i/o redirection byte
	CALL 	SelectRoutine
			; Vectors to device routines
	DW		TTYOutput			; 00 <- IOBYTE bits 1,0
	DW		TerminalOutput		; 01
	DW		CommunicationOutput	; 10
	DW		DummyOutput			; 11

;---------------------------------------------------------------------------
;	List output  BIOS 05
; entered directly from the BIOS JMP Vector
; outputs the data in Register C
LIST:
	LDA		IOBYTE
	RLC						; move bits 7,6
	RLC						; to 1,0
	CALL	SelectRoutine
	DW		TTYOutput			; 00 <- IOBYTE bits 1,0
	DW		TerminalOutput		; 01
	DW		CommunicationOutput	; 10
	DW		DummyOutput			; 11	

;---------------------------------------------------------------------------
;	Punch output  BIOS 06	- not tested
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
	
;---------------------------------------------------------------------------
;	Reader input  BIOS 07	- not tested
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
	
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
;				Disk routines
;---------------------------------------------------------------------------
;	Select Disk	BIOS 09
; Select disk in C. C=0 for A: 1 for B: etc.
; Return the address of the appropriate disk parameter header
; in HL, or 0000H if selected disk does not exist		
;**********************	
SELDSK:
	LXI		H,00H				; Assume an error
	MOV		A,C 				; Check if  requested disk is valid
	CPI		NumberOfLogicalDisks
	RNC							; return if > max number of Disks
	
	STA		SelectedDisk		; save disk number
	MOV		L,A					; make disk into word number
	MVI		H,0
		; Compute offset down disk parameter table by multiplying by parameter
		; header length (16 bytes)
	DAD		H
	DAD		H
	DAD		H
	DAD		H					; pointing at right one
	LXI		D,DiskParameterHeaders		; get base address
	DAD		D					; DE -> appropriate DPH
	PUSH	H					; Save DPH address access disk parameter block to extract special
								;    prefix byte that identifies disk type and whether de-blocking
								;    is required
	LXI		D,10				; Get DPB pointer offset in DPH
	DAD		D					; DE -> DPB address
	MOV		E,M					; Get DPB address in DE
	INX		H
	MOV		D,M	
	XCHG						; DE ->DPB
	DCX		H					; DE -> prefix byte
	MOV		A,M					; get Disk Type/Blocking byte
								; Disk Type bottom nibble - Blocking MSB (bit 7)
	ANI		0FH					; isolate disk type
	STA		DiskType			; save for use in low level driver
	MOV		A,M					; get another copy
	ANI		NeedDeblocking		; determin if deblocking is required and
	STA		DeblockingRequired	; save for low level driver
	POP		H					; recover DPH pointer
	RET
	
;**********************	
;	Set Track	BIOS 0A
;SETTRK - Set logical track for next read or write
;		Track is in BC
;**********************	
SETTRK:
	MOV		H,B					; select track in BC on entry
	MOV		L,C
	SHLD	SelectedTrack		; save for low level driver	
	RET
;---------------------------------------------------------------------------
;				Disk Data
;---------------------------------------------------------------------------
;				Disk Equates
;---------------------------------------------------------------------------
; Disk Types
Floppy5			EQU		1 		; 5 1/4" mini floppy
Floppy8			EQU		2 		; 8"  floppy (SS SD)

NumberOfLogicalDisks	EQU 4	; max number of disk in this system

NeedDeblocking	EQU 	080H	; Sector size > 128 bytes

;---------------------------------------------------------------------------
;				Disk Storage area
;---------------------------------------------------------------------------
;     variables for selected disk, track and sector
; These are moved and compared as a group, DO NOT ALTER
SelectedDkTrkSec:
SelectedDisk:			DB		00H
SelectedTrack:			DW		00H
SelectedSector:			DB		00H

DiskType:				DB		00H		; Indicate 8" or 5 1/4" selected  (set in SELDSK)
DeblockingRequired:		DB		00H		; Non-zero when the selected disk needs de-blocking (set in SELDSK)
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
;				Disk Definition Tables
; These consists of disk parameter headers, with one entry
; per logical disk driver, and disk parameter blocks, with
; either one parameter block per logical disk or the same
; parameter block for several logical disks.
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
DiskParameterHeaders:		; described in chapter 3

		; Logical Disk A: (5 1/4" Diskette)
	DW	Floppy5SkewTable				; 5 1/4" skew table
	DW	0								; Rel pos for file (0-3)
	DW	0								; Last Selected Track #
	DW	0								; Last Selected Sector #
	DW	DirectoryBuffer
	DW	Floppy5ParameterBlock
	DW	DiskAWorkArea
	DW	DiskAAllocationVector
	
		; Logical Disk B: (5 1/4" Diskette)
	DW	Floppy5SkewTable	; shares the same skew table as A:
	DW	0								; Rel pos for file (0-3)
	DW	0								; Last Selected Track #
	DW	0								; Last Selected Sector #
	DW	DirectoryBuffer		; all disks use this buffer
	DW	Floppy5ParameterBlock
	DW	DiskBWorkArea
	DW	DiskBAllocationVector
	
		; Logical Disk C: (8" Floppy)
	DW	Floppy8SkewTable	; 8" skew table
	DW	0								; Rel pos for file (0-3)
	DW	0								; Last Selected Track #
	DW	0								; Last Selected Sector #
	DW	DirectoryBuffer		; all disks use this buffer
	DW	Floppy8ParameterBlock
	DW	DiskCWorkArea
	DW	DiskCAllocationVector
	
		; Logical Disk D: (8" Floppy)
	DW	Floppy8SkewTable	; shares the same skew table as A:
	DW	0								; Rel pos for file (0-3)
	DW	0								; Last Selected Track #
	DW	0								; Last Selected Sector #
	DW	DirectoryBuffer		; all disks use this buffer
	DW	Floppy8ParameterBlock
	DW	DiskDWorkArea
	DW	DiskDAllocationVector
	
	DB	Floppy5 + NeedDeblocking
	
Floppy5ParameterBlock:
	DW	048H				; 128-byte sectors per track- (72)
	DB	04H					; Block shift ( 4=> 2K)
	DB	0FH					; Block mask
	DB	01 					; Extent mask
	DW	0AEH 				; Maximum allocation block number (174)
	DW	07FH 				; Number of directory entries - 1 (127)
	DB	0C0H				; Bit map for reserving 1 alloc. block
	DB	00					;  for file directory
	DW	020H				;Disk change work area size (32)
	DW	01					; Number of tracks before directory
	
	; Standard 8" floppy
							; extra byte prefixed to DPB for 
							;  this version of the BIOS
	DB	Floppy8				; Indicates disk type and the fact
							;   that no de-blocking is required
	
Floppy8ParameterBlock:
	DW	01AH				; sectors per track (26)
	DB	03					; Block shift (3=>1K)
	DB	07					; Block mask
	DB	00 					; Extent mask
	DW	0F2H 				; Maximum allocation block number (242)
	DW	03FH 				; Number of directory entries - 1 (63)
	DB	0C0H				; Bit map for reserving 2 alloc. block
	DB	00					;  for file directory
	DW	010H				;Disk change work area size (16)
	DW	02					; Number of tracks before directory
	

Floppy5SkewTable:			; each physical sector contains four
							;  128-byte sectors						
	DB		00,01,02,03,04,05,06,07,08,09
	DB		10,11,12,13,14,15,16,17,18,19
	DB		20,21,22,23,24,25,26,27,28,29
	DB		30,31,32,33,34,35,36,37,38,39
	DB		40,41,42,43,44,45,46,47,48,49
	DB		50,51,52,53,54,55,56,57,58,59
	DB		60,61,62,63,64,65,66,67,68,69
	DB		70,71
Floppy8SkewTable:			; Standard 8" Driver
	DB		01,02,03,04,05,06,07,08,09,10		; Physical Sectors
	DB		11,12,13,14,15,16,17,18,19,20		; Physical Sectors
	DB		21,22,23,24,25,26					; Physical Sectors

;---------------------------------------------------------------------------
;				Disk work area
;---------------------------------------------------------------------------
; These are used by the BDOS to detect any unexpected
; change of diskette. The BDOS will automatically set
; such a changed diskette to read-only status.
	
DiskAWorkArea:	DS	020H		; A:
DiskBWorkArea:	DS	020H		; B:
DiskCWorkArea:	DS	010H		; C:
DiskDWorkArea:	DS	010H		; D:

;---------------------------------------------------------------------------
;				Disk allocation vectors
;---------------------------------------------------------------------------
; Disk allocation vectors
; These are used by the BDOS to maintain a bit map of
; which allocation blocks are used and which are free.
; One byte is used for eight allocation blocks, hence the
; expression of the form (allocation blocks/8)+1

DiskAAllocationVector:	DS		(174/8)+1 	; A:
DiskBAllocationVector:	DS		(174/8)+1 	; B:
	
DiskCAllocationVector:	DS		(242/8)+1 	; C:
DiskDAllocationVector:	DS		(242/8)+1 	; A:
;---------------------------------------------------------------------------
;				Disk Buffer
;---------------------------------------------------------------------------
DirBuffSize	EQU		128
DirectoryBuffer:	DS	DirBuffSize
;---------------------------------------------------------------------------
		
;------------------------- Not Yet Implemented	
BOOT:
WBOOT:

PUNCH:
READER:
HOME:
SELDSK:
SETTRK:
SETSEC:
SETDMA:
READ:
WRITE:
LISTST:
SECTRAN:
		HLT
		
CodeEnd: