; newBDOS.asm
; part of newOS
; 2014-03-14  :  Frank Martyn
; TODO ------
		$Include ../Headers/osHeader.asm
		$Include ../Headers/stdHeader.asm
STACK_SIZE	EQU		20H			; make stak big enough
EOD			EQU		-1			; enddir End of Directory
;WORD		EQU		02			; number of bytes for a word
;BYTE		EQU		01			; number of bytes for a byte

;	bios access constants
bcBoot		EQU	BIOSEntry+3*0	; bootf		cold boot function
bcWboot		EQU	BIOSEntry+3*1	; wbootf	warm boot function
bcConst		EQU	BIOSEntry+3*2	; constf	console status function
bcConin		EQU	BIOSEntry+3*3	; coninf	console input function
bcConout	EQU	BIOSEntry+3*4	; conoutf	console output function
bcList		EQU	BIOSEntry+3*5	; listf		list output function
bcPunch		EQU	BIOSEntry+3*6	; punchf	punch output function
bcReader	EQU	BIOSEntry+3*7	; readerf	reader input function
bcHome		EQU	BIOSEntry+3*8	; homef		disk home function
bcSeldsk	EQU	BIOSEntry+3*9	; seldskf	select disk function
bcSettrk	EQU	BIOSEntry+3*10	; settrkf	set track function
bcSetsec	EQU	BIOSEntry+3*11	; setsecf	set sector function
bcSetdma	EQU	BIOSEntry+3*12	; setdmaf	set dma function
bcRead		EQU	BIOSEntry+3*13	; readf		read disk function
bcWrite		EQU	BIOSEntry+3*14	; writef	write disk function
bcListst	EQU	BIOSEntry+3*15	; liststf	list status function
bcSectran	EQU	BIOSEntry+3*16	; sectran	sector translate
		
CodeStart:
	ORG		BDOSBase
	DB		0,0,0,0,0,0
; Enter here from the user's program with function number in c,
;	and information address in d,e
;BDOSEntry:
	JMP	BdosStart	;past parameter block
	
BdosStart:
	XCHG					; swap DE and HL
	SHLD	paramDE			; save the original value of DE
	XCHG					; restore DE
	MOV		A,E				; Byte argument
	STA		paramE
	LXI		HL,0000H
	SHLD	statusBDOSReturn	; assume alls well for return
	; Save users Stack pointer
	DAD		SP
	SHLD	usersStack
	LXI		SP,bdosStack	; use our own stack area
	; initialize variables
	XRA		A
	STA		fcbDisk			; initalize to 00
	STA		fResel			; clear reselection flag
	LXI		HL,RetCaller	; exit to caller vector
	PUSH	HL				; makes a JMP to RetCaller = RET
	
	MOV		A,C				; get the Function Number
	CPI		functionCount	; make sure its a good number
	RNC						; exit if not a valid function
	
	MOV		C,E				; might be a single byte argument
	LXI		HL,functionTable	; get table base
	MOV		E,A				; function number in E
	MVI		D,0				; setting up DE = function number
	DAD		DE
	DAD		DE				; Vector is (2 * Function number) + table base
	MOV		E,M				; get LSB of vector
	INX		HL
	MOV		D,M				; get MSB of vector
	XCHG					; Vector now in HL
	PCHL					; move vector to Program Counter ie JMP (HL)
;*****************************************************************
;arrive here at end of processing to return to user
RetCaller:			; goback
	LDA		fResel			; get reselction flag
	ORA		A				; is it set?
	JZ		RetDiskMon
	;reselection may have taken place
	LHLD	paramDE
	MVI		M,0
	LDA		fcbDisk
	ORA		A				; Disk = 0?
	JZ		RetDiskMon		; exit if yes
	
	MOV		M,A
	LDA		entryDisk		; get back original Disk
	STA		paramE			; and select it
	CALL	SelectCurrent	

;	return from the disk monitor
RetDiskMon:			; retmon
	LHLD	 usersStack
	SPHL					; Restore callers stack
	LHLD	statusBDOSReturn
	MOV		A,L
	MOV		B,H				; BA = statusBDOSReturn
	RET	
;*****************************************************************
;------------------- Function Table -------------------------------
functionTable:
	DW		DUMMY			; Function  0 - System Reset
	DW		fConsoleIn		; Function  1 - Console Input
	DW		fConsoleOut		; Function  2 - Console Output
	DW		DUMMY			; Function  3 - Reader Input
	DW		DUMMY			; Function  4 - Punch Output
	DW		DUMMY			; Function  5 - List Output
	DW		fDirectConIO	; Function  6 - Direct Console I/O
	DW		fGetIOBYTE		; Function  7 - Get I/O Byte
	DW		fSetIOBYTE		; Function  8 - Set I/O Byte
	DW		fPrintString	; Function  9 - Print String
	DW		fReadString		; Function  A - Read Console String
	DW		DUMMY			; Function  B - Get Console Status
diskf		EQU		($-functionTable)/2 		; disk functions
	DW		DUMMY			; Function  C - Return Version Number
	DW		DUMMY			; Function  D - Reset Disk System
	DW		DUMMY			; Function  E - Select Disk
	DW		DUMMY			; Function  F - Open File
	DW		DUMMY			; Function 10 - Close File
	DW		DUMMY			; Function 11 - Search For First
	DW		DUMMY			; Function 12 - Search for Next
	DW		DUMMY			; Function 13 - Delete File
	DW		DUMMY			; Function 14 - Read Sequential
	DW		DUMMY			; Function 15 - Write Sequential
	DW		DUMMY			; Function 16 - Make File
	DW		DUMMY			; Function 17 - Rename File
	DW		DUMMY			; Function 18 - Return Login Vector
	DW		DUMMY			; Function 19 - Return Current Disk
	DW		DUMMY			; Function 1A - Set DMA address
	DW		DUMMY			; Function 1B - Get ADDR (ALLOC)
	DW		DUMMY			; Function 1C - Write Protect Disk
	DW		DUMMY			; Function 1D - Get Read/Only Vector
	DW		DUMMY			; Function 1E - Set File Attributes
	DW		DUMMY			; Function 1F - Get ADDR (Disk Parameters)
	DW		DUMMY			; Function 20 - Set/Get User Code
	DW		DUMMY			; Function 21 - Read Random
	DW		DUMMY			; Function 22 - Write Random
	DW		DUMMY			; Function 23 - Compute File Size
	DW		DUMMY			; Function 24 - Set Random Record
	DW		DUMMY			; Function 25 - Reset Drive
	DW		DUMMY			; Function 26 - Access Drive (not supported)
	DW		DUMMY			; Function 27 - Free Drive (not supported)
	DW		DUMMY			; Function 28 - Write random w/Fill
functionCount	EQU	($-functionTable)/2 		; Number of  functions

DUMMY:
	HLT
;*****************************************************************
;return console character with echo
fConsoleIn:					; func1 (01 - 01) Console In
	CALL	ConsoleInWithEcho
	JMP		StoreARet
;----------
; write console character with TAB expansion
fConsoleOut:				; func2 (02 - 02) Console Out
	CALL	TabOut
	RET						; jmp goback
;----------
;direct console i/o - read if 0ffh
fDirectConIO:				; func6 (06 - 06) get Direct Console Out
	MOV		A,C
	INR		A
	JZ		fDirectConIn	; 0ffh => 00h, means input mode
							; direct output function
	CALL	bcConout
	RET						; jmp goback
fDirectConIn:
	CALL	bcConst			; status check
	ORA		A
	JZ		RetDiskMon		; skip, return 00 if not ready
							; character is ready, get it
	CALL	bcConin			; to A
	JMP		StoreARet
;----------
;return io byte	
fGetIOBYTE:				; func7 (07 - 07) get IOBYTE
	LDA		IOBYTE		; get the byte
	JMP		StoreARet	; store A and return
;----------
;set i/o byte
fSetIOBYTE:				; func8 (08 - 08)	set IOBYTE
	LXI		HL,IOBYTE
	MOV		M,C			; put passed value into IOBYTE
	RET					; exit
;----------
;write line until $ encountered
fPrintString:			; func9 (09 - 09)	 Print Dollar terminated String
	LHLD	paramDE
	MOV		C,L
	MOV		B,H					; BC=string address
	CALL	Print				; out to console
	RET							; jmp goback
;----------
;read Console until $ encountered
fReadString:			; func10 (10 - 0A)	read Dollar terminated String from console
	CALL	read
	RET 						; jmp goback

;----------
;----------
; store A and return
StoreARet:				; sta$ret
	STA		statusBDOSReturn
	RET					; jmp , go back
	
;*****************************************************************
;----------------
;read to paramDE address (max length, current length, buffer)
ReadString:						; read
	LDA		columnPosition
	STA		startingColumn ;save start for ctl-x, ctl-h
	LHDL	paramDE
	MOV		C,M
	INX		H
	PUSH	HL
	MVI		B,0
						; B = current buffer length,
						; C = maximum buffer length,
						; HL= next to fill - 1
ReadNext:						; readnx:
						; read next character, BC, HL active
	PUSH	BC
	PUSH	HL			; blen, cmax, HL saved
ReadNext0:
	CALL	ConIn		; next char in A
	ANI		ASCII_MASK	; mask parity bit
	POP		HL
	POP		BC			; reactivate counters
	CPI		CR
	JZ		EndRead		; end of line?
	CPI		LF
	JZ		EndRead		; also end of line
	CPI		CTRL_H
	JNZ		NotCtntl_H	; backspace?
						; do we have any characters to back over?
	MOV		A,B
	ORA		A
	JZ		paramDE
						; characters remain in buffer, backup one
	DCR		B			; remove one character
	LDA		columnPosition
	STA		compcol		; col > 0
						; compcol > 0 marks repeat as length compute
	JMP		LineLengthOrRepeat ; uses same code as repeat
NotCtntl_H:
						; not a backspace
	CPI		RUBOUT
	JNZ		NotRubout	; RUBOUT char?
						; RUBOUT encountered, RUBOUT if possible
	MOV		A,B
	ORA		A
	JZ		ReadNext	; skip if len=0
						; buffer has characters, resend last char
	MOV		A,M
	DCR		B
	DCX		HL			; A = LAST CHAR
						; BLEN=BLEN-1, NEXT TO FILL - 1 DECREMENTED
	JMP ReadEcho1		; act like this is an echo
;
NotRubout:
						; not a RUBOUT character, check end line
	CPI		CTRL_E
	JNZ		NotCtntl_E	; physical end line?
						; yes, save active counters and force eol
	PUSH	BC
	PUSH	HL
	CALL	showCRLF
	XRA		A
	STA		startingColumn ; start position = 00
	JMP		ReadNext0		; for another character
NotCtntl_E:				; note
						; not end of line, list toggle?
	CPI		CTRL_P
	JNZ		NotCtntl_P	; skip if not CTRL_P
						; list toggle - change parity
	PUSH	HL			; save next to fill - 1
	LXI		HL,listeningToggle	; HL=.listeningToggle flag
	MVI		A,1
	SUB		M				; True-listeningToggle
	MOV		M,A			; listeningToggle = not listeningToggle
	POP		HL
	JMP		ReadNext	;for another char
NotCtntl_P:				; notp:
						; not a CTRL_P, line delete?
	CPI		CTRL_X
	JNZ		NotCtntl_X
	POP		HL			; discard start position
						; loop while columnPosition > startingColumn
GoBack:					; backx:
	LDA		startingColumn
	LXI		HL,columnPosition
	CMP		M
	JNC		ReadString	; start again
	DCR		M			; columnPosition = columnPosition - 1
	CALL	BackUp		; one position
	JMP		GoBack
NotCtntl_X:					; notx:
						; not a control x, control u?
						; not control-X, control-U?
	CPI		CTRL_U
	JNZ		NotCtntl_U	; skip if not
			;delete line (CTRL_U)
	call crlfp ;physical eol
	POP	HL ;discard starting position
	jmp ReadString ;to start all over
NotCtntl_U:				; notu:
			;not line delete, repeat line?
	CPI CTRL_R
	JNZ notr
LineLengthOrRepeat:
			;repeat line, or compute line len (CTRL_H)
			;if compcol > 0
	PUSH	BC
	call crlfp ;save line length
	POP	BC
	POP	HL
	PUSH	HL
	PUSH	BC
			;bcur, cmax active, beginning buff at HL
rep0:
	MOV a,b
	ora a
	JZ rep1 ;count len to 00
	inx h
	MOV c,m ;next to print
	dcr b
	PUSH	BC
	PUSH	HL ;count length down
	call ctlout ;character echoed
	POP	HL
	POP	BC ;recall remaining count
	JMP rep0 ;for the next character
rep1:
			;end of repeat, recall lengths
			;original BC still remains pushed
	PUSH	HL ;save next to fill
	LDA compcol
	ora a ;>0 if computing length
	JZ ReadNext0 ;for another char if so
			;columnPosition position computed for CTRL_H
	lxi h,columnPosition
	sub m ;diff > 0
	STA compcol ;count down below
			;move back compcol-columnPosition spaces
backsp:
			;move back one more space
	call BackUp ;one space
	lxi h,compcol
	dcr m
	JNZ backsp
	JMP ReadNext0 ;for next character
notr:
			;not a CTRL_R, place into buffer
ReadEcho:
	inx h
	MOV m,a ;character filled to mem
	inr b ;blen = blen + 1
ReadEcho1:
			;look for a random control character
	PUSH	BC
	PUSH	HL ;active values saved
	MOV c,a ;ready to print
	call ctlout ;may be up-arrow C
	POP	HL
	POP	BC
	MOV a,m ;recall char
	CPI CTRL_C ;set flags for reboot test
	MOV a,b ;move length to A
	JNZ notc ;skip if not a control c
	CPI 1 ;control C, must be length 1
	JZ reboot ;reboot if blen = 1
			;length not one, so skip reboot
notc:
			;not reboot, are we at end of buffer?
	cmp c
	jc paramDE ;go for another if not
EndRead:
			;end of read operation, store blen
	POP	HL
	MOV m,b ;M(current len) = B
	mvi c,CR
	JMP conout ;return carriage
	;ret
;------------------
;back-up one screen position
BackUp:							; backup
 	CALL	PutCntl_H
	MVI		C,SPACE
	CALL	bcConout
;	JMP PutCntl_H
;send CTRL_H to console without affecting column count	
PutCntl_H:						; pctlh
	MVI		C,CTRL_H
	JMP		bcConout
	;ret	
;----------------------------------------------------------------
;


;expand tabs to console	
TabOut:							; tabout
	;expand tabs to console
	MOV		A,C
	CPI		TAB
	JNZ		ConsoleOut			; direct to ConsoleOut if not
								; TAB encountered, move to next TAB position
TabOut0:						; tab0:
	MVI		C,SPACE
	CALL	ConsoleOut			; another blank
	LDA		columnPosition
	ANI		111b				; columnPosition mod 8 = 0 ?
	JNZ		TabOut0				; back for another if not
	RET
;-----------------------------------------------------------------
;***************** Disks ****************************
;-----------------------------------------------------------------
SelectCurrent:				; curselect
	LDA		paramE
	LXI		HL,currentDisk
	CMP		M
	RZ					; exit if parame = Current disk
	
	MOV		M,A
	JMP		Select
;*****************************************************************
Select:
	LHLD	loggedDisks
	LDA		currentDisk
	MOV		C,A
	CALL	ShiftRightHLbyC
	PUSH	HL			; save result
	XCHG				; send to seldsk
	CALL	SelectDisk
	POP		HL			; get back logged disk vector
	CZ		errSelect
	MOV		A,L			; get logged disks
	RAR
	RC					; exit if the disk already logged in
	
	LHLD	loggedDisks	; else log in a differenet disk
	MOV		C,L
	MOV		B,H			; BC has logged disk
	CALL	SetCurrentDiskBit
	SHLD	loggedDisks	; save result
	JMP		InitDisk
	; RET
;*****************************************************************
; select the disk drive given by curdsk, and fill the base addresses
; caTrack - caAllocVector, then fill the values of the disk parameter block
SelectDisk:
	LDA		currentDisk
	MOV		C,A			; prepare for Bios Call
	CALL	bcSeldsk
	MOV		A,H			;HL = 0000 if error, otherwise disk headers
	ORA		L
	RZ					; exit if error, with Zflag set
	MOV		E,M
	INX		H
	MOV		D,M			; Disk Header Block pointer in DE
	INX		HL
	SHLD	caDirMaxValue
	INX		HL
	INX		HL
	SHLD	caTrack
	INX		HL
	INX		HL
	SHLD	caSector
	INX		HL
	INX		HL
	XCHG				; DE points at Directory DMA, HL at Skew Table
	SHLD	caSkewTable
	LXI		HL,caDirectoryDMA
	MVI		C,caListSize
	CALL	Move		; finish filling in address list
	
	LHLD	caDiskParamBlock
	XCHG				; DE is source
	LXI		HL,dpbSPT	; start of Disk Parameter Block
	MVI		C,dpbSize
	CALL	Move		; load the table
	LHLD	dpbDSM		; max entry number
	MOV		A,H			; if 00 then < 255
	LXI		HL,single		; point at the single byte entry flag
	MVI		M,TRUE		; assume its less than 255
	ORA		A			; assumtion confirmed ?
	JZ		SelectDisk1	; skip if yes
	MVI		M,FALSE		; correct assumption, set falg to false
	
SelectDisk1:
	MVI		A,TRUE
	ORA		A			; Set Carry and Sign reset Zero
	RET

;---------------
; set a "1" value in currentDisk position of BC
; return in HL
SetCurrentDiskBit:			; set$cdisk
	PUSH	BC			; save input parameter
	LDA		currentDisk
	MOV		C,A			; ready parameter for shift
	LXI		H,1			; number to shift
	CALL	ShiftLeftHLbyC ;HL = mask to integrate
	POP		BC			; original mask
	MOV		A,C
	ORA		L
	MOV		L,A
	MOV		A,B
	ORA		H
	MOV		H,A			; HL = mask or rol(1,currentDisk)
	RET	
;--------------
;set current disk to read only
SetDiskReadOnly:		; set$ro
	LXI		HL,ReadOnlyVector
	MOV		C,M
	INX		HL
	MOV		B,M
	CALL	SetCurrentDiskBit	; sets bit to 1
	SHLD	ReadOnlyVector
								; high water mark in directory goes to max
	LHLD	dpbDRM				; directory max
	XCHG						; DE = directory max
	LHLD	caDirMaxValue		;HL = .Directory max value
	MOV		M,E
	INX		HL
	MOV		M,D ;cdrmax = dpbDRM
	RET	
;----------------------- initialize the current disk
; 
;lowReturnStatus = false ;set to true if $ file exists
; compute the length of the allocation vector - 2

InitDisk:				; initialize
	LHDL	dpbDSM		; get max allocation value
	MVI		C,3			; wew want maxall/8
						; number of bytes in alloc vector is (maxall/8)+1
	CALL	ShiftRightHLbyC
	INX		HL			; HL = maxall/8+1
	MOV		B,H
	MOV		C,L			; count down BC til zero
	LHDL	caAllocVector ;base of allocation vector
	;fill the allocation vector with zeros
InitDisk0:				; initial0:
	MVI		M,0
	INX		H			; alloc(i)=0
	DCX		BC			; count length down
	MOV		A,B
	ORA		C
	JNZ		InitDisk0
						; set the reserved space for the directory
	LHLD	dpbDABM		; get the directory block
	XCHG
	LHLD	caAllocVector ; HL=.alloc()
	MOV		M,E
	INX		HL
	MOV		M,D			; sets reserved directory blks
						; allocation vector initialized, home disk
	CALL	Home
						; caDirMaxValue = 3 (scans at least one directory record)
	LHLD	caDirMaxValue
	MVI		M,3
	INX		H
	MVI		M,0
						; caDirMaxValue = 0000
	CALL	SetEndDirectory ;dirCounter = EOD
						;	read directory entries and check for allocated storage
InitDisk1:
	MVI		C,TRUE
	CALL	ReadDirectory
	CALL	EndOfDirectory
	RZ							; return if end of directory
								; not end of directory, valid entry?
	CALL	GetDirElementAddress ; HL = caDirectoryDMA + dirPointer
	MVI		A,emptyDir
	CMP		M
	JZ		InitDisk1			; go get another item
								; not empty, user code the same?
	LDA		currentUserNumber
	CMP		M
	JNZ		InitDisk2
								; same user code, check for '$' submit
	INX		H
	MOV		A,M					; first character
	SUI		DOLLAR				; dollar file?
	JNZ		InitDisk2
								; dollar file found, mark in lowReturnStatus
	DCR		A
	STA		lowReturnStatus		; lowReturnStatus = 255
InitDisk2:
								; now scan the disk map for allocated blocks
	MVI		C,1					; set to allocated
	CALL	ScanDiskMap
	CALL	SetDirectoryEntry	; set DirMaxVAlue to dirCounter
	JMP		InitDisk1			; for another entry
;
;-------------Scan the disk map for unallocated entry-----------------------------------
; scan the disk map addressed by dptr for non-zero entries.  The allocation
; vector entry corresponding to a non-zero entry is set to the value of C (0,1)
ScanDiskMap:					; scandm
	CALL	GetDirElementAddress ; HL = buffa + dptr
								 ; HL addresses the beginning of the directory entry
	LXI		DE,diskMap
	DAD		D					; hl now addresses the disk map
	PUSH	BC					; save the 0/1 bit to set
	MVI		C,fcbLength-diskMap+1 ; size of single byte disk map + 1
	
ScanDiskMap0:					; loop once for each disk map entry
	POP		DE					; recall bit parity
	DCR		C
	RZ							; exit when done

	PUSH	DE					; replace bit parity
	LDA		single				; single entry flag
	ORA		A
	JZ		ScanDiskMap1		; skip if two byte value
								; single byte scan operation
	PUSH	BC					; save counter
	PUSH	HL					; save map address
	MOV		C,M
	MVI		B,0					; BC=block#
	JMP ScanDiskMap2
	
ScanDiskMap1:					; two byte scan operation
	DCR		C					; count for double byte
	PUSH	BC					; save counter
	MOV		C,M
	INX		HL
	MOV		B,M					; BC=block#
	PUSH	HL					; save map address
ScanDiskMap2:					; arrive here with BC=block#, E=0/1
	MOV		A,C
	ORA		B					; skip if = 0000
	CNZ		SetAllocBit			; bit set to 0/1 its in C
	POP		HL
	INX		HL					; to next bit position
	POP		BC					; recall counter
	JMP		ScanDiskMap0		; for another item
;
;-----------------------------------
;given allocation vector position BC, return with byte
;containing BC shifted so that the least significant
;bit is in the low order accumulator position.  HL is
;the address of the byte for possible replacement in
;memory upon return, and D contains the number of shifts
;required to place the returned value back into position
GetAllocBit:					; getallocbit
	MOV		A,C
	ANI		111b
	INR		A
	MOV		E,A
	MOV		D,A
								; d and e both contain the number of bit positions to shift
	MOV		A,C
	RRC
	RRC
	RRC
	ANI		11111b
	MOV		C,A					; C shr 3 to C
	MOV		A,B
	ADD		A
	ADD		A
	ADD		A
	ADD		A
	ADD		A					; B shl 5
	ORA		C
	MOV		C,A					; bbbccccc to C
	MOV		A,B
	RRC
	RRC
	RRC
	ANI		11111b
	MOV		B,A					; BC shr 3 to BC
	LHLD	caAllocVector		; base address of allocation vector
	DAD		B
	MOV		A,M					; byte to A, hl = .alloc(BC shr 3)
								 ;now move the bit to the low order position of A
GetAllocBitl:
	RLC
	DCR		E
	JNZ		GetAllocBitl
	RET

;-----------------------------------
; BC is the bit position of ALLOC to set or reset.  The
; value of the bit is in register E.
SetAllocBit:					; setallocbit
	PUSH	DE
	CALL	GetAllocBit			; shifted val A, count in D
	ANI		11111110b			; mask low bit to zero (may be set)
	POP		BC
	ORA		C					; low bit of C is masked into A
	JMP		RotateAndReplace	; to rotate back into proper position
	;ret
;-----------------------------------
; byte value from ALLOC is in register A, with shift count
; in register C (to place bit back into position), and
; target ALLOC position in registers HL, rotate and replace
RotateAndReplace:				; rotr
	RRC
	DCR		D
	JNZ		RotateAndReplace	; back into position
	MOV		M,A					; back to ALLOC
	RET
	;-----------------------------------
	;move to home position, then offset to start of dir
Home:
	CALL	bcHome			; move to track 00, sector 00 reference
	LXI		HL,dpbOFF		; get track ofset at begining
	MOV		C,M
	INX		HL
	MOV		B,M
	CALL	bcSettrk		; select first directory position
						
	XRA		A				; constant zero to accumulator
	LHLD	caTrack
	MOV		M,A
	INX		HL
	MOV		M,A				; curtrk=0000
	LHLD	caSector
	MOV		M,A
	INX		HL
	MOV		M,A				; currec=0000
	RET


;*****************************************************************
;read buffer and check condition
ReadBuffer:					; rdbuff
	CALL	bcRead			; current drive, track, sector, dma
	ORA		A
	JNZ		erPermanentNoWait
	RET
;*****************************************************************
;*****************************************************************
; set directory counter to end  -1
SetEndDirectory:			; set$end$dir
	LXI		HL,EOD
	SHLD	dirCounter
	RET
;---------------
SetDataDMA:					; setdata
	LXI		HL,InitDAMAddress
	JMP		SetDMA			; to complete the call
;---------------
SetDirDMA:					; setdir
	LXI		HL,caDirectoryDMA
;	JMP		setdma
SetDMA:						; setdma
	MOV		C,M
	INX		HL
	MOV		B,M				; parameter ready
	JMP		bcSetdma		; call bios to set
;---------------
;---------------
; return zero flag if at end of directory
; non zero if not at end (end of dir if dirCounter = 0ffffh)
EndOfDirectory:				; end$of$dir
	LXI		HL,dirCounter
	MOV		A,M				; may be 0ffh
	INX		HL
	CMP		M				; low(dirCounter) = high(dirCounter)?
	RNZ						; non zero returned if different
							; high and low the same, = 0ffh?
	INR		A				; 0ffh becomes 00 if so
	RET
;---------------
; read a directory entry into the directory buffer
ReadDirRecord:				; rd$dir
	CALL	SetDirDMA		; directory dma
	CALL	ReadBuffer		;directory record loaded
    JMP		SetDataDMA ;to data dma address
	;ret
;---------------
; read next directory entry, with C=true if initializing
ReadDirectory:				; read$dir:
	LHLD	dpbDRM
	XCHG					; in preparation for subtract
	LHLD	dirCounter
	INX		HL
	SHLD	dirCounter		; dirCounter=dirCounter+1
							; continue while dpbDRM >= dirCounter (dpbDRM-dirCounter no cy)
	CALL	DEminusHL2HL	; DE-HL
	JNC		ReadDirectory0
							; yes, set dirCounter to end of directory
	CALL	SetEndDirectory
	RET
	
ReadDirectory0:				; read$dir0:
							; not at end of directory, seek next element
							; initialization flag is in C
	LDA		dirCounter
	ANI		dskmsk			; low(dirCounter) and dskmsk
	MVI		B,fcbshf		; to multiply by fcb size
ReadDirectory1:				; read$dir1:
	ADD		A
	DCR		B
	JNZ		ReadDirectory1
							; A = (low(dirCounter) and dskmsk) shl fcbshf
	STA		dirPointer		; ready for next dir operation
	ORA		A
	RNZ						; return if not a new record
	PUSH	BC				; save initialization flag C
	CALL	SeekDir			; seek$dir seek proper record
	CALL	ReadDirectory	; read the directory record
	POP		BC				; recall initialization flag
	JMP		CalculateCheckSum ; checksum the directory elt
	;ret
;---------
	;seek the record containing the current dir entry
SeekDir:					; seekdir
	LHLD	dirCounter		; directory counter to HL
	MVI		C,dskshf
	CALL	ShiftRightHLbyC ; value to HL
	SHLD	currentRecord
	SHLD	dirRecord ;ready for seek
	JMP		Seek
	;ret

;---------------------------
Seek:
	;seek the track given by currentRecord (actual record)
	;local equates for registers
							; arech  equ b
							; arecl  equ c ;currentRecord = BC
							; crech  equ d
							; crecl  equ e ;currec  = DE
							; ctrkh  equ h
							; ctrkl  equ l ;curtrk  = HL
							; tcrech equ h
							; tcrecl equ l ;tcurrec = HL
	;load the registers from memory
	LXI		HL,currentRecord
	MOV		C,M				; arecl,m
	INX		HL
	MOV		B,M				; arech,m
	LHLD	caSector 
	MOV		E,M				; crecl,m
	INX		HL
	MOV		D,M				; crech,m
	LHLD	caTrack 
	MOV		A,M
	INX		HL
	MOV		H,M				; ctrkh,M
	MOV		L,A				; ctrkl,a
	;loop while currentRecord < currec
Seek0:
	MOV		A,C				; a,arecl
	SUB		E				; crecl
	MOV		A,B				; a,arech
	SBB		D				; crech
	JNC		Seek1			; skip if currentRecord >= currec
							; currec = currec - dpbSPT
	PUSH	HL				; ctrkh
	LHLD	dpbSPT			; sectors per track
	MOV		A,E				; a,crecl
	SUB		L
	MOV		E,A				; crecl,a
	MOV		A,D				; a,crech
	SBB		H
	MOV		D,A				; crech,a
	POP		HL				; ctrkh
							; curtrk = curtrk - 1
	DCX		HL				; ctrkh
	JMP		Seek0			; for another try
	
Seek1:
	;look while currentRecord >= (t:=currec + dpbSPT)
	PUSH	HL				; ctrkh
	LHLD	dpbSPT			; sectors per track
	DAD		D				; crech ;HL = currec+dpbSPT
	MOV		A,C				; a,arecl
	SUB		L				; tcrecl
	MOV		A,B				; a,arech
	SBB		H				; tcrech
	JC		Seek2			; skip if t > currentRecord
							; currec = t
	XCHG
							; curtrk = curtrk + 1
	POP		HL				; ctrkh
	INX		HL				; ctrkh
	JMP		Seek1			; for another try
	
Seek2:
	POP		HL					; ctrkh
							; arrive here with updated values in each register
	PUSH	BC				; arech
	PUSH	DE				; crech
	PUSH	HL				; ctrkh ;to stack for later
							; stack contains (lowest) BC=currentRecord, DE=currec, HL=curtrk
	XCHG
	LHLD	dpbOFF			; offset tracks at beginning
	DAD		D				; HL = curtrk+dpbOFF
	MOV		B,H
	MOV		C,L
	CALL	bcSettrk		; track set up
							; note that BC - curtrk is difference to move in bios
	POP		DE				; recall curtrk
	LHLD	caTrack
	MOV		M,E
	INX		H
	MOV		M,D				; curtrk updated
							; now compute sector as currentRecord-currec
	POP		DE				; crech ;recall currec
	LHLD	caSector
	MOV		M,E				; m,crecl
	INX		HL
	MOV		M,D				; m,crech
	POP		BC				; arech ;BC=currentRecord, DE=currec
	MOV		A,C				; a,arecl
	SUB		E				; crecl
	MOV		C,A				; arecl,a
	MOV		A,B				; a,arech
	SBB		D				; crech
	MOV		B,A				; arech,a
	LHLD	caSkewTable
	XCHG					; BC=sector#, DE=.tran
	CALL	bcSectran		; HL = tran(sector)
	MOV		C,L
	MOV		B,H				; BC = tran(sector)
	JMP		bcSetsec		; sector selected
	;ret	
;************* CheckSum *******************************
; compute current checksum record
; and update the directory element if C=true 
; or check for = if not dirRecord < dpbCKS?
NewCheckSum:				; newchecksum
	MVI		C,TRUE			; drop thru
CalculateCheckSum:			; checksum
	LHLD dirRecord
	XCHG
	LHLD	dpbCKS			; size of checksum vector
	CALL	DEminusHL2HL	; DE-HL
	RNC						; skip checksum if past checksum vector size
							; dirRecord < dpbCKS, so continue
	PUSH	BC				; save init flag
	CALL	ComputeCheckSum ; check sum value to A
	LHLD	caCheckSum		; address of check sum vector
	XCHG
	LHLD	dirRecord		; value of dirRecord
	DAD		D				; HL = .check(dirRecord)
	POP		BC				; recall true=0ffh or false=00 to C
	INR		C				; 0ffh produces zero flag
	JZ		SetNewCheckSum
							; not initializing, compare
	CMP		M				; compute$cs=check(dirRecord)?
	RZ						; no message if ok
							; possible checksum error, are we beyond
							; the end of the disk?
	CALL	StillInDirectory
	RNC						; no message if so
	CALL	SetDiskReadOnly ;read/only disk set
	RET
	
;initializing the checksum
SetNewCheckSum:				; initial$cs:
	MOV		M,A
	RET
;------------------
;compute checksum for current directory buffer
ComputeCheckSum:				; compute$cs
	MVI		C,recordSize		; size of directory buffer
	LHLD	caDirectoryDMA		; current directory buffer
	XRA		A					; clear checksum value
ComputeCheckSum0:
	ADD		M
	INX		H
	DCR		C					; cs=cs+buff(recordSize-C)
	JNZ		ComputeCheckSum0
	RET							;with checksum in A
;*****************************************************************
; compute the address of a directory element at positon dirPointer in the buffer
GetDirElementAddress:				; getdptra
	LHLD	caDirectoryDMA
	LDA		dirPointer
	JMP		AddAtoHL
;---------------------
;if not still in directory set max value
SetDirectoryEntry:					; setcdr:
	CALL	StillInDirectory
	RC								; return if yes
									; otherwise, HL = DirMaxValue+1, DE = directoryCount
	INX		D
	MOV		M,D
	DCX		H
	MOV		M,E
	RET
;---------------------
; return CY if entry is still in Directory
StillInDirectory:				; compcdr
	LHLD	dirCounter
	XCHG						; DE = directory counter
	LHLD	caDirMaxValue		; HL=caDirMaxValue
	MOV		A,E
	SUB		M					; low(dirCounter) - low(cdrmax)
	INX		H					; HL = .cdrmax+1
	MOV		A,D
	SBB		M					; hi(dirCounter) - hig(cdrmax)
								;condition dirCounter - cdrmax  produces cy if cdrmax>dirCounter
	RET
;*****************************************************************

;****************** Utilities *********************************
AddAtoHL:				; addh
	ADD L
	MOV L,A
	RNC
						; overflow to H
	INR H
	RET
DEminusHL2HL:			; subdh
	MOV		A,E
	SUB		L
	MOV		L,A
	MOV		A,D
	SBB		H
	MOV		H,A
	RET
;-------------
ShiftRightHLbyC:		; hlrotr rotate
	INC		C
ShiftRightHLbyC0:
	DEC		C
	RZ				; exit when done
	MOV		A,H
	ORA		A		; reset carry bit
	RAR				; rotate
	MOV		H,A		; high byte
	MOV		A,L
	RAR		
	MOV		L,A		; low byte
	JMP		ShiftRightHLbyC0
	
;-------
ShiftLeftHLbyC:		; hlrotl
	INC		C
ShiftLeftHLbyC0:
	DEC		C
	RZ				; exit when done
	DAD		HL
	JMP		ShiftLeftHLbyC0
;*****************************************************************
;move data length of length C from source DE to HL
Move:
	INC		C		; housekeeping
Move0:
	DCR		C
	RZ				; exit if done
	LDAX	D		; get byte
	MOV		M,A		; put the byte
	INX		DE
	INX		HL		; move pointers
	JMP		Move0	; keep going
	
;********** Console Routines***********************
;********** Console IN Routines********************
;read console character to A
ConIn:							; conin
	LXI		HL,kbchar
	MOV		A,M
	MVI		M,0
	ORA		A
	RNZ
	;no previous keyboard character ready
	JMP		bcConin ;get character externally
	;ret
;
;----------------
;echo character if graphic CR, LF, TAB, or backspace
EchoNonGraphicCharacter:		; echoc
	CPI		CR
	RZ							; carriage return?
	CPI		LF
	RZ							; line feed?
	CPI		TAB
	RZ							; TAB?
	CPI		CTRL_H
	RZ							; backspace?
	CPI		SPACE
	RET							; carry set if not graphic
;----------------
;read character with echo
ConsoleInWithEcho:				; conech
	CALL	ConIn
	CALL	EchoNonGraphicCharacter
	RC							; return if graphic character
								; character must be echoed before return
	PUSH	PSW
	MOV		C,A
	CALL	TabOut
	POP		PSW
	RET							; with character in A
;********** Console OUT Routines*******************
ConBreak:						; conbrk for character ready
	LDA		kbchar
	ORA		A
	JNZ		ConBreak1 			; skip if active kbchar
	CALL	bcConst				; get status
	ANI		1
	RZ							; return if no char ready
	CALL	bcConin				; to A
	CPI		CTRL_S
	JNZ		ConBreak0			; check stop screen function
									;found CTRL_S, read next character
	CALL	bcConin 			;to A
	CPI		CTRL_C
	JZ		WarmBoot ;CTRL_C implies re-boot
		;not a WarmBoot, act as if nothing has happened
	XRA		A
	RET ;with zero in accumulator
ConBreak0:				; conb0:
		;character in accum, save it
	STA kbchar
ConBreak1:				; conb1:
		;return with true set in accumulator
	MVI		A,TRUE
	RET
;


;
;display #, CR, LF for CTRL_X, CTRL_U, CTRL_R functions
;then move to startingColumn (starting columnPosition)
showHashCRLF:			; crlfp:
	MVI		C,HASH_TAG
	CALL	ConsoleOut
	CALL	showCRLF
			;columnPosition = 0, move to position startingColumn
showHashCRLF0:			; crlfp0:
	LDA		columnPosition
	LXI		HL,startingColumn
	CMP		M
	RNC						; stop when columnPosition reaches startingColumn
	MVI		C,SPACE
	CALL	ConsoleOut			; display blank
	JMP		showHashCRLF0
;
showCRLF:				;crlf:
	;carriage return line feed sequence
	MVI		C,CR
	CALL	ConsoleOut
	MVI		C,LF
	JMP		ConsoleOut
	;ret
;
;-------------
;print message until M(BC) = '$'
Print:								; print
	LDAX	BC
	CPI		DOLLAR
	RZ								 ; stop on $
	INX		BC
	PUSH	BC
	MOV		C,A
	CALL	TabOut
	POP		BC
	JMP		Print

;----------------
; compute character position/write console char from C
; compcol = true if computing column position
ConsoleOut:						; conout
	LDA		compcol
	ORA		A
	JNZ		ConsoleOut1
								; write the character, then compute the columnPosition
								; write console character from C
	PUSH	BC
	CALL	ConBreak			; check for screen stop function
	POP		BC
	PUSH	BC					; recall/save character
	CALL	bcConout			; externally, to console
	POP		BC
	PUSH	BC					; recall/save character
								; may be copying to the list device
	LDA		listeningToggle
	ORA		A
	CNZ		bcList				; to printer, if so
	POP		BC					; recall the character
ConsoleOut1:
	MOV		A,C					; recall the character
								; and compute column position
	LXI		HL,columnPosition	; A = char, HL = .columnPosition
	CPI		RUBOUT
	RZ							; no columnPosition change if nulls
	INR		M					; columnPosition = columnPosition + 1
	CPI		SPACE
	RNC							; return if graphic
								;	not graphic, reset columnPosition position
	DCR		M					; columnPosition = columnPosition - 1
	MOV		A,M
	ORA		A
	RZ							; return if at zero
								; not at zero, may be backspace or end line
	MOV		A,C					; character back to A
	CPI		CTRL_H
	JNZ		NotBackSpace
								; backspace character
	DCR		M					; columnPosition = columnPosition - 1
	RET
NotBackSpace:					; notbacksp:  not a backspace character  eol?
	CPI		LF
	RNZ							; return if not
								; end of line, columnPosition = 0
	MVI		M,0					; columnPosition = 0
	RET
;************Error message World*************************
errSelect:		; sel$error  report selection error
	LXI		HL,evSelection
	JMP		GoToError
;************Error message handler **********************
GoToError:					; goerr:
	;HL = .errorhandler, call subroutine
	MOV		E,M
	INX		HL
	MOV		D,M				; address of routine in DE
	XCHG
	PCHL					; vector to subroutine
;************ Error Vectors *****************************
evPermanent: 	DW	erPermanent	;pererr permanent error subroutine
evSelection:	DW	erSelection	;selerr select error subroutine
evReadOnlyDisk:	DW	erReadOnlyDisk	;roderr ro disk error subroutine
evReadOnlyFile:	DW	erReadOnlyFile	;roferr ro file error subroutine
;************Error Routines ******************************
erPermanentNoWait:				; per$error
	LXI		HL,emPermanent
	JMP	GoToError

erPermanent:					; persub report permanent error
	LXI		HL,emPermanent
	CALL	displayAndWait		; to report the error
	CPI 	CTRL_C
	JZ		WarmBoot			; reboot if response is CTRL_C
	RET							; and ignore the error
;
erSelection:					;selsub report select error
	LXI		HL,emSelection
	JMP		waitB4boot			; wait console before boot
;
erReadOnlyDisk:					; rodsub report write to read/only disk
	LXI		HL,emReadOnlyDisk
	JMP		waitB4boot			; wait console before boot
;
erReadOnlyFile:					;rofsub report read/only file
	LXI		HL,emReadOnlyFile	; drop through to wait for console
;
waitB4boot:						; wait$err wait for response before boot
	CALL	displayAndWait
JMP WarmBoot

displayAndWait:			; errflg:
	;report error to console, message address in HL
	PUSH	HL					; save message pointer
	CALL	showCRLF			; stack mssg address, new line
	LDA		currentDisk
	ADI		ASCII_A
	STA		emDisk				 ; Problem disk name
	LXI		BC,emDisk0
	CALL	Print ;the error message
	POP		BC
	CALL	Print ;error mssage tail
	JMP		ConIn ;to get the input character
	;ret	
;**************Error Messages*******************************
emDisk0:		DB	'Bdos Err On '	; dskmsg:
emDisk:			DB	' : $'			; dskerr filled in by errflg
emPermanent:	DB	'Bad Sector$'	; permsg
emSelection:	DB	'Select$'		; selmsg
emReadOnlyFile:	DB	'File '			; rofmsg	
emReadOnlyDisk:	DB	'R/O$'			; rodmsg:	
;*****************************************************************
;********* file control block (fcb) constants ********************
emptyDir	EQU		0E5H		; empty empty directory entry
lastRecordNumber	EQU		127	; lstrec last record# in extent
recordSize	EQU		128			; recsiz record size
fcbLength	EQU		32			; fcblen file control block size
dirrec		EQU		recordSize/fcbLength	;directory elts / record
dskshf		EQU		2	;log2(dirrec)
dskmsk		EQU		dirrec-1
fcbshf		EQU		5	;log2(fcbLength)
;
extnum		EQU		12	;extent number field
maxext		EQU		31	;largest extent number
ubytes		EQU		13	;unfilled bytes field
modnum		EQU		14	;data module number
maxmod		EQU		15	;largest module number
fwfmsk		EQU		80h	;file write flag is high order modnum
nameLength	EQU		15	; namlen name length
reccnt		EQU		15	;record count field
diskMap		EQU		16	; dskmap disk map field
lstfcb		EQU		fcbLength-1
nxtrec		EQU		fcbLength
ranrec		EQU		nxtrec+1;random record field (2 bytes)
;
;	reserved file indicators
rofile		EQU		9	;high order of first type char
invis		EQU		10	;invisible file in dir command
;	equ	11	;reserved
;*****************************************************************
;*****************************************************************

;***common values shared between bdosi and bdos******************
currentUserNumber:	DB		0	;usrcode current user number
paramDE:			DS		2	;ParamsDE information address
statusBDOSReturn:	DS		2	;address value to return
currentDisk:		DB		0	; curdsk current disk number
lowReturnStatus:	EQU		statusBDOSReturn	;lret low(statusBDOSReturn)

;********************* Local Variables ***************************
;     ************************
;     *** Initialized Data ***

;efcb:	DB	emptyDir	;0e5=available dir entry
ReadOnlyVector:	DW	0			; rodsk read only disk vector
loggedDisks:	DW	0			; dlog	 logged-in disks
InitDAMAddress:	DW	DMABuffer	; dmaad tbuff initial dma address

;     *** Current Disk attributes ****
; These are set upon disk select
; data must be adjacent, do not insert variables
; address of translate vector, not used
; ca - currentAddress

caDirMaxValue:	DW		0000H	;cdrmaxa pointer to cur dir max value
caTrack:		DW		0000H	;curtrka current track address
caSector:		DW		0000H	;curreca current record address
caDirectoryDMA:	DW		0000H	;buffa pointer to directory dma address
caDiskParamBlock:	DW	0000H	;dpbaddr current disk parameter block address
caCheckSum:		DW		0000H	;checka current checksum vector address
caAllocVector:	DW		0000H	;alloca current allocation vector address
caListSize		EQU		$ - caDirectoryDMA	;addlist	equ	$-caDirectoryDMA	 address list size

;     ***** Disk Parameter Block *******
; data must be adjacent, do not insert variables
; dpb - Disk Parameter Block

dpbSPT:			DW		0000H	;sectpt sectors per track
dpbBSH:			DB		0000H	;blkshf block shift factor
dpbBLM:			DB		00H		;blkmsk block mask
dpbEXM:			DB		00H		;extmsk extent mask
dpbDSM:			DW		0000H	;maxall maximum allocation number
dpbDRM:			DW		0000H	;dirmax largest directory number
dpbDABM:		DW		0000H	;dirblk reserved allocation bits for directory
dpbCKS:			DW		0000H	;chksiz size of checksum vector
dpbOFF:			DW		0000H	;offset offset tracks at beginning
dpbSize			EQU		$ - dpbSPT	;dpblist	equ	$-dpbSPT	;size of area
;

;     ************************

paramE:				DS		BYTE		; low(info)
caSkewTable:		DW		0000H	;tranv address of translate vector
;fcb$copied:
;	ds	byte	;set true if copy$fcb called
;rmf:	ds	byte	;read mode flag for open$reel
;dirloc:	ds	byte	;directory flag in rename, etc.
;seqio:	ds	byte	;1 if sequential i/o
;dminx:	ds	byte	;local for diskwrite
;searchl:ds	byte	;search length
;searcha:ds	word	;search address
;tinfo:	ds	word	;temp for info in "make"
single:			DB		00H		; set true if single byte allocation map
fResel:			DB		00H		; resel reselection flag
entryDisk:		DB		00H		; olddsk disk on entry to bdos
fcbDisk:		DB		00H		;disk named in fcb
;rcount:	ds	byte	;record count in current fcb
;extval:	ds	byte	;extent number and extmsk
;vrecord:ds	word	;current virtual record
currentRecord:	DW		0000H	;arecord current actual record
;
;	local variables for directory access
dirPointer:		DB		00H		; dptr directory pointer 0,1,2,3
dirCounter:		DW		00H		; dcnt directory counter 0,1,...,dpbDRM
dirRecord:		DW		00H		; drec:	ds	word	;directory record 0,1,...,dpbDRM/4

;********************** data areas ******************************
compcol:			DB	0			; true if computing column position
startingColumn:		DB	0			; strtcol starting column position after read
columnPosition:		DB	0			; column column position
listeningToggle:	DB	0			; listcp listing toggle
kbchar:				DB	0			; initial key char = 00
usersStack:			DS	2			; entry stack pointer
					DS	STACK_SIZE * 2		; stack size
bdosStack:
;	end of Basic I/O System
;-----------------------------------------------------------------;*****************************************************************

;	
CodeEnd: