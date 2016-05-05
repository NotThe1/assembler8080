; newBDOS.asm
; part of newOS
; 2014-03-14  :  Frank Martyn
; TODO ------
	$Include ../Headers/osHeader.asm
	$Include ../Headers/stdHeader.asm
	
VERSION	EQU	20H				; dvers version 2.0
STACK_SIZE	EQU	20H			; make stak big enough
EOD	EQU	-1				; enddir End of Directory
;WORD	EQU	02				; number of bytes for a word
;BYTE	EQU	01				; number of bytes for a byte

;	bios access constants
bcBoot	EQU	BIOSEntry+3*0			; bootf	cold boot function
bcWboot	EQU	BIOSEntry+3*1			; wbootf	warm boot function
bcConst	EQU	BIOSEntry+3*2			; constf	console status function
bcConin	EQU	BIOSEntry+3*3			; coninf	console input function
bcConout	EQU	BIOSEntry+3*4			; conoutf	console output function
bcList	EQU	BIOSEntry+3*5			; listf	list output function
bcPunch	EQU	BIOSEntry+3*6			; punchf	punch output function
bcReader	EQU	BIOSEntry+3*7			; readerf	reader input function
bcHome	EQU	BIOSEntry+3*8			; homef	disk home function
bcSeldsk	EQU	BIOSEntry+3*9			; seldskf	select disk function
bcSettrk	EQU	BIOSEntry+3*10			; settrkf	set track function
bcSetsec	EQU	BIOSEntry+3*11			; setsecf	set sector function
bcSetdma	EQU	BIOSEntry+3*12			; setdmaf	set dma function
bcRead	EQU	BIOSEntry+3*13			; readf	read disk function
bcWrite	EQU	BIOSEntry+3*14			; writef	write disk function
bcListst	EQU	BIOSEntry+3*15			; liststf	list status function
bcSectran	EQU	BIOSEntry+3*16			; sectran	sector translate
	                              
	ORG	BDOSBase
CodeStart:
	DB	0,0,0,0,0,0
; Enter here from the user's program with function number in c,
; and information address in d,e
;BDOSEntry:
	JMP	BdosStart				;past parameter block
	
BdosStart:
	XCHG					; swap DE and HL
	SHLD	paramDE				; save the original value of DE
	XCHG					; restore DE
	MOV	A,E				; Byte argument
	STA	paramE
	LXI	HL,0000H
	SHLD	statusBDOSReturn			; assume alls well for return
						; Save users Stack pointer
	DAD	SP
	SHLD	usersStack
	LXI	SP,bdosStack			; use our own stack area
						; initialize variables
	XRA	A
	STA	fcbDisk				; initalize to 00
	STA	fResel				; clear reselection flag
	LXI	HL,RetCaller			; exit to caller vector
	PUSH	HL				; makes a JMP to RetCaller = RET
	
	MOV	A,C				; get the Function Number
	CPI	functionCount			; make sure its a good number
	RNC					; exit if not a valid function
	
	MOV	C,E				; might be a single byte argument
	LXI	HL,functionTable			; get table base
	MOV	E,A				; function number in E
	MVI	D,0				; setting up DE = function number
	DAD	DE
	DAD	DE				; Vector is (2 * Function number) + table base
	MOV	E,M				; get LSB of vector
	INX	HL
	MOV	D,M				; get MSB of vector
	XCHG					; Vector now in HL
	PCHL					; move vector to Program Counter ie JMP (HL)
;*****************************************************************
;arrive here at end of processing to return to user
RetCaller:					; goback
	LDA	fResel				; get reselction flag
	ORA	A				; is it set?
	JZ	RetDiskMon
	;reselection may have taken place
	LHLD	paramDE
	MVI	M,0
	LDA	fcbDisk
	ORA	A				; Disk = 0?
	JZ	RetDiskMon			; exit if yes
	
	MOV	M,A
	LDA	entryDisk				; get back original Disk
	STA	paramE				; and select it
	CALL	SelectCurrent	

; return from the disk monitor
RetDiskMon:					; retmon
	LHLD	 usersStack
	SPHL					; Restore callers stack
	LHLD	statusBDOSReturn
	MOV	A,L
	MOV	B,H				; BA = statusBDOSReturn
	RET		
;*****************************************************************
;------------------- Function Table -------------------------------
functionTable:
	DW	bcBoot				; Function  0 - System Reset
	DW	fConsoleIn			; Function  1 - Console Input
	DW	fConsoleOut			; Function  2 - Console Output
	DW	DUMMY				; Function  3 - Reader Input
	DW	DUMMY				; Function  4 - Punch Output
	DW	DUMMY				; Function  5 - List Output
	DW	fDirectConIO			; Function  6 - Direct Console I/O
	DW	fGetIOBYTE			; Function  7 - Get I/O Byte
	DW	fSetIOBYTE			; Function  8 - Set I/O Byte
	DW	fPrintString			; Function  9 - Print String
	DW	fReadString			; Function  A - Read Console String
	DW	fGetConsoleStatus			; Function  B - Get Console Status
diskf	EQU	($-functionTable)/2			; disk functions
	DW	fGetVersion			; Function  C - Return Version Number
	DW	fResetSystem			; Function  D - Reset Disk System
	DW	fSelectDisk			; Function  E - Select Disk
	DW	fOpenFile				; Function  F - Open File
	DW	fCloseFile			; Function 10 - Close File
	DW	fFindFirst			; Function 11 - Search For First
	DW	fFindNext				; Function 12 - Search for Next
	DW	fDeleteFile			; Function 13 - Delete File
	DW	fReadSeq				; Function 14 - Read Sequential
	DW	fWriteSeq				; Function 15 - Write Sequential
	DW	fMakeFile				; Function 16 - Make File
	DW	fRenameFile			; Function 17 - Rename File
	DW	fGetLoginVector			; Function 18 - Return Login Vector
	DW	fGetCurrentDisk			; Function 19 - Return Current Disk
	DW	fSetDMA				; Function 1A - Set DMA address
	DW	fGetAllocAddr			; Function 1B - Get ADDR (ALLOC)
	DW	DUMMY				; Function 1C - Write Protect Disk
	DW	DUMMY				; Function 1D - Get Read/Only Vector
	DW	DUMMY				; Function 1E - Set File Attributes
	DW	fGetDiskParamBlock			; Function 1F - Get ADDR (Disk Parameters)
	DW	fGetSetUserNumber			; Function 20 - Set/Get User Code
	DW	DUMMY				; Function 21 - Read Random
	DW	DUMMY				; Function 22 - Write Random
	DW	DUMMY				; Function 23 - Compute File Size
	DW	fGetLoginVector			; Function 24 - Set Random Record
	DW	DUMMY				; Function 25 - Reset Drive
	DW	DUMMY				; Function 26 - Access Drive (not supported)
	DW	DUMMY				; Function 27 - Free Drive (not supported)
	DW	DUMMY				; Function 28 - Write random w/Fill
functionCount	EQU	($-functionTable)/2 				; Number of  functions

DUMMY:
	HLT
;*****************************************************************
;**************** IOByte device I/O ******************************
;*****************************************************************
;return console character with echo
fConsoleIn:					; func1 (01 - 01) Console In
	CALL	ConsoleInWithEcho
	JMP	StoreARet
;----------
; write console character with TAB expansion
fConsoleOut:					; func2 (02 - 02) Console Out
	CALL	TabOut
	RET					; jmp goback
;----------
;direct console i/o - read if 0ffh
fDirectConIO:					; func6 (06 - 06) get Direct Console Out
	MOV	A,C
	INR	A
	JZ	fDirectConIn			; 0ffh => 00h, means input mode
						; direct output function
	CALL	bcConout
	RET					; jmp goback
fDirectConIn:
	CALL	bcConst				; status check
	ORA	A
	JZ	RetDiskMon			; skip, return 00 if not ready
						; character is ready, get it
	CALL	bcConin				; to A
	JMP	StoreARet
;----------
;return io byte	
fGetIOBYTE:					; func7 (07 - 07) get IOBYTE
	LDA	IOBYTE				; get the byte
	JMP	StoreARet				; store A and return
;----------
;set i/o byte
fSetIOBYTE:					; func8 (08 - 08)	set IOBYTE
	LXI	HL,IOBYTE
	MOV	M,C				; put passed value into IOBYTE
	RET					; exit
;----------
;write line until $ encountered
fPrintString:					; func9 (09 - 09)	 Print Dollar terminated String
	LHLD	paramDE
	MOV	C,L
	MOV	B,H				; BC=string address
	CALL	Print				; out to console
	RET					; jmp goback
;----------
;read String from Console until limit or CR is reached
;In - (DE) = limit 
;Out - (DE+1) = count of chars read (DE+2) = characters read
fReadString:					; func10 (10 - 0A)	read String from console
	CALL	ReadString
	RET 					; jmp goback
;*****************************************************************
;----------
;check console status
fGetConsoleStatus:					; func11 (11 - 01)	read Dollar terminated String from console
	CALL	ConBreak
	JMP	StoreARet

;----------
;get/set user code
; IN - (E) = FF its a get else user Number(0-15)
; OUT - (A) Current user number or no value
fGetSetUserNumber:					; func32 (32 - 20)	Get or set User code
    LDA	paramE
	CPI	0FFH
	JNZ	SetUserNumber
						; interrogate user code instead
	LDA	currentUserNumber
	STA	lowReturnStatus			; lowReturnStatus=currentUserNumber
	RET					; jmp goback
SetUserNumber:					; setusrcode
	ANI	0FH
	STA	currentUserNumber
	RET					; jmp goback

;*****************************************************************
; store A and return
StoreARet:					; sta$ret
	STA	statusBDOSReturn
	RET					; jmp , go back
	
;----------------
;read to paramDE address (max length, current length, buffer)
ReadString:					; read
	LDA	columnPosition
	STA	startingColumn			; save start for ctl-x, ctl-h
	LHLD	paramDE
	MOV	C,M
	INX	H
	PUSH	HL
	MVI	B,0
						; B = current buffer length,
						; C = maximum buffer length,
						; HL= next to fill - 1
ReadNext:						; readnx:
						; read next character, BC, HL active
	PUSH	BC
	PUSH	HL				; blen, cmax, HL saved
ReadNext0:
	CALL	ConIn				; next char in A
	ANI	ASCII_MASK			; mask parity bit
	POP	HL
	POP	BC				; reactivate counters
	CPI	CR
	JZ	EndRead				; end of line?
	CPI	LF
	JZ	EndRead				; also end of line
	CPI	CTRL_H
	JNZ	NotCtntl_H			; backspace?
						; do we have any characters to back over?
	MOV	A,B
	ORA	A
	JZ	ReadNext
						; characters remain in buffer, backup one
	DCR	B				; remove one character
	LDA	columnPosition
	STA	compcol				; col > 0
						; compcol > 0 marks repeat as length compute
	JMP	LineLengthOrRepeat			; uses same code as repeat
NotCtntl_H:
						; not a backspace
	CPI	RUBOUT
	JNZ	NotRubout				; RUBOUT char?
						; RUBOUT encountered, RUBOUT if possible
	MOV	A,B
	ORA	A
	JZ	ReadNext				; skip if len=0
						; buffer has characters, resend last char
	MOV	A,M
	DCR	B
	DCX	HL				; A = LAST CHAR
						; BLEN=BLEN-1, NEXT TO FILL - 1 DECREMENTED
	JMP ReadEcho1				; act like this is an echo
