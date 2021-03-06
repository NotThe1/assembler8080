; newBios.asm
; part of newOS
; 2014-03-14  :  Frank Martyn

	$Include ../Headers/osHeader.asm
	$Include ../Headers/stdHeader.asm
INopCode	EQU	0DBH
OUTopCode	EQU	0D3H


; DefaultDisk	EQU	0004H
PageZero:	ORG	0000H				; Start of page Zero
	JMP	WarmBootEntry			; warm start
;IOBYTE:
	DB	01000001B				; IOBYTE- Console & List is assigned the CRT device
DefaultDisk:
	DB	00H				; Current default drive (A)
	JMP	BDOSEntry				; jump to BDOS entry
	DS	028H				; interrupt locations 1-5 not used
	DS	008H				; interrupt location 6 is reserved
	JMP	0000H				; rst 7 used only by DDT & SID programs
	DS	005H				; not currently used
	DS	010H				; reserved for scratch by CBIOS- not used by CP/M
	DS	00CH				; not currently used
FCB:
	DS	021H				; Default FCB for transient programs
RandomRecordPosition:
	DS	003H				; optional random record position
DefaultDiskBuffer:
	DS	080H				; default 128- byte disk buffer,
						; also filled with the command line from CCP
	

	ORG	BIOSEntry				; Assemble code at BIOS address
						; BIOS jum Vector
CodeStart:
	
	JMP	BOOT				; 00  Not Yet Checked
WarmBootEntry:
	JMP	WBOOT				; 01 Not Yet Checked
	JMP	CONST				; 02 Checked
	JMP	CONIN				; 03 Checked
	JMP	CONOUT				; 04 Checked
	JMP	LIST				; 05 Checked
	JMP	PUNCH				; 06 Not Yet Checked *
	JMP	READER				; 07 Not Yet Checked *
	JMP	HOME				; 08 Checked
	JMP	SELDSK				; 09 Checked
	JMP	SETTRK				; 0A Checked
	JMP	SETSEC				; 0B Checked
	JMP	SETDMA				; 0C Checked
	JMP	READ				; 0D Not Yet Checked
	JMP	WRITE				; 0E Not Yet Checked
	JMP	LISTST				; 0F Not Yet Checked *
	JMP	SECTRAN				; 10 Checked
	
;-------------------------------------------------
	ORG	(($+10H)/10H) * 10H
PhysicalSectorSize	EQU	512			; for the 5.25" disk the 8" size is 128 
DiskBuffer:
	DS	PhysicalSectorSize	
AfterDiskBuffer	EQU	$
;-------------------------------------------------



;	ORG AfterDiskBuffer				; reset Location Counter
	


;-------------------------------------------------

TTYStatusPort		EQU	0EDH
TTYDataPort		EQU	0ECH
TTYOutputReady		EQU	01H		; Status Mask
TTYInputReady		EQU	02H		; Status Mask

TerminalStatusPort		EQU	02H
TerminalDataPort		EQU	01H
TerminalOutputReady		EQU	80H		; Status Mask - ready for output
TerminalInputReady		EQU	07FH		; Status Mask - bytes yet to have been read
                                                  
CommunicationStatusPort	EQU	0EDH      
CommunicationDataPort	EQU	0ECH      
CommunicationOutputReady	EQU	01H		; Status Mask
CommunicationInputReady	EQU	02H		; Status Mask

;CommunicationBaudMode	EQU	0DFH
;CommunicationBaudRate	EQU	0DEH
TTYTable:
	DB	TTYStatusPort
	DB	TTYDataPort
	DB	TTYOutputReady
	DB	TTYInputReady
TerminalTable:
	DB	TerminalStatusPort
	DB	TerminalDataPort
	DB	TerminalOutputReady
	DB	TerminalInputReady
CommunicationTable:
	DB	CommunicationStatusPort
	DB	CommunicationDataPort
	DB	CommunicationOutputReady
	DB	CommunicationInputReady
	
SelectRoutine:	
						; SelectRoutine. When called, the calling code has a vector table immediately following it.
						; it is used to get the correct physical routine determined by the IOBYTE bits for the
						; logical device. (00,01,10,11). 
						; It will transfer control to a specified address following its calling address
						; according to the values in bits 1, 0 in A.	

	RLC					; Shift select values into bits 2,1 in order to do word arithmetic
SelectRoutine21:					; entry point if bits already in 2,1
	ANI	06H				; isolate bits 2 and 1
	XTHL					; HL-> first word of address after CALL instruction
	MOV	E,A				; Add on selection value to address table base
	MVI	D,00H
	DAD	D				; HL-> now has the selected routine
	MOV	A,M				; LS Byte
	INX	H				; HL-> MS byte
	MOV	H,M				; MS byte
	MOV	L,A				; HL->routine
	XTHL					; top of stack -> routine
	RET					; transfer control to the selected routine
;----------------------routines called by SelectRoutine----------------------------	
TTYInStatus:
	LXI	H,TTYTable			;HL-> control table
	JMP	InputStatus			; use of JMP, InputStatus will execute thr RETurn
TerminalInStatus:                                 
	LXI	H,TerminalTable			;HL-> control table
	JMP	InputStatus			; use of JMP, InputStatus will execute thr RETurn
CommunicationInStatus:                            
	LXI	H,CommunicationTable		;HL-> control table
	JMP	InputStatus			; use of JMP, InputStatus will execute thr RETurn
DummyInStatus:
	MVI	A,0FFH				; Dummy always indicates data ready
	RET
	
TTYOutStatus:
	LXI	H,TTYTable			;HL-> control table
	JMP	OutputStatus			; use of JMP, OutputStatus will execute thr RETurn
TerminalOutStatus:                                
	LXI	H,TerminalTable			;HL-> control table
	JMP	OutputStatus			; use of JMP, OutputStatus will execute thr RETurn
CommunicationOutStatus:                           
	LXI	H,CommunicationTable		;HL-> control table
	JMP	OutputStatus			; use of JMP, OutputStatus will execute thr RETurn
DummyOutStatus:
	MVI	A,0FFH				; Dummy always indicates ready to output data
	RET

;--------------------------------------------------------------------------------
TTYInput:
	LXI	H,TTYTable			;HL-> control table
	JMP	InputData				; use of JMP, InputStatus will execute thr RETurn
TerminalInput:
	LXI	H,TerminalTable			;HL-> control table
	CALL	InputData				;** special **
	ANI	07FH				; Strip off high order bit
	RET		
CommunicationInput:
	LXI	H,CommunicationTable		;HL-> control table
	JMP	InputData				; use of JMP, InputStatus will execute thr RETurn
DummyInput:
	MVI	A,01AH				; Dummy always returns EOF
	RET
;---------------------------------------------------------------------------
InputStatus:					; return- A = 00H no incoming data
	MOV	A,M				; get status port
	STA	InputStatusPort			; ** self modifying code
	DB	INopCode				; IN opcode
InputStatusPort:
	DB	00H				; <- set from above
	INX	H				; move HL to point to input data mask
	INX	H
	INX	H
	ANA	M				; mask with input status
	RET					; return with status (00 nothing, FF - data available)
;---------------------------------------------------------------------------
InputData:					; return with next character
	PUSH	H				; save control table pointer
	CALL	InputStatus
	POP	H				; restore the control table
	JZ	InputData				; wait until incoming data
	INX	H				; HL <- data port
	MOV	A,M				; get data port
	STA	InputDataPort			; modify code here
	DB	INopCode				; do the actual I/O
InputDataPort:
	DB	00H				; <- set from above
	RET					; return with data in A
;---------------------------------------------------------------------------
OutputStatus:					; return - A = 00H not ready
	MOV	A,M
	STA	OutputStatusPort
	DB	INopCode				; IN opcode
OutputStatusPort:
	DB	00H				; <- set from above
	INX	H				;HL , Output status mask
	INX	H
	ANA	M				; mask with output status, 00 = Not ready
	RET
;---------------------------------------------------------------------------
OutputData:					; data in Register C is output
	PUSH	H				; save control table pointer
	CALL	OutputStatus
	POP	H				; restore table pointer
	JZ	OutputData			; wait until incoming data
	INX	H				; HL <- data port
	MOV	A,M				; get data port
	STA	OutputDataPort			; store it here Modify the code
	MOV	A,C				; get the data to output
	DB	OUTopCode				; Do the I/O here !!
OutputDataPort:
	DB	00H				; <- set from above
	RET
;---------------------------------------------------------------------------
TTYOutput:
	LXI	H,TTYTable			;HL-> control table
	JMP	OutputData			; use of JMP, InputStatus will execute thr RETurn
TerminalOutput:                                   
	LXI	H,TerminalTable			;HL-> control table
	JMP	OutputData			; use of JMP, InputStatus will execute thr RETurn
CommunicationOutput:                              
	LXI	H,CommunicationTable		;HL-> control table
	JMP	OutputData			; use of JMP, InputStatus will execute thr RETurn
DummyOutput:
	RET					; Dummy always discards the data
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
;	Console Status  BIOS 02
; Entered directly from BIOS JMP vector, returns Register A
; 00H -> No data ,  0FFH -> there is data
;

CONST:
	CALL	GetConsoleStatus			; return A= zero or not zero
	ORA	A
	RZ					; if 0 no returning data
	MVI	A,0FFH				; else indicate there is data
	RET
;---------------------------------------------------------------------------
GetConsoleStatus:
	LDA	IOBYTE				; Get IO redirection byte
	CALL	SelectRoutine			; these routines return to the caller of GetConsoleStatus
	DW	TTYInStatus			; 00  <- IOBYTE bits 1,0
	DW	TerminalInStatus			; 01
	DW	CommunicationInStatus		; 10
	DW	DummyInStatus			; 11

;---------------------------------------------------------------------------
;	Console In  BIOS 03
; Get console Input character entered directly from the BIOS jmp Vector
; return the character from the console in the A register.
; most significant bit will be 0. except when "reader" (communication)
; port has input , all 8 bits are reurned

CONIN:
						; normally this follows a call to CONST ( a blocking call) to indicates a char is ready.
	LDA	IOBYTE				; get i/o redirection byte
	CALL 	SelectRoutine
						; Vectors to device routines
	DW	TTYInput				; 00 <- IOBYTE bits 1,0
	DW	TerminalInput			; 01
	DW	CommunicationInput			; 10
	DW	DummyInput			; 11

;---------------------------------------------------------------------------
;	Console Out  BIOS 04
;  entered directly from BIOS JMP Vector. it outputs the 
; character in the C register to the appropriate device according to
; bits 1,0 of IOBYTE
CONOUT:
	LDA	IOBYTE				; get i/o redirection byte
	CALL 	SelectRoutine
						; Vectors to device routines
	DW	TTYOutput				; 00 <- IOBYTE bits 1,0
	DW	TerminalOutput			; 01
	DW	CommunicationOutput			; 10
	DW	DummyOutput			; 11

;---------------------------------------------------------------------------
;	List Status  BIOS 0F
	
LISTST:
; List Device (output) status entered directly from the BIOS JMP Vector
; returns in A the list device status that indicates if the device will
; accept another character the IOBYTE's bits 7,6 determin the physical device
; A = 00H (zero flag set): cannot accpet data
; A = 0FFH ( zero flag cleared): can accept data

	CALL	GetListStatus			; return  A = 0 or non-zero	
	ORA	A				; set flags
	RZ					; exit if not ready
	MVI	A,0FFH				; else set retuen value for ok
	RET		
						; exit
GetListStatus:
	LDA	IOBYTE
	RLC					; move bits 7,6
	RLC					; to 1,0
	CALL	SelectRoutine
	DW	TTYOutStatus			; 00 <- IOBYTE bits 1,0
	DW	TerminalOutStatus			; 01
	DW	CommunicationOutStatus		; 10
	DW	DummyOutStatus			; 11
;---------------------------------------------------------------------------
;	List output  BIOS 05
; entered directly from the BIOS JMP Vector
; outputs the data in Register C
LIST:
	LDA	IOBYTE
	RLC					; move bits 7,6
	RLC					; to 1,0
	CALL	SelectRoutine
	DW	TTYOutput				; 00 <- IOBYTE bits 1,0
	DW	TerminalOutput			; 01
	DW	CommunicationOutput			; 10
	DW	DummyOutput			; 11

;---------------------------------------------------------------------------
;	Punch output  BIOS 06	- not tested
PUNCH:				; Punch output
						; entered directly from the BIOS JMP Vector
						; outputs the data in Register C
	LDA	IOBYTE
	RLC					; move bits 5,4
	RLC
	RLC					; to 1,0
	CALL	SelectRoutine
	DW	TTYOutput				; 00 <- IOBYTE bits 1,0
	DW	DummyOutput			; 01
	DW	CommunicationOutput			; 10
	DW	TerminalOutput			; 11
	
;---------------------------------------------------------------------------
;	Reader input  BIOS 07	- not tested
READER:				; Reader Input
						; entered directly from the BIOS JMP Vector
						; inputs data into the A register
	LDA	IOBYTE
	RLC					; move bits 3,2  to 1,0
	CALL	SelectRoutine
	DW	TTYOutput				; 00 <- IOBYTE bits 1,0
	DW	DummyOutput			; 01
	DW	CommunicationOutput			; 10
	DW	TerminalOutput			; 11
	
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
;	Disk routines
;---------------------------------------------------------------------------
;**********************
;	Home Disk	BIOS 08
;HOME - Home the selected logical disk to track 0.
;	Before doing this, a check must be made to see if the
;	physical disk buffer has information that must be
;	written out. This is indicated by a flag, MustWriteBuffer,
;	set in the de-blocking code
;**********************	
HOME:
	LDA	MustWriteBuffer			; check flag
	ORA	A
	JNZ	HomeNoWrite
	STA	DataInDiskBuffer			; no, so indicate empty buffer
HomeNoWrite:
	MVI	C,00H				; Set to track 0
	CALL	SETTRK				; no, physical, only logical
	RET
	
;	Select Disk	BIOS 09
; Select disk in C. C=0 for A: 1 for B: etc.
; Return the address of the appropriate disk parameter header
; in HL, or 0000H if selected disk does not exist	
;**********************	
SELDSK:
	LXI	H,00H				; Assume an error
	MOV	A,C 				; Check if  requested disk is valid
	CPI	NumberOfLogicalDisks
	RNC					; return if > max number of Disks
	
	STA	SelectedDisk			; save disk number
	MOV	L,A				; make disk into word number
	MVI	H,0
						; Compute offset down disk parameter table by multiplying by parameter
						; header length (16 bytes)
	DAD	H
	DAD	H
	DAD	H
	DAD	H				; pointing at right one
	LXI	D,DiskParameterHeaders			; get base address
	DAD	D				; DE -> appropriate DPH
	PUSH	HL				; Save DPH pointer
	LXI	DE,10				; point at Parameter Block
	DAD	D				; point at the Number of Sectors/Head
	MOV	E,M
	INX	HL
	MOV	D,M				; DE has Parameter Block
	LXI	HL,15
	DAD	DE				; HL is at SecPerHeadPerTrack
	MOV	A,M				; get the value and
	STA	SelectedDskSecsPerHead		; save for actual IO	


;**	
;	PUSH	H				; Save DPH address access disk parameter block to extract special
;						;    prefix byte that identifies disk type and whether de-blocking
;						;    is required
;	LXI	D,10				; Get DPB pointer offset in DPH
;	DAD	D				; DE -> DPB address
;	MOV	E,M				; Get DPB address in DE
;	INX	H
;	MOV	D,M	
;	XCHG						; DE ->DPB
;	DCX	H				; DE -> prefix byte
;	MOV	A,M				; get Disk Type/Blocking byte
;;;***** excess code around Disk Type ****						; Disk Type bottom nibble - Blocking MSB (bit 7)
;	ANI	0FH				; isolate disk type
;	STA	DiskType				; save for use in low level driver
;	POP	H
;**	; recover DPH pointer
	POP	HL				; recover DPH pointer
	RET
	
;**********************	
;	Set Track	BIOS 0A
;SETTRK - Set logical track for next read or write.	Track is in BC
;**********************	
SETTRK:
	MOV	H,B				; select track in BC on entry
	MOV	L,C
	SHLD	SelectedTrack			; save for low level driver	
	RET
	
;**********************	
;	Set Sector	BIOS 0B
;SETSEC - Set logical sector for next read or write. Sector is in C
;**********************
SETSEC:
	MOV	A,C
	STA	SelectedSector			; save for low level driver	
	RET
	
;**********************
;	Set Sector	BIOS 0C
;SetDMA - Set DMA (input/output) address for next read or write. Address in BC
;**********************
SETDMA:
	MOV	L,C				; select address in BC on entry
	MOV	H,B
	SHLD	DMAAddress			; save for low level driver	
	RET
	
;**********************
;	Sector Translate	BIOS 10
;SECTRAN - Translate logical sector to physical
; on Entry:	BC= logical sector number DE-> appropriate skew table
; on Exit:	HL = physical sector number
;**********************
SECTRAN:
	PUSH	BC
	POP	HL			; just move the value from BC to HL
	RET
;;	XCHG					; HL -> skew table base
;;	DAD	B			; Add on logical sector number
;;	MOV	L,M			; Get physical sector number
;;	MVI	H,00H			; make into a word
;;	RET
	
;************************************************************************************************
;        READ	BIOS 
; Read in the 128-byte CP/M sector specified by previous calls to select disk and to set track  and 
; sector. The sector will be read into the address specified in the previous call to set DMA address
;
; If reading from a disk drive using sectors larger than 128 bytes, de-blocking code will be used
; to unpack a 128-byte sector from  the physical sector. 
;************************************************************************************************
READ:
;;	LDA	DeblockingRequired
;;	ORA	A
;;	JZ	ReadNoDeblock			; if 0 use normal non-blocked read (128 byte sectors)
; The de-blocking algorithm used is such that a read operation can be viewed UP until the actual
; data transfer as though it was the first write to an unallocated allocation block. 
						; else its a 512 byte sector
	XRA	A				; set record count to 0
	STA	UnalocatedlRecordCount
	INR	A
	STA	ReadFlag				; Set to non zero to indicate that this is a read
	STA	PrereadSectorFlag			; force pre-read
	MVI	A,WriteUnallocated			; fake de-blocking code into responding as if this
	STA	WriteType				;  is the first write to an unallocated allocation block
	JMP	PerformReadWrite			; use common code to execute read
;----------------------------------------
;************************************************************************************************
;	WRITE
;Write a 128-byte sector from the current DMA address to the previously $elected disk, track, and sector.
;
; On arrival here, the BOOS will have set register C to indicate whether this write operation is to:
;	00H [WriteAllocated]	 An already allocated allocation block (which means a pre-read of the sector may be needed),
;	01H [WriteDirectory]	 To the directory (in which case the data will be written to the disk immediately),
;	02H	[WriteUnallocated]	 To the first 128-byte sector of a previously unallocated allocation block (In which case no pre-read is required).
;
; Only writes to the directory take place immediately.
; In all other cases, the data will be moved from the DMA address into the disk buffer,
; and only written out when circumstance, force the transfer.
; The number of physical disk operations can therefore be reduced considerably.
;************************************************************************************************
WRITE:
; Buffered I/O
	XRA	A
	STA	ReadFlag				; Set to zero to indicate that this is not a read
	MOV	A,C
	STA	WriteType				; save the BDOS write type
	CPI	WriteUnallocated			; first write to an unallocated allocation block ?
	JNZ	CheckUnallocatedBlock		; No, - in the middle of writing to an unallocated block ?
						; Yes, It is the first write to unallocated allocation block.
; Initialize  variables associated with unallocated writes
	MVI	A,AllocationBlockSize/ 128		; Number of 128 byte sectors
	STA	UnalocatedlRecordCount                  
	LXI	H,SelectedDkTrkSec			; copy disk, track & sector into unallocated variables
	LXI	D,UnallocatedDkTrkSec
	CALL 	MoveDkTrkSec
	
						; Check if this is not the first write to an unallocated allocation block -- if it is,
						; the unallocated record count has just been set to the number of 128-byte sectors in the allocation block
CheckUnallocatedBlock:
	LDA	UnalocatedlRecordCount
	ORA	A
	JZ	RequestPreread			; No - write to an unallocated block
	DCR	A				; decrement 128 byte sectors left
	STA	UnalocatedlRecordCount
	
	LXI	H,SelectedDkTrkSec			; same Disk, Track & sector as for those in an unallocated block
	LXI	D,UnallocatedDkTrkSec         
	CALL	CompareDkTrkSec			; are they the same
	JNZ	RequestPreread			; NO - do a pre-read
						;Compare$DkSTrkSec  returns with  DE -> Unallocated$Sector , HL -> UnallocatedSSector 
	XCHG
	INR	M
	MOV	A,M
	CPI	CPMSecPerTrack			; Sector > maximum on track ?
	JC	NoTrackChange			; No ( A < M)
	MVI	M,00H				; Yes
	LHLD	UnallocatedTrack
	INX	H				; increment track 
	SHLD	UnallocatedTrack
NoTrackChange:
	XRA	A
	STA	PrereadSectorFlag			; clear flag
	JMP	PerformReadWrite
	
RequestPreread:
	XRA	A
	STA	UnalocatedlRecordCount		; not a write into an unallocated block
	INR	A
	STA	PrereadSectorFlag			; set flag
;*******************************************************
; Common code to execute both reads and writes of 128-byte sectors
;*******************************************************
PerformReadWrite:
	XRA	A				; Assume no disk error will occur
	STA	DiskErrorFlag
	LDA	SelectedSector
	RAR					; Convert selected 128-byte sector
	RAR					; into physical sector by dividing by 4
	ANI	03FH				; remove unwanted bits
	STA	SelectedPhysicalSector
	LXI	H,DataInDiskBuffer			; see if there is any data here ?
	MOV	A,M
	MVI	M,001H				; force there is data here for after the actual read
	ORA	A				; really is there any data here ?
	JZ	ReadSectorIntoBuffer		; NO - go read into buffer
;
						; The buffer does have a physical sector in it, Note: The disk, track, and PHYSICAL sector
						; in the buffer need to be checked, hence the use of the CompareDkTrk subroutine.
	LXI	D,InBufferDkTrkSec
	LXI	H,SelectedDkTrkSec			; get the requested sector
	CALL	CompareDkTrk			; is it in the buffer ? 
	JNZ	SectorNotInBuffer			; NO, it must be read
						; Yes, it is in the buffer
	LDA	InBufferSector			; get the sector
	LXI	H,SelectedPhysicalSector
	CMP	M				; Check if correct physical sector
	JZ	SectorInBuffer			; Yes - it is already in memory
						; No, it will have to be read in over current contents of buffer
SectorNotInBuffer:
	LDA	MustWriteBuffer
	ORA	A				; do we need to write ?
	CNZ	WritePhysical			; if yes - write it out

ReadSectorIntoBuffer:
						; indicate the  selected disk, track, and sector now residing in buffer
	LDA	SelectedDisk
	STA	InBufferDisk
	LHLD	SelectedTrack
	SHLD	InBufferTrack
	LDA	SelectedPhysicalSector
	STA	InBufferSector
	
	LDA	PrereadSectorFlag			; do we need to pre-read
	ORA	A
	CNZ	ReadPhysical			; yes - pre-read the sector
	
; At this point the data is in the buffer.
; Either it was already here, or we returned from ReadPhysical

	XRA	A				; reset the flag
	STA	MustWriteBuffer			; and store it away
	
; Selected sector on correct track and  disk is already 1n the buffer.
; Convert the selected CP/M(128-byte sector into relative address down the buffer. 
SectorInBuffer:
	LDA	SelectedSector
	ANI	SectorMask			; only want the least bits
	MOV	L,A				; to calculate offset into 512 byte buffer
	MVI	H,00H				; Multiply by 128
	DAD	H				; *2
	DAD	H				; *4
	DAD	H				; *8
	DAD	H				; *16
	DAD	H				; *32
	DAD	H				; *64
	DAD	H				; *128
	LXI	D,DiskBuffer
	DAD	D				; HL -> 128-byte sector number start address
	XCHG					; DE -> sector in the disk buffer
	LHLD	DMAAddress			; Get DMA address (set in SETDMA)
	XCHG					; assume a read so :
						; DE -> DMA Address & HL -> sector in disk buffer
	MVI	C,128/8				; 8 bytes per move (loop count)
;
;  At this point -
;	C	->	loop count
;	DE	->	DMA address
;	HL	->	sector in disk buffer
;
	LDA	ReadFlag				; Move into or out of buffer /
	ORA	A				; 0 => Write, non Zero => Read
	JNZ	BufferMove			; Move out of buffer
	
	INR	A				; going to force a write
	STA	MustWriteBuffer
	XCHG					; DE <--> HL
	
;The following move loop moves eight bytes at a time from (HL> to (DE), C contains the loop count
BufferMove:
	MOV	A,M				; Get byte from source
	STAX	D				; Put into destination
	INX	D				; update pointers
	INX	H
	
	MOV	A,M
	STAX	D
	INX	D
	INX	H
	
	MOV	A,M
	STAX	D
	INX	D
	INX	H
	
	MOV	A,M
	STAX	D
	INX	D
	INX	H
	
	MOV	A,M
	STAX	D
	INX	D
	INX	H
	
	MOV	A,M
	STAX	D
	INX	D
	INX	H
	
	MOV	A,M
	STAX	D
	INX	D
	INX	H
	
	MOV	A,M
	STAX	D
	INX	D
	INX	H
	
	DCR	C				; count down on loop counter
	JNZ	BufferMove			; repeat till done (CP/M sector moved)
; end of loop
	
	LDA	WriteType				; write to directory ?
	CPI	WriteDirectory
	LDA	DiskErrorFlag			; get flag in case of a delayed read or write
	RNZ					; return if delayed read or write
	
	ORA	A				; Any disk errors ?
	RNZ					; yes - abandon attempt to write to directory
	
	XRA	A
	STA	MustWriteBuffer			; clear flag
	CALL	WritePhysical                           
	LDA	DiskErrorFlag			; return error flag to caller
	RET
;********************************************************************
; Compares just the disk and track   pointed to by DE and HL (used for Blocking/Deblocking)
CompareDkTrk:	
	MVI	C,03H				; Disk(1), Track(2)
	JMP	CompareDkTrkSecLoop
CompareDkTrkSec:					;Compares just the disk and track   pointed to by DE and HL 
	MVI	C,04H				; Disk(1), Track(2), Sector(1)
CompareDkTrkSecLoop:
	LDAX	D
	CMP	M
	RNZ					; Not equal
	INX	D
	INX	H
	DCR	C
	RZ					; return they match (zero flag set)
	JMP	CompareDkTrkSecLoop			; keep going

;********************************************************************
;Moves the disk, track, and sector variables pointed at by HL to those pointed at by DE 
MoveDkTrkSec:
	MVI	C,04H				; Disk(1), Track(2), Sector(1)
MoveDkTrkSecLoop:
	MOV	A,M
	STAX	D
	INX	D
	INX	H
	DCR	C
	RZ					; exit loop done
	JMP	MoveDkTrkSecLoop
;********************************************************************

;********************************************************************
;Write contents of disk buffer to correct sector
WritePhysical:
	MVI	A,DiskWriteCode			; get write function
	JMP	CommonPhysical                
ReadPhysical:                                     
	MVI	A,DiskReadCode			; get read function
CommonPhysical:                                   
	STA	DCTCommand			; set the command
	LDA	InBufferDisk
	ANI	03H				;; only units 0 to 3
	STA	DCTUnit				; set disk
	LHLD	InBufferTrack
	MOV	A,L				; for this controller it is a byte value
	STA	DCTTrack				; set track
;  The sector must be converted into a head number and sector number.
; This set of disks and Diskettes only have two Heads ******
	MVI	B,0				; assume head 0
	LXI	HL,SelectedDskSecsPerHead		; Point at track counts
	LDA	InBufferSector			; get target sector
Head0:
	CMP	M				; Need another Head?
	JC	Head1				; nope Acc < M
	JZ	Head1				; nope Acc = M
	SUB	M				; subtrack track value
	INR	B				; Increment head
	JMP	Head0				; loop til done
	
Head1:
	INR	A				; physical sectors start at 1
	STA	DCTSector
	; set sector
	MOV	A,B
	STA	DCTHead				; set head number

	LXI	H,PhysicalSectorSize
	SHLD	DCTByteCount			; set byte count
	LXI	H,DiskBuffer
	SHLD	DCTDMAAddress			; set transfer address
;	As only one control table is in use, close the status and busy chain pointers
;  back to the main control bytes
	LXI	H,DiskStatusBlock
	SHLD	DCTNextStatusBlock
	LXI	H,DiskControlByte
	SHLD	DCTNextControlLocation
	LXI	H,DCTCommand
	SHLD	DiskCommandBlock
	
	LXI	H,DiskControlByte			; activate 5 1/4" disk controller
	MVI	M,080H

;Wait until Disk Status Block indicates , operation complete, then check 
; if any errors occurred. ,On entry HL -> disk control byte	
WaitForDiskComplete:
	MOV	A,M				; get control bytes
	ORA	A
	JNZ	WaitForDiskComplete			; operation not done
	                                        
	LDA	DiskStatusBlock			; done , so now check status
	CPI	080H                          
	JC	DiskError                     
	XRA	A                             
	STA	DiskErrorFlag			; clear the flag
	RET
	
DiskError:
	MVI	A,1
	STA	DiskErrorFlag			; set the error flag
	RET
	
;**********************************************************************************
;********************************************************************
;********************************************************************
	
;---------------------------------------------------------------------------
;	Disk Data
;---------------------------------------------------------------------------
;	Disk Equates
;---------------------------------------------------------------------------
; Disk Types
;;Floppy5DD	EQU	1 				; 5 1/4" mini floppy
;;Floppy8	EQU	2 				; 8"  floppy (SS SD)
;;HardDisk	EQU	2				; hard disk
NumberOfLogicalDisks	EQU 4			; max number of disk in this system
                                                  
;;NeedDeblocking	EQU 	080H			; Sector size > 128 bytes

;**************************************************************************************************
;  There are two "smart" disk controllers on this system, one for the 8" floppy diskette drives,
; and one for the 5 1/4" mini-diskette drives
;
;  The controllers are "hard-wired" to monitor certain locations in memory to detect when they are to
; perform some disk operation. The 8" controller monitors location 0040H, and the 5 1/4 controller
; monitors location 0045H. These are called their disk control bytes.
; If the most significant bit of  disk control byte is set, the controller will look at the word
; following the respective control bytes. This word must contain the address of  valid disk control
; table that specifies the exact disk operation to be performed.
;
;  Once the operation has been completed. the controller resets its disk control byte to OOH.
; This indicates completion to the disk driver code.
;
;  The controller also sets a return code in a disk status block -both controllers use the SAME location
; for this, 0043H. If the first byte of this status block is less than 80H. then a disk error
; has occurred. For this simple BIOS. no further details of the status settings are relevant.
; Note that the disk controller has built-in retry logic -- reads and writes are attempted
; ten times before the controller returns an error
;
;  The disk control table layout is shown below. Note that the controllers have the capability
; for control tables to be chained together so that a sequence of disk operations can be initiated.
; In this BIOS this feature is not used. However. the controller requires that the chain pointers
; in the disk control tables be pointed back to the main control bytes in order to indicate
; the end of the chain
;**************************************************************************************************

;;DiskControl8	EQU	040H			; 8" control byte
;;CommandBlock8	EQU	041H			; Control Table Pointer
                                                  
DiskStatusBlock	EQU	043H			; 8" and 5 1/4" status block
                                                  
DiskControlByte	EQU	045H			; 8" control byte
DiskCommandBlock	EQU	046H			; Control Table Pointer
                                                  
DiskReadCode	EQU	01H			; Code for Read
DiskWriteCode	EQU	02H			; Code for Write
;***************************************************************************
;	Disk Control tables
;***************************************************************************
DiskControlTable:
DCTCommand:		DB	00H		; Command
DCTUnit:			DB	00H		; unit (drive) number = 0 or 1
DCTHead:			DB	00H		; head number = 0 or 1
DCTTrack:			DB	00H		; track number
DCTSector:		DB	00H		; sector number
DCTByteCount:		DW	0000H		; number of bytes to read/write
DCTDMAAddress:		DW	0000H		; transfer address
DCTNextStatusBlock:		DW	0000H		; pointer to next status block
DCTNextControlLocation:	DW	0000H		; pointer to next control byte

;*******************************************************************************
;	 More tables
; Data written to or read from the mini-floppy drive is transferred via a
; physical buffer that is actually 512 bytes long (it was declared at the front
; of the BIOS and holds the "one-time" initialization code used for the
; cold boot procedure.)
;
; The blocking/de-blocking code attempts to minimize the amount of actual
; disk I/O by storing the disk,track, and physical sector currently residing
; in the Physical Buffer. If a read request is for a 128 byte CP/M "sector"
; that is already in the physical buffer, then no disk access occurs
;*******************************************************************************
AllocationBlockSize	EQU	0800H			; 2048
PhysicalSecPerTrack	EQU	012H			; 18
CPMSecPerPhysical	EQU	PhysicalSectorSize/128
CPMSecPerTrack	EQU	CPMSecPerPhysical * PhysicalSecPerTrack
SectorMask	EQU	CPMSecPerPhysical - 1
SectorBitShift	EQU	02H			; LOG2(CPMSecPerPhysical)
;***************************************************************************

; the following has been moved to osHeader.asm
;*******************************************************************************
; These are the values handed over by the BDOS when it calls the Writer operation
; The allocated.unallocated indicates whether the BDOS is set to write to an
; unallocated allocation block (it only indicates this for the first 128 byte
; sector write) or to an allocation block that has already been allocated to a
; file. The BDOS also indicates if it is set to write to the file directory
;*******************************************************************************
;WriteAllocated	EQU	00H
;WriteDirectory	EQU	01H
;WriteUnallocated	EQU	02H
;------------------------------

WriteType:	DB	00H			; The type of write indicated by BDOS

						; variables for physical sector
						; These are moved and compared as a group, DO NOT ALTER
InBufferDkTrkSec:
InBufferDisk:	DB	00H
InBufferTrack:	DW	00H
InBufferSector:	DB	00H

DataInDiskBuffer:	DB	00H			; when non-zero, the disk buffer has data from disk
                                                  
MustWriteBuffer:	DB	00H			; Non-zero when data has been written into DiskBuffer,
						; but not yet written out to the disk
;---------------------------------------------------------------------------
;	Disk Storage area
;---------------------------------------------------------------------------
;     variables for selected disk, track and sector
; These are moved and compared as a group, DO NOT ALTER
SelectedDskSecsPerHead:	DB	00H		; Sectors / head 

SelectedDkTrkSec:
SelectedDisk:		DB	00H
SelectedTrack:		DW	00H
SelectedSector:		DB	00H

DMAAddress:		DW	00H			; DMA address

						;Selected physical sector derived from selected (CP/M) sector by shifting it
						; right the number of of bits specified by SectorBitShift
SelectedPhysicalSector:	DB	00H

						; Parameters for writing to a previously unallocated allocation block
						; These are moved and compared as a group, DO NOT ALTER
UnallocatedDkTrkSec:
UnallocatedDisk:		DB	00H
UnallocatedTrack:		DW	00H
UnallocatedSector:		DB	00H
UnalocatedlRecordCount:	DB	00H		; Number of unallocated "records"in current previously unallocated allocation block.
                                                  
DiskErrorFlag:		DB	00H		; Non-Zero - unrecoverable error output "Bad Sector" message
                                                  
						; Flags used inside the de-blocking code
PrereadSectorFlag:		DB	00H		; non-zero if physical sector must be read into the disk buffer
						; either before a write to a allocated block can occur, or
						; for a normal CP/M 128 byte sector read
ReadFlag:			DB	00H		; Non-zero when a CP/M 128 byte sector is to be read
;DiskType:			DB	00H		; Indicate 8" or 5 1/4" selected  (set in SELDSK)
;;DeblockingRequired:	DB	00H			; Non-zero when the selected disk needs de-blocking (set in SELDSK)

;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
;	Disk Definition Tables
; These consists of disk parameter headers, with one entry
; per logical disk driver, and disk parameter blocks, with
; either one parameter block per logical disk or the same
; parameter block for several logical disks.
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
DiskParameterHeaders:				; described in chapter 3

; Logical Disk A: (3.25" ED 2.88MB Diskette)
	DW	0000H				; Floppy5SkewTable  - No Skew table
	DW	0000H				; Rel pos for file (0-3)
	DW	0000H				; Last Selected Track #
	DW	0000H				; Last Selected Sector #
	DW	DirectoryBuffer
	DW	ParameterBlock3ED
	DW	DiskAWorkArea
	DW	DiskAAllocationVector
	
; Logical Disk B: (3.25" ED 2.88MB Diskette)
	DW	0000H				; No Skew table
	DW	0000H				; Rel pos for file (0-3)
	DW	0000H				; Last Selected Track #
	DW	0000H				; Last Selected Sector #
	DW	DirectoryBuffer			; all disks use this buffer
	DW	ParameterBlock3ED
	DW	DiskBWorkArea
	DW	DiskBAllocationVector
	
; Logical Disk C: (5.5" DD 360 KB Floppy)
	DW	0000H				; No Skew table
	DW	0000H				; Rel pos for file (0-3)
	DW	0000H				; Last Selected Track #
	DW	0000H				; Last Selected Sector #
	DW	DirectoryBuffer			; all disks use this buffer
	DW	ParameterBlock5DD
	DW	DiskCWorkArea
	DW	DiskCAllocationVector
	
; Logical Disk D: (5.5" DD 360 KB Floppy)
	DW	0000H				; No Skew table
	DW	0000H				; Rel pos for file (0-3)
	DW	0000H				; Last Selected Track #
	DW	0000H				; Last Selected Sector #
	DW	DirectoryBuffer			; all disks use this buffer
	DW	ParameterBlock5DD			; Disk Parameter Block
	DW	DiskDWorkArea
	DW	DiskDAllocationVector
	
 ;;	DB	Floppy5DD
;;	DB	Floppy5DD + NeedDeblocking
;; Disk block parameters for F5DD - 5.25 DD   360 KB Floppy
dpb5ddSPT	EQU	0048H				; 128-byte sectors per track- (72)
dpb5ddBSH	EQU	04H				; Block shift ( 4=> 2K)
dpb5ddBLM	EQU	0FH				; Block mask
dpb5ddEXM	EQU	01H				; Extent mask 
dpb5ddDSM	EQU	00AEH 				; Maximum allocation block number (174)
dpb5ddDRM	EQU	007FH 				; Number of directory entries - 1 (127)
dpb5ddAL0	EQU	0C0H				; Bit map for reserving 1 alloc. block
dpb5ddAL1	EQU	00H				;  for file directory
dpb5ddCKS	EQU	0020H				; Disk change work area size (32)
dpb5ddOFF	EQU	0001H				; Number of tracks before directory

dpb5ddNOH	EQU	02H				;Number of heads
;-----------------------------------------------------------	
;; Disk block parameters for F3HD - 3.5 HD   1.44 MB Diskette
dpb3hdSPT	EQU	0090H				; 128-byte sectors per track- (144)
dpb3hdBSH	EQU	04H				; Block shift ( 4=> 2K)
dpb3hdBLM	EQU	0FH				; Block mask
dpb3hdEXM	EQU	00H				; Extent mask 
dpb3hdDSM	EQU	02C6H 				; Maximum allocation block number (710)
dpb3hdDRM	EQU	007FH 				; Number of directory entries - 1 (127)
dpb3hdAL0	EQU	0C0H				; Bit map for reserving 1 alloc. block
dpb3hdAL1	EQU	00H				;  for file directory
dpb3hdCKS	EQU	0020H				; Disk change work area size (32)
dpb3hdOFF	EQU	0001H				; Number of tracks before directory

dpb3hdNOH	EQU	02H				;Number of heads
;-----------------------------------------------------------	
;;  Disk block parameters for F3ED - 3.5 ED   2.88 MB Diskette
dpb3edSPT	EQU	0120H				; 128-byte sectors per track- (288)
dpb3edBSH	EQU	04H				; Block shift ( 4=> 2K)
dpb3edBLM	EQU	0FH				; Block mask
dpb3edEXM	EQU	00H				; Extent mask 
dpb3edDSM	EQU	058DH 				; Maximum allocation block number (1,421)
dpb3edDRM	EQU	007FH 				; Number of directory entries - 1 (127)
dpb3edAL0	EQU	0C0H				; Bit map for reserving 1 alloc. block
dpb3edAL1	EQU	00H				;  for file directory
dpb3edCKS	EQU	0020H				; Disk change work area size (32)
dpb3edOFF	EQU	0001H				; Number of tracks before directory

dpb3edNOH	EQU	02H				;Number of heads
;-----------------------------------------------------------	
	
ParameterBlock3ED:
	DW	dpb3edSPT				; 128-byte sectors per track- (288)
	DB	dpb3edBSH				; Block shift ( 4=> 2K)
	DB	dpb3edBLM				; Block mask
	DB	dpb3edEXM				; Extent mask 
	DW	dpb3edDSM				; Maximum allocation block number (1,421)
	DW	dpb3edDRM				; Number of directory entries - 1 (127)
	DB	dpb3edAL0				; Bit map for reserving 1 alloc. block
	DB	dpb3edAL1				;  for file directory
	DW	dpb3edCKS				; Disk change work area size (32)
	DW	dpb3edOFF				; Number of tracks before directory
	
	DB	(dpb3edSPT/4)/dpb3edNOH		; number of Sectors/Head	
	
ParameterBlock5DD:
	DW	dpb5ddSPT				; 128-byte sectors per track- (72)
	DB	dpb5ddBSH				; Block shift ( 4=> 2K)
	DB	dpb5ddBLM				; Block mask
	DB	dpb5ddEXM				; Extent mask
	DW	dpb5ddDSM				; Maximum allocation block number (174)
	DW	dpb5ddDRM				; Number of directory entries - 1 (127)
	DB	dpb5ddAL0				; Bit map for reserving 1 alloc. block
	DB	dpb5ddAL1				;  for file directory
	DW	dpb5ddCKS				; Disk change work area size (32)
	DW	dpb5ddOFF				; Number of tracks before directory
	
	DB	(dpb5ddSPT/4)/dpb5ddNOH		; number of Sectors/Head	
	
						; Standard 8" floppy
						; extra byte prefixed to DPB for 
						;  this version of the BIOS


;---------------------------------------------------------------------------
;	Disk work area
;---------------------------------------------------------------------------
; These are used by the BDOS to detect any unexpected
; change of diskette. The BDOS will automatically set
; such a changed diskette to read-only status.
	
DiskAWorkArea:	DS	dpb3edCKS			; A:  020H
DiskBWorkArea:	DS	dpb3edCKS			; B:  020H
DiskCWorkArea:	DS	dpb5ddCKS			; C:  020H
DiskDWorkArea:	DS	dpb5ddCKS			; D:  060H

;---------------------------------------------------------------------------
;	Disk allocation vectors
;---------------------------------------------------------------------------
; Disk allocation vectors
; These are used by the BDOS to maintain a bit map of
; which allocation blocks are used and which are free.
; One byte is used for eight allocation blocks, hence the
; expression of the form (allocation blocks/8)+1

DiskAAllocationVector:	DS	(dpb3edDSM/8)+1 	; A:
DiskBAllocationVector:	DS	(dpb3edDSM/8)+1 	; B:
						
DiskCAllocationVector:	DS	(dpb5ddDSM/8)+1 	; C:
DiskDAllocationVector:	DS	(dpb5ddDSM/8)+1 	; D:
;---------------------------------------------------------------------------
;	Disk Buffer
;---------------------------------------------------------------------------
DirBuffSize	EQU	128
DirectoryBuffer:	DS	DirBuffSize
;---------------------------------------------------------------------------
;**********************************************************************************
;	Disk Control table image for warm boot
;**********************************************************************************
BootControlPart1:
	DB	01H				; Read function
	DB	00H				; unit number
	DB	00H				; head number
	DB	00H				; track number
	DB	02H				; Starting sector number (skip cold boot sector)
	DW	11 * 512				; Number of bytes to read ( rest of the head)
	DW	CCPEntry				; read into this address
	DW	DiskStatusBlock			; pointer to next block - no linking
	DW	DiskControlByte			; pointer to next table- no linking
;ootControlPart2:
;	DB	01H				; Read function
;	DB	00H				; unit number
;	DB	01H				; head number - next head
;	DB	00H				; track number
;	DB	01H				; Starting sector number
;	DW	3 * 512				; Number of bytes to read (Rest of BDOS)
;	DW	CCPEntry + ( 8 * 512)		; Pick up where 1st read left off
;	DW	DiskStatusBlock			; pointer to next block - no linking
;	DW	DiskControlByte			; pointer to next table - no linking
;
;**********************************************************************************	
;	Warm Boot
;  On warm boot. the CCP and BDOS must be reloaded into memory.
; In this BIOS. only the 5 1/4" diskettes will be used.
; Therefore this code is hardware specific to the controller.
; Two prefabricated control tables are used.
;**********************************************************************************	
WBOOT:
	LXI	SP,DefaultDiskBuffer
	LXI	D,BootControlPart1
	CALL	WarmBootRead
	
;	LXI	D,BootControlPart2
;	CALL	WarmBootRead
	JMP	EnterCPM
	
WarmBootRead:
	LXI	H,DiskControlTable			; get pointer to the Floppy's Device Control Table
	SHLD	DiskCommandBlock			; put it into the Command block for drive A:
	MVI	C,13				; set byte count for move
WarmByteMove:
	LDAX	D				; Move the coded Control block into the Command Block
	MOV	M,A
	INX	H
	INX	D
	DCR	C
	JNZ	WarmByteMove
	
	LXI	H,DiskControlByte
	MVI	M,080H				; activate the controller 
	
WaitForBootComplete:
	MOV	A,M				; Get the control byte
	ORA	A				; Reset to 0 (Completed operation) ?
	JNZ	WaitForBootComplete			; if not try again
	
	LDA	DiskStatusBlock			; after operation what's the status?
	CPI	080H				; any errors ?
	JC	WarmBootError			; Yup
	RET					; else we are done!

WarmBootError:
	LXI	H,WarmBootErroMessage		; point at error message
	CALL	DisplayMessage			; sent it. and
	JMP	WBOOT				; try again.
	
WarmBootErroMessage:
	DB	CR,LF
	DB	'Warm Boot -'
	DB	' Retrying.'
	DB	CR,LF
	DB	EndOfMessage
;---------------------------------------------------------------------------
;--------------------BOOT-----------------------------	

						; entered directly from the BIOS JMP vector
						; Control transfered by the CP/M bootstrap loader
						; initial state will be determined by the PROM
	

;---------------End of Cold Boot Initialization Code--------------

	
BOOT:
	JMP	EnterCPM
							; HL points at a Zero-Byte terminated string to be output
	
EnterCPM:
	MVI	A,0C3H				; JMP op code
	STA	0000H				; set up the jump in location 0000H
	STA	0005H				; and at location 0005H
	
	LXI	H,WarmBootEntry			; get BIOS vector address
	SHLD	0001H				; put address in location 1
	
	LXI	H,BDOSEntry			; Get BDOS entry point address
	SHLD	0006H				; put address at location 5
	
	LXI	B,DefaultDiskBuffer			; set disk I/O address to default
	CALL	SETDMA				; use normal BIOS routine
	
	EI
	LDA	DefaultDisk			; Transfer current default disk to
	MOV	C,A				; Console Command Processor
	JMP	CCPEntry				; transfer to CCP
	
DisplayMessage:
	MOV	A,M				; get next message byte
	ORA	A				; terminator (a = 0)?
	RZ					; Yes, thes return to caller
	
	MOV	C,A				; prepare for output
	PUSH	HL				; save message pointer
	CALL	CONOUT				; go to main console output routine *******
	POP	H
	INX	H 				; point at next character
	JMP	DisplayMessage			; loop till done

;-------------------------------------------------

	
CodeEnd: