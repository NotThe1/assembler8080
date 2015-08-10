
					; listing starts on page 175/493 FIgure 6-4
					; in Programmers CPM Handbook by
					; Andy Johnston-Laird

	ORG	0F981H	; Continue from bios.asm
PhysicalSectorSize	EQU	512			; for the 5.25" disk the 8" size is 128,
	
; 					High level diskette drivers
;
;
; These drivers perform the following functions:
;
; SELDSK		Select a specific disk and return the address of
;				the appropriate disk parameter header
; SETTRK		Set the track number for the next read or write
; SETSEC		Set the sector number for the next read or write
; SETDMA		Set the DMA (read/write) address for the next read or write
; SECTRAN	Translate a logical sector number into a physical
; HOME		Set the track to 0 so that the next read or write will
;				be on Track 0
;
; In addition, the high-level drivers are responsible for making
; the 5 1/4"" floppy diskettes that use a 512-byte sector appear
; to CP/M as though they use a 128-byte sector. They do this
; by using what is called blocking/de-blocking code,
; described in more detail later in this listing.
;
;
; 					Disk Parameter Tables
;
; As discussed in Chapter 3, these describe the physical
; characteristics of the disk drives. In this example BIOS,
; there are two types of disk drives: standard single-sided,
; single-density 8", and double-sided, double-density 5 1/4"
; diskettes.
;
; The standard 8" diskettes do not need the blocking/de-blocking
; code, but the 5 1/4" drives do. Therefore an additional
; byte has been prefixed to the disk parameter block to
; tell the disk drivers each logical disk's physical
; diskette type, and whether or not it needs de-blocking.
;
;
; 					Disk Definition Tables
;
; These consists of disk parameter headers, with one entry
; per logical disk driver, and disk parameter blocks, with
; either one parameter block per logical disk or the same
; parameter block for several logical disks.
;
DiskParameterHeaders:		; described in chapter 3

		; Logical Disk A: (5 1/4" Diskette)
	DW	Floppy5SkewTable	; 5 1/4" skew table
	DW	0,0,0F981H			; reserved for CP/M
	DW	DirectoryBuffer
	DW	Floppy5ParameterBlock
	DW	DiskAWorkArea
	DW	DiskAAllocationVector
	
		; Logical Disk B: (5 1/4" Diskette)
	DW	Floppy5SkewTable	; shares the same skew table as A:
	DW	0,0,0F981H			; reserved for CP/M
	DW	DirectoryBuffer		; all disks use this buffer
	DW	Floppy5ParameterBlock
	DW	DiskBWorkArea
	DW	DiskBAllocationVector
	
		; Logical Disk C: (8" Floppy)
	DW	Floppy8SkewTable	; 8" skew table
	DW	0,0,0F981H			; reserved for CP/M
	DW	DirectoryBuffer		; all disks use this buffer
	DW	Floppy8ParameterBlock
	DW	DiskCWorkArea
	DW	DiskCAllocationVector
	
		; Logical Disk D: (8" Floppy)
	DW	Floppy5SkewTable	; shares the same skew table as A:
	DW	0,0,0F981H			; reserved for CP/M
	DW	DirectoryBuffer		; all disks use this buffer
	DW	Floppy8ParameterBlock
	DW	DiskDWorkArea
	DW	DiskDAllocationVector
	
DirectoryBuffer:	DS	128

	; Disk Types
Floppy5		EQU		1 		; 5 1/4" mini floppy
Floppy8 	EQU		2 		; 8"  floppy (SS SD)

	; blocking/de-blocking indicator
NeedDeblocking	EQU 	080H	; Sector size > 128 bytes


	; Disk Parameter Blocks
	
	; 5 1/4" mini floppy
							; extra byte prefixed to indicate 
							; disk type and blocking required
	DB	Floppy5 + NeedDeblocking
	
Floppy5ParameterBlock:
	DW	048H				; 128-byte sectors per track
	DB	49					; Block shift
	DB	15 					; Block mask
	DB	01 					; Extent mask
	DW	174 				; Maximum allocation block number
	DW	127 				; Number of directory entries - 1
	DB	0C0H				; Bit map for reserving 1 alloc. block
	DB	00					;  for file directory
	DW	020H				;Disk change work area size
	DW	01					; Number of tracks before directory
	
	; Standard 8" floppy
							; extra byte prefixed to DPB for 
							;  this version of the BIOS
	DB	Floppy8				; Indicates disk type and the fact
							;   that no de-blocking is required
	
Floppy8ParameterBlock:
	DW	01AH				; sectors per track
	DB	03					; Block shift
	DB	07					; Block mask
	DB	00 					; Extent mask
	DW	242 				; Maximum allocation block number
	DW	63	 				; Number of directory entries - 1
	DB	0C0H				; Bit map for reserving 2 alloc. block
	DB	00					;  for file directory
	DW	010H				;Disk change work area size
	DW	02					; Number of tracks before directory
	
			; Disk work area
	
	; These are used by the BDOS to detect any unexpected
	; change of diskette. The BDOS will automatically set
	; such a changed diskette to read-only status.
	
DiskAWorkArea:	DS	020H		; A:
DiskBWorkArea:	DS	020H		; B:
DiskCWorkArea:	DS	010H		; C:
DiskDWorkArea:	DS	010H		; D:

	
			; Disk allocation vectors
			
		; These are used by the BDOS to maintain a bit map of
		; which allocation blocks are used and which are free.
		; One byte is used for eight allocation blocks, hence the
		; expression of the form (allocation blocks/8)+1

DiskAAllocationVector:	DS		(174/8)+1 	; A:
DiskBAllocationVector:	DS		(174/8)+1 	; B:
	
DiskCAllocationVector:	DS		(242/8)+1 	; C:
DiskDAllocationVector:	DS		(242/8)+1 	; A:
	
NumberOfLogicalDisks:	EQU 4


		;  Disk routines
		
;**********************
;SELDSK - Select disk in C. C=0 for A: 1 for B: etc.
;  Return the address of the appropriate disk parameter header
;  in HL, or 0000H if selected disk does not exist		
;**********************	
SELDSK:
	LXI		H,00H		; Assume an error
	MOV		A,C 		; Check if  requested disk is valid
	CPI		NumberOfLogicalDisks
	RNC					; return if > max number of Disks
	
	STA		SelectedDisk	; save disk number
	MOV		L,A			; make disk into word number
	MVI		H,0
						; Compute offset down disk parameter
						; table by multiplying by parameter
						; header length (16 bytes)
	DAD		H
	DAD		H
	DAD		H
	DAD		H			; pointing at right one
	LXI		D,DiskParameterHeaders		; get base address
	DAD		D			; DE -> appropriate DPH
	PUSH	H			; save DPH address
						; access disk parameter block to
						; extract special prefix byte that
						; identifies disk type and whether
						; de-blocking is required
	LXI		D,10		; Get DPB pointer offset in DPH
	DAD		D			; DE -> DPB address
	MOV		E,M			; Get DPB address in DE
	INX		H
	MOV		D,M	
	XCHG				; DE ->DPB
	DCX		H			; DE -> prefix byte
	MOV		A,M			; get prefix byte
	ANI		0FH			; isolate disk type
	STA		DiskType	; save for use in low level driver
	MOV		A,M			; get another copy
	ANI		NeedDeblocking
	STA		DeblockingRequired	; save for low level driver
	POP		H			; recover DPH pointer
	RET

;**********************	
;SETTRK - Set logical track for next read or write
;		Track is in BC
;**********************	
SETTRK:
	MOV		H,B					; select track in BC on entry
	MOV		L,C
	SHLD	SelectedTrack		; save for low level driver	
	RET
	
;**********************	
;SETSEC - Set logical sector for next read or write
;		Sector is in C
;**********************
SETSEC:
	MOV		A,C
	STA		SelectedSector		; save for low level driver	
	RET
	
;**********************
;SetDMA - Set DMA (input/output) address for next read or write
;       Address in BC
;**********************
DMAAddress:	DW	0		; DMA address
SETDMA:
	MOV		L,C					; select address in BC on entry
	MOV		H,B
	SHLD	DMAAddress		; save for low level driver	
	RET
	
			; Translate logical sector number to physical
			
			; Sector translation tables
			; These tables are indexed using the logical sector number
			; and contain the corresponding physical sector number


;**********************
;	Skew tables
;**********************

Floppy5SkewTable:			; each physical sector contains four
							;  128-byte sectors
							
;	,		Physical 128b 	Logical 128b	Physical 512-byte
	DB		00,01,02,03		;00,01,02,03				0	)
	DB		16,17,18,19		;04,05,06,07				4	)
	DB		32,33,34,35		;08,09,10,11				8	)
	DB		12,13,14,15		;12,13,14,15				3	)Head
	DB		28,29,30,31		;16,17,18,19				7	) 0
	DB		08,09,10,11		;20,21,22,23				2	)
	DB		24,25,26,27		;24,25,26,27				6	)
	DB		04,05,06,07		;28,29,30,31				1	)
	DB		20,21,22,23		;32,33,34,35				5	)
	
	DB		36,37,38,39		;36,37,38,39				0	]
	DB		52,53,54,55		;40,41,42,43				4	]
	DB		68,69,70,71		;44,45,46,47				8	]
	DB		48,49,50,51		;48,49,50,51				3	]Head
	DB		64,65,66,67		;52,53,54,55				7	] 0
	DB		44,45,46,47		;56,57,58,59				2	]
	DB		60,61,62,63		;60,61,62,63				6	]
	DB		40,41,42,43		;63,65,66,67				1	]
	DB		56,57,58,59		;68,69,70,71				5	]
	
Floppy8SkewTable:			; Standard 8" Driver
	;		01,02,03,04,05,06,07,08,09,10		; Logical Sectors
	DB		01,07,13,19,25,05,11,17,23,03		; Physical Sectors
	
	;		11,12,13,14,15,16,17,18,19,20		; Logical Sectors	
	DB		09,15,21,02,08,14,20,26,06,12		; Physical Sectors
	
	;		21,22,23,24,25,26					; Logical Sectors	
	DB		18,24,04,10,16,22					; Physical Sectors
	
;**********************
;SECTRAN - Translate logical sector to physical
;	on Entry:	BC= logical sector number
;				DE-> appropriate skew table
;	on Exit:	HL = physical sector number
;**********************
SECTRAN:
	XCHG			;HL -> skew table base
	DAD		B		; Add on logical sector number
	MOV		L,M		; Get physical sector number
	MVI		H,00H	; make into a word
	RET
	
;**********************
;HOME - Home the selected logical disk to track 0.
;	Before doing this, a check must be made to see if the
;	physical disk buffer has information that must be
;	written out. This is indicated by a flag, MustWriteBuffer,
;	set in the de-blocking code
;**********************	
HOME:
	LDA		MustWriteBuffer		; check flag
	ORA		A
	JNZ		HomeNoWrite
	STA		DataInDiskBuffer	; no, so indicate empty buffer
HomeNoWrite:
	MVI		C,00H				; Set to track 0
	CALL	SETTRK				; no, physical, only logical
	RET

;*******************************************************************************
;					 More tables
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
AllocationBlockSize		EQU		0800H		; 2048
PhysicalSecPerTrack		EQU		012H		; 18
CPMSecPerPhysical		EQU		PhysicalSectorSize/128
CPMSecPerTrack			EQU		CPMSecPerPhysical * PhysicalSecPerTrack
SectorMask				EQU		CPMSecPerPhysical - 1
SectorBitShift			EQU		02H			; LOG2(CPMSecPerPhysical)

;*******************************************************************************
; These are the values handed over by the BDOS when it calls the Writer operation
; The allocated.unallocated indicates whether the BDOS is set to write to an
; unallocated allocation block (it only indicates this for the first 128 byte
; sector write) or to an allocation block that has already been allocated to a
; file. The BDOS also indicates if it is set to write to the file directory
;*******************************************************************************
WriteAllocated			EQU		00H
WriteDirectory			EQU		01H
WriteUnallocated		EQU		02H

WriteType				DB		00H		; The type of write indicated by BDOS

	;       variables for physical sector
	; These are moved and compared as a group, DO NOT ALTER
InBufferDkTrkSec:
InBufferDisk:			DB		00H
InBufferTrack:			DW		00H
InBufferSector:			DB		00H

DataInDiskBuffer:		DB		00H		; when non-zero, the disk buffer has data from disk

MustWriteBuffer:		DB		00H		; Non-zero when data has been written into DiskBuffer,
										;	but not yet written out to the disk
										
	;     variables for selected disk, track and sector
	; These are moved and compared as a group, DO NOT ALTER
SelectedDkTrkSec:
SelectedDisk:			DB		00H
SelectedTrack:			DW		00H
SelectedSector:			DB		00H

	;Selected physical sector derived from selected (CP/M) sector by shifting it
	;	right the number of of bits specified by SectorBitShift
SelectedPhysicalSector:	DB		00H

SelectedDiskType:		DB		00H		; Set by SELDSK to indicate either , 8" or 5 1/4" floppy 
SelectedDiskDeblock:	DB		00H		; Set by SELDSK to indicate whether de-blocking is required

	; Parameters for writing to a previously unallocated allocation block
	; These are moved and compared as a group, DO NOT ALTER
UnallocatedDkTrkSec:
UnallocatedDisk:		DB		00H
UnallocatedTrack:		DW		00H
UnallocatedSector:		DB		00H
UnallocatedRecordCount	DB		00H		; Number of unallocated "records"in current previously unallocated allocation block.

DiskErrorFlag:			DB		00H		; Non-Zero - unrecoverable error output "Bad Sector" message

	; Flags used inside the de-blocking code
MustPrereadSector:		DB		00H		; non-zero if physical sector must be read into the disk buffer
										; either before a write to a allocated block can occur, or
										; for a normal CP/M 128 byte sector read
ReadOperation:			DB		00H		; Non-zero when a CP/M 128 byte sector is to be read
DeblockingRequired:		DB		00H		; Non-zero when the selected disk needs de-blocking (set in SELDSK)
DiskType:				DB		00H		; Indicate 8" or 5 1/4" selected  (set in SELDSK)

; 180/493

;************************************************************************************************
;        READ
; Read in the 128-byte CP/M sector specified by previous calls to select disk and to set track  and 
; sector. The sector will be read into the address specified in the previous call to set DMA address
;
; If reading from a disk drive using sectors larger than 128 bytes, de-blocking code will be used
; to unpack a 128-byte sector from  the physical sector. 
;************************************************************************************************
READ:
		LDA		DeblockingRequired
		ORA		A
		JZ		ReadNoBlock			; if 0 use normal non-blocked read
; The de-blocking algorithm used is such that a read operation can be viewed UP until the actual
; data transfer as though it was the first write to an unallocated allocation block. 
		XRA		A					; set record count to 0
		STA		UnallocatedRecordCount
		INR		A
		STA		ReadOperation			; Indicate that this is a read
		STA		MustPreReadSector		; force pre-read
		MVI		A,WriteUnallocated		; fake de-blocking code into responding as if this
		STA		WriteType				;  is the first write to an unallocated allocation block
		JMP		PerformReadWrite		; use common code to execute read
		
;************************************************************************************************
;		WRITE
;Write a 128-byte sector from the current DMA address to the previously $elected disk, track, and sector.
;
; On arrival here, the BOOS will have set register C to indicate whether this write operation is to
; an already allocated allocation block (which means a pre-read of the sector may be needed),
; to the directory (in which case the data will be written to the disk immediately),
; or to the first 128-byte sector of a previously unallocated allocation block (In which case no pre-read is required).

; Only writes to the directory take place immediately. In all other cases, the data will be moved
; from the DMA address into the disk buffer, and only written out when circumstance, force the transfer.
; The number of physical disk operations can therefore be reduced considerably.
;************************************************************************************************
WRITE:
		LDA		DeblockingRequired
		ORA		A
		JZ		WriteNoBlock			; if 0 use normal non-blocked write

		XRA		A
		STA		ReadOperation			; its a write (Not a read)
		MOV		A,C
		STA		WriteType				; save the BDOS write type
		CPI		WriteUnallocated		; first write to an unallocated allocation block ?
		JNZ		CheckUnallocatedBlock	; No, - in the middle of writing to an unallocated block ?
										; Yes, first write to unallocated allocation block. Initialize
										; variables associated with unallocated writes
		MVI		A,AllocationBlockSize/ 128	; Number of 128 byte sectors
		STA		UnallocatedRecordCount
		LXI		H,SelectedDkTrkSec		; copy disk, track & sector into unallocated variables
		LXI		D,UnallocatedDkTrkSec
		CALL 	MoveDkTrackSec
		
	; Check if this is not the first write to an unallocated allocation block -- if it is,
	; the unallocated record count has just been set to the number of 128-byte sectors in the allocation block
CheckUnallocatedBlock:
		LDA		UnallocatedRecordCount
		ORA		A
		JZ		RequestPreread			; No - write to an unallocated block
		DCR		A						; decrement 128 byte sectors left
		STA		UnallocatedRecordCount
		
		LXI		H,SelectedDkTrkSec		; same Disk, Track & sector as for those in an unallocated block
		LXI		D,UnallocatedDkTrkSec
		CALL	CompareDkTrkSec			; are they the same
		JNZ		RequestPreread			; NO - do a pre-read
										;Compare$DkSTrkSec  returns with  DE -> Unallocated$Sector , HL -> UnallocatedSSector 
		XCHG
		INR	M
		MOV		A,M
		CPI		CPMSecPerTrack			; Sector > maximum on track ?
		JC		NoTrackChange			; No ( A < M)
		MVI		M,00H					; Yes
		LHLD	UnallocatedTrack
		INX		H						; increment track 
		SHLD	UnallocatedTrack
NoTrackChange:
		XRA		A
		STA		MustPrereadSector		; clear flag
		JMP		PerformReadWrite
RequestPreread:
		XRA		A
		STA		UnallocatedRecordCount	; not a write into an unallocated block
		INR		A
		STA		MustPrereadSector		; set flag
;*******************************************************
; Common code to execute both reads and writes of 128-byte sectors	
;*******************************************************	
PerformReadWrite:
		XRA		A				; Assume no disk error will occur
		STA		DiskErrorFlag
		LDA		SelectedSector
		RAR						; Convert selected 128-byte sector
		RAR						; into physical sector by dividing by 4
		ANI		03FH			; remove unwanted bits
		STA		SelectedPhysicalSector
		LXI		H,DataInDiskBuffer	; see if there is any data here ?
		MOV		A,M
		MVI		M,001H				; force there is data
		ORA		A					; any data here ?
		JZ		ReadSectorIntoBuffer	; NO - go read into buffer
;
;The buffer does have a physical sector in it.
; Note: The disk. track. and PHYSICAL sector in the buffer need to be checked,
; hence the use of the CompareDkTrk subroutine
;
		LXI		D,InBufferDkTrkSec
		LXI		H,SelectedDkTrkSec	; is it the same 
		CALL	CompareDkTrk		;    Disk and Track as selected ?
		JNZ		SectorNotInBuffer	; NO, it must be read
; it is in the buffer
		LDA		InBufferSector		; get the sector
		LXI		H,SelectedPhysicalSector
		CMP		M					; Check if correct physical sector
		JZ		SectorInBuffer		; Yes - it is already in memory
		
; No, it will have to be read in over current contents of buffer
SectorNotInBuffer:
		LDA		MustWriteBuffer
		ORA		A					; do we need to write ?
		CNZ		WritePhysical		; Yes - write it out

ReadSectorIntoBuffer:
		CALL	SetInBufferDKTrkSec
		LDA		MustPrereadSector	; do we need to pre-read
		ORA		A
		CNZ		ReadPhysical		; yes - pre-read the sector
		XRA		A					; reset the flag
		STA		MustWriteBuffer
		
; Selected sector on correct track and  disk is already 1n the buffer.
; Convert the selected CP/M(128-byte sector into relative address down the buffer. 
SectorInBuffer:
		LDA		SelectedSector
		ANI		SectorMask			; only want the least bits
		MOV		L,A
		MVI		H,00H				; Multiply by 128
		DAD		H					; *2
		DAD		H					; *4
		DAD		H					; *8
		DAD		H					; *16
		DAD		H					; *32
		DAD		H					; *64
		DAD		H					; *128
		LXI		D,DiskBuffer
		DAD		D					; HL -> 128-byte sector number start address
		XCHG						; DE -> sector in the disk buffer
		LHLD	DMAAddress			; Get DMA address (set in SETDMA)
		XCHG						; assume a read so :
									; DE -> DMA Address & HL -> sector in disk buffer
		MVI		C,128/8				; 8 bytes per move (loop count)
;
;  At this point -
;	C	->	loop count
;	DE	->	DMA address
;	HL	->	sector in disk buffer
;
		LDA		ReadOperation		; Move into or out of buffer /
		ORA		A
		JNZ		BufferMove			; Move out of buffer
		
		INR		A					; going to force a write
		STA		MustWriteBuffer
		XCHG						; DE <--> HL
		
;The following move loop moves eight bytes at a time from (HL> to (DE), C contains the loop count
BufferMove:
		MOV		A,M					; Get byte from source
		STAX	D					; Put into destination
		INX		D					; update pointers
		INX		H
		
		MOV		A,M					; Get byte from source
		STAX	D					; Put into destination
		INX		D					; update pointers
		INX		H
		
		MOV		A,M					; Get byte from source
		STAX	D					; Put into destination
		INX		D					; update pointers
		INX		H
		
		MOV		A,M					; Get byte from source
		STAX	D					; Put into destination
		INX		D					; update pointers
		INX		H
		
		MOV		A,M					; Get byte from source
		STAX	D					; Put into destination
		INX		D					; update pointers
		INX		H
		
		MOV		A,M					; Get byte from source
		STAX	D					; Put into destination
		INX		D					; update pointers
		INX		H
		
		MOV		A,M					; Get byte from source
		STAX	D					; Put into destination
		INX		D					; update pointers
		INX		H
		
		MOV		A,M					; Get byte from source
		STAX	D					; Put into destination
		INX		D					; update pointers
		INX		H
		
		DCR		C					; count down on loop counter
		JNZ		BufferMove			; repeat till done (CP/M sector moved)
; end of loop		
		LDA		WriteType			; write to directory ?
		CPI		WriteDirectory
		LDA		DiskErrorFlag		; get flag in case of a delayed read or write
		RNZ							; return if delayed read or write
		
		ORA		A					; Any disk errors ?
		RNZ							; yes - abandon attempt to write to directory
		
		XRA		A
		STA		MustWriteBuffer		; clear flag
		CALL	WritePhysical
		LDA		DiskErrorFlag		; return error flag to caller
		RET
;********************************************************************

		
; indicates  selected disk, track, and sector now residing in buffer
SetInBufferDKTrkSector:
		LDA		SelectedDisk
		STA		InBufferDisk
		LHLD	SelectedTrack
		SHLD	InBufferTrack
		LDA		SelectedPhysicalSector
		STA		InBufferSector
		Ret
		
CompareDkTrk:					;Compares just the disk and track   pointed to by DE and HL 
		MVI		C,03H			; Disk(1), Track(2)
		JMP		CompareDkTrkSecLoop
CompareDkTrkSec:				;Compares just the disk and track   pointed to by DE and HL 
		MVI		C,04H			; Disk(1), Track(2), Sector(1)
CompareDkTrkSecLoop:
		LDAX	D
		CMP		M
		RNZ						; Not equal
		INX	D
		INX	H
		DCR		C
		RZ						; return they match (zero flag set)
		JMP		CompareDkTrkSecLoop	; keep going

;********************************************************************

;Moves the disk, track, and sector variables pointed at by HL to those pointed at by DE 
MoveDkTrkSec:
		MVI		C,04H			; Disk(1), Track(2), Sector(1)
MoveDkTrkSecLoop:
		MOV		A,M
		STAX	D
		INX		D
		INX		H
		DCR		C
		RZ					; exit loop done
		JMP		MoveDkTrkSecLoop
		
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

DiskControl8	EQU	040H	; 8" control byte
CommandBlock8	EQU	041H	; Control Table Pointer

DiskStatusBlock	EQU	043H	; 8" and 5 1/4" status block

DiskControl5	EQU	045H	; 8" control byte
CommandBlock5	EQU	046H	; Control Table Pointer

;***************************************************************************
;					Floppy Disk Control tables
;***************************************************************************
FloppyCommand:	DB	00H		; Command
FloppyReadCode	EQU	01H
FloppyWriteCode	EQU	02H
FloppyUnit:		DB	00H		; unit (drive) number = 0 or 1
FloppyHead:		DB	00H		; head number = 0 or 1
FloppyTrack:	DB	00H		; track number
FloppySector:	DB	00H		; sector number
FloppyByteCount:	DW	0000H	; number of bytes to read/write
FloppyDMAAddress:	DW	0000H	; transfer address
FloppyNextStatusBlock:	DW	0000H	; pointer to next status block
FloppyNextControlLocation:	DW	0000H	; pointer to next control byte

; Write contents of disk buffer to correct sector
WriteNoDeblock:
	MVI		A,FloppyWriteCode	; get write function code
	JMP		CommonNoDeblock
;Read previously selected sector into disk buffer
ReadNoDeblock:
	MVI		A,FloppyReadCode	; get read function code
CommonNoDeblock:
	STA		FloppyCommand		; set the correct command code
	LXI		H,128				; bytes per sector
	SHLD	FloppyByteCount
	XRA		A					; 8" has only head 0
	STA		FloppyHead
	
	LDA		SelectedDisk		; insure only disk 0 or 1
	ANI		01H
	STA		FloppyUnit			; set the unit number
	
	LDA		SelectedTrack
	STA		FloppyTrack			; set track number
	
	LDA		SelectedSector
	STA		FloppySector		; set sector
	
	LHLD	DMAAddress
	SHLD	FloppyDMAAddress	; set transfer address
	
;  The disk controller can accept chained disk control tables, but in this case
; they are not used. so the "Next" pointers must be pointed back at the initial
; control bytes in the base page. 
	LXI		H,DiskStatusBlock
	SHLD	FloppyNextStatusBlock	; set pointer back to start
	LXI		H,DiskControl8
	SHLD	FloppyNextControlLocation	; set pointer back to start
	LXI		H,FloppyCommand
	SHLD	CommandBlock8
	
	LXI		H,DiskControl8
	MVI		M,080H				; activate the controller to perform operation
	JMP		WaitForDiskComplete
	
;Write contents of disk buffer to correct sector
WritePhysical:
	MVI		A,FloppyWriteCode	; get write function
	JMP		CommonPhysical
ReadPhysical:
	MVI		A,FloppyReadCode	; get read function
CommonPhysical:
	STA		FloppyCommand		; set the command
	
	LDA		DiskType
	CPI		Floppy5				; is it 5 1/4 ?
	JZ		CorrectDisktype		; yes
	MVI		A,1
	STA		DiskError			; no set error and exit
	RET
CorrectDisktype:
	LDA		InBufferDisk
	ANI		01H					; only units 0 or 1
	STA		FloppyUnit			; set disk
	LHLD	InBufferTrack
	MOV		A,L					; for this controller it is a byte value
	STA		FloppyTrack			; set track
;  The sector must be converted into a head number and sector number.
; Sectors 0 - 8 are head 0, 9 - 17 , are head 1 
	MVI		B,0					; assume head 0
	LDA		InBufferSector
	MOV		C,A					; save copy
	CPI		09H
	JC		Head0
	SUI		09H					; Modulo sector
	MOV		C,A
	INR		B					; set head to 1
Head0:
	MOV		A,B
	STA		FloppyHead			; set head number
	MOV		A,C
	INR		A					; physical sectors start at 1
	STA		FloppySector		; set sector
	LXI		H,PhysicalSectorSize
	SHLD	FloppyByteCount		; set byte count
	LXI		H,DiskBuffer
	SHLD	FloppyDMAAddress	; set transfer address
;	As only one control table is in use, close the status and busy chain pointers
;  back to the main control bytes
	LXI		H,DiskStatusBlock
	SHLD	FloppyNextStatusBlock
	LXI		H,DiskControl5
	SHLD	FloppyNextControlLocation
	LXI		H,FloppyCommand
	SHLD	CommandBlock5
	
	LXI		H,DiskControl5		; activate 5 1/4" disk controller
	MVI		M,080H

;Wait until Disk Status Block indicates , operation complete, then check 
; if any errors occurred. ,On entry HL -> disk control byte	
WaitForDiskComplete:
	MOV		A,M				; get control bytes
	ORA		A
	JNZ		WaitForDiskComplete	; operation not done
	
	LDA		DiskStatusBlock		; done , so now check status
	CPI		080H
	JC		DiskError
	XRA		A
	STA		DiskErrorFlag		; clear the flag
	RET
	
DiskError:
	MVI		A,1
	STA		DiskErrorFlag		; set the error flag
	RET
	
;**********************************************************************************
;		Disk Control table image for warm boot
;**********************************************************************************
BootControlPart1:
	DB	01H				; Read function
	DB	00H				; unit number
	DB	00H				; head number
	DB	00H				; track number
	DB	02H				; Starting sector number
	DW	8 * 512			; Number of bytes to read
	DW	CCPEntry		; read into this address
	DW	DiskStatusBlock	; pointer to next block
	DW	DiskControl5	; pointer to next table
BootControlPart2:
	DB	01H				; Read function
	DB	00H				; unit number
	DB	01H				; head number
	DB	00H				; track number
	DB	01H				; Starting sector number
	DW	3 * 512			; Number of bytes to read
	DW	CCPEntry + ( 8 * 512)		; read into this address
	DW	DiskStatusBlock	; pointer to next block
	DW	DiskControl5	; pointer to next table

;**********************************************************************************	
;						Warm Boot
;  On warm boot. the CCP and BDOS must be reloaded into memory.
; In this BIOS. only the 5 1/4" diskettes will be used.
; Therefore this code is hardware specific to the controller.
; Two prefabricated control tables are used.
;**********************************************************************************	
WBOOT:
	LXI		SP,080H
	LXI		D,BootControlPart1
	CALL	WarmBootRead
	
	LXi		D,BootControlPart2
	CALL	WarmBootRead
	JMP		EnterCPM
	
WarmBootRead:
	LXI		H,FloppyCommand
	SHLD	CommandBlock5
	MVI		C,13				; set byte count
WarmByteMove:
	LDAX	D
	MOV		M,A
	INX		H
	INX		D
	DCR		C
	JNZ		WarmByteMove
	
	LXI		H,DiskControl5
	MVI		M,080H			; activate the controller
	
WaitForBootComplete:
	MOV		A,M
	ORA		A
	JNZ		WaitForBootComplete
	
	LDA		DiskStatusBlock
	CPI		080H		; any errors ?
	JC		WarmBootError	; Yup
	RET

WarmBootError:
	LXI		H,WarmBootErroMessage
	CALL	DisplayMessage
	JMP		WBOOT
	
WarmBootErroMessage:
	DB		0DH,0AH
	DB		057H,061H,072H,06DH,020H				; Warm
	DB		042H,06FH,06FH,074H,020H				; Boot
	DB		072H,065H,074H,072,079H,069H,06EH,067H	;retrying
	DB		02EH,02EH,02EH,0DH,0AH
	DB		00H
End:

CCPEntry:	
DISKBUFFER:
DisplayMessage:
EnterCPM:
MOVEDKTRACKSEC:
ReadNoBlocK:
;READPHYSICAL:
SETINBUFFERDKTRKSEC:
UNALLOCATEDRECORDCOUNT:
UNALLOCATEDRECORDCOUNT:
;WRITEPHYSICAL:
WRITENOBLOCK:
WRITETYPE:

	