;
NotRubout:
						; not a RUBOUT character, check end line
	CPI	CTRL_E
	JNZ	NotCtntl_E			; physical end line?
						; yes, save active counters and force eol
	PUSH	BC
	PUSH	HL
	CALL	showCRLF
	XRA	A
	STA	startingColumn			; start position = 00
	JMP	ReadNext0				; for another character
NotCtntl_E:					; note
						; not end of line, list toggle?
	CPI	CTRL_P
	JNZ	NotCtntl_P			; skip if not CTRL_P
						; list toggle - change parity
	PUSH	HL				; save next to fill - 1
	LXI	HL,listeningToggle			; HL=.listeningToggle flag
	MVI	A,1
	SUB	M				; True-listeningToggle
	MOV	M,A				; listeningToggle = not listeningToggle
	POP	HL
	JMP	ReadNext				; for another char
NotCtntl_P:					; notp:
						; not a CTRL_P, line delete?
	CPI	CTRL_X
	JNZ	NotCtntl_X
	POP	HL				; discard start position
						; loop while columnPosition > startingColumn
GoBack:						; backx:
	LDA	startingColumn
	LXI	HL,columnPosition
	CMP	M
	JNC	ReadString			; start again
	DCR	M				; columnPosition = columnPosition - 1
	CALL	BackUp				; one position
	JMP	GoBack
NotCtntl_X:					; notx:
						; not a control x, control u?
						; not control-X, control-U?
	CPI	CTRL_U
	JNZ	NotCtntl_U			; skip if not
						; delete line (CTRL_U)
	CALL	showHashCRLF			; physical eol
	POP	HL				; discard starting position
	JMP	ReadString			; to start all over
NotCtntl_U:					; notu:
						; not line delete, repeat line?
	CPI	CTRL_R
	JNZ	NotCtntl_R
LineLengthOrRepeat:
						; repeat line, or compute line len (CTRL_H)
						; if compcol > 0
	PUSH	BC
	CALL	showHashCRLF			; save line length
	POP	BC
	POP	HL
	PUSH	HL
	PUSH	BC
						; bcur, cmax active, beginning buff at HL
Repeat:						; rep0:
	MOV	A,B
	ORA	A
	JZ	Repeat1				; count len to 00
	INX	HL
	MOV	C,M				; next to print
	DCR	B
	PUSH	BC
	PUSH	HL				; count length down
	CALL	CaretCout				; character echoed
	POP	HL
	POP	BC				; recall remaining count
	JMP	Repeat				; for the next character
Repeat1:						; rep1:
						; end of repeat, recall lengths
						; original BC still remains pushed
	PUSH	HL				; save next to fill
	LDA	compcol
	ORA	A				; >0 if computing length
	JZ	ReadNext0				; for another char if so
						; columnPosition position computed for CTRL_H
	LXI	HL,columnPosition
	SUB	M				; diff > 0
	STA	compcol				; count down below
						; move back compcol-columnPosition spaces
BackSpace:					; backsp:
						; move back one more space
	CALL	BackUp				; one space
	LXI	HL,compcol
	DCR	M
	JNZ	BackSpace
	JMP	ReadNext0				; for next character
NotCtntl_R:					; notr:
						; not a CTRL_R, place into buffer
ReadEcho:
	INX	HL
	MOV	M,A				; character filled to mem
	INR	B				; blen = blen + 1
ReadEcho1:
						; look for a random control character
	PUSH	BC
	PUSH	HL				; active values saved
	MOV	C,A				; ready to print
	CALL	CaretCout				; may be up-arrow C
	POP	HL
	POP	BC
	MOV	A,M				; recall char
	CPI	CTRL_C				; set flags for reboot test
	MOV	A,B				; move length to A
	JNZ	NotCtntl_C			; skip if not a control c
	CPI	1				; control C, must be length 1
	JZ	WarmBoot				; reboot if blen = 1
						; length not one, so skip reboot
NotCtntl_C:					; notc:
						; not reboot, are we at end of buffer?
	CMP	C
	JC	ReadNext				; go for another if not paramDE
EndRead:						; readen
						; end of read operation, store blen
	POP	HL
	MOV	M,B				; M(current len) = B
	MVI	C,CR
	JMP	ConsoleOut			; return carriage
	;ret
;------------------
;back-up one screen position
BackUp:						; backup
 	CALL	PutCntl_H
	MVI	C,SPACE
	CALL	bcConout
;	JMP PutCntl_H
;send CTRL_H to console without affecting column count
PutCntl_H:					; pctlh
	MVI	C,CTRL_H
	JMP	bcConout
	;ret	
;----------------------------------------------------------------
;


;------------------
;send C character with possible preceding up-arrow
CaretCout:					; ctlout
	MOV	A,C
	CALL	EchoNonGraphicCharacter		; cy if not graphic (or special case)
	JNC	TabOut				; skip if graphic, TAB, CR, LF, or CTRL_H
						; send preceding up arrow
	PUSH	PSW
	MVI	C,CARET
	CALL	ConsoleOut			; up arrow
	POP	PSW
	ORI	40H				; becomes graphic letter
	MOV	C,A				; ready to print
	;(drop through to tabout)
;expand tabs to console	
TabOut:						; tabout
	;expand tabs to console
	MOV	A,C
	CPI	TAB
	JNZ	ConsoleOut			; direct to ConsoleOut if not
						; TAB encountered, move to next TAB position
TabOut0:						; tab0:
	MVI	C,SPACE
	CALL	ConsoleOut			; another blank
	LDA	columnPosition
	ANI	111b				; columnPosition mod 8 = 0 ?
	JNZ	TabOut0				; back for another if not
	RET
;--------------------
;*****************************************************************
;********************** Disk  I/O ********************************
;*****************************************************************
;reset disk system - initialize to disk 0
fResetSystem:					; func13 (13 - 0D)	 Reset Disk System
 	LXI	HL,0
	SHLD	ReadOnlyVector
	SHLD	loggedDisks
	XRA	A
	STA	currentDisk			; note that currentUserNumber remains unchanged
	LXI	HL,DMABuffer
	SHLD	InitDAMAddress			; InitDAMAddress = DMABuffer
    CALL	SetDataDMA				; to data dma address 
	JMP	Select
	;ret ;jmp goback
;-----------------------------------------------------------------
;select disk in (E) paramDE
; IN - (E) disk number -- 0=A  1=B ...15=P
fSelectDisk:					; func14 (14 - 0E)	Select Current Disk
	JMP	SelectCurrent
	;ret ;jmp goba
;-----------------------------------------------------------------
;return the login vector
;OUT - (HL) loggedDisks
fGetLoginVector:					; func24: (24 - 18) Return login Vector
	LHLD	loggedDisks
	SHLD	statusBDOSReturn
	RET					; jmp goback
;-----------------------------------------------------------------
;return selected disk number
;OUT - A current disk -- 0=A  1=B ...15=P
fGetCurrentDisk:					; func25 (25 - 19)	Get Current Disk
	LDA	currentDisk
	STA	lowReturnStatus
	RET		;jmp goback
;-----------------------------------------------------------------
;set the subsequent dma address to paramDE
;IN - (HL) value to set as DMA
fSetDMA:						; func26 (25 - 1A) Set Dma Address
	LHLD	paramDE
	SHLD	InitDAMAddress			; InitDAMAddress = paramDE
    JMP	SetDataDMA				; to data dma address
	;ret ;jmp goback
;

;-----------------------------------------------------------------
;return the Allocation Vector Address
;OUT - (HL) Allocation Vector Address
fGetAllocAddr:					; func27 (27 - 1B) Get Allocation Vector Address
	LHLD	caAllocVector
	SHLD	statusBDOSReturn
	RET ;jmp goback


;-----------------------------------------------------------------
;return address of disk parameter block
; OUT - (HL) Disk Parameter Black for current drive
fGetDiskParamBlock:					; func31 (31 - 1F)
	LHLD	caDiskParamBlock
	SHLD	statusBDOSReturn
	RET		;jmp goback
;-----------------------------------------------------------------

SelectCurrent:					; curselect
	LDA	paramE
	LXI	HL,currentDisk
	CMP	M
	RZ					; exit if parame = Current disk
	
	MOV	M,A
	JMP	Select
;*****************************************************************
Select:						; select  - Login Drive
	LHLD	loggedDisks
	LDA	currentDisk
	MOV	C,A
	CALL	ShiftRightHLbyC			; see if we already have drive logged in
	PUSH	HL				; save result
	XCHG					; send to seldsk
	CALL	SelectDisk
	POP	HL				; get back logged disk vector
	CZ	errSelect
	MOV	A,L				; get logged disks
	RAR
	RC					; exit if the disk already logged in
	
	LHLD	loggedDisks			; else log in a differenet disk
	MOV	C,L
	MOV	B,H				; BC has logged disk
	CALL	SetCurrentDiskBit
	SHLD	loggedDisks			; save result
	JMP	InitDisk
						; RET
;*****************************************************************
; select the disk drive given by currentDisk, and fill the base addresses
; caTrack - caAllocVector, then fill the values of the disk parameter block
SelectDisk:					; selectdisk
	LDA	currentDisk
	MOV	C,A				; prepare for Bios Call
	CALL	bcSeldsk
	MOV	A,H				; HL = 0000 if error, otherwise disk headers
	ORA	L
	RZ					; exit if error, with Zflag set
	MOV	E,M
	INX	H
	MOV	D,M				; Disk Header Block pointer in DE
	INX	HL
	SHLD	caDirMaxValue
	INX	HL
	INX	HL
	SHLD	caTrack
	INX	HL
	INX	HL
	SHLD	caSector
	INX	HL
	INX	HL
	XCHG					; DE points at Directory DMA, HL at Skew Table
	SHLD	caSkewTable
	LXI	HL,caDirectoryDMA
	MVI	C,caListSize
	CALL	Move				; finish filling in address list
	
	LHLD	caDiskParamBlock
	XCHG					; DE is source
	LXI	HL,dpbSPT				; start of Disk Parameter Block
	MVI	C,dpbSize
	CALL	Move				; load the table
	LHLD	dpbDSM				; max entry number
	MOV	A,H				; if 00 then < 255
	LXI	HL,single				; point at the single byte entry flag
	MVI	M,TRUE				; assume its less than 255
	ORA	A				; assumtion confirmed ?
	JZ	SelectDisk1			; skip if yes
	MVI	M,FALSE				; correct assumption, set falg to false
	
SelectDisk1:
	MVI	A,TRUE
	ORA	A				; Set Carry and Sign reset Zero
	RET

;---------------
; set a "1" value in currentDisk position of BC
; return in HL
SetCurrentDiskBit:					; set$cdisk
	PUSH	BC				; save input parameter
	LDA	currentDisk
	MOV	C,A				; ready parameter for shift
	LXI	H,1				; number to shift
	CALL	ShiftLeftHLbyC			; HL = mask to integrate
	POP	BC				; original mask
	MOV	A,C
	ORA	L
	MOV	L,A
	MOV	A,B
	ORA	H
	MOV	H,A				; HL = mask or rol(1,currentDisk)
	RET		
;--------------
;set current disk to read only
SetDiskReadOnly:					; set$ro
	LXI	HL,ReadOnlyVector
	MOV	C,M
	INX	HL
	MOV	B,M
	CALL	SetCurrentDiskBit			; sets bit to 1
	SHLD	ReadOnlyVector
						; high water mark in directory goes to max
	LHLD	dpbDRM				; directory max
	XCHG					; DE = directory max
	LHLD	caDirMaxValue			; HL = .Directory max value
	MOV	M,E
	INX	HL
	MOV	M,D				; cdrmax = dpbDRM
	RET
;----------------------- initialize the current disk
; 
;lowReturnStatus = false ;set to true if $ file exists
; compute the length of the allocation vector - 2

InitDisk:						; initialize
	LHLD	dpbDSM				; get max allocation value
	MVI	C,3				; we want dpbDSM/8
						; number of bytes in alloc vector is (dpbDSM/8)+1
	CALL	ShiftRightHLbyC
	INX	HL				; HL = dpbDSM/8+1
	MOV	B,H
	MOV	C,L				; count down BC til zero
	LHLD	caAllocVector ;base of allocation vector
	;fill the allocation vector with zeros
InitDisk0:					; initial0:
	MVI	M,0
	INX	H				; alloc(i)=0
	DCX	BC				; count length down
	MOV	A,B
	ORA	C
	JNZ	InitDisk0
						; set the reserved space for the directory
	LHLD	dpbDABM				; get the directory block
	XCHG
	LHLD	caAllocVector ; HL=.alloc()
	MOV	M,E
	INX	HL
	MOV	M,D				; sets reserved directory blks
						; allocation vector initialized, home disk
	CALL	Home
						; caDirMaxValue = 3 (scans at least one directory record)
	LHLD	caDirMaxValue
	MVI	M,3
	INX	H
	MVI	M,0
						; caDirMaxValue = 0000
	CALL	SetEndDirectory ;dirCounter = EOD
	;	read directory entries and check for allocated storage
InitDisk1:
	MVI	C,TRUE
	CALL	ReadDirectory
	CALL	EndOfDirectory
	RZ					; return if end of directory
						; not end of directory, valid entry?
	CALL	GetDirElementAddress ; HL = caDirectoryDMA + dirPointer
	MVI	A,emptyDir
	CMP	M
	JZ	InitDisk1				; go get another item
						; not emptyDir, user code the same?
	LDA	currentUserNumber
	CMP	M
	JNZ	InitDisk2
						; same user code, check for '$' submit
	INX	H
	MOV	A,M				; first character
	SUI	DOLLAR				; dollar file?
	JNZ	InitDisk2
						; dollar file found, mark in lowReturnStatus
	DCR	A
	STA	lowReturnStatus			; lowReturnStatus = 255
InitDisk2:
						; now scan the disk map for allocated blocks
	MVI	C,1				; set to allocated
	CALL	ScanDiskMap
	CALL	SetDirectoryEntry			; set DirMaxVAlue to dirCounter
	JMP	InitDisk1				; for another entry
;
;-------------Scan the disk map for unallocated entry-----------------------------------
; scan the disk map addressed by dptr for non-zero entries.  The allocation
; vector entry corresponding to a non-zero entry is set to the value of C (0,1)
ScanDiskMap:					; scandm
	CALL	GetDirElementAddress ; HL = buffa + dptr
	 ; HL addresses the beginning of the directory entry
	LXI	DE,diskMap
	DAD	D				; hl now addresses the disk map
	PUSH	BC				; save the 0/1 bit to set
	MVI	C,fcbLength-diskMap+1 ; size of single byte disk map + 1
	
ScanDiskMap0:					; loop once for each disk map entry
	POP	DE				; recall bit parity
	DCR	C
	RZ					; exit when done

	PUSH	DE				; replace bit parity
	LDA	single				; single entry flag
	ORA	A
	JZ	ScanDiskMap1			; skip if two byte value
						; single byte scan operation
	PUSH	BC				; save counter
	PUSH	HL				; save map address
	MOV	C,M
	MVI	B,0				; BC=block#
	JMP ScanDiskMap2
	
ScanDiskMap1:					; two byte scan operation
	DCR	C				; count for double byte
	PUSH	BC				; save counter
	MOV	C,M
	INX	HL
	MOV	B,M				; BC=block#
	PUSH	HL				; save map address
ScanDiskMap2:					; arrive here with BC=block#, E=0/1
	MOV	A,C
	ORA	B				; skip if = 0000
	CNZ	SetAllocBit			; bit set to 0/1 its in C
	POP	HL
	INX	HL				; to next bit position
	POP	BC				; recall counter
	JMP	ScanDiskMap0			; for another item
;
;-----------------------------------
;given allocation vector position BC, return with byte
;containing BC shifted so that the least significant
;bit is in the low order accumulator position.  HL is
;the address of the byte for possible replacement in
;memory upon return, and D contains the number of shifts
;required to place the returned value back into position
GetAllocBit:					; getallocbit
	MOV	A,C
	ANI	111b
	INR	A
	MOV	E,A
	MOV	D,A
						; d and e both contain the number of bit positions to shift
	MOV	A,C
	RRC
	RRC
	RRC
	ANI	11111b
	MOV	C,A				; C shr 3 to C
	MOV	A,B
	ADD	A
	ADD	A
	ADD	A
	ADD	A
	ADD	A				; B shl 5
	ORA	C
	MOV	C,A				; bbbccccc to C
	MOV	A,B
	RRC
	RRC
	RRC
	ANI	11111b
	MOV	B,A				; BC shr 3 to BC
	LHLD	caAllocVector			; base address of allocation vector
	DAD	B
	MOV	A,M				; byte to A, hl = .alloc(BC shr 3)
	 ;now move the bit to the low order position of A
GetAllocBitl:
	RLC
	DCR	E
	JNZ	GetAllocBitl
	RET

;-----------------------------------
; BC is the bit position of ALLOC to set or reset.  The
; value of the bit is in register E.
SetAllocBit:					; setallocbit
	PUSH	DE
	CALL	GetAllocBit			; shifted val A, count in D
	ANI	11111110b				; mask low bit to zero (may be set)
	POP	BC
	ORA	C				; low bit of C is masked into A
	JMP	RotateAndReplace			; to rotate back into proper position
	;ret
;-----------------------------------
; byte value from ALLOC is in register A, with shift count
; in register C (to place bit back into position), and
; target ALLOC position in registers HL, rotate and replace
RotateAndReplace:					; rotr
	RRC
	DCR	D
	JNZ	RotateAndReplace			; back into position
	MOV	M,A				; back to ALLOC
	RET
	;-----------------------------------
	;move to home position, then offset to start of dir
Home:						; home
	CALL	bcHome				; move to track 00, sector 00 reference
	LXI	HL,dpbOFF				; get track ofset at begining
	MOV	C,M
	INX	HL
	MOV	B,M
	CALL	bcSettrk				; select first directory position
	
	XRA	A				; constant zero to accumulator
	LHLD	caTrack
	MOV	M,A
	INX	HL
	MOV	M,A				; curtrk=0000
	LHLD	caSector
	MOV	M,A
	INX	HL
	MOV	M,A				; currec=0000
	RET


;*****************************************************************

;*****************************************************************
;*****************************************************************
; set directory counter to end  -1
SetEndDirectory:					; set$end$dir
	LXI	HL,EOD
	SHLD	dirCounter
	RET
;---------------
SetDataDMA:					; setdata
	LXI	HL,InitDAMAddress
	JMP	SetDMA				; to complete the call
;---------------
SetDirDMA:					; setdir
	LXI	HL,caDirectoryDMA
;	JMP	setdma
SetDMA:						; setdma
	MOV	C,M
	INX	HL
	MOV	B,M				; parameter ready
	JMP	bcSetdma				; call bios to set
;---------------
;---------------
; return zero flag if at end of directory
; non zero if not at end (end of dir if dirCounter = 0ffffh)
EndOfDirectory:					; end$of$dir
	LXI	HL,dirCounter
	MOV	A,M				; may be 0ffh
	INX	HL
	CMP	M				; low(dirCounter) = high(dirCounter)?
	RNZ						; non zero returned if different
						; high and low the same, = 0ffh?
	INR	A				; 0ffh becomes 00 if so
	RET
;---------------
; read a directory entry into the directory buffer
ReadDirRecord:					; rd$dir
	CALL	SetDirDMA				; directory dma
	CALL	ReadBuffer			; directory record loaded
    JMP	SetDataDMA				; to data dma address
	;ret
;---------------
; read next directory entry, with C=true if initializing
ReadDirectory:					; read$dir:
	LHLD	dpbDRM
	XCHG					; in preparation for subtract
	LHLD	dirCounter
	INX	HL
	SHLD	dirCounter			; dirCounter=dirCounter+1
						; continue while dpbDRM >= dirCounter (dpbDRM-dirCounter no cy)
	CALL	DEminusHL2HL			; DE-HL
	JNC	ReadDirectory0
						; yes, set dirCounter to end of directory
	CALL	SetEndDirectory
	RET
	
ReadDirectory0:					; read$dir0:
						; not at end of directory, seek next element
						; initialization flag is in C
	LDA	dirCounter
	ANI	dskmsk				; low(dirCounter) and dskmsk
	MVI	B,fcbshf				; to multiply by fcb size to get the correct index in dir record
ReadDirectory1:					; read$dir1:
	ADD	A
	DCR	B
	JNZ	ReadDirectory1
						; A = (low(dirCounter) and dskmsk) shl fcbshf
	STA	dirPointer			; ready for next dir operation
	ORA	A
	RNZ					; return if not a new record
	PUSH	BC				; save initialization flag C
	CALL	SeekDir				; seek$dir seek proper record
	CALL	ReadDirRecord			; read the directory record
	POP	BC				; recall initialization flag
	JMP	CalculateCheckSum			; checksum the directory elt
	;ret
;---------
	;seek the record containing the current dir entry
SeekDir:						; seekdir seek$dir
	LHLD	dirCounter			; directory counter to HL
	MVI	C,dskshf				; 4 entries per CP/M sector ?
	CALL	ShiftRightHLbyC ; value to HL
	SHLD	currentRecord
	SHLD	dirRecord ;ready for seek
	JMP	Seek
	;ret

;---------------------------
Seek:						; seek
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
	
	LXI	HL,currentRecord
	MOV	C,M				; arecl,m
	INX	HL
	MOV	B,M				; arech,m
	LHLD	caSector 				; physical record
	MOV	E,M				; crecl,m
	INX	HL
	MOV	D,M				; crech,m
	LHLD	caTrack 
	MOV	A,M
	INX	HL
	MOV	H,M				; ctrkh,M
	MOV	L,A				; ctrkl,a
;(BC) - Record Count
;(DE) - Current Sector
;(HL) - Current Track
	;loop while currentRecord < currec
Seek0:
	MOV	A,C				; a,arecl
	SUB	E				; crecl
	MOV	A,B				; a,arech
	SBB	D				; crech
	JNC	Seek1				; skip if currentRecord >= currec
						; currec = currec - dpbSPT
	PUSH	HL				; ctrkh
	LHLD	dpbSPT				; sectors per track
	MOV	A,E				; a,crecl
	SUB	L
	MOV	E,A				; crecl,a
	MOV	A,D				; a,crech
	SBB	H
	MOV	D,A				; crech,a
	POP	HL				; ctrkh
						; curtrk = curtrk - 1
	DCX	HL				; ctrkh
	JMP	Seek0				; for another try
	
Seek1:
	;look while currentRecord >= (t:=currec + dpbSPT)
	PUSH	HL				; ctrkh
	LHLD	dpbSPT				; sectors per track
	DAD	D				; crech ;HL = currec+dpbSPT
	MOV	A,C				; a,arecl
	SUB	L				; tcrecl
	MOV	A,B				; a,arech
	SBB	H				; tcrech
	JC	Seek2				; skip if t > currentRecord
						; currec = t
	XCHG
						; curtrk = curtrk + 1
	POP	HL				; ctrkh
	INX	HL				; ctrkh
	JMP	Seek1				; for another try
	
Seek2:
	POP	HL				; ctrkh
						; arrive here with updated values in each register
	PUSH	BC				; arech
	PUSH	DE				; crech
	PUSH	HL				; ctrkh ;to stack for later
						; stack contains (lowest) BC=currentRecord, DE=currec, HL=curtrk
	XCHG
	LHLD	dpbOFF				; offset tracks at beginning
	DAD	D				; HL = curtrk+dpbOFF
	MOV	B,H
	MOV	C,L
	CALL	bcSettrk				; track set up
						; note that BC - curtrk is difference to move in bios
	POP	DE				; recall curtrk
	LHLD	caTrack
	MOV	M,E
	INX	H
	MOV	M,D				; curtrk updated
						; now compute sector as currentRecord-currec
	POP	DE				; crech ;recall currec
	LHLD	caSector
	MOV	M,E				; m,crecl
	INX	HL
	MOV	M,D				; m,crech
	POP	BC				; arech ;BC=currentRecord, DE=currec
	MOV	A,C				; a,arecl
	SUB	E				; crecl
	MOV	C,A				; arecl,a
	MOV	A,B				; a,arech
	SBB	D				; crech
	MOV	B,A				; arech,a
	LHLD	caSkewTable
	XCHG					; BC=sector#, DE=.tran
	CALL	bcSectran				; HL = tran(sector)
	MOV	C,L
	MOV	B,H				; BC = tran(sector)
	JMP	bcSetsec				; sector selected
	;ret	
;************* CheckSum *******************************
; compute current checksum record
; and update the directory element if C=true 
; or check for = if not dirRecord < dpbCKS?
NewCheckSum:					; newchecksum
	MVI	C,TRUE				; drop thru
CalculateCheckSum:					; checksum
	LHLD dirRecord
	XCHG
	LHLD	dpbCKS				; size of checksum vector
	CALL	DEminusHL2HL			; DE-HL
	RNC					; skip checksum if past checksum vector size
						; dirRecord < dpbCKS, so continue
	PUSH	BC				; save init flag
	CALL	ComputeCheckSum			; check sum value to A
	LHLD	caCheckSum			; address of check sum vector
	XCHG
	LHLD	dirRecord				; value of dirRecord
	DAD	D				; HL = .check(dirRecord)
	POP	BC				; recall true=0ffh or false=00 to C
	INR	C				; 0ffh produces zero flag
	JZ	SetNewCheckSum
						; not initializing, compare
	CMP	M				; compute$cs=check(dirRecord)?
	RZ					; no message if ok
						; possible checksum error, are we beyond
						; the end of the disk?
	CALL	StillInDirectory
	RNC					; no message if so
	CALL	SetDiskReadOnly			; read/only disk set
	RET
	
;initializing the checksum
SetNewCheckSum:					; initial$cs:
	MOV	M,A
	RET
;------------------
;compute checksum for current directory buffer
ComputeCheckSum:					; compute$cs
	MVI	C,recordSize			; size of directory buffer
	LHLD	caDirectoryDMA			; current directory buffer
	XRA	A				; clear checksum value
ComputeCheckSum0:
	ADD	M
	INX	H
	DCR	C				; cs=cs+buff(recordSize-C)
	JNZ	ComputeCheckSum0
	RET					; with checksum in A
;*****************************************************************
; compute the address of a directory element at positon dirPointer in the buffer
GetDirElementAddress:				; getdptra
	LHLD	caDirectoryDMA
	LDA	dirPointer
	JMP	AddAtoHL
;---------------------
;if not still in directory set max value
SetDirectoryEntry:					; setcdr:
	CALL	StillInDirectory
	RC					; return if yes
						; otherwise, HL = DirMaxValue+1, DE = directoryCount
	INX	D
	MOV	M,D
	DCX	H
	MOV	M,E
	RET
; return CY if entry is still in Directory
StillInDirectory:					; compcdr
	LHLD	dirCounter
	XCHG					; DE = directory counter
	LHLD	caDirMaxValue			; HL=caDirMaxValue
	MOV	A,E
	SUB	M				; low(dirCounter) - low(cdrmax)
	INX	H				; HL = .cdrmax+1
	MOV	A,D
	SBB	M				; hi(dirCounter) - hig(cdrmax)
	;condition dirCounter - cdrmax  produces cy if cdrmax>dirCounter
	RET
;---------------------
;compute reccnt and nxtrec addresses for get/setfcb
GetFcbAddress:					; getfcba
	LHLD	paramDE
	LXI	DE,reccnt
	DAD	DE
	XCHG					; DE=.fcb(reccnt)
	LXI	HL,(nxtrec-reccnt)
	DAD	DE				; HL=.fcb(nxtrec)
	RET
;---------------------
;set variables from currently addressed fcb
SetFcbVariables:					; getfcb
	CALL	GetFcbAddress			; addresses in DE, HL
	MOV	A,M
	STA	vrecord 				; vrecord=fcb(nxtrec)
	XCHG
	MOV	A,M
	STA	rcount				; rcount=fcb(reccnt)
	CALL	GetExtentAddress			; HL=.fcb(extnum)
	LDA	dpbEXM				; extent mask to a
	ANA	M				; fcb(extnum) and dpbEXM
	STA	extval				; save extent number
	RET
;---------------------
;set variables from currently addressed fcb
PutFcbVariables:					; setfcb
	CALL	GetFcbAddress			; addresses to DE, HL
	LDA	seqReadFlag
	MOV	C,A				; =1 if sequential i/o
	LDA	vrecord
	ADD	C
	MOV	M,A				; fcb(nxtrec)=vrecord+seqReadFlag
	XCHG
	LDA	rcount
	MOV	M,A				; fcb(reccnt)=rcount
	RET
;*****************************************************************

;*****************************************************************
;********************** File  Routines ***************************
;*****************************************************************
;open file
; IN  - (DE)	FCB Address
; OUT - (A)	Directory Code
;	0-3 = success ; 0FFH = File Not Found
fOpenFile:					; 
	CALL	ClearModuleNum			; clear the module number
	CALL	Reselect				; do we need to reselect disk?
	JMP	OpenFile
	;ret ;jmp goback
;-----------------------------------------------------------------
;close file
fCloseFile:					; func16: (16 - 10) Close File
	CALL	Reselect
	JMP	CloseDirEntry
;-----------------------------------------------------------------
;search for first occurrence of a file
; In - (DE)	FCB Address
; OUT - (A)	Directory Code
;	0-3 = success ; 0FFH = File Not Found
fFindFirst:					; func17: (17 - 11) Search for first
	MVI	C,0				; length assuming '?' true
	LHLD	paramDE
	MOV	A,M
	CPI	QMARK				; no reselect if ?
	JZ	QMarkSelect			; skip reselect if so

	CALL	ClearModuleNum			; module number zeroed
	CALL	Reselect
	MVI	C,nameLength
QMarkSelect:					; qselect:
	CALL	Search4DirElement
	JMP	CopyDirEntryToUser			; copy directory entry to user
	;ret ;jmp goback
;-----------------------------------------------------------------
;search for next occurrence of a file name
; OUT - (A)	Directory Code
;	0-3 = success ; 0FFH = File Not Found
fFindNext:					; func18: (18 - 12) Search for next
	LHLD	searchAddress
	SHLD	paramDE
	CALL	Reselect
	CALL	Search4NextDirElement
	JMP	CopyDirEntryToUser			; copy directory entry to user
;-----------------------------------------------------------------
;search for next occurrence of a file name
; OUT - (A)	Directory Code
;delete a file
fDeleteFile:					; func18: (19 - 13) Delete File
	CALL	Reselect
	CALL	DeleteFile
	JMP	DirLocationToReturnLoc
;-----------------------------------------------------------------
;read sequential 
;IN  - (DE) FCB address
;OUT - (A) 00 = success and data available. else no read and no data
fReadSeq:						; func20: (20 - 14) read sequential
	CALL	Reselect
	CALL	ReadSeq
	RET					; jmp goback
;-----------------------------------------------------------------
;write sequential 
;IN  - (DE) FCB address
;OUT - (A) 00 = success and data available. else no read and no data
fWriteSeq:					; func21 (21 - 15) write sequention
	CALL	Reselect
	CALL	DiskWriteSeq
	RET	;jmp goback

;-----------------------------------------------------------------
; Make file 
; In - (DE)	FCB Address
; OUT - (A)	Directory Code
;	0-3 = success ; 0FFH = File Not Found
fMakeFile:						; func22 (22 - 16) Make file
	CALL	ClearModuleNum
	CALL	Reselect
	JMP	MakeNewFile
	;ret ;jmp goback
;-----------------------------------------------------------------
; Rename file 
; In - (DE)	FCB Address
; OUT - (A)	Directory Code
;	0-3 = success ; 0FFH = File Not Found
fRenameFile:						; func23 (23 - 17) Rename File
	CALL	Reselect
	CALL	Rename
	JMP	DirLocationToReturnLoc

;-----------------------------------------------------------------
;-----------------------------------------------------------------
;*****************************************************************
;-----------------------------------------------------------------
;check current directory element for read/only status
CheckRODirectory:					; check$rodir
	CALL	GetDirElementAddress		; address of element
;	JMP	CheckROFile
;------------
;check current buff(dptr) or fcb(0) for r/o status
CheckROFile:					; check$rofile
	LXI	DE,rofile
	DAD	DE				; offset to ro bit
	MOV	A,M
	RAL
	RNC					; return if not set
	JMP	 errReadOnlyFile			; exit to read only disk message
;-----------------------------------------------------------------
;check for write protected disk
CheckWrite:					; check$write
	CALL	DoNotWrite
	RZ					; ok to write if not rodsk
	JMP	errReadOnlyDisk			; read only disk error

;-----------------------------------------------------------------
;return true if dir checksum difference occurred
DoNotWrite:					; nowrite
	LHLD	ReadOnlyVector
	LDA	currentDisk
	MOV	C,A
	CALL	ShiftRightHLbyC
	MOV	A,L
	ANI	1BH				; 1b
	RET					; non zero if nowrite
;
;-----------------------------------------------------------------
;sequential disk read operation
ReadSeq:						; seqdiskread
	MVI	A,1
	STA	seqReadFlag			; set flag for seqential read
;---
; read the disk
DiskRead:						; diskread
	MVI	A,TRUE
	STA	readModeFlag			; read mode flag = true (OpenNextExt)
						; read the next record from the current fcb
	CALL	SetFcbVariables			; sets parameters for the read
	LDA	vrecord
	LXI	HL,rcount
	CMP	M				; vrecord-rcount
						; skip if rcount > vrecord
	JC	RecordOK
						; not enough records in the extent
						; record count must be 128 to continue
	CPI	128				; vrecord = 128?
	JNZ	DiskEOF				; skip if vrecord<>128
	CALL	OpenNextExt			; go to next extent if so
	XRA	A
	STA	vrecord				; vrecord=00
						; now check for open ok
	LDA	lowReturnStatus
	ORA	A
	JNZ	DiskEOF				; stop at eof
RecordOK:						; recordok:
						; arrive with fcb addressing a record to read
	CALL	GetBlockNumber
						; error 2 if reading unwritten data
						; (returns 1 to be compatible with 1.4)
	CALL	IsAllocated			; currentRecord=0000?
	JZ	DiskEOF
						; record has been allocated, read it
	CALL	SetActualRecordAdd			; currentRecord now a disk address
	CALL	Seek				; to proper track,sector
	CALL	ReadBuffer			; to dma address
	CALL	PutFcbVariables			; replace parameters
	RET
DiskEOF:						; diskeof:
	JMP	SetLowReturnTo1			; lowReturnStatus = 1
	;ret
;-----------------------------------------------------------------
;sequential disk write
DiskWriteSeq:					; seqdiskwrite
	MVI	A,1
	STA seqReadFlag
;--------
;disk write
DiskWrite:					; diskwrite
	MVI	A,FALSE
	STA	readModeFlag
						; write record to currently selected file
	CALL	CheckWrite			; in case write protected
	LHLD	paramDE				; HL = .fcb(0)
	CALL	CheckROFile			; may be a read-only file
	CALL	SetFcbVariables			; to set local parameters
	LDA	vrecord
	CPI	lastRecordNumber + 1		; vrecord-128
						; skip if vrecord > lastRecordNumber
	JC	DiskWrite1
						; vrecord = 128, cannot open next extent
	CALL	SetLowReturnTo1
	RET					; lowReturnStatus = 1
DiskWrite1:					; diskwr0:
						; can write the next record, so continue
	CALL	GetBlockNumber
	CALL	IsAllocated
	MVI	C,0				; marked as normal write operation for WriteBuffer
	JNZ	DiskWrite3
						; not allocated
						; the argument to getblock is the starting
						; position for the disk search, and should be
						; the last allocated block for this file, or
						; the value 0 if no space has been allocated
	CALL	ComputeDmPosition
	STA	diskMapIndex			; save for later
	LXI	BC,0000h				; may use block zero
	ORA	A
	JZ	FirstBlock			; skip if no previous block
						; previous block exists at A
	MOV	C,A
	DCX	BC				; previous block # in BC
	CALL	GetDiskMapValue			; previous block # to HL
	MOV	B,H
	MOV	C,L				; BC=prev block#
FirstBlock:					; nopblock:
						; BC = 0000, or previous block #
	CALL	GetClosestBlock			; block # to HL
						; arrive here with block# or zero
	MOV	A,L
	ORA	H
	JNZ	BlockOK
						; cannot find a block to allocate
	MVI	A,2
	STA	lowReturnStatus
	RET					; lowReturnStatus=2
	
BlockOK:						; blockok:
						; allocated block number is in HL
	SHLD	currentRecord
	XCHG					; block number to DE
	LHLD	paramDE
	LXI	BC,diskMap
	DAD	BC				; HL=.fcb(diskMap)
	LDA	single
	ORA	A				; set flags for single byte dm
	LDA	diskMapIndex			; recall dm index
	JZ	Allocate16Bit			; skip if allocating word
						; else allocate using a byte value
	CALL	AddAtoHL
	MOV	M,E				; single byte alloc
	JMP	DiskWrite2			; to continue
Allocate16Bit:					; allocwd:
						; allocate a word value
	MOV	C,A
	MVI	B,0				; double(diskMapIndex)
	DAD	BC
	DAD	BC				; HL=.fcb(diskMapIndex*2)
	MOV	M,E
	INX	HL
	MOV	M,D				; double wd
DiskWrite2:					; diskwru:
						; disk write to previously unallocated block
	MVI	C,2				; marked as unallocated write
DiskWrite3:					; diskwr1:
						; continue the write operation of no allocation error
						; C = 0 if normal write, 2 if to prev unalloc block
	LDA	lowReturnStatus
	ORA	A
	RNZ					; stop if non zero returned value
	PUSH	BC				; save write flag
	CALL	SetActualRecordAdd			; currentRecord set
	CALL	Seek				; to proper file position
	POP	BC
	PUSH	BC				; restore/save write flag (C=2 if new block)
	CALL	WriteBuffer			; written to disk
	POP	BC				; C = 2 if a new block was allocated, 0 if not
						; increment record count if rcount<=vrecord
	LDA	vrecord
	LXI	HL,rcount
	CMP	M ;vrecord-rcount
	JC	DiskWrite4
						; rcount <= vrecord
	MOV	M,A
	INR	M				; rcount = vrecord+1
	MVI	C,2				; mark as record count incremented
DiskWrite4:					; diskwr2:
						; A has vrecord, C=2 if new block or new record#
	DCR	C
	DCR	C
	JNZ	DiskWrite5
	PUSH	PSW				; save vrecord value
	CALL	GetModuleNum			; HL=.fcb(modnum), A=fcb(modnum)
						; reset the file write flag to mark as written fcb
		
;XXXXXXXXXXXXX ani (not fwfmsk) and 0ffh		; bit reset
	ANI	7FH				; not fwfmsk
		
	MOV	M,A				; fcb(modnum) = fcb(modnum) and 7fh
	POP	PSW				; restore vrecord
DiskWrite5:					; noupdate:
						; check for end of extent, if found attempt to open
						; next extent in preparation for next write
	CPI	lastRecordNumber			; vrecord=lastRecordNumber?
	JNZ	DiskWrite7			; skip if not
						; may be random access write, if so we are done
	LDA	seqReadFlag
	ORA	A
	JZ	DiskWrite7			; skip next extent open op
						; update current fcb before going to next extent
	CALL	PutFcbVariables
	CALL	OpenNextExt			; readModeFlag=false
						; vrecord remains at lastRecordNumber causing eof if
						; no more directory space is available
	LXI	HL,lowReturnStatus
	MOV	A,M
	ORA	A
	JNZ	DiskWrite6			; no space
						; space available, set vrecord=255
	DCR	A
	STA	vrecord				; goes to 00 next time
DiskWrite6:					; nospace:
	MVI	M,0				; lowReturnStatus = 00 for returned value
DiskWrite7:					; diskwr3:
	JMP	PutFcbVariables ;replace parameters
	;ret
;-----------------------------------------------------------------
;close the current extent  and open the next one if possible.
;readModeFlag is true if in read mode
OpenNextExt:					; open$reel
	XRA	A
	STA	fcbCopiedFlag			; set true if actually copied
	CALL	CloseDirEntry			; close current extent
						; lowReturnStatus remains at enddir if we cannot open the next ext
	CALL	EndOfDirectory
	RZ					; return if end
						; increment extent number
	LHLD	paramDE
	LXI	BC,extnum
	DAD	BC				; HL=.fcb(extnum)
	MOV	A,M
	INR	A
	ANI	maxext
	MOV	M,A				; fcb(extnum)=++1
	JZ	OpenNextModule			; move to next module if zero
						; may be in the same extent group
	MOV	B,A
	LDA	dpbEXM
	ANA	B
						; if result is zero, then not in the same group
	LXI	HL,fcbCopiedFlag			; true if the fcb was copied to directory
	ANA	M 				; produces a 00 in accumulator if not written
	JZ	OpenNextExt1			; go to next physical extent
						; result is non zero, so we must be in same logical ext
	JMP	OpenNextExt2			; to copy fcb information
OpenNextModule:					; open$mod
						; extent number overflow, go to next module
	LXI	BC,(modnum-extnum)
	DAD	BC				; HL=.fcb(modnum)
	INR	M				; fcb(modnum)=++1
						; module number incremented, check for overflow
	MOV	A,M
	ANI	maxmod				; mask high order bits
	JZ	OpenNextExtError			; cannot overflow to zero
						; otherwise, ok to continue with new module
OpenNextExt1:					; open$reel0
	MVI	C,nameLength
	CALL	Search4DirElement			; next extent found?
	CALL	EndOfDirectory
	JNZ	OpenNextExt2
						; end of file encountered
	LDA	readModeFlag
	INR	A				; 0ffh becomes 00 if read
	JZ	OpenNextExtError			; sets lowReturnStatus = 1
	`					; try to extend the current file
	CALL	MakeNewFile
						; cannot be end of directory
	CALL	EndOfDirectory
	JZ	OpenNextExtError			; with lowReturnStatus = 1
	JMP	OpenNextExt3
OpenNextExt2:					; open$reel1:
						; not end of file, open
	CALL	OpenFileCopyFCB
OpenNextExt3:					; open$reel2:
	CALL	SetFcbVariables			; set parameters
	XRA	A
	STA	lowReturnStatus			; lowReturnStatus = 0
	RET					; with lowReturnStatus = 0
	
OpenNextExtError:					; open$r$err:
						; cannot move to next extent of this file
	CALL	SetLowReturnTo1			; lowReturnStatus = 1
	JMP	SetFileWriteFlag			; ensure that it will not be closed
;-----------------------------------------------------------------
;rename the file described by the first half of the currently addressed FCB.
;the new name is contained in the last half of the FCB. The file name and type
;are changed, but the reel number is ignored.  the user number is identical
Rename:						; rename
	CALL	CheckWrite			; may be write protected
						; search up to the extent field
	MVI	C,extnum				; extent number field index
	CALL	Search4DirElement
						; copy position 0
	LHLD	paramDE
	MOV	A,M				; HL=.fcb(0), A=fcb(0)
	LXI	DE,diskMap
	DAD	DE				; HL=.fcb(diskMap)
	MOV	M,A				; fcb(diskMap)=fcb(0)
						; assume the same disk drive for new named file
Rename1:						; rename0:
	CALL	EndOfDirectory
	RZ					; stop at end of dir
						; not end of directory, rename next element
	CALL	CheckRODirectory			; may be read-only file
	MVI	C,diskMap
	MVI	E,extnum
	CALL	CopyDir
						; element renamed, move to next
	CALL	Search4NextDirElement
	JMP	Rename1
;-----------------------------------------------------------------
;create a new file by creating a directory entry then opening the file
MakeNewFile:					; make
	CALL	CheckWrite			; may be write protected
	LHLD	paramDE
	PUSH	HL				; save fcb address, look for e5
	LXI	HL,emptyFCB
	SHLD	paramDE				; paramDE = .empty
	MVI	C,1
	CALL	Search4DirElement			; length 1 match on empty entry
	CALL	EndOfDirectory			; zero flag set if no space
	POP	HL				; recall paramDE address
	SHLD	paramDE				; in case we return here
	RZ					; return with error condition 255 if not found
	XCHG					; DE = paramDE address
						; clear the remainder of the fcb
	LXI	HL,nameLength
	DAD	DE				; HL=.fcb(nameLength)
	MVI	C,fcbLength-nameLength		; number of bytes to fill
	XRA	A				; clear accumulator to 00 for fill
MakeNewFile1:					; make0:
	MOV	M,A
	INX	HL
	DCR	C
	JNZ	MakeNewFile1
	LXI	HL,unFilledBytes
	DAD	DE				; HL = .fcb(unFilledBytes)
	MOV	M,A				; fcb(unFilledBytes) = 0
	CALL	SetDirectoryEntry			; may have extended the directory
						; now copy entry to the directory
	CALL	CopyFCB
						; and set the file write flag to "1"
	JMP	SetFileWriteFlag
;-----------------------------------------------------------------
;delete the currently addressed file
DeleteFile:					; delete
	CALL	CheckWrite			; write protected ?
	MVI	C,extnum				; extent number field
	CALL	Search4DirElement			; search through file type
DeleteFile1:					; delete0:
						; loop while directory matches
	CALL	EndOfDirectory
	RZ					; stop if end
						; set each non zero disk map entry to 0
						; in the allocation vector
						; may be r/o file
	CALL	CheckRODirectory			; ro disk error if found
	CALL	GetDirElementAddress		; HL=.buff(dptr)
	MVI	M,emptyDir
	MVI	C,0
	CALL	ScanDiskMap			; alloc elts set to 0
	CALL	WriteDir				; write the directory
	CALL	Search4NextDirElement		; to next element
	JMP	DeleteFile1			; for another record
;-----------------------------------------------------------------
;locate the directory element and re-write it
CloseDirEntry:					; close
	XRA	A
	STA	lowReturnStatus
	CALL	DoNotWrite			; return TRUE (0) if checksum change
	RNZ					; skip close if r/o disk
						; check file write flag - 0 indicates written
	CALL	GetModuleNum			; fcb(modnum) in A
	ANI	fwfmsk
	RNZ					; return if bit remains set
	MVI	C,nameLength
	CALL	Search4DirElement			; locate file
	CALL	EndOfDirectory
	RZ					; return if not found
						; merge the disk map at paramDE with that at buff(dptr)
	LXI	BC,diskMap
	CALL	GetDirElementAddress
	DAD	BC
	XCHG					; DE is .buff(dptr+16)
	LHLD	paramDE
	DAD	BC				; DE=.buff(dptr+16), HL=.fcb(16)
	MVI	C,(fcbLength-diskMap)			; length of single byte dm
CloseDirEntry1:					; merge0:
	LDA	single
	ORA	A
	JZ	CloseDirEntry4			; skip to double
						; this is a single byte map
						; if fcb(i) = 0 then fcb(i) = buff(i)
						; if buff(i) = 0 then buff(i) = fcb(i)
						; if fcb(i) <> buff(i) then error
	MOV	A,M
	ORA	A
	LDAX	D
	JNZ	CloseDirEntry2
						; fcb(i) = 0
	MOV	M,A				; fcb(i) = buff(i)
CloseDirEntry2:					; fcbnzero:
	ORA	A
	JNZ	CloseDirEntry3
						; buff(i) = 0
	MOV	A,M
	STAX	DE				; buff(i)=fcb(i)
CloseDirEntry3:					; buffnzero:
	CMP	M
	JNZ	CloseDirEntryError			; fcb(i) = buff(i)?
	JMP	CloseDirEntry5			; if merge ok
CloseDirEntry4:					; merged:
						; this is a double byte merge operation
	CALL	Merge				; buff = fcb if buff 0000
	XCHG
	CALL	Merge
	XCHG					; fcb = buff if fcb 0000
						; they should be identical at this point
	LDAX	DE
	CMP	M
	JNZ	CloseDirEntryError			; low same?
	INX	DE
	INX	HL				; to high byte
	LDAX	DE
	CMP	M
	JNZ	CloseDirEntryError			; high same?
						;	merge operation ok for this pair
	DCR	C				; extra count for double byte
CloseDirEntry5:					; dmset:
	INX	DE
	INX	HL				; to next byte position
	DCR	C
	JNZ	CloseDirEntry1			; for more
						; end of disk map merge, check record count
						; DE = .buff(dptr)+32, HL = .fcb(32)
	LXI	BC,-(fcbLength-extnum)
	DAD	BC
	XCHG
	DAD	BC
						; DE = .fcb(extnum), HL = .buff(dptr+extnum)
	LDAX	DE				; current user extent number
						; if fcb(ext) >= buff(fcb) then
						;	buff(ext) := fcb(ext), buff(rec) := fcb(rec)
	CMP	M
	JC	CloseDirEntryEnd
						; fcb extent number >= dir extent number
	MOV	M,A				; buff(ext) = fcb(ext)
						; update directory record count field
	LXI	BC,(reccnt-extnum)
	DAD	BC
	XCHG
	DAD	BC
						; DE=.buff(reccnt), HL=.fcb(reccnt)
	MOV	A,M
	STAX	DE				; buff(reccnt)=fcb(reccnt)
CloseDirEntryEnd:					; endmerge:
	MVI	A,TRUE
	STA	fcbCopiedFlag			; mark as copied
	CALL	SeekCopy				; ok to "WriteDir" here - 1.4 compat
	RET
CloseDirEntryError:					; mergerr:
						; elements did not merge correctly
	LXI	HL,lowReturnStatus
	DCR	M				; =255 non zero flag set
	RET
;-----------------------------------------------------------------
;enter from CloseDirEntry to seek and copy current element
SeekCopy:						; seek$copy
	CALL	SeekDir				; to the directory element
	JMP	WriteDir				; write the directory element
	;ret
;-----------------------------------------------------------------
;write the current directory entry, set checksum
WriteDir:						; wrdir
	CALL	NewCheckSum			; initialize entry
	CALL	SetDirDMA				; directory dma
	MVI	C,1				; indicates a write directory operation
	CALL	WriteBuffer			; write the buffer
	JMP	SetDataDMA			; to data dma address
	;ret
;-----------------------------------------------------------------
;write buffer and check condition
;write type (wrtype) is in register C
;wrtype = 0 => normal write operation
;wrtype = 1 => directory write operation
;wrtype = 2 => start of new block
WriteBuffer:					; wrbuff
	CALL	bcWrite				; current drive, track, sector, dma
	ORA	A
	JNZ	erPermanentNoWait			; error if not 00
	RET
;-----------------------------------------------------------------
;read buffer and check condition
;read buffer and check condition
ReadBuffer:					; rdbuff
	CALL	bcRead				; current drive, track, sector, dma
	ORA	A
	JNZ	erPermanentNoWait
	RET
;-----------------------------------------------------------------
;HL = .fcb1(i), DE = .fcb2(i),
;if fcb1(i) = 0 then fcb1(i) := fcb2(i)

Merge:						; mergezero
	MOV	A,M
	INX	HL
	ORA	M
	DCX	HL
	RNZ					; return if = 0000
	LDAX	DE
	MOV	M,A
	INX	DE
	INX	HL				; low byte copied
	LDAX	DE
	MOV	M,A
	DCX	DE
	DCX	HL				; back to input form
	RET
;-----------------------------------------------------------------
;compute closest disk block number from current block
;given allocation vector position BC, find the zero bit closest to this position
;by searching left and right.
;if found, set the bit to one and return the bit position in hl.
;if not found (i.e., we pass 0 on the left, or dpbDSM on the right), return 0000 in hl
GetClosestBlock:					; get$block
	MOV	D,B
	MOV	E,C				; copy of starting position to de
TestLeft:						; lefttst:
	MOV	A,C
	ORA	B
	JZ	TestRight				; skip if left=0000
						; left not at position zero, bit zero?
	DCX	BC
	PUSH	DE
	PUSH	BC				; left,right pushed
	CALL	GetAllocBit
	RAR
	JNC	ReturnBlockNumber			; return block number if zero
						; bit is one, so try the right
	POP	BC
	POP	DE				; left, right restored
TestRight:					; righttst:
	LHLD	dpbDSM				; value of maximum allocation#
	MOV	A,E
	SUB	L
	MOV	A,D
	SBB	H				; right=dpbDSM?
	JNC	ReturnBlockZero			; return block 0000 if so
	INX	DE
	PUSH	B
	PUSH	D				; left, right pushed
	MOV	B,D
	MOV	C,E				; ready right for call
	CALL	GetAllocBit
	RAR
	JNC	ReturnBlockNumber			; return block number if zero
	POP	DE
	POP	BC ;restore left and right pointers
	JMP	TestLeft ;for another attempt
ReturnBlockNumber:					; retblock:
	RAL
	INR	A				; bit back into position and set to 1
						; d contains the number of shifts required to reposition
	CALL	RotateAndReplace			; move bit back to position and store
	POP	HL
	POP	DE ;HL returned value, DE discarded
	RET
	
ReturnBlockZero:					; retblock0:
						; cannot find an available bit, return 0000
	LXI	HL,0000H
	RET
;-----------------------------------------------------------------
;compute disk block number from current fcb
GetBlockNumber:					; index
	CALL	ComputeDmPosition			; 0...15 in register A
	MOV	C,A
	MVI	B,0
	CALL	GetDiskMapValue			; value to HL
	SHLD	currentRecord
	RET
;-----------------------------------------------------------------
;is  block allocated
IsAllocated:					; allocated
	LHLD	currentRecord
	MOV	A,L
	ORA	H
	RET
;-----------------------------------------------------------------
;compute actual record address
SetActualRecordAdd:					; atran
	LDA	dpbBSH				; shift count to reg A
	LHLD	currentRecord
SetActualRecordAdd1:				; atran0:
	DAD	HL
	DCR	A
	JNZ	SetActualRecordAdd1			; shl(currentRecord,dpbBSH)
	LDA	dpbBLM				; get block mask
	MOV	C,A				; mask value to C
	LDA	vrecord
	ANA	C				; masked value in A
	ORA	L
	MOV	L,A				; to HL
	SHLD	currentRecord			; currentRecord=HL or (vrecord and dpbBLM)
	RET
;-----------------------------------------------------------------
;---------------------
;copy directory location to lowReturnStatus
DirLocationToReturnLoc:				; copy$dirloc
	LDA	directoryFlag
	STA	lowReturnStatus
	RET
;---------------------

;clear the module number field for user open/make (S2)
ClearModuleNum:					; clrmodnum
	CALL	GetModuleNum
	MVI	M,0				; fcb(modnum)=0
	RET
;---------------------
;get data module number (high order bit is fwf -file write flag)
GetModuleNum:					; getmodnum
	LHLD	paramDE
	LXI	DE,modnum
	DAD	DE				; HL=.fcb(modnum)
	MOV	A,M
	RET					; A=fcb(modnum)
;---------------------
;check current fcb to see if reselection necessary
Reselect:						; reselect
	MVI	A,TRUE
	STA	fResel	;mark possible reselect
	LHLD	paramDE
	MOV	A,M				; drive select code
	ANI	00011111B				; non zero is auto drive select
	DCR	A				; drive code normalized to 0..30, or 255
	STA	paramE				; save drive code
	CPI	30
	JNC	NoSelect
						; auto select function, save currentDisk
	LDA	currentDisk
	STA	entryDisk				; entryDisk=currentDisk
	MOV	A,M
	STA	fcbDisk				; save drive code
	ANI	11100000B
	MOV	M,A				; preserve hi bits
	CALL	SelectCurrent
NoSelect:						; noselect:
	
	LDA	currentUserNumber			; set user code 0...31
	LHLD	paramDE
	ORA	M
	MOV	M,A
	RET
;---------------------
;search for the directory entry, copy to fcb
OpenFile:						; open
	MVI	C,nameLength
	CALL	Search4DirElement
	CALL	EndOfDirectory
	RZ					; return with lowReturnStatus=255 if end
						; not end of directory, copy fcb information
OpenFileCopyFCB:					; open$copy
	;(referenced below to copy fcb info)
	CALL	GetExtentAddress
	MOV	A,M
	PUSH	PSW
	PUSH	HL				; save extent#
	CALL	GetDirElementAddress
	XCHG					; DE = .buff(dptr)
	LHLD	paramDE				; HL=.fcb(0)
	MVI	C,nxtrec				; length of move operation
	PUSH	DE				; save .buff(dptr)
	CALL	Move				; from .buff(dptr) to .fcb(0)
						; note that entire fcb is copied, including indicators
	CALL	SetFileWriteFlag			; sets file write flag
	POP	DE
	LXI	HL,extnum
	DAD	DE				; HL=.buff(dptr+extnum)
	MOV	C,M				; C = directory extent number
	LXI	HL,reccnt				; point at the record Count field
	DAD	DE				; HL=.buff(dptr+reccnt)
	MOV	B,M				; B holds directory record count
	POP	HL
	POP	PSW
	MOV	M,A				; restore extent number
						; HL = .user extent#, B = dir rec cnt, C = dir extent#
						; if user ext < dir ext then user := 128 records
						; if user ext = dir ext then user := dir records
						; if user ext > dir ext then user := 0 records
	MOV	A,C
	CMP	M
	MOV	A,B				; ready dir reccnt
	JZ	OpenRecordCount			; if same, user gets dir reccnt
	MVI	A,0
	JC	OpenRecordCount			; user is larger
	MVI	A,128				; directory is larger
OpenRecordCount:					; open$rcnt  has record count to fill
	LHLD	paramDE
	LXI	DE,reccnt
	DAD	DE
	MOV	M,A
	RET

;---------------------
;search for directory element of length C at info
Search4DirElement:					; search
	MVI	A,0FFH
	STA	directoryFlag			; changed if actually found
	LXI	HL,searchLength
	MOV	M,C				; searchLength = C
	LHLD	paramDE
	SHLD	searchAddress			; searchAddress = paramDE
	CALL	SetEndDirectory			; dirCounter = enddir
	CALL	Home				; to start at the beginning
	JMP	Search4NextDirElement
;---------------------
;search for the next directory element, assuming a previous
;call on search which sets searchAddress and searchLength
Search4NextDirElement:				; searchn
	MVI	C,FALSE
	CALL	ReadDirectory			; read next dir element
	CALL	EndOfDirectory
	JZ	SearchDone			; skip to end if so
						; not end of directory, scan for match
	LHLD	searchAddress
	XCHG					; DE=beginning of user fcb
	LDAX	DE				; first character
	CPI	emptyDir				; keep scanning if Dir entry is empty
	JZ	Search4NextDirElement1
						; not emptyDir, may be end of logical directory
	PUSH	DE				; save search address
	CALL	StillInDirectory			; past logical end?
	POP	DE				; recall address
	JNC	SearchDone			; artificial stop
Search4NextDirElement1:
	CALL	GetDirElementAddress		; HL = buffa+dptr
	LDA	searchLength
	MOV	C,A				; length of search to c
	MVI	B,0				; bcounts up, c counts down
Search4NextLoop:					; searchloop
	MOV	A,C
	ORA	A
	JZ	EndDirElementSearch
	LDAX	DE
	CPI	QMARK
	JZ	Search4NextOK			; ? matches all
						; scan next character if not unFilledBytes
	MOV	A,B
	CPI	unFilledBytes
	JZ	Search4NextOK
						; not the unFilledBytes field, extent field?
	CPI	extnum				; may be extent field
	LDAX	DE				; fcb character
	JZ	Search4Ext			; skip to search extent
	SUB	M
	ANI	07FH				; mask-out flags/extent modulus
	JNZ	Search4NextDirElement		; skip if not matched
	JMP	Search4NextOK ;matched character
Search4Ext:					; searchext
						; A has fcb character
						; attempt an extent # match
	PUSH	BC				; save counters
	MOV	C,M				; directory character to c
	CALL	CompareExtents			; compare user/dir char
	POP	BC				; recall counters
	JNZ	Search4NextDirElement		; skip if no match
Search4NextOK:					; searchok:
						; current character matches
	INX	DE
	INX	HL
	INR	B
	DCR	C
	JMP	Search4NextLoop
EndDirElementSearch:					; endsearch
						; entire name matches, return dir position
	LDA	dirCounter
	ANI	dskmsk
	STA	lowReturnStatus
						; lowReturnStatus = low(dirCounter) and 11b
	LXI	HL,directoryFlag
	MOV	A,M
	RAL
	RNC					; directoryFlag=0ffh?
						; yes, change it to 0 to mark as found
	XRA	A
	MOV	M,A				; directoryFlag=0
	RET
SearchDone:					; search$fin:
						; end of directory, or empty name
	CALL	SetEndDirectory			; may be artifical end
	MVI	A,0FFH
	STA	lowReturnStatus
	RET
;---------------------
;get current extent field address to (HL)
GetExtentAddress:					; getexta
	LHLD	paramDE
	LXI	DE,extnum
	DAD	DE ;HL=.fcb(extnum)
	RET
;---------------------
;Set file write flag
SetFileWriteFlag:					; setfwf
	CALL	GetModuleNum			; HL=.fcb(modnum), A=fcb(modnum)				
	ORI	fwfmsk				; set fwf (file write flag) to "1"
	MOV	M,A				; fcb(modnum)=fcb(modnum) or 80h
	RET					; also returns non zero in accumulator
;---------------------
;set lowReturnStatus to 1
SetLowReturnTo1:					;setlret1
	MVI	A,1
	STA	lowReturnStatus
	RET
;---------------------
;compare extent# in A with that in C, return nonzero if they do not match
CompareExtents:					; compext
	PUSH	BC				; save C's original value
	PUSH	PSW
	LDA	dpbEXM
	CMA
	MOV	B,A
						; B has negated form of extent mask
	MOV	A,C
	ANA	B
	MOV	C,A				; low bits removed from C
	POP	PSW
	ANA	B				; low bits removed from A
	SUB	C
	ANI	maxext				; set flags
	POP	BC				; restore original values
	RET

;---------------------
;copy the directory entry to the user buffer
CopyDirEntryToUser:					; dir$to$user
	LHLD	caDirectoryDMA
	XCHG					; source is directory buffer
	LHLD	InitDAMAddress			; destination is user dma address
	MVI	C,recordSize			; copy entire record
	JMP	Move
	;ret
;---------------------
;copy the whole file control block
CopyFCB:						; copy$fcb
	MVI	C,0
	MVI	E,fcbLength			; start at 0, to fcblen-1
	JMP	CopyDir
;---------------------
	;copy fcb information starting at C for E bytes
	;into the currently addressed directory entry
CopyDir:						; copy$dir
	PUSH	DE				; save length for later
	MVI	B,0				; double index to BC
	LHLD	paramDE				; HL = source for data
	DAD	BC
	XCHG					; DE=.fcb(C), source for copy
	CALL	GetDirElementAddress		; HL=.buff(dptr), destination
	POP	BC				; DE=source, HL=dest, C=length
	CALL	Move				; data moved
;enter from close to seek and copy current element
SeekAndCopy:					; seek$copy:
	CALL	SeekDir				; seek$dir ;to the directory element
	JMP	WriteDir				; write the directory element
	;ret
;---------------------
;compute disk map position for vrecord to HL
ComputeDmPosition:					; dm$position
	LXI	HL,dpbBSH				; get block shift value
	MOV	C,M				; shift count to C
	LDA	vrecord				; current virtual record to A
ComputeDmPosition1:					; dmpos0:
	ORA	A
	RAR
	DCR	C
	JNZ	ComputeDmPosition1
						; A = shr(vrecord,dpbBSH) = vrecord/2**(sect/block)
	MOV	B,A				; save it for later addition
	MVI	A,8
	SUB	M				; 8-dpbBSH to accumulator
	MOV	C,A				; extent shift count in register c
	LDA	extval				; extent value ani extmsk
ComputeDmPosition2:					; dmpos1:
						; dpbBSH = 3,4,5,6,7, C=5,4,3,2,1
						; shift is 4,3,2,1,0
	DCR	C
	JZ	ComputeDmPosition3
	ORA	A
	RAL
	JMP	ComputeDmPosition2
ComputeDmPosition3:					; dmpos2:
						; arrive here with A = shl(ext and extmsk,7-dpbBSH)
	ADD	B 				; add the previous shr(vrecord,dpbBSH) value
						; A is one of the following values, depending upon alloc
						; bks dpbBSH
						; 1k   3     v/8 + extval * 16
						; 2k   4     v/16+ extval * 8
						; 4k   5     v/32+ extval * 4
						; 8k   6     v/64+ extval * 2
						; 16k  7     v/128+extval * 1
	RET 					; with disk map position in A
;---------------------
;return disk map value from position given by BC
GetDiskMapValue:					; getdm
	LHLD	paramDE				; base address of file control block
	LXI	DE,diskMap
	DAD	DE				; HL =.diskmap
	DAD	BC				; index by a single byte value
	LDA	single				; single byte/map entry?
	ORA	A
	JZ	GetDiskMapValue1 			; get disk map single byte
	MOV	L,M
	MVI	H,0
	RET					; with HL=00bb
GetDiskMapValue1:					; getdmd:
	DAD	BC				; HL=.fcb(dm+i*2)
						; double precision value returned
	MOV	E,M
	INX	HL
	MOV	D,M
	XCHG
	RET
;---------------------
;---------------------
;*****************************************************************
;************************ Utilities ******************************
;*****************************************************************
AddAtoHL:						; addh
	ADD L
	MOV L,A
	RNC
						; overflow to H
	INR H
	RET
DEminusHL2HL:					; subdh
	MOV	A,E
	SUB	L
	MOV	L,A
	MOV	A,D
	SBB	H
	MOV	H,A
	RET
;-------------
ShiftRightHLbyC:					; hlrotr rotate
	INR	C
ShiftRightHLbyC0:
	DCR	C
	RZ					; exit when done
	MOV	A,H
	ORA	A				; reset carry bit
	RAR					; rotate
	MOV	H,A				; high byte
	MOV	A,L
	RAR	
	MOV	L,A				; low byte
	JMP	ShiftRightHLbyC0
	
;-------
ShiftLeftHLbyC:					; hlrotl
	INR	C
ShiftLeftHLbyC0:
	DCR	C
	RZ					; exit when done
	DAD	HL
	JMP	ShiftLeftHLbyC0
;*****************************************************************
;move data length of length C from source DE to HL
Move:						; move
	INR	C				; housekeeping
Move0:
	DCR	C
	RZ					; exit if done
	LDAX	D				; get byte
	MOV	M,A				; put the byte
	INX	DE
	INX	HL				; move pointers
	JMP	Move0				; keep going
	
;********** Console Routines***********************
;********** Console IN Routines********************
;read console character to A
ConIn:						; conin
	LXI	HL,kbchar
	MOV	A,M
	MVI	M,0
	ORA	A
	RNZ
	;no previous keyboard character ready
	JMP	bcConin ;get character externally
	;ret
;
;----------------
;echo character if graphic CR, LF, TAB, or backspace
EchoNonGraphicCharacter:				; echoc
	CPI	CR
	RZ					; carriage return?
	CPI	LF
	RZ					; line feed?
	CPI	TAB
	RZ					; TAB?
	CPI	CTRL_H
	RZ					; backspace?
	CPI	SPACE
	RET					; carry set if not graphic
;----------------
;read character with echo
ConsoleInWithEcho:					; conech
	CALL	ConIn
	CALL	EchoNonGraphicCharacter
	RC					; return if graphic character
						; character must be echoed before return
	PUSH	PSW
	MOV	C,A
	CALL	TabOut
	POP	PSW
	RET					; with character in A
;********** Console OUT Routines*******************
ConBreak:						; conbrk for character ready
	LDA	kbchar
	ORA	A
	JNZ	ConBreak1 			; skip if active kbchar
	CALL	bcConst				; get status
	ANI	1
	RZ					; return if no char ready
	CALL	bcConin				; to A
	CPI	CTRL_S
	JNZ	ConBreak0				; check stop screen function
						; found CTRL_S, read next character
	CALL	bcConin				; to A
	CPI	CTRL_C
	JZ	WarmBoot				; CTRL_C implies re-boot
						; not a WarmBoot, act as if nothing has happened
	XRA	A
	RET					; with zero in accumulator
ConBreak0:					; conb0:
						; character in accum, save it
	STA kbchar
ConBreak1:					; conb1:
						; return with true set in accumulator
	MVI	A,TRUE
	RET
;
;
;display #, CR, LF for CTRL_X, CTRL_U, CTRL_R functions
;then move to startingColumn (starting columnPosition)
showHashCRLF:					; crlfp:
	MVI	C,HASH_TAG
	CALL	ConsoleOut
	CALL	showCRLF
						; columnPosition = 0, move to position startingColumn
showHashCRLF0:					; crlfp0:
	LDA	columnPosition
	LXI	HL,startingColumn
	CMP	M
	RNC					; stop when columnPosition reaches startingColumn
	MVI	C,SPACE
	CALL	ConsoleOut			; display blank
	JMP	showHashCRLF0
;
showCRLF:						; crlf:
	;carriage return line feed sequence
	MVI	C,CR
	CALL	ConsoleOut
	MVI	C,LF
	JMP	ConsoleOut
	;ret
;
;-------------
; print message until M(BC) = '$'
Print:						; print
	LDAX	BC
	CPI	DOLLAR
	RZ		 ; stop on $
	INX	BC
	PUSH	BC
	MOV	C,A
	CALL	TabOut
	POP	BC
	JMP	Print

;----------------
; compute character position/write console char from C
; compcol = true if computing column position
ConsoleOut:					; conout
	LDA	compcol
	ORA	A
	JNZ	ConsoleOut1
						; write the character, then compute the columnPosition
						; write console character from C
	PUSH	BC
	CALL	ConBreak				; check for screen stop function
	POP	BC
	PUSH	BC				; recall/save character
	CALL	bcConout				; externally, to console
	POP	BC
	PUSH	BC				; recall/save character
						; may be copying to the list device
	LDA	listeningToggle
	ORA	A
	CNZ	bcList				; to printer, if so
	POP	BC				; recall the character
ConsoleOut1:
	MOV	A,C				; recall the character
						; and compute column position
	LXI	HL,columnPosition			; A = char, HL = .columnPosition
	CPI	RUBOUT
	RZ					; no columnPosition change if nulls
	INR	M				; columnPosition = columnPosition + 1
	CPI	SPACE
	RNC					; return if graphic
						; not graphic, reset columnPosition position
	DCR	M				; columnPosition = columnPosition - 1
	MOV	A,M
	ORA	A
	RZ					; return if at zero
						; not at zero, may be backspace or end line
	MOV	A,C				; character back to A
	CPI	CTRL_H
	JNZ	NotBackSpace
						; backspace character
	DCR	M				; columnPosition = columnPosition - 1
	RET
NotBackSpace:					; notbacksp:  not a backspace character  eol?
	CPI	LF
	RNZ					; return if not
						; end of line, columnPosition = 0
	MVI	M,0				; columnPosition = 0
	RET
	
;********************************************************
;return version number
fGetVersion:					; func12 (12 - 0C)	 Get Verson 
	MVI	A,VERSION
	STA	lowReturnStatus ;lowReturnStatus = VERSION (high = 00)
	RET		;jmp goback
;************Error message World*************************
errSelect:					; sel$error  report selection error
	LXI	HL,evSelection
	JMP	GoToError

errReadOnlyDisk:					; rod$error
	LXI	HL,evReadOnlyDisk
	JMP	GoToError
errReadOnlyFile:					; rof$error
	LXI	HL,evReadOnlyFile
	JMP	GoToError
errPermanent:					; per$error
	LXI	HL,evPermanent
	JMP	GoToError

;************Error message handler **********************
GoToError:					; goerr:
	;HL = .errorhandler, call subroutine
	MOV	E,M
	INX	HL
	MOV	D,M				; address of routine in DE
	XCHG
	PCHL					; vector to subroutine
;************ Error Vectors *****************************
evPermanent: 	DW	erPermanent	;pererr permanent error subroutine
evSelection:	DW	erSelection	;selerr select error subroutine
evReadOnlyDisk:	DW	erReadOnlyDisk	;roderr ro disk error subroutine
evReadOnlyFile:	DW	erReadOnlyFile	;roferr ro file error subroutine
;************Error Routines ******************************
erPermanentNoWait:					; per$error
	LXI	HL,emPermanent
	JMP	GoToError

erPermanent:					; persub report permanent error
	LXI	HL,emPermanent
	CALL	displayAndWait			; to report the error
	CPI 	CTRL_C
	JZ	WarmBoot				; reboot if response is CTRL_C
	RET					; and ignore the error
;
erSelection:					; selsub report select error
	LXI	HL,emSelection
	JMP	waitB4boot			; wait console before boot
;
erReadOnlyDisk:					; rodsub report write to read/only disk
	LXI	HL,emReadOnlyDisk             
	JMP	waitB4boot			; wait console before boot
;                                                 
erReadOnlyFile:	;rofsub report read/only file 
	LXI	HL,emReadOnlyFile			; drop through to wait for console
;                                                 
waitB4boot:					; wait$err wait for response before boot
	CALL	displayAndWait
JMP WarmBoot

displayAndWait:					; errflg:
	;report error to console, message address in HL
	PUSH	HL				; save message pointer
	CALL	showCRLF				; stack mssg address, new line
	LDA	currentDisk
	ADI	ASCII_A
	STA	emDisk				; Problem disk name
	LXI	BC,emDisk0
	CALL	Print				; the error message
	POP	BC
	CALL	Print				; error mssage tail
	JMP	ConIn				; to get the input character
	;ret	
;**************Error Messages*******************************
emDisk0:		DB	'Bdos Err On '		; dskmsg:
emDisk:		DB	' : $'			; dskerr filled in by errflg
emPermanent:	DB	'Bad Sector$'		; permsg
emSelection:	DB	'Select$'			; selmsg
emReadOnlyFile:	DB	'File '			; rofmsg	
emReadOnlyDisk:	DB	'R/O$'			; rodmsg:	
;*****************************************************************
;********* file control block (fcb) constants ********************
emptyDir		EQU	0E5H			; empty empty directory entry
lastRecordNumber	EQU	127			; lstrec last record# in extent
recordSize	EQU	128			; recsiz record size
fcbLength		EQU	32			; fcblen file control block size
dirrec		EQU	recordSize/fcbLength	; directory elts / record
dskshf		EQU	2			; log2(dirrec)
dskmsk		EQU	dirrec-1                      
fcbshf		EQU	5			; log2(fcbLength)
;                                                           
extnum		EQU	12			; extent number field
maxext		EQU	31			; largest extent number
unFilledBytes	EQU	13			; ubytes unfilled bytes field
modnum		EQU	14			; data module number	S2?????
maxmod		EQU	15			; largest module number
fwfmsk		EQU	80h			; file write flag is high order modnum
nameLength	EQU	15			; namlen name length
reccnt		EQU	15			; record count field
diskMap		EQU	16			; dskmap disk map field
lstfcb		EQU	fcbLength-1                   
nxtrec		EQU	fcbLength                     
ranrec		EQU	nxtrec+1			; random record field (2 bytes)
;
;	reserved file indicators
rofile	EQU	9				; high order of first type char
invis	EQU	10				; invisible file in dir command
;	equ	11				; reserved
;*****************************************************************
;*****************************************************************

;***common values shared between bdosi and bdos******************
currentUserNumber:	DB	0			; usrcode current user number
paramDE:		DS	2			; ParamsDE information address
statusBDOSReturn:	DS	2			; address value to return
currentDisk:	DB	-1			; curdsk current disk number
lowReturnStatus	EQU	statusBDOSReturn		; lret low(statusBDOSReturn)

;********************* Local Variables ***************************
;     ************************
;     *** Initialized Data ***

emptyFCB:		DB	emptyDir			; efcb 0E5 = available dir entry
ReadOnlyVector:	DW	0			; rodsk read only disk vector
loggedDisks:	DW	0			; dlog	 logged-in disks
InitDAMAddress:	DW	DMABuffer			; dmaad tbuff initial dma address

;     *** Current Disk attributes ****
; These are set upon disk select
; data must be adjacent, do not insert variables
; address of translate vector, not used
; ca - currentAddress

caDirMaxValue:	DW	0000H			; cdrmaxa pointer to cur dir max value
caTrack:		DW	0000H			; curtrka current track address
caSector:		DW	0000H			; curreca current record address
caListSizeStart:                   		       
caDirectoryDMA:	DW	0000H			; buffa pointer to directory dma address
caDiskParamBlock:	DW	0000H			; dpbaddr current disk parameter block address
caCheckSum:	DW	0000H			; checka current checksum vector address
caAllocVector:	DW	0000H			; alloca current allocation vector address
caListSizeEnd:
caListSize	EQU	caListSizeEnd - caListSizeStart	;addlist	equ	$-caDirectoryDMA	 address list size
;caListSize	EQU	$ - caDirectoryDMA	;addlist	equ	$-caDirectoryDMA	 address list size

;     ***** Disk Parameter Block *******
; data must be adjacent, do not insert variables
; dpb - Disk Parameter Block
dpbStart:
dpbSPT:	DW	0000H				; sectpt sectors per track
dpbBSH:	DB	0000H				; blkshf block shift factor
dpbBLM:	DB	00H				; blkmsk block mask
dpbEXM:	DB	00H				; extmsk extent mask
dpbDSM:	DW	0000H				; maxall maximum allocation number
dpbDRM:	DW	0000H				; dirmax largest directory number
dpbDABM:	DW	0000H				; dirblk reserved allocation bits for directory
dpbCKS:	DW	0000H				; chksiz size of checksum vector
dpbOFF:	DW	0000H				; offset offset tracks at beginning
dpbEnd:
dpbSize	EQU	dpbEnd - dpbStart	;dpblist	equ	$-dpbSPT	;size of area
;

;     ************************

paramE:		DS	BYTE			; ParamE low(info)
caSkewTable:	DW	0000H			; tranv address of translate vector
fcbCopiedFlag:	DB	00H			; fcb$copied set true if CopyFCB called
readModeFlag:	DB	00H			; rmf read mode flag for OpenNextExt
directoryFlag:	DB	00H			; dirloc directory flag in rename, etc.
seqReadFlag:	DB	00H			; seqio  1 if sequential i/o
diskMapIndex:	DB	00H			; dminx  local for diskwrite
searchLength:	DB	00H			; searchl search length
searchAddress:	DW	0000H			; searcha search address
;tinfo:	ds	word				; temp for info in "make"
single:		DB	00H			; set true if single byte allocation map
fResel:		DB	00H			; resel reselection flag
entryDisk:	DB	00H			; olddsk disk on entry to bdos
fcbDisk:		DB	00H			; fcbdsk disk named in fcb
rcount:		DB	00H			; record count in current fcb
extval:		DB	00H			; extent number and dpbEXM
vrecord:		DW	0000H			; current virtual record
currentRecord:	DW	0000H			; arecord current actual record
;
;	local variables for directory access
dirPointer:	DB	00H			; dptr directory pointer 0,1,2,3
dirCounter:	DW	00H			; dcnt directory counter 0,1,...,dpbDRM
dirRecord:	DW	00H			; drec:	ds	word	;directory record 0,1,...,dpbDRM/4

;********************** data areas ******************************
compcol:	DB	0				; true if computing column position
startingColumn:	DB	0			; strtcol starting column position after read
columnPosition:	DB	0			; column column position
listeningToggle:	DB	0			; listcp listing toggle
kbchar:	DB	0				; initial key char = 00
usersStack:	DS	2			; entry stack pointer
stackBottom:	DS	STACK_SIZE * 2		; stack size
bdosStack:
;	end of Basic I/O System
;-----------------------------------------------------------------;*****************************************************************

;	
CodeEnd: