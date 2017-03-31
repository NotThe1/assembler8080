; BDOS.asm

; 2017-03-31 added vector for BDOS Call 5 -ListOut
; 2017-03-02 Refactored the CP/M Suite
; 2017-02-12 fixed allocate 16 bit problem
; 2014-01-16 extended from part of newOS (newBDOS)
; 2014-03-14  :  Frank Martyn


	$Include ./stdHeader.asm
	$Include ./osHeader.asm
	$Include ./diskHeader.asm

VERSION		EQU		20H				; dvers version 2.0
STACK_SIZE	EQU		20H				; make stak big enough
EOD			EQU		-1				; enddir End of Directory

;------------------- BIOS Function Constants ---------------------------

bcBoot		EQU		BIOSStart+3*0			; bootf	cold boot function
bcWboot		EQU		BIOSStart+3*1			; wbootf	warm boot function
bcConst		EQU		BIOSStart+3*2			; constf	console status function
bcConin		EQU		BIOSStart+3*3			; coninf	console input function
bcConout	EQU		BIOSStart+3*4			; conoutf	console output function
bcList		EQU		BIOSStart+3*5			; listf	list output function
bcPunch		EQU		BIOSStart+3*6			; punchf	punch output function
bcReader	EQU		BIOSStart+3*7			; readerf	reader input function
bcHome		EQU		BIOSStart+3*8			; homef	disk home function
bcSeldsk	EQU		BIOSStart+3*9			; seldskf	select disk function
bcSettrk	EQU		BIOSStart+3*10			; settrkf	set track function
bcSetsec	EQU		BIOSStart+3*11			; setsecf	set sector function
bcSetdma	EQU		BIOSStart+3*12			; setdmaf	set dma function
bcRead		EQU		BIOSStart+3*13			; readf	read disk function
bcWrite		EQU		BIOSStart+3*14			; writef	write disk function
bcListst	EQU		BIOSStart+3*15			; liststf	list status function
bcSectran	EQU		BIOSStart+3*16			; sectran	sector translate
;--------------------------------------------------------------------------------

	ORG	BDOSBase
CodeStart:
			DS		6						; dead space


; Enter here from the user's program with function number in c,
; and information address in d,e
;BDOSEntry:
	JMP		BdosStart						;past parameter block

BdosStart:
	MOV		A,C
	STA		Cvalue
	XCHG									; swap DE and HL
	SHLD	paramDE							; save the original value of DE
	XCHG									; restore DE
	MOV		A,E								; Byte argument
	STA		paramE
	LXI		HL,0000H
	SHLD	statusBDOSReturn				; assume alls well for return
; Save users Stack pointer
	DAD		SP
	SHLD	usersStack
	LXI		SP,bdosStack					; use our own stack area
; initialize variables
	XRA		A
	STA		fcbDisk							; initalize to 00
	STA		fResel							; clear reselection flag
	LXI		HL,RetCaller					; exit to caller vector
	PUSH	HL								; makes a JMP to RetCaller = RET

	MOV		A,C								; get the Function Number
	CPI		functionCount					; make sure its a good number
	RNC										; exit if not a valid function

	MOV		C,E								; might be a single byte argument
	LXI		HL,functionTable				; get table base
	MOV		E,A								; function number in E
	MVI		D,0								; setting up DE = function number
	DAD		DE
	DAD		DE								; Vector is (2 * Function number) + table base
	MOV		E,M								; get LSB of vector
	INX		HL
	MOV		D,M								; get MSB of vector
	XCHG									; Vector now in HL
	PCHL									; move vector to Program Counter ie JMP (HL)
;*****************************************************************
;arrive here at end of processing to return to user
RetCaller:									; goback
	LDA		fResel							; get reselction flag
	ORA		A								; is it set?
	JZ		RetDiskMon
;reselection may have taken place
	LHLD	paramDE
	MVI		M,0
	LDA		fcbDisk
	ORA		A								; Disk = 0?
	JZ		RetDiskMon						; exit if yes

	MOV		M,A
	LDA		entryDisk						; get back original Disk
	STA		paramE							; and select it
	CALL	SelectCurrent

; return from the disk monitor
RetDiskMon:
	LHLD	usersStack
	SPHL									; restore callers stack
	LHLD	statusBDOSReturn
	MOV		A,L
	MOV		B,H								; BA = statusBDOSReturn
	RET
;*****************************************************************
;------------------- Function Table -------------------------------
functionTable:
	DW		bcBoot							; Function  0 - System Reset
	DW		vConsoleIn						; Function  1 - Console Input
	DW		vConsoleOut						; Function  2 - Console Output
	DW		vReaderIn						; Function  3 - Reader Input
	DW		vPunchOut	; Not Implemented	  Function  4 - Punch Output
	DW		vListOut	; Not Implemented	  Function  5 - List Output
	DW		vDirectConIO					; Function  6 - Direct Console I/O
	DW		vGetIOBYTE						; Function  7 - Get I/O Byte
	DW		vSetIOBYTE						; Function  8 - Set I/O Byte
	DW		vPrintString					; Function  9 - Print String
	DW		vReadString						; Function  A - Read Console String
	DW		vGetConsoleStatus				; Function  B - Get Console Status
diskf	EQU	($-functionTable)/2				; disk functions
	DW		vGetVersion						; Function  C - Return Version Number
	DW		vResetSystem					; Function  D - Reset Disk System
	DW		vSelectDisk						; Function  E - Select Disk
	DW		vOpenFile						; Function  F - Open File
	DW		vCloseFile						; Function 10 - Close File
	DW		vFindFirst						; Function 11 - Search For First
	DW		vFindNext						; Function 12 - Search for Next
	DW		vDeleteFile						; Function 13 - Delete File
	DW		vReadSeq						; Function 14 - Read Sequential
	DW		vWriteSeq						; Function 15 - Write Sequential
	DW		vMakeFile						; Function 16 - Make File
	DW		vRenameFile						; Function 17 - Rename File
	DW		vGetLoginVector					; Function 18 - Return Login Vector
	DW		vGetCurrentDisk					; Function 19 - Return Current Disk
	DW		vSetDMA							; Function 1A - Set DMA address
	DW		vGetAllocAddr					; Function 1B - Get ADDR (ALLOC)
	DW		vWriteProtectDisk				; Function 1C - Write Protect Disk
	DW		vGetRoVector					; Function 1D - Get Read/Only Vector
	DW		vSetFileAttributes				; Function 1E - Set File Attributes ??
	DW		vGetDiskParamBlock				; Function 1F - Get ADDR (Disk Parameters)
	DW		vGetSetUserNumber				; Function 20 - Set/Get User Code
	DW		vReadRandom						; Function 21 - Read Random
	DW		vWriteRandom					; Function 22 - Write Random
	DW		vComputeFileSize				; Function 23 - Compute File Size
	DW		vSetRandomRecord				; Function 24 - Set Random Record
	DW		vResetDrive	; Not Implemented	  Function 25 - Reset Drive
	DW		DUMMY							; Function 26 - Access Drive (not supported)
	DW		DUMMY							; Function 27 - Free Drive (not supported)
	DW		vWriteRandom0Fill; Not Implemented	  Function 28 - Write random w/Fill
functionCount	EQU	($-functionTable)/2 	; Number of  functions

DUMMY:
	HLT
;*****************************************************************
;**************** IOByte device I/O ******************************
;*****************************************************************
;return CON: character with echo
vConsoleIn:									; func1 (01 - 01) Console In
	CALL	ConsoleInWithEcho
	STA		statusBDOSReturn
	RET					
;----------
; write CON: character with TAB expansion
vConsoleOut:								; func2 (02 - 02) Console Out
	CALL	TabOut
	RET
;----------
; Read next character from RDR: (Paper Tape Reader)
vReaderIn:									; func3 (03 - 03) Reader Input
; Not Yet Implemented   **************
	STA		statusBDOSReturn
	RET	
;----------
; send char in E directly to PTP: (Paper Tape Punch)
vPunchOut:									; func4 (04 - 04) Punch Output
; Not Yet Implemented   **************
	RET
;----------
; send char in E directly to LST:
vListOut:									; func5 (05 - 05) List Output
	CALL	bcList							; direct call to BIOS
	RET
;----------
;direct console i/o - read if 0ffh
vDirectConIO:								; func6 (06 - 06) get Direct Console Out
	MOV		A,C
	INR		A
	JZ		fDirectConIn					; 0ffh => 00h, means input mode, else
	CALL	bcConout						; direct output function
	RET
fDirectConIn:
	CALL	bcConst							; status check
	ORA		A
	JZ		RetDiskMon						; skip, return 00 if not ready
	CALL	bcConin							; character is ready, get it to A
	STA		statusBDOSReturn
	RET	
;----------
;return io byte
vGetIOBYTE:									; func7 (07 - 07) get IOBYTE
	LDA		IOBYTE							; get the byte
	STA		statusBDOSReturn
	RET	
;----------
;set i/o byte
vSetIOBYTE:									; func8 (08 - 08)	set IOBYTE
	LXI		HL,IOBYTE
	MOV		M,C								; put passed value into IOBYTE
	RET
;----------
;write line until $ encountered
vPrintString:								; func9 (09 - 09)	 Print Dollar terminated String
	LHLD	paramDE
	MOV		C,L
	MOV		B,H								; BC=string address
	CALL	Print							; out to console
	RET
;----------
;read String from Console until limit or CR is reached
;In - (DE) = limit
;Out - (DE+1) = count of chars read (DE+2) = characters read
vReadString:								; func10 (10 - 0A)	read String from console
	CALL	ReadString
	RET
;----------
;check console status
vGetConsoleStatus:							; func11 (11 - 01)	read Dollar terminated String from console
	CALL	ConBreak
	STA		statusBDOSReturn
	RET	
;----------
;get/set user code
; IN - (E) = FF its a get else user Number(0-15)
; OUT - (A) Current user number or no value
vGetSetUserNumber:							; func32 (32 - 20)	Get or set User code
    LDA		paramE
	CPI		0FFH
	JNZ		SetUserNumber					; interrogate user code instead
	LDA		currentUserNumber
	STA		lowReturnStatus					; lowReturnStatus=currentUserNumber
	RET

SetUserNumber:								; setusrcode
	ANI		LO_NIBBLE_MASK
	STA		currentUserNumber
	RET

;*****************************************************************
;random disk read
;IN  - (DE) FCB address
;OUT - (A) 01 = Reading unwritten data
;	 02 = N/U
;	 03 = Cannot close current extent
;	 04 = Seek to unwriten Extent
;	 05 = N/U
;	 06 = Seek past Physical end of Disk
vReadRandom:								; func33 (33 - 21) Read Random record
	CALL	Reselect
	JMP		RandomDiskRead					; to perform the disk read
;*****************************************************************
;write random record
;IN  - (DE) FCB address
;OUT - (A) 01 = Reading unwritten data
;	 02 = N/U
;	 03 = Cannot close current extent
;	 04 = Seek to unwriten Extent
;	 05 = Cannot create new Extent because of directory overflow
;	 06 = Seek past Physical end of Disk
vWriteRandom:								; func34 (34 - 22) Write Random record
	CALL	Reselect
	JMP		RandomDiskWrite					; to perform the disk write
	;ret ;jmp goback
;*****************************************************************
;return file size (0-65536)
;IN  - (DE) FCB address
vComputeFileSize:							; func35 (35 - 23) Compute File Size
	CALL	Reselect
	JMP		GetFileSize
;*****************************************************************
;set random record
;IN  - (DE) FCB address
;OUT - Random Record Field is set
vSetRandomRecord:							; func36 (36 - 24) Set random Record
	JMP		SetRandomRecord
;*****************************************************************
;Reset Drive
;IN  - (DE) Drive Vector
;OUT - (A) 00
vResetDrive:								; func37 (37 - 25) Reset Drive
; Not Yet Implemented   **************
	RET
;*****************************************************************
;*****************************************************************
;Write Random With Zero Fill
;IN  - (DE) FCB address
;OUT - (A) Return Code		see Function 34
vWriteRandom0Fill:								; func40 (40 - 28) Reset Drive
; Not Yet Implemented   **************
	RET
;*****************************************************************
;******************< Random I/O Stuff ****************************
;*****************************************************************
;random disk read
RandomDiskRead:								; randiskread
	MVI		C,TRUE							; marked as read operation
	CALL	RandomSeek
	CZ		DiskRead						; if seek successful
	RET
;*****************************************************************
;random disk write
RandomDiskWrite:							; randiskwrite
	MVI		C,FALSE							; marked as read operation
	CALL	RandomSeek
	CZ		DiskWrite						; if seek successful
	RET
;*****************************************************************
;*****************************************************************
;random access seek operation, C=0ffh if read mode
;fcb is assumed to address an active file control block
;(fcbS2Index has been set to 11000000b if previous bad seek)
RandomSeek:
 	XRA		A
	STA		seqReadFlag						; marked as random access operation
	PUSH	BC								; save r/w flag
	LHLD	paramDE
	XCHG									; DE will hold base of fcb
	LXI		HL,RANDOM_REC_FIELD
	DAD		DE								; HL=.fcb(RANDOM_REC_FIELD)
	MOV		A,M
	ANI		7FH
	PUSH	PSW								; record number
	MOV		A,M
	RAL										; cy=lsb of extent#
	INX		HL
	MOV		A,M
	RAL
	ANI		11111B							; A=ext#
	MOV		C,A								; C holds extent number, record stacked
	MOV		A,M
	RAR
	RAR
	RAR
	RAR
	ANI		1111B							; mod#
	MOV		B,A								; B holds module#, C holds ext#
	POP		PSW								; recall sought record #
											;check to insure that high byte of ran rec = 00
	INX		HL
	MOV		L,M								; l=high byte (must be 00)
	INR		L
	DCR		L
	MVI		L,06							; zero flag, l=6
											; produce error 6, seek past physical eod
	JNZ		RandomSeekError
											; otherwise, high byte = 0, A = sought record
	LXI		HL,NEXT_RECORD
	DAD		DE								; HL = .fcb(NEXT_RECORD)
	MOV		M,A								; sought rec# stored away
											; arrive here with B=mod#, C=ext#, DE=.fcb, rec stored
											; the r/w flag is still stacked.  compare fcb values
	LXI		HL,fcbExtIndex						; extent number field
	DAD		DE
	MOV		A,C								; A=seek ext#
	SUB		M
	JNZ		RandomSeekClose					; tests for = extents
											; extents match, check mod#
	LXI		HL,fcbS2Index
	DAD		DE
	MOV		A,B								; B=seek mod#
											; could be overflow at eof, producing module#
											; of 90H or 10H, so compare all but fwf
	SUB		M
	ANI		7FH
	JZ			RandomSeekExit				; same?
RandomSeekClose:
	PUSH	BC
	PUSH	DE								; save seek mod#,ext#, .fcb
	CALL	CloseDirEntry					; current extent closed
	POP		DE
	POP		BC								; recall parameters and fill
	MVI		L,03							; cannot close error #3
	LDA		lowReturnStatus
	INR		A
	JZ		RandomSeekErrorBadSeek
	LXI		HL,fcbExtIndex
	DAD		DE
	MOV		M,C								; fcb(fcbExtIndex)=ext#
	LXI		HL,fcbS2Index
	DAD		DE
	MOV		M,B								; fcb(fcbS2Index)=mod#
	CALL	OpenFile						; is the file present?
	LDA		lowReturnStatus
	INR		A
	JNZ		RandomSeekExit					; open successful?
											; cannot open the file, read mode?
	POP		BC								; r/w flag to c (=0ffh if read)
	PUSH	BC								; everyone expects this item stacked
	MVI		L,04							; seek to unwritten extent #4
	INR		C								; becomes 00 if read operation
	JZ		RandomSeekErrorBadSeek			; skip to error if read operation
	CALL	MakeNewFile						; write operation, make new extent
	MVI		L,05							; cannot create new extent #5
	LDA		lowReturnStatus
	INR		A
	JZ		RandomSeekErrorBadSeek			; no dir space
; file make operation successful
RandomSeekExit:								; seekok:
	POP		BC								; discard r/w flag
	XRA		A
	STA		lowReturnStatus
	RET										; with zero set

RandomSeekErrorBadSeek:
; fcb no longer contains a valid fcb, mark with 11000000b in fcbS2Index field so that it
; appears as overflow with file write flag set
	PUSH	HL								; save error flag
	CALL	GetModuleNum					; HL = .fcbS2Index
	MVI		M,11000000B
	POP		HL								; and drop through
RandomSeekError:							; seekerr:
	POP		B								; discard r/w flag
	MOV		A,L
	STA		lowReturnStatus					; lowReturnStatus=#, nonzero
; SetFileWriteFlag returns non-zero accumulator for err
	JMP		SetFileWriteFlag				; flag set, so subsequent close ok
	;ret
;
;*****************************************************************
SetRandomRecord:							; setrandom
	LHLD	paramDE
	LXI		DE,NEXT_RECORD					; ready params for computesize
	CALL	GetRandomRecordPosition			; DE=paramDE, A=cy, BC=mmmm eeee errr rrrr
	LXI		HL,RANDOM_REC_FIELD
	DAD		DE								; HL = .FCB(RANDOM_REC_FIELD)
	MOV		M,C
	INX		HL
	MOV		M,B
	INX		HL
	MOV		M,A								; to RANDOM_REC_FIELD
	RET
;*****************************************************************
;compute logical file size for current fcb
GetFileSize:								; getfilesize
	MVI		C,fcbExtIndex
	CALL	Search4DirElement
; zero the receiving Ramdom record field
	LHLD	paramDE
	LXI		D,RANDOM_REC_FIELD
	DAD		DE
	PUSH	HL								; save position
	MOV		M,D
	INX		HL
	MOV		M,D
	INX		HL
	MOV		M,D								; =00 00 00
GetFileSize1:								; getsize:
	CALL	EndOfDirectory
	JZ		GetFileSizeExit
; current fcb addressed by dptr
	CALL	GetDirElementAddress
	LXI		DE,fcbRCIndex					; ready for compute size
	CALL	GetRandomRecordPosition
; A=0000 000? BC = mmmm eeee errr rrrr compare with memory, larger?
	POP		HL
	PUSH	HL								; recall, replace .fcb(Random record Field)
	MOV		E,A								; save cy
	MOV		A,C
	SUB		M
	INX		HL								; ls byte
	MOV		A,B
	SBB		M
	INX		HL								; middle byte
	MOV		A,E
	SBB		M								; carry if .fcb(random record field) > directory
	JC		GetFileSize2							; for another try
											; fcb is less or equal, fill from directory
	MOV		M,E
	DCX		HL
	MOV		M,B
	DCX		HL
	MOV		M,C
GetFileSize2:								; getnextsize:
	CALL	Search4NextDirElement
	JMP		GetFileSize1
GetFileSizeExit:							; setsize:
	POP		HL								; discard .fcb(random record field)
	RET
;-----------------------------------------------------------------
;compute random record position
GetRandomRecordPosition:				; compute$rr
	XCHG
	DAD		DE
; DE=.buf(dptr) or .fcb(0), HL = .f(NEXT_RECORD/fcbRCIndex)
	MOV		C,M
	MVI		B,0							; BC = 0000 0000 ?rrr rrrr
	LXI		HL,fcbExtIndex
	DAD		DE
	MOV		A,M
	RRC
	ANI		80H							; A=e000 0000
	ADD		C
	MOV		C,A
	MVI		A,0
	ADC		B
	MOV		B,A
; BC = 0000 000? errrr rrrr
	MOV		A,M
	RRC
	ANI		LO_NIBBLE_MASK
	ADD		B
	MOV		B,A
										; BC = 000? eeee errrr rrrr
	LXI		HL,fcbS2Index
	DAD		DE
	MOV		A,M							; A=XXX? mmmm
	ADD		A
	ADD		A
	ADD		A
	ADD		A							; cy=? A=mmmm 0000
	PUSH	PSW
	ADD		B
	MOV		B,A
; cy=?, BC = mmmm eeee errr rrrr
	PUSH	PSW							; possible second carry
	POP		HL							; cy = lsb of L
	MOV		A,L							; cy = lsb of A
	POP		HL							; cy = lsb of L
	ORA		L 							; cy/cy = lsb of A
	ANI		1 							; A = 0000 000? possible carry-out
	RET
;-----------------------------------------------------------------

;*****************************************************************
;****************** Random I/O Stuff >****************************
;*****************************************************************


;read to paramDE address (max length, current length, buffer)
ReadString:
	LDA		columnPosition
	STA		startingColumn				; save start for ctl-x, ctl-h
	LHLD	paramDE
	MOV		C,M
	INX		H
	PUSH	HL
	MVI		B,0
; B = current buffer length,
; C = maximum buffer length,
; HL= next to fill - 1

; read next character, BC, HL active
ReadNext:
	PUSH	BC
	PUSH	HL								; blen, cmax, HL saved
ReadNext0:
	CALL	ConIn							; next char in A
	ANI		ASCII_MASK						; mask parity bit
	POP		HL
	POP		BC								; reactivate counters
	CPI		CR
	JZ		EndRead							; end of line?
	CPI		LF
	JZ		EndRead							; also end of line
	CPI		CTRL_H
	JNZ		NotCtntl_H						; backspace?
; do we have any characters to back over?
	MOV		A,B
	ORA		A
	JZ		ReadNext
; characters remain in buffer, backup one
	DCR		B								; remove one character
	LDA		columnPosition
	STA		compcol							; col > 0
; compcol > 0 marks repeat as length compute
	JMP		LineLengthOrRepeat				; uses same code as repeat
; not a backspace
NotCtntl_H:
	CPI		RUBOUT
	JNZ		NotRubout						; RUBOUT char?
; RUBOUT encountered, RUBOUT if possible
	MOV		A,B
	ORA		A
	JZ		ReadNext						; skip if len=0
; buffer has characters, resend last char
	MOV		A,M
	DCR		B
	DCX		HL								; A = LAST CHAR
; BLEN=BLEN-1, NEXT TO FILL - 1 DECREMENTED
	JMP		ReadEcho1						; act like this is an echo
;
; not a RUBOUT character, check end line
NotRubout:
	CPI		CTRL_E
	JNZ		NotCtntl_E						; physical end line?
; yes, save active counters and force eol
	PUSH	BC
	PUSH	HL
	CALL	showCRLF
	XRA		A
	STA		startingColumn					; start position = 00
	JMP		ReadNext0						; for another character
NotCtntl_E:
; not end of line, list toggle?
	CPI		CTRL_P
	JNZ		NotCtntl_P						; skip if not CTRL_P
; list toggle - change parity
	PUSH	HL								; save next to fill - 1
	LXI		HL,listeningToggle				; HL=.listeningToggle flag
	MVI		A,1
	SUB		M								; True-listeningToggle
	MOV		M,A								; listeningToggle = not listeningToggle
	POP		HL
	JMP		ReadNext						; for another char
; not a CTRL_P, line delete?
NotCtntl_P:
	CPI		CTRL_X
	JNZ		NotCtntl_X
	POP		HL								; discard start position
; loop while columnPosition > startingColumn
GoBack:
	LDA		startingColumn
	LXI		HL,columnPosition
	CMP		M
	JNC		ReadString						; start again
	DCR		M								; columnPosition = columnPosition - 1
	CALL	BackUp							; one position
	JMP		GoBack

; not a control X, control U?
NotCtntl_X:
	CPI		CTRL_U
	JNZ		NotCtntl_U						; skip if not
; delete line (CTRL_U)
	CALL	showHashCRLF					; physical eol
	POP		HL								; discard starting position
	JMP		ReadString						; to start all over
NotCtntl_U:
; not line delete, repeat line?
	CPI		CTRL_R
	JNZ		NotCtntl_R
LineLengthOrRepeat:
; repeat line, or compute line len (CTRL_H) if compcol > 0
	PUSH	BC
	CALL	showHashCRLF					; save line length
	POP		BC
	POP		HL
	PUSH	HL
	PUSH	BC
; bcur, cmax active, beginning buff at HL
Repeat:
	MOV		A,B
	ORA		A
	JZ		Repeat1							; count len to 00
	INX		HL
	MOV		C,M								; next to print
	DCR		B
	PUSH	BC
	PUSH	HL								; count length down
	CALL	CaretCout						; character echoed
	POP		HL
	POP		BC								; recall remaining count
	JMP		Repeat							; for the next character
Repeat1:									; rep1:
; end of repeat, recall lengths original BC still remains pushed
	PUSH	HL								; save next to fill
	LDA		compcol
	ORA		A								; >0 if computing length
	JZ		ReadNext0				; for another char if so
; columnPosition position computed for CTRL_H
	LXI		HL,columnPosition
	SUB		M								; diff > 0
	STA		compcol							; count down below
; move back compcol-columnPosition spaces

; move back one more space
BackSpace:
	CALL	BackUp							; one space
	LXI		HL,compcol
	DCR		M
	JNZ		BackSpace
	JMP		ReadNext0						; for next character

; not a CTRL_R, place into buffer
NotCtntl_R:

ReadEcho:
	INX		HL
	MOV		M,A								; character filled to mem
	INR		B								; blen = blen + 1
ReadEcho1:
											; look for a random control character
	PUSH	BC
	PUSH	HL								; active values saved
	MOV		C,A								; ready to print
	CALL	CaretCout						; may be up-arrow C
	POP		HL
	POP		BC
	MOV		A,M								; recall char
	CPI		CTRL_C							; set flags for reboot test
	MOV		A,B								; move length to A
	JNZ		NotCtntl_C						; skip if not a control c
	CPI	1									; control C, must be length 1
	JZ		WarmBoot						; reboot if blen = 1
; length not one, so skip reboot
NotCtntl_C:
; not reboot, are we at end of buffer?
	CMP		C
	JC		ReadNext						; go for another if not paramDE

; end of read operation, store blen
EndRead:
	POP		HL
	MOV		M,B								; M(current len) = B
	MVI		C,CR
	JMP		ConsoleOut						; return carriage

;------------------
;back-up one screen position
BackUp:
 	CALL	PutCntl_H
	MVI		C,SPACE
	CALL	bcConout
;send CTRL_H to console without affecting column count
PutCntl_H:
	MVI		C,CTRL_H
	JMP		bcConout
	;ret
;----------------------------------------------------------------
;


;------------------
;send C character with possible preceding up-arrow
CaretCout:
	MOV		A,C
	CALL	EchoNonGraphicCharacter			; cy if not graphic (or special case)
	JNC		TabOut							; skip if graphic, TAB, CR, LF, or CTRL_H
; send preceding up arrow
	PUSH	PSW
	MVI		C,CARET
	CALL	ConsoleOut						; up arrow
	POP		PSW
	ORI		40H								; becomes graphic letter
	MOV		C,A								; ready to print

;expand tabs to console
TabOut:
	MOV		A,C
	CPI		TAB
	JNZ		ConsoleOut						; direct to ConsoleOut if not
; TAB encountered, move to next TAB position
TabOut0:
	MVI		C,SPACE
	CALL	ConsoleOut						; another blank
	LDA		columnPosition
	ANI		111b							; columnPosition mod 8 = 0 ?
	JNZ		TabOut0							; back for another if not
	RET
;--------------------


;*****************************************************************
;********************** Disk  I/O ********************************
;*****************************************************************

;reset disk system - initialize to disk 0
vResetSystem:					; func13 (13 - 0D)	 Reset Disk System
 	LXI		HL,0
	SHLD	ReadOnlyVector
	SHLD	loggedDisks						; clear the vectors for R/O and Logged Disks
	XRA		A								; also clear the current disk
	STA		currentDisk						; note that currentUserNumber remains unchanged
	LXI		HL,DMABuffer
	SHLD	InitDAMAddress					; InitDAMAddress = DMABuffer
    CALL	SetDataDMA						; to data dma address
	JMP		Select
	;ret ;jmp goback
;-----------------------------------------------------------------
;select disk in (E) paramDE
; IN - (E) disk number -- 0=A  1=B ...15=P
vSelectDisk:								; func14 (14 - 0E)	Select Current Disk
	JMP	SelectCurrent
	;ret ;jmp goba
;-----------------------------------------------------------------
;return the login vector
;OUT - (HL) loggedDisks
vGetLoginVector:							; func24: (24 - 18) Return login Vector
	LHLD	loggedDisks
	SHLD	statusBDOSReturn
	RET
;-----------------------------------------------------------------
;return selected disk number
;OUT - A current disk -- 0=A  1=B ...15=P
vGetCurrentDisk:							; func25 (25 - 19)	Get Current Disk
	LDA	currentDisk
	STA	lowReturnStatus
	RET
;-----------------------------------------------------------------
;set the subsequent dma address to paramDE
;IN - (HL) value to set as DMA
vSetDMA:									; func26 (25 - 1A) Set Dma Address
	LHLD	paramDE
	SHLD	InitDAMAddress					; InitDAMAddress = paramDE
    JMP	SetDataDMA							; to data dma address
;-----------------------------------------------------------------
;return the Allocation Vector Address
;OUT - (HL) Allocation Vector Address
vGetAllocAddr:								; func27 (27 - 1B) Get Allocation Vector Address
	LHLD	caAllocVector
	SHLD	statusBDOSReturn
	RET
;-----------------------------------------------------------------
;;write protect current disk
vWriteProtectDisk:							; func28 (28 - 1C) Write protect disk
	JMP	SetDiskReadOnly
;-----------------------------------------------------------------
;return r/o bit vector
;OUT - (HL) Read Only Vector Vector
vGetRoVector:								; func29 (29 - 1D)	Get read Only vector
	LHLD	ReadOnlyVector
	SHLD	statusBDOSReturn
	RET
;-----------------------------------------------------------------
;;set file Attributes
vSetFileAttributes:							; func30 (30 - 1E) Set File Attributes
	CALL	Reselect
	CALL	SetAttributes
	JMP	DirLocationToReturnLoc				; lowReturnStatus=dirloc
;-----------------------------------------------------------------
;return address of disk parameter block
; OUT - (HL) Disk Parameter Black for current drive
vGetDiskParamBlock:							; func31 (31 - 1F)
	LHLD	caDiskParamBlock
	SHLD	statusBDOSReturn
	RET
;-----------------------------------------------------------------

SelectCurrent:								; curselect
	LDA	paramE
	LXI	HL,currentDisk
	CMP	M
	RZ										; exit if parame = Current disk
	MOV	M,A
	JMP	Select
;*****************************************************************
; select Login Drive
Select:
	LHLD	loggedDisks
	LDA		currentDisk
	MOV		C,A
	CALL	ShiftRightHLbyC					; see if we already have drive logged in
	PUSH	HL								; save result
	XCHG									; send to seldsk
	CALL	SelectDisk
	POP		HL								; get back logged disk vector
	CZ		errSelect
	MOV		A,L								; get logged disks
	RAR
	RC										; exit if the disk already logged in

	LHLD	loggedDisks						; else log in a differenet disk
	MOV		C,L
	MOV		B,H								; BC has logged disk
	CALL	SetCurrentDiskBit
	SHLD	loggedDisks						; save result
	JMP		InitDisk
;*****************************************************************
; select the disk drive given by currentDisk, and fill the base addresses
; caTrack - caAllocVector, then fill the values of the disk parameter block
SelectDisk:
	LDA		currentDisk
	MOV		C,A								; prepare for Bios Call
	CALL	bcSeldsk
	MOV		A,H								; HL = 0000 if error, otherwise disk headers
	ORA		L
	RZ										; exit if error, with Zflag set
	MOV		E,M
	INX		H
	MOV		D,M								; Disk Header Block pointer in DE
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
	XCHG									; DE points at Directory DMA, HL at Skew Table
	SHLD	caSkewTable
	LXI		HL,caDirectoryDMA
	MVI		C,caListSize
	CALL	Move							; finish filling in address list

	LHLD	caDiskParamBlock
	XCHG									; DE is source
	LXI		HL,dpbStart						; start of Disk Parameter Block
	MVI		C,dpbSize
	CALL	Move							; load the table
	LHLD	dpbDSM							; max entry number
	MOV		A,H								; if 00 then < 255
	LXI		HL,single						; point at the single byte entry flag
	MVI		M,TRUE							; assume its less than 255
	ORA		A								; assumtion confirmed ?
	JZ		SelectDisk1						; skip if yes
	MVI		M,FALSE							; correct assumption, set falg to false

SelectDisk1:
	MVI	A,TRUE
	ORA	A									; Set Sign, reset Carry and   Zero
	RET

;---------------
; set a "1" value in currentDisk position of BC
; return in HL
SetCurrentDiskBit:
	PUSH	BC								; save input parameter
	LDA		currentDisk
	MOV		C,A								; ready parameter for shift
	LXI		H,1								; number to shift
	CALL	ShiftLeftHLbyC							; HL = mask to integrate
	POP		BC								; original mask
	MOV		A,C
	ORA		L
	MOV		L,A
	MOV		A,B
	ORA		H
	MOV		H,A								; HL = mask or rol(1,currentDisk)
	RET
;--------------
;set current disk to read only
SetDiskReadOnly:
	LXI		HL,ReadOnlyVector
	MOV		C,M
	INX		HL
	MOV		B,M
	CALL	SetCurrentDiskBit				; sets bit to 1
	SHLD	ReadOnlyVector
; high water mark in directory goes to max
	LHLD	dpbDRM							; directory max
	XCHG									; DE = directory max
	LHLD	caDirMaxValue					; HL = .Directory max value
	MOV		M,E
	INX		HL
	MOV		M,D								; cdrmax = dpbDRM
	RET
;----------------------- initialize the current disk
;
;lowReturnStatus = false ;set to true if $ file exists
; compute the length of the allocation vector - 2

InitDisk:
	LHLD	dpbDSM							; get max allocation value
	MVI		C,3								; we want dpbDSM/8
; number of bytes in alloc vector is (dpbDSM/8)+1
	CALL	ShiftRightHLbyC
	INX		HL								; HL = dpbDSM/8+1
	MOV		B,H
	MOV		C,L								; BC has size of AllocationVector
	LHLD	caAllocVector					; base of allocation vector
;fill the allocation vector with zeros
InitDisk0:
	MVI		M,0
	INX		H								; alloc(i)=0
	DCX		BC								; count length down
	MOV		A,B
	ORA		C
	JNZ	InitDisk0
; set the reserved space for the directory
	LHLD	dpbDABM							; get the directory block reserved bits
	XCHG
	LHLD	caAllocVector 					; HL=.alloc()
	MOV		M,E
	INX		HL
	MOV		M,D								; sets reserved directory blks
; allocation vector initialized, home disk
	CALL	Home
; caDirMaxValue = 3 (scans at least one directory record)
	LHLD	caDirMaxValue
	MVI		M,3
	INX		H
	MVI		M,0								; caDirMaxValue = 0003

	CALL	SetEndDirectory					; dirEntryIndex = EOD
; read directory entries and check for allocated storage
InitDisk1:
	MVI		C,TRUE
	CALL	ReadDirectory
	CALL	EndOfDirectory
	RZ										; return if end of directory
; not end of directory, valid entry?
	CALL	GetDirElementAddress			; HL = caDirectoryDMA + dirBlockIndex
	MVI		A,emptyDir
	CMP		M
	JZ		InitDisk1						; go get another item
; not emptyDir, user code the same?
	LDA		currentUserNumber
	CMP		M
	JNZ		InitDisk2
; same user code, check for '$' submit
	INX		H
	MOV		A,M								; first character
	SUI		DOLLAR							; dollar file?
	JNZ		InitDisk2
; dollar file found, mark in lowReturnStatus
	DCR		A
	STA		lowReturnStatus					; lowReturnStatus = 255
InitDisk2:
; now scan the disk map for allocated blocks
	MVI		C,1								; set to allocated
	CALL	ScanDiskMap
	CALL	SetDirectoryEntry				; set DirMaxVAlue to dirEntryIndex
	JMP		InitDisk1						; for another entry
;
;-------------Scan the disk map for unallocated entry-----------------------------------
; scan the disk map addressed by dptr for non-zero entries.  The allocation
; vector entry corresponding to a non-zero entry is set to the value of C (0,1)
ScanDiskMap:
	CALL	GetDirElementAddress			; HL = buffa + dptr
 ; HL addresses the beginning of the directory entry
	LXI		DE,fcbDiskMapIndex
	DAD		D								; hl now addresses the disk map
	PUSH	BC								; save the set/reset bit
	MVI		C,fcbLength-fcbDiskMapIndex+1	; size of Disk Allocation Map + 1

ScanDiskMap0:								; loop once for each disk map entry
	POP		DE								; recall the set/reset bit
	DCR		C
	RZ

	PUSH	DE								; save the set/reset bit
	LDA		single							; single byte entry flag
	ORA		A
	JZ		ScanDiskMap1					; skip if two byte value
; single byte scan operation
	PUSH	BC								; save counter
	PUSH	HL								; save map address
	MOV		C,M
	MVI		B,0								; BC=block#
	JMP		ScanDiskMap2
; two byte scan operation
ScanDiskMap1:
	DCR		C								; adjust counter for double byte
	PUSH	BC								; save counter
;	MOV		C,M
	MOV		B,M
	INX		HL
;	MOV		B,M								; BC=block#
	MOV		C,M								; BC=block#
	PUSH	HL								; save map address
ScanDiskMap2:								; arrive here with BC=block#, E=0/1
	MOV		A,C
	ORA		B								; skip if = 0000
	CNZ		SetAllocBit						; bit set to 0/1 its in C
	POP		HL
	INX		HL								; to next bit position
	POP		BC								; recall counter
	JMP		ScanDiskMap0					; for another item
;
;-----------------------------------
;given allocation vector position BC, return with byte
;containing BC shifted so that the least significant
;bit is in the low order accumulator position.  HL is
;the address of the byte for possible replacement in
;memory upon return, and D contains the number of shifts
;required to place the returned value back into position

GetAllocBit:								; getallocbit
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
	MOV		C,A								; C shr 3 to C
	MOV		A,B
	ADD		A
	ADD		A
	ADD		A
	ADD		A
	ADD		A								; B shl 5
	ORA		C
	MOV		C,A								; bbbccccc to C
	MOV		A,B
	RRC
	RRC
	RRC
	ANI		11111b
	MOV		B,A								; BC shr 3 to BC
	LHLD	caAllocVector					; base address of allocation vector
	DAD		B
	MOV		A,M								; byte to A, hl = .alloc(BC shr 3)
	 ;now move the bit to the low order position of A
GetAllocBitl:
	RLC
	DCR		E
	JNZ		GetAllocBitl
	RET

;-----------------------------------
; BC is the bit position of ALLOC to set or reset.  The
; value of the bit is in register E.
SetAllocBit:
	PUSH	DE
	CALL	GetAllocBit						; shifted val A, count in D
	ANI		11111110b						; mask low bit to zero (may be set)
	POP		BC
	ORA		C								; low bit of C is masked into A
	JMP		RotateAndReplace				; to rotate back into proper position
	;ret
;-----------------------------------
; byte value from ALLOC is in register A, with shift count
; in register C (to place bit back into position), and
; target ALLOC position in registers HL, rotate and replace
RotateAndReplace:
	RRC
	DCR	D
	JNZ	RotateAndReplace					; back into position
	MOV	M,A									; back to ALLOC
	RET
;-----------------------------------

;move to home position, then offset to start of dir
Home:
	CALL	bcHome							; move to track 00, sector 00 reference
	LXI		HL,dpbOFF						; get track ofset at begining
	MOV		C,M
	INX		HL
	MOV		B,M
	CALL	bcSettrk						; select first directory position

	XRA		A								; constant zero to accumulator
	LHLD	caTrack
	MOV		M,A
	INX		HL
	MOV		M,A								; curtrk=0000
	LHLD	caSector
	MOV		M,A
	INX		HL
	MOV		M,A								; currec=0000
	RET


;*****************************************************************

;*****************************************************************
;*****************************************************************
; set directory counter to end  -1
SetEndDirectory:
	LXI		HL,EOD
	SHLD	dirEntryIndex
	RET
;---------------
SetDataDMA:									; setdata
	LXI		HL,InitDAMAddress
	JMP		SetDMA							; to complete the call
;---------------
SetDirDMA:									; setdir
	LXI		HL,caDirectoryDMA

SetDMA:										; setdma
	MOV		C,M
	INX		HL
	MOV		B,M								; parameter ready
	JMP		bcSetdma						; call bios to set
;---------------
;---------------
; return zero flag if at end of directory
; non zero if not at end (end of dir if dirEntryIndex = 0ffffh)
EndOfDirectory:
	LXI		HL,dirEntryIndex
	MOV		A,M								; may be 0ffh
	INX		HL
	CMP		M								; low(dirEntryIndex) = high(dirEntryIndex)?
	RNZ										; non zero returned if different
											; high and low the same, = 0ffh?
	INR		A								; 0ffh becomes 00 if so
	RET
;---------------
; read a directory entry into the directory buffer
ReadDirRecord:
	CALL	SetDirDMA						; directory dma
	CALL	ReadBuffer						; directory record loaded
    JMP		SetDataDMA						; to data dma address
	;ret
;---------------
; read next directory entry, with C=true if initializing
ReadDirectory:
	LHLD	dpbDRM
	XCHG									; determine number of directory entries
	LHLD	dirEntryIndex					; index into directory
	INX		HL
	SHLD	dirEntryIndex					; initialize directory index
; continue while dpbDRM >= dirEntryIndex (dpbDRM-dirEntryIndex no cy)
	CALL	DEminusHL2HL					; DE-HL - processed all entries ?
	JNC		ReadDirectory0					; no - do it again
; yes, set dirEntryIndex to end of directory
	CALL	SetEndDirectory
	RET

; not at end of directory, seek next element, initialization flag is in C
ReadDirectory0:
	LDA		dirEntryIndex
	ANI		dirEntryMask					; low(dirEntryIndex) and dirEntryMask
	MVI		B,fcbShift						; to multiply by fcb size to get the correct index in dir record
ReadDirectory1:
	ADD		A
	DCR		B
	JNZ		ReadDirectory1
; A = (low(dirEntryIndex) and dirEntryMask) shl fcbShift
	STA		dirBlockIndex					; ready for next dir operation
	ORA		A
	RNZ										; return if not a new record (Directory Block)
	PUSH	BC								; save initialization flag C
	CALL	SeekDir							; seek$dir seek proper record
	CALL	ReadDirRecord					; read the directory record
	POP		BC								; recall initialization flag
	JMP		CalculateCheckSum				; checksum the directory elt
;---------
;seek the record containing the current dir entry
SeekDir:
	LHLD	dirEntryIndex					; directory counter to HL
	MVI		C,dirEntryShift					; 4 entries per record
	CALL	ShiftRightHLbyC 				; value to HL
	SHLD	currentBlock
	SHLD	dirRecord						; ready for seek
	JMP		Seek
;---------------------------
Seek:						; seek
	;seek the track given by currentBlock (actual record number)

	LXI		HL,currentBlock					; contains the cpm record number
	MOV		C,M								; Actual Record Number Low
	INX		HL
	MOV		B,M								; Actual Record Number High
	LHLD	caSector		 				; Current Sector
	MOV		E,M								; Current Sector Number Low
	INX		HL
	MOV		D,M								; Current Sector Number High
	LHLD	caTrack 						; Current track
	MOV		A,M								; Current track Number Low - temp
	INX		HL
	MOV		H,M								; Current track Number High
	MOV		L,A								; Current track Number Low
;(BC) - cpmRecord Number
;(DE) - Current Sector
;(HL) - Current Track

	;loop while currentBlock < currec   ?????
Seek0:
	MOV		A,C								;   Current Sector
	SUB		E								;
	MOV		A,B								; - cpmRecord Number
	SBB		D								;
	JNC		Seek1							; skip if cpmRecord Number >= Current Sector

	PUSH	HL
	LHLD	dpbSPT
	MOV		A,E
	SUB		L
	MOV		E,A
	MOV		A,D
	SBB		H
	MOV		D,A
	POP		HL
	DCX		HL
	JMP		Seek0

Seek1:

	PUSH	HL								; Save Current Track
	LHLD	dpbSPT							; records per track
	DAD		D								; HL = Current Sector + sectorsPerClynder
	MOV		A,C								;     cpmRecord Number
	SUB		L								;
	MOV		A,B								;  - HL (above)
	SBB		H								;
	JC	Seek2								; skip if cpmRecord Number > HL (above)

	XCHG

	POP	HL
	INX	HL
	JMP	Seek1

Seek2:
	POP		HL								; retreive Current Track
	PUSH	BC								; save  cpmRecord Number
	PUSH	DE								; save  Current Sector
	PUSH	HL								; save CurrentTrack
; stack contains CurrentTrack , Current Sector, cpmRecord Number
	XCHG									; DE => CurrentTrack, HL => Current Sector
	LHLD	dpbOFF							; Block Zero starting Track
	DAD		D								; HL =  actual physical Track number
	MOV		B,H
	MOV		C,L								; BC has physical Track number
	CALL	bcSettrk						; track set up
						; note that BC - curtrk is difference to move in bios
	POP		DE								; recall CurrentTrack
	LHLD	caTrack							; point at current Track
	MOV		M,E
	INX		H
	MOV		M,D								; current Track updated
; now compute sector as currentBlock-currec
	POP		DE								; recall Current Sector
	LHLD	caSector						; point at current Sector
	MOV		M,E
	INX		HL
	MOV		M,D								; current sector updated / DE has currentSector
	POP		BC								; recall cpmRecord Number
	MOV		A,C								; cpmRecord Number
	SUB		E
	MOV		C,A								; - currentSector
	MOV		A,B
	SBB		D
	MOV		B,A								; back into BC
	JMP	bcSetsec							; sector selected
	;ret
;************* CheckSum *******************************
; compute current checksum record
; if C = TRUE , update the allocation vector
;
; or check for = if not dirRecord < dpbCKS ????

NewCheckSum:
	MVI		C,TRUE

CalculateCheckSum:
	LHLD	dirRecord
	XCHG
	LHLD	dpbCKS							; size of checksum vector
	CALL	DEminusHL2HL					; DE-HL
	RNC										; skip checksum if past checksum vector size
	PUSH	BC								; save init flag
	CALL	ComputeCheckSum					; check sum value to A
	LHLD	caCheckSum						; address of check sum vector
	XCHG
	LHLD	dirRecord						; value of dirRecord
	DAD		D								; HL = .check(dirRecord)
	POP		BC								; recall true=0ffh or false=00 to C
	INR		C								; 0ffh produces zero flag
	JZ		SetNewCheckSum
; not initializing, compare
	CMP		M								; compute$cs=check(dirRecord)?
	RZ										; no message if ok
; possible checksum error, are we beyond the end of the disk?
	CALL	StillInDirectory
	RNC										; no message if so
	CALL	SetDiskReadOnly					; read/only disk set
	RET

;initializing the checksum
SetNewCheckSum:
	MOV		M,A
	RET
;------------------
;compute checksum for current directory buffer
ComputeCheckSum:
	MVI		C,cpmRecordSize					; size of directory buffer
	LHLD	caDirectoryDMA					; current directory buffer
	XRA		A								; clear checksum value
ComputeCheckSum0:
	ADD		M
	INX		H
	DCR		C								; cs=cs+buff(cpmRecordSize-C)
	JNZ		ComputeCheckSum0
	RET										; with checksum in A
;*****************************************************************
; compute the address of a directory element at positon dirBlockIndex in the buffer
GetDirElementAddress:
	LHLD	caDirectoryDMA
	LDA		dirBlockIndex
	JMP		AddAtoHL
;---------------------
;if not still in directory set max value
SetDirectoryEntry:
	CALL	StillInDirectory
	RC
; return if yes,otherwise, HL = DirMaxValue+1, DE = directoryCount

	INX	D
	MOV	M,D
	DCX	H
	MOV	M,E
	RET
; return CY if entry is still in Directory
StillInDirectory:
	LHLD	dirEntryIndex
	XCHG									; DE = directory counter
	LHLD	caDirMaxValue					; HL=caDirMaxValue
	MOV	A,E
	SUB	M									; low(dirEntryIndex) - low(cdrmax)
	INX	H									; HL = .cdrmax+1
	MOV	A,D
	SBB	M									; hi(dirEntryIndex) - hig(cdrmax)
;condition dirEntryIndex - cdrmax  produces cy if cdrmax>dirEntryIndex
	RET
;---------------------
;compute fcbRCIndex and NEXT_RECORD addresses for get/setfcb
; returns with DE pointing at RC from FCB
;         with HL pointing at Next Record
GetFcbAddress:					; getfcba
	LHLD	paramDE
	LXI		DE,fcbRCIndex
	DAD		DE
	XCHG									; DE=.fcb(fcbRCIndex)
	LXI		HL,(NEXT_RECORD-fcbRCIndex)
	DAD		DE								; HL=.fcb(NEXT_RECORD)
	RET
;---------------------
;set variables from currently fcb - NEXT_RECORD, RC, EXM
SetRecordVars:
	CALL	GetFcbAddress					; DE => fcbRCIndex(RC) , HL => NEXT_RECORD
	MOV		A,M
	STA		cpmRecord 						; cpmRecord=fcb(NEXT_RECORD)
	XCHG
	MOV		A,M
	STA		fcbRecordCount					; fcbRecordCount=fcb(fcbRCIndex)
	CALL	GetExtentAddress				; HL=.fcb(fcbExtIndex)
	LDA		dpbEXM							; extent mask to a
	ANA		M								; fcb(fcbExtIndex) and dpbEXM
	STA		extentValue						; save extent number
	RET
;---------------------
;update variables from I/O in  fcb
UpdateRecordVars:
	CALL	GetFcbAddress					; DE => fcbRCIndex(RC) , HL => NEXT_RECORD
	LDA		seqReadFlag
	MOV		C,A								; =1 if sequential i/o
	LDA		cpmRecord							; get NEXT_RECORD
	ADD		C
	MOV		M,A								; fcb(NEXT_RECORD)=cpmRecord+seqReadFlag
	XCHG
	LDA		fcbRecordCount
	MOV		M,A								; fcb(fcbRCIndex)=fcbRecordCount
	RET
;---------------------
;set file Attributes for current fcb
SetAttributes:
	MVI		C,fcbExtIndex
	CALL	Search4DirElement				; through file type
SetAttributes1:
	CALL	EndOfDirectory
	RZ										; exit at end of dir
	MVI		C,0
	MVI		E,fcbExtIndex					;copy name
	CALL	CopyDir
	CALL	Search4NextDirElement
	JMP		SetAttributes1
;
;*****************************************************************

;*****************************************************************
;********************** File  Routines ***************************
;*****************************************************************
;open file
; IN  - (DE)	FCB Address
; OUT - (A)	Directory Code
;	0-3 = success ; 0FFH = File Not Found
vOpenFile:					;
	CALL	ClearModuleNum					; clear the module number
	CALL	Reselect						; do we need to reselect disk?
	JMP		OpenFile
	;ret ;jmp goback
;-----------------------------------------------------------------
;close file
vCloseFile:									; func16: (16 - 10) Close File
	CALL	Reselect
	JMP		CloseDirEntry
;-----------------------------------------------------------------
;search for first occurrence of a file
; In - (DE)	FCB Address
; OUT - (A)	Directory Code
;	0-3 = success ; 0FFH = File Not Found
vFindFirst:									; func17: (17 - 11) Search for first
	MVI		C,0								; length assuming '?' true
	LHLD	paramDE
	MOV		A,M
	CPI		QMARK							; no reselect if ?
	JZ		QMarkSelect						; skip reselect if so

	CALL	ClearModuleNum					; module number zeroed
	CALL	Reselect
	MVI		C,nameLength
QMarkSelect:								; qselect:
	CALL	Search4DirElement
	JMP		CopyDirEntryToUser				; copy directory entry to user
;-----------------------------------------------------------------
;search for next occurrence of a file name
; OUT - (A)	Directory Code
;	0-3 = success ; 0FFH = File Not Found
vFindNext:									; func18: (18 - 12) Search for next
	LHLD	searchAddress
	SHLD	paramDE
	CALL	Reselect
	CALL	Search4NextDirElement
	JMP		CopyDirEntryToUser				; copy directory entry to user
;-----------------------------------------------------------------
;search for next occurrence of a file name
; OUT - (A)	Directory Code
;delete a file
vDeleteFile:								; func18: (19 - 13) Delete File
	CALL	Reselect
	CALL	DeleteFile
	JMP		DirLocationToReturnLoc
;-----------------------------------------------------------------
;read sequential
;IN  - (DE) FCB address
;OUT - (A) 00 = success and data available. else no read and no data
vReadSeq:									; func20: (20 - 14) read sequential
	CALL	Reselect
	CALL	ReadSeq
	RET
;-----------------------------------------------------------------
;write sequential
;IN  - (DE) FCB address
;OUT - (A) 00 = success and data available. else no read and no data
vWriteSeq:									; func21 (21 - 15) write sequention
	CALL	Reselect
	CALL	DiskWriteSeq
	RET
;-----------------------------------------------------------------
; Make file
; In - (DE)	FCB Address
; OUT - (A)	Directory Code
;	0-3 = success ; 0FFH = File Not Found
vMakeFile:									; func22 (22 - 16) Make file
	CALL	ClearModuleNum					; set S2 to Zero
	CALL	Reselect
	JMP		MakeNewFile
;-----------------------------------------------------------------
; Rename file
; In - (DE)	FCB Address
; OUT - (A)	Directory Code
;	0-3 = success ; 0FFH = File Not Found
vRenameFile:								; func23 (23 - 17) Rename File
	CALL	Reselect
	CALL	Rename
	JMP		DirLocationToReturnLoc
;-----------------------------------------------------------------
;-----------------------------------------------------------------
;*****************************************************************
;-----------------------------------------------------------------
;check current directory element for read/only status
CheckRODirectory:
	CALL	GetDirElementAddress			; address of element
;	JMP	CheckROFile
;------------
;check current buff(dptr) or fcb(0) for r/o status
CheckROFile:
	LXI		DE,fcbROfileIndex
	DAD		DE								; offset to ro bit
	MOV		A,M
	RAL
	RNC										; return if not set
	JMP		errReadOnlyFile					; exit to read only disk message
;-----------------------------------------------------------------
;check for write protected disk
CheckWrite:
	CALL	DoNotWrite
	RZ										; ok to write if not rodsk
	JMP		errReadOnlyDisk					; read only disk error
;-----------------------------------------------------------------
;return true if dir checksum difference occurred
DoNotWrite:
	LHLD	ReadOnlyVector
	LDA		currentDisk
	MOV		C,A
	CALL	ShiftRightHLbyC
	MOV		A,L
	ANI		1BH								; 01BH
	RET										; non zero if nowrite
;-----------------------------------------------------------------
;sequential disk read operation
ReadSeq:
	MVI		A,1
	STA		seqReadFlag						; set flag for seqential read
;---
; read the disk
; read the next record from the current fcb
DiskRead:
	MVI		A,TRUE
	STA		readModeFlag					; read mode flag = true (OpenNextExt)

	CALL	SetRecordVars					; sets cpmRecord, fcbRecordCount and EXM
	LDA		cpmRecord
	LXI		HL,fcbRecordCount
	CMP		M								; cpmRecord-fcbRecordCount
											; skip if  cpmRecord < fcbRecordCount
	JC		RecordOK
; not enough records in the extent
	CPI		RecordsPerExtent				; cpmRecord = 128?   *** Records in an Extent
	JNZ		DiskEOF							; skip if cpmRecord<>128
	CALL	OpenNextExt						; go to next extent if so
	XRA		A
	STA		cpmRecord						; cpmRecord=00
; now check for open ok
	LDA		lowReturnStatus
	ORA		A
	JNZ		DiskEOF
	; stop at eof
; arrive with fcb addressing a record to read
RecordOK:									; recordok:
	CALL	GetBlockNumber					; save it in currentBlock
	CALL	IsAllocated						; currentBlock=0000?
	JZ		DiskEOF							; get out if not allocated already

	CALL	SetActualRecordAdd				; currentBlock now a record value
	CALL	Seek							; to proper track,sector
	CALL	ReadBuffer						; to dma address
	CALL	UpdateRecordVars				; update variables from I/O in  fcb
	RET
DiskEOF:									; diskeof:
	JMP		SetLowReturnTo1					; lowReturnStatus = 1
	;ret
;-----------------------------------------------------------------
;sequential disk write
DiskWriteSeq:
	MVI		A,1
	STA		seqReadFlag
;--------
;disk write
DiskWrite:
	MVI		A,FALSE
	STA		readModeFlag
											; write record to currently selected file
	CALL	CheckWrite						; in case write protected
	LHLD	paramDE							; HL = .fcb(0)
	CALL	CheckROFile						; may be a read-only file
	CALL	SetRecordVars					; set local Record parameters
	LDA		cpmRecord
	CPI		highestRecordNumber + 1			; Still in the same extent?
	JC		DiskWrite1						; skip if in the same Extent
	CALL	SetLowReturnTo1
	RET										; Exit ???????????

; can write the next record, so continue
DiskWrite1:
	CALL	GetBlockNumber					; sets up actual block number
	CALL	IsAllocated
	MVI		C,WriteAllocated				; assume a normal write operation for WriteBuffer
	JNZ		DiskWrite3
; not allocated -
; the argument to getblock is the starting position for the disk search
; and should be the last allocated block for this file,
; or the value 0 if no space has been allocated

	CALL	GetDiskMapIndex					; return with Disk Map index in Acc
	STA		diskMapIndex					; save for later
	LXI		BC,0000h						; may use block zero
	ORA		A
	JZ		FirstBlock						; skip if no previous block
; previous block exists
	MOV		C,A
	DCX		BC								; previous block # in BC
	CALL	GetDiskMapValue					; previous block # to HL
	MOV		B,H
	MOV		C,L								; BC=prev block#
; BC = 0000, or previous block #
FirstBlock:
	CALL	GetClosestBlock					; block # to HL
; arrive here with block# or zero
	MOV		A,L
	ORA		H
	JNZ		BlockOK
; cannot find a block to allocate
	MVI		A,2
	STA		lowReturnStatus
	RET										; lowReturnStatus=2

BlockOK:
	SHLD	currentBlock					; allocated block number is in HL
	XCHG									; block number to DE
	LHLD	paramDE
	LXI		BC,fcbDiskMapIndex
	DAD		BC								; HL=.fcb(fcbDiskMapIndex)
	LDA		single
	ORA		A								; set flags for single byte dm
	LDA		diskMapIndex					; recall dm index
	JZ		Allocate16Bit					; skip if allocating word
; else allocate using a byte value
	CALL	AddAtoHL
	MOV		M,E								; single byte alloc
	JMP		DiskWrite2						; to continue

Allocate16Bit:								; allocate a word value

	MOV		C,A
	MVI		B,0								; double(diskMapIndex)
	DAD		BC
	DAD		BC								; HL=.fcb(diskMapIndex*2)
	MOV		M,D
	INX		HL
	MOV		M,E								; double wd
; disk write to previously unallocated block
DiskWrite2:
	MVI		C,WriteUnallocated				; marked as unallocated write

; continue the write operation of no allocation error
; C = 0 if normal write, 1 if directory write, 2 if to prev unalloc block

DiskWrite3:
	LDA		lowReturnStatus
	ORA		A
	RNZ										; stop if non zero returned value

	PUSH	BC								; save write flag ( in C see above)
	CALL	SetActualRecordAdd				; currentBlock set to actual record number
	CALL	Seek							; to proper file position
	POP		BC								; get write flag
	PUSH	BC								; restore/save write flag (C=2 if new block)
	CALL	WriteBuffer						; written to disk
	POP		BC								; C = 2 if a new block was allocated, 0 if not
											; increment record count if fcbRecordCount<=cpmRecord
	LDA		cpmRecord
	LXI		HL,fcbRecordCount
	CMP		M 								; cpmRecord-fcbRecordCount
	JC		DiskWrite4
; fcbRecordCount <= cpmRecord
	MOV		M,A
	INR		M								; fcbRecordCount = cpmRecord+1
	MVI		C,2								; mark as record count incremented
DiskWrite4:
; A has cpmRecord, C=2 if new block or new record#
	DCR		C
	DCR		C
	JNZ		DiskWrite5
	PUSH	PSW								; save cpmRecord value
	CALL	GetModuleNum					; HL=.fcb(fcbS2Index), A=fcb(fcbS2Index)
; reset the file write flag to mark as written fcb
	ANI		7FH								; not writeFlagMask
	MOV		M,A								; fcb(fcbS2Index) = fcb(fcbS2Index) and 7fh
	POP		PSW								; restore cpmRecord
DiskWrite5:
; check for end of extent, if found attempt to open next extent in preparation for next write
	CPI		highestRecordNumber				; cpmRecord=highestRecordNumber?
	JNZ		DiskWrite7						; skip if not
; may be random access write, if so we are done
	LDA		seqReadFlag
	ORA		A
	JZ		DiskWrite7						; skip next extent open op
; update current fcb before going to next extent
	CALL	UpdateRecordVars				;update variables from I/O in  fcb
	CALL	OpenNextExt						; readModeFlag=false
; cpmRecord remains at highestRecordNumber causing eof if no more directory space is available
	LXI		HL,lowReturnStatus
	MOV		A,M
	ORA		A
	JNZ		DiskWrite6						; no space
; space available, set cpmRecord=255
	DCR		A
	STA		cpmRecord						; goes to 00 next time
DiskWrite6:
	MVI		M,0								; lowReturnStatus = 00 for returned value
DiskWrite7:
	JMP		UpdateRecordVars				; update variables from I/O in  fcb
	;ret
;-----------------------------------------------------------------
;close the current extent  and open the next one if possible.
;readModeFlag is true if in read mode
OpenNextExt:					; open$reel
	XRA		A
	STA		fcbCopiedFlag					; set true if actually copied
	CALL	CloseDirEntry					; close current extent
; lowReturnStatus remains at enddir if we cannot open the next ext
	CALL	EndOfDirectory
	RZ										; return if end
	LHLD	paramDE							; increment extent number
	LXI		BC,fcbExtIndex
	DAD		BC								; HL=.fcb(fcbExtIndex)
	MOV		A,M
	INR		A
	ANI		maxExtValue
	MOV		M,A								; fcb(fcbExtIndex)=++1
	JZ		OpenNextModule					; move to next module if zero
											; may be in the same extent group
	MOV		B,A
	LDA		dpbEXM
	ANA		B
; if result is zero, then not in the same group
	LXI		HL,fcbCopiedFlag				; true if the fcb was copied to directory
	ANA		M 								; produces a 00 in accumulator if not written
	JZ		OpenNextExt1					; go to next physical extent
											; result is non zero, so we must be in same logical ext
	JMP		OpenNextExt2					; to copy fcb information
; extent number overflow, go to next module

OpenNextModule:
	LXI		BC,(fcbS2Index-fcbExtIndex)
	DAD		BC								; HL=.fcb(fcbS2Index)
	INR		M								; fcb(fcbS2Index)=++1
											; module number incremented, check for overflow
	MOV		A,M
	ANI		moduleMask						; mask high order bits
	JZ		OpenNextExtError				; cannot overflow to zero
; otherwise, ok to continue with new module

OpenNextExt1:
	MVI		C,nameLength
	CALL	Search4DirElement				; next extent found?
	CALL	EndOfDirectory
	JNZ		OpenNextExt2
; end of file encountered
	LDA		readModeFlag
	INR		A								; 0ffh becomes 00 if read
	JZ		OpenNextExtError				; sets lowReturnStatus = 1
; try to extend the current file
	CALL	MakeNewFile
; cannot be end of directory
	CALL	EndOfDirectory
	JZ		OpenNextExtError				; with lowReturnStatus = 1
	JMP		OpenNextExt3

; not end of file, open
OpenNextExt2:
	CALL	OpenFileCopyFCB
OpenNextExt3:
	CALL	SetRecordVars					; Set Record parameters
	XRA		A
	STA		lowReturnStatus					; lowReturnStatus = 0
	RET										; with lowReturnStatus = 0

; cannot move to next extent of this file
OpenNextExtError:
	CALL	SetLowReturnTo1					; lowReturnStatus = 1
	JMP		SetFileWriteFlag				; ensure that it will not be closed
;-----------------------------------------------------------------
;rename the file described by the first half of the currently addressed FCB.
;the new name is contained in the last half of the FCB. The file name and type
;are changed, but the reel number is ignored.  the user number is identical
Rename:
	CALL	CheckWrite						; may be write protected
; search up to the extent field
	MVI		C,fcbExtIndex					; extent number field index
	CALL	Search4DirElement
; copy position 0
	LHLD	paramDE
	MOV		A,M								; HL=.fcb(0), A=fcb(0)
	LXI		DE,fcbDiskMapIndex
	DAD		DE								; HL=.fcb(fcbDiskMapIndex)
	MOV		M,A								; fcb(fcbDiskMapIndex)=fcb(0)
; assume the same disk drive for new named file
Rename1:
	CALL	EndOfDirectory
	RZ										; stop at end of dir
; not end of directory, rename next element
	CALL	CheckRODirectory				; may be read-only file
	MVI		C,fcbDiskMapIndex
	MVI		E,fcbExtIndex
	CALL	CopyDir
; element renamed, move to next
	CALL	Search4NextDirElement
	JMP		Rename1
;-----------------------------------------------------------------
;create a new file by creating a directory entry then opening the file
MakeNewFile:
	CALL	CheckWrite						; may be write protected
	LHLD	paramDE
	PUSH	HL								; save fcb address, look for e5
	LXI		HL,emptyFCB
	SHLD	paramDE							; paramDE = .empty
	MVI		C,1
	CALL	Search4DirElement				; length 1 match on empty entry
	CALL	EndOfDirectory					; zero flag set if no space
	POP		HL								; recall paramDE address
	SHLD	paramDE							; in case we return here
	RZ										; return with error condition 255 if not found
	XCHG									; DE = paramDE address
; clear the remainder of the fcb
	LXI		HL,nameLength
	DAD		DE								; HL=.fcb(nameLength)
	MVI		C,fcbLength-nameLength			; number of bytes to fill
	XRA		A								; clear accumulator to 00 for fill
MakeNewFile1:
	MOV		M,A
	INX		HL
	DCR		C
	JNZ		MakeNewFile1
	LXI		HL,fcbS1Index
	DAD		DE								; HL = .fcb(fcbS1Index)
	MOV		M,A								; fcb(fcbS1Index) = 0
	CALL	SetDirectoryEntry				; may have extended the directory
; now copy entry to the directory
	CALL	CopyFCB
; and set the file write flag to "1"
	JMP		SetFileWriteFlag
;-----------------------------------------------------------------
;delete the currently addressed file
DeleteFile:
	CALL	CheckWrite						; write protected ?
	MVI		C,fcbExtIndex					; extent number field
	CALL	Search4DirElement				; search through file type
DeleteFile1:
						; loop while directory matches
	CALL	EndOfDirectory
	RZ										; exit if end
; set each non zero disk map entry to 0 in the allocation vector
	CALL	CheckRODirectory				; ro disk error if found
	CALL	GetDirElementAddress			; HL=.buff(dptr)
	MVI		M,emptyDir
	MVI		C,0
	CALL	ScanDiskMap						; alloc elts set to 0
	CALL	WriteDir						; write the directory
	CALL	Search4NextDirElement			; to next element
	JMP		DeleteFile1						; for another record
;-----------------------------------------------------------------
;locate the directory element and re-write it
CloseDirEntry:
	XRA		A
	STA		lowReturnStatus
	CALL	DoNotWrite						; return TRUE (0) if checksum change
	RNZ										; skip close if r/o disk
; check file write flag - 0 indicates written
	CALL	GetModuleNum					; fcb(fcbS2Index) in A
	ANI		writeFlagMask
	RNZ										; return if bit remains set
	MVI		C,nameLength
	CALL	Search4DirElement				; locate file
	CALL	EndOfDirectory
	RZ										; return if not found
; merge the disk map at paramDE with that at buff(dptr)
	LXI		BC,fcbDiskMapIndex
	CALL	GetDirElementAddress
	DAD		BC
	XCHG									; DE is .buff(dptr+16)
	LHLD	paramDE
	DAD		BC								; DE=.buff(dptr+16), HL=.fcb(16)
	MVI		C,(fcbLength-fcbDiskMapIndex)	; length of single byte dm
CloseDirEntry1:
	LDA		single
	ORA		A
	JZ		CloseDirEntry4					; skip to double
; this is a single byte map
; if fcb(i) = 0 then fcb(i) = buff(i)
; if buff(i) = 0 then buff(i) = fcb(i)
; if fcb(i) <> buff(i) then error
	MOV		A,M
	ORA		A
	LDAX	D
	JNZ		CloseDirEntry2
; fcb(i) = 0
	MOV		M,A								; fcb(i) = buff(i)
CloseDirEntry2:
	ORA		A
	JNZ		CloseDirEntry3
; buff(i) = 0
	MOV		A,M
	STAX	DE								; buff(i)=fcb(i)
CloseDirEntry3:
	CMP		M
	JNZ		CloseDirEntryError				; fcb(i) = buff(i)?
	JMP		CloseDirEntry5					; if merge ok

; this is a double byte merge operation
CloseDirEntry4:
	CALL	Merge							; buff = fcb if buff 0000
	XCHG
	CALL	Merge
	XCHG									; fcb = buff if fcb 0000
; they should be identical at this point
	LDAX	DE
	CMP		M
	JNZ		CloseDirEntryError				; low same?
	INX		DE
	INX		HL								; to high byte
	LDAX	DE
	CMP		M
	JNZ		CloseDirEntryError				; high same?
;	merge operation ok for this pair
	DCR			C							; extra count for double byte
CloseDirEntry5:
	INX		DE
	INX		HL								; to next byte position
	DCR		C
	JNZ		CloseDirEntry1					; for more
; end of disk map merge, check record count DE = .buff(dptr)+32, HL = .fcb(32)
	LXI		BC,-(fcbLength-fcbExtIndex)
	DAD		BC
	XCHG
	DAD		BC
											; DE = .fcb(fcbExtIndex), HL = .buff(dptr+fcbExtIndex)
	LDAX	DE								; current user extent number
; if fcb(ext) >= buff(fcb) then	buff(ext) := fcb(ext), buff(rec) := fcb(rec)
	CMP		M
	JC		CloseDirEntryEnd
; fcb extent number >= dir extent number
	MOV		M,A								; buff(ext) = fcb(ext)
; update directory record count field
	LXI		BC,(fcbRCIndex-fcbExtIndex)
	DAD		BC
	XCHG
	DAD		BC
; DE=.buff(fcbRCIndex), HL=.fcb(fcbRCIndex)
	MOV		A,M
	STAX	DE								; buff(fcbRCIndex)=fcb(fcbRCIndex)
CloseDirEntryEnd:
	MVI		A,TRUE
	STA		fcbCopiedFlag					; mark as copied
	CALL	SeekCopy						; ok to "WriteDir" here - 1.4 compat
	RET

; elements did not merge correctly
CloseDirEntryError:
	LXI		HL,lowReturnStatus
	DCR		M								; =255 non zero flag set
	RET
;-----------------------------------------------------------------
;enter from CloseDirEntry to seek and copy current element
SeekCopy:
	CALL	SeekDir							; to the directory element
	JMP		WriteDir						; write the directory element
	;ret
;-----------------------------------------------------------------
;write the current directory entry, set checksum
WriteDir:
	CALL	NewCheckSum						; initialize entry
	CALL	SetDirDMA						; directory dma
	MVI		C,1								; indicates a write directory operation
	CALL	WriteBuffer						; write the buffer
	JMP		SetDataDMA						; to data dma address
	;ret
;-----------------------------------------------------------------
;write buffer and check condition
;write type (wrtype) is in register C
;wrtype = 0 => normal write operation		WriteAllocated
;wrtype = 1 => directory write operation	WriteDirectory
;wrtype = 2 => start of new block			WriteUnallocated
WriteBuffer:
	CALL	bcWrite							; current drive, track, sector, dma
	ORA		A
	JNZ		erPermanentNoWait				; error if not 00
	RET
;-----------------------------------------------------------------
;read buffer and check condition
ReadBuffer:
	CALL	bcRead							; current drive, track, sector, dma
	ORA		A
	JNZ		erPermanentNoWait
	RET
;-----------------------------------------------------------------
;HL = .fcb1(i), DE = .fcb2(i),
;if fcb1(i) = 0 then fcb1(i) := fcb2(i)
Merge:
	MOV		A,M
	INX		HL
	ORA		M
	DCX		HL
	RNZ										; return if = 0000
	LDAX	DE
	MOV		M,A
	INX		DE
	INX		HL								; low byte copied
	LDAX	DE
	MOV		M,A
	DCX		DE
	DCX		HL								; back to input form
	RET
;-----------------------------------------------------------------
;compute closest disk block number from current block
;given allocation vector position BC, find the zero bit closest to this position
;by searching left and right.
;if found, set the bit to one and return the bit position in hl.
;if not found (i.e., we pass 0 on the left, or dpbDSM on the right), return 0000 in hl
GetClosestBlock:
	MOV		D,B
	MOV		E,C								; copy of starting position to de
TestLeft:
	MOV		A,C
	ORA		B
	JZ		TestRight						; skip if left=0000
; left not at position zero, bit zero?
	DCX		BC
	PUSH	DE
	PUSH	BC								; left,right pushed
	CALL	GetAllocBit
	RAR
	JNC		ReturnBlockNumber				; return block number if zero
; bit is one, so try the right
	POP		BC
	POP		DE								; left, right restored
TestRight:
	LHLD	dpbDSM							; value of maximum allocation#
	MOV		A,E
	SUB		L
	MOV		A,D
	SBB		H								; right=dpbDSM?
	JNC		ReturnBlockZero					; return block 0000 if so
	INX		DE
	PUSH	B
	PUSH	D								; left, right pushed
	MOV		B,D
	MOV		C,E								; ready right for call
	CALL	GetAllocBit
	RAR
	JNC		ReturnBlockNumber				; return block number if zero
	POP		DE
	POP		BC								; restore left and right pointers
	JMP		TestLeft						; for another attempt
ReturnBlockNumber:
	RAL
	INR		A								; bit back into position and set to 1
											; 	D contains the number of shifts required to reposition
	CALL	RotateAndReplace				; move bit back to position and store
	POP		HL
	POP		DE								; HL returned value, DE discarded
	RET

; cannot find an available bit, return 0000
ReturnBlockZero:
	LXI		HL,0000H
	RET
;-----------------------------------------------------------------
;compute disk block number from current fcb
GetBlockNumber:
	CALL	GetDiskMapIndex					; 0...15 in register A
	MOV		C,A
	MVI		B,0
	CALL	GetDiskMapValue					; return value in HL
	SHLD	currentBlock					; save for later
	RET
;-----------------------------------------------------------------
;is  block allocated
IsAllocated:
	LHLD	currentBlock
	MOV		A,L
	ORA		H
	RET
;-----------------------------------------------------------------
;compute actual record address
; result = currentBlock * ( 2**BSH)
SetActualRecordAdd:
	LDA		dpbBSH							; Block Shift  to reg A
	LHLD	currentBlock

SetActualRecordAdd1:
	DAD		HL
	DCR		A								; shl(currentBlock,dpbBSH)
	JNZ		SetActualRecordAdd1
; HL has Record number for start of the block;
	LDA		dpbBLM							; get block mask
	MOV		C,A								; to get cpmRecord mod Block
	LDA		cpmRecord						; get index into block
	ANA		C								; masked value in A
	ORA		L
	MOV		L,A								; to HL
	SHLD	currentBlock					; currentBlock=HL or (cpmRecord and dpbBLM)
; *** currentBlock now has current record number - Starting record number + index into block
	RET
;-----------------------------------------------------------------
;---------------------
;copy directory location to lowReturnStatus
DirLocationToReturnLoc:
	LDA		directoryFlag
	STA		lowReturnStatus
	RET
;---------------------
;clear the module number field for user open/make (S2)
ClearModuleNum:
	CALL	GetModuleNum
	MVI		M,0								; fcb(fcbS2Index)=0
	RET
;---------------------
;get data module number (high order bit is fwf -file write flag)
GetModuleNum:
	LHLD	paramDE
	LXI		DE,fcbS2Index
	DAD		DE								; HL=.fcb(fcbS2Index)
	MOV		A,M
	RET										; A=fcb(fcbS2Index)
;---------------------
;check current fcb to see if reselection necessary
Reselect:
	MVI		A,TRUE
	STA		fResel							;mark possible reselect
	LHLD	paramDE
	MOV		A,M								; drive select code
	ANI		00011111B						; non zero is auto drive select
	DCR		A								; drive code normalized to 0..30, or 255
	STA		paramE							; save drive code
	CPI		30
	JNC		NoSelect
											; auto select function, save currentDisk
	LDA		currentDisk
	STA		entryDisk						; entryDisk=currentDisk
	MOV		A,M
	STA		fcbDisk							; save drive code
	ANI		11100000B
	MOV		M,A								; preserve hi bits
	CALL	SelectCurrent
NoSelect:									; noselect:

	LDA		currentUserNumber				; set user code 0...31
	LHLD	paramDE
	ORA		M
	MOV		M,A
	RET
;---------------------
;search for the directory entry, copy to fcb
OpenFile:
	MVI		C,nameLength
	CALL	Search4DirElement
	CALL	EndOfDirectory
	RZ										; return with lowReturnStatus=255 if end

; not end of directory, copy fcb information
OpenFileCopyFCB:
	CALL	GetExtentAddress				; HL=.fcb(fcbExtIndex)
	MOV		A,M
	PUSH	PSW
	PUSH	HL								; save extent#
	CALL	GetDirElementAddress
	XCHG									; DE = .buff(dptr)
	LHLD	paramDE							; HL=.fcb(0)
	MVI		C,NEXT_RECORD					; length of move operation
	PUSH	DE								; save .buff(dptr)
	CALL	Move							; from .buff(dptr) to .fcb(0)
; note that entire fcb is copied, including indicators
	CALL	SetFileWriteFlag				; sets file write flag
	POP		DE
	LXI		HL,fcbExtIndex
	DAD		DE								; HL=.buff(dptr+fcbExtIndex)
	MOV		C,M								; C = directory extent number
	LXI		HL,fcbRCIndex					; point at the record Count field
	DAD		DE								; HL=.buff(dptr+fcbRCIndex)
	MOV		B,M								; B holds directory record count
	POP		HL
	POP		PSW
	MOV		M,A								; restore extent number
; HL = .user extent#, B = dir rec cnt, C = dir extent#
; if user ext < dir ext then user := 128 records
; if user ext = dir ext then user := dir records
; if user ext > dir ext then user := 0 records
	MOV		A,C
	CMP		M
	MOV		A,B								; ready dir fcbRCIndex
	JZ		OpenRecordCount					; if same, user gets dir fcbRCIndex
	MVI		A,0
	JC		OpenRecordCount					; user is larger
	MVI		A,RecordsPerExtent				; directory is larger >>>RecordsPerExtent
OpenRecordCount:							;Acc has record count to fill
	LHLD	paramDE
	LXI		DE,fcbRCIndex
	DAD		DE
	MOV		M,A
	RET

;---------------------
;search for directory element of length C at info
Search4DirElement:
	MVI		A,0FFH
	STA		directoryFlag					; changed if actually found
	LXI		HL,searchLength
	MOV		M,C								; searchLength = C
	LHLD	paramDE
	SHLD	searchAddress					; searchAddress = paramDE
	CALL	SetEndDirectory					; dirEntryIndex = enddir
	CALL	Home							; to start at the beginning
	JMP		Search4NextDirElement
;---------------------
;search for the next directory element, assuming a previous
;call on search which sets searchAddress and searchLength
Search4NextDirElement:
	MVI		C,FALSE
	CALL	ReadDirectory					; read next dir element
	CALL	EndOfDirectory
	JZ		SearchDone						; skip to end if so
; not end of directory, scan for match
	LHLD	searchAddress
	XCHG									; DE=beginning of user fcb
	LDAX	DE								; first character
	CPI		emptyDir						; keep scanning if Dir entry is empty
	JZ		Search4NextDirElement1
; not emptyDir, may be end of logical directory
	PUSH	DE								; save search address
	CALL	StillInDirectory				; past logical end?
	POP		DE								; recall address
	JNC		SearchDone						; artificial stop
Search4NextDirElement1:
	CALL	GetDirElementAddress			; HL = buffa+dptr
	LDA		searchLength
	MOV		C,A								; length of search to c
	MVI		B,0								; bcounts up, c counts down
Search4NextLoop:
	MOV		A,C
	ORA		A
	JZ		EndDirElementSearch
	LDAX	DE
	CPI		QMARK
	JZ		Search4NextOK					; ? matches all
; scan next character if not fcbS1Index
	MOV		A,B
	CPI		fcbS1Index
	JZ		Search4NextOK
; not the fcbS1Index field, extent field?
	CPI		fcbExtIndex						; may be extent field
	LDAX	DE								; fcb character
	JZ		Search4Ext						; skip to search extent
	SUB		M
	ANI		07FH							; mask-out flags/extent modulus
	JNZ		Search4NextDirElement			; skip if not matched
	JMP		Search4NextOK					;matched character

; A has fcb character attempt an extent # match
Search4Ext:
	PUSH	BC								; save counters
	MOV		C,M								; directory character to c
	CALL	CompareExtents					; compare user/dir char
	POP		BC								; recall counters
	JNZ		Search4NextDirElement			; skip if no match

; current character matches
Search4NextOK:
	INX		DE
	INX		HL
	INR		B
	DCR		C
	JMP		Search4NextLoop

; entire name matches, return dir position
EndDirElementSearch:
	LDA		dirEntryIndex
	ANI		dirEntryMask
	STA		lowReturnStatus
; lowReturnStatus = low(dirEntryIndex) and 11b
	LXI		HL,directoryFlag
	MOV		A,M
	RAL
	RNC										; directoryFlag=0ffh?
; yes, change it to 0 to mark as found
	XRA		A
	MOV		M,A								; directoryFlag=0
	RET

; end of directory, or empty name
SearchDone:
	CALL	SetEndDirectory					; may be artifical end
	MVI		A,0FFH
	STA		lowReturnStatus
	RET
;---------------------
;get current extent field address to (HL)
GetExtentAddress:
	LHLD	paramDE
	LXI		DE,fcbExtIndex
	DAD		DE						;HL=.fcb(fcbExtIndex)
	RET
;---------------------
;Set file write flag
SetFileWriteFlag:
	CALL	GetModuleNum					; HL=.fcb(fcbS2Index), A=fcb(fcbS2Index)
	ORI		writeFlagMask					; set fwf (file write flag) to "1"
	MOV		M,A								; fcb(fcbS2Index)=fcb(fcbS2Index) or 80h
	RET										; also returns non zero in accumulator
;---------------------
;set lowReturnStatus to 1
SetLowReturnTo1:
	MVI		A,1
	STA		lowReturnStatus
	RET
;---------------------
;compare extent# in A with that in C, return nonzero if they do not match
CompareExtents:
	PUSH	BC								; save C's original value
	PUSH	PSW
	LDA		dpbEXM
	CMA
	MOV		B,A
											; B has negated form of extent mask
	MOV		A,C
	ANA		B
	MOV		C,A								; low bits removed from C
	POP		PSW
	ANA		B								; low bits removed from A
	SUB		C
	ANI		maxExtValue						; set flags
	POP		BC								; restore original values
	RET
;---------------------
;copy the directory entry to the user buffer
CopyDirEntryToUser:
	LHLD	caDirectoryDMA
	XCHG									; source is directory buffer
	LHLD	InitDAMAddress					; destination is user dma address
	MVI		C,cpmRecordSize					; copy entire record
	JMP		Move
;---------------------
;copy the whole file control block
CopyFCB:
	MVI		C,0
	MVI		E,fcbLength						; start at 0, to fcblen-1
	JMP		CopyDir
;---------------------
;copy fcb information starting at C for E bytes into the currently addressed directory entry
CopyDir:
	PUSH	DE								; save length for later
	MVI		B,0								; double index to BC
	LHLD	paramDE							; HL = source for data
	DAD		BC
	XCHG									; DE=.fcb(C), source for copy
	CALL	GetDirElementAddress			; HL=.buff(dptr), destination
	POP		BC								; DE=source, HL=dest, C=length
	CALL	Move							; data moved
;enter from close to seek and copy current element
SeekAndCopy:								; seek$copy:
	CALL	SeekDir							; seek$dir ;to the directory element
	JMP	WriteDir							; write the directory element
;---------------------
;Return the  disk map Index for cpmRecord in the ACC
;  account for multiple extents in 1 physical Directory entry
GetDiskMapIndex:							; dm$position
	LXI		HL,dpbBSH						; get block shift value
	MOV		C,M								; shift count to C
	LDA		cpmRecord						; current virtual record to A
GetDiskMapIndex1:
	ORA		A								; reset the carry flag
	RAR
	DCR		C
	JNZ		GetDiskMapIndex1
											; A = shr(cpmRecord,dpbBSH) = cpmRecord/2**(sect/block)
											; A has the relative position in the block.
	MOV		B,A								; save it for later addition
	MVI		A,8
	SUB		M								; 8-dpbBSH to accumulator
	MOV		C,A								; extent shift count in register c
	LDA		extentValue						; extent value ani extmsk
GetDiskMapIndex2:							; dmpos1:
											; dpbBSH = 3,4,5,6,7, C=5,4,3,2,1
											; shift is 4,3,2,1,0
	DCR		C
	JZ		GetDiskMapIndex3
	ORA		A								; clear the carry flag
	RAL
	JMP		GetDiskMapIndex2

; The ACC has the Block Number for this record
GetDiskMapIndex3:
											; arrive here with A = shl(ext and extmsk,7-dpbBSH)
	ADD	B 									; add the previous shr(cpmRecord,dpbBSH) value
											; A is one of the following values, depending upon alloc
											; bks dpbBSH
											; 1k   3     v/8 + extentValue * 16
											; 2k   4     v/16+ extentValue * 8
											; 4k   5     v/32+ extentValue * 4
											; 8k   6     v/64+ extentValue * 2
											; 16k  7     v/128+extentValue * 1
	RET 									; with disk map position in A
;---------------------
; Enter with Disk Map Index in BG
; Return disk map value  in HL
GetDiskMapValue:
	LHLD	paramDE							; base address of file control block
	LXI		DE,fcbDiskMapIndex				; offset to the disk map
	DAD		DE								; HL =.diskmap
	DAD		BC								; index by a single byte value
	LDA		single							; single byte/map entry?
	ORA		A
	JZ		GetDiskMap16Bit 				; get disk map single byte
	MOV		L,M
	MVI		H,0
	RET										; with HL=00bb
GetDiskMap16Bit:							; getdmd:
	DAD		BC								; HL=.fcb(dm+i*2)
											; double precision value returned
	MOV		D,M
	INX		HL
	MOV		E,M
	XCHG
	RET
;---------------------
;---------------------
;*****************************************************************
;************************ Utilities ******************************
;*****************************************************************
AddAtoHL:
	ADD		L
	MOV		L,A
	RNC
	INR		H
	RET
;----------
DEminusHL2HL:
	MOV		A,E
	SUB		L
	MOV		L,A
	MOV		A,D
	SBB		H
	MOV		H,A
	RET
;-------------
ShiftRightHLbyC:
	INR		C
ShiftRightHLbyC0:
	DCR		C
	RZ
	MOV		A,H
	ORA		A
	RAR
	MOV		H,A
	MOV		A,L
	RAR
	MOV		L,A
	JMP		ShiftRightHLbyC0
;-------
ShiftLeftHLbyC:
	INR		C
ShiftLeftHLbyC0:
	DCR		C
	RZ										; exit when done
	DAD		HL
	JMP		ShiftLeftHLbyC0
;*****************************************************************
;move data length of length C from source DE to HL
Move:
	INR		C
Move0:
	DCR		C
	RZ
	LDAX	D
	MOV		M,A
	INX		DE
	INX		HL
	JMP		Move0

;********** Console Routines***********************
;********** Console IN Routines********************
;read console character to A
ConIn:
	LXI	HL,kbchar
	MOV	A,M
	MVI	M,0
	ORA	A
	RNZ
	;no previous keyboard character ready
	JMP	bcConin ;get character externally
;----------------
;echo character if graphic CR, LF, TAB, or backspace
EchoNonGraphicCharacter:
	CPI	CR
	RZ										; carriage return?
	CPI	LF
	RZ										; line feed?
	CPI	TAB
	RZ										; TAB?
	CPI	CTRL_H
	RZ										; backspace?
	CPI	SPACE
	RET										; carry set if not graphic
;----------------
;read character with echo
ConsoleInWithEcho:
	CALL	ConIn
	CALL	EchoNonGraphicCharacter
	RC										; return if graphic character
; character must be echoed before return
	PUSH	PSW
	MOV		C,A
	CALL	TabOut
	POP		PSW
	RET										; with character in A
;********** Console OUT Routines*******************
ConBreak:
	LDA		kbchar
	ORA		A
	JNZ		ConBreak1 						; skip if active kbchar
	CALL	bcConst							; get status
	ANI		1
	RZ										; return if no char ready
	CALL	bcConin							; to A
	CPI		CTRL_S
	JNZ		ConBreak0						; check stop screen function
											; found CTRL_S, read next character
	CALL	bcConin							; to A
	CPI		CTRL_C
	JZ		WarmBoot						; CTRL_C implies re-boot
											; not a WarmBoot, act as if nothing has happened
	XRA		A
	RET										; with zero in accumulator
ConBreak0:
											; character in accum, save it
	STA		kbchar
ConBreak1:

	MVI		A,TRUE							; return with true set in accumulator
	RET
;
;
;display #, CR, LF for CTRL_X, CTRL_U, CTRL_R functions
;then move to startingColumn (starting columnPosition)
showHashCRLF:
	MVI		C,HASH_TAG
	CALL	ConsoleOut
	CALL	showCRLF
; columnPosition = 0, move to position startingColumn
showHashCRLF0:
	LDA		columnPosition
	LXI		HL,startingColumn
	CMP		M
	RNC										; stop when columnPosition reaches startingColumn
	MVI		C,SPACE
	CALL	ConsoleOut						; display blank
	JMP		showHashCRLF0
;
;carriage return line feed sequence
showCRLF:
	MVI		C,CR
	CALL	ConsoleOut
	MVI		C,LF
	JMP		ConsoleOut

;-------------
; print message until M(BC) = '$'
Print:
	LDAX	BC
	CPI		DOLLAR
	RZ		 								; stop on $
	INX		BC
	PUSH	BC
	MOV		C,A
	CALL	TabOut
	POP		BC
	JMP		Print

;----------------
; compute character position/write console char from C
; compcol = true if computing column position
ConsoleOut:					; conout
	LDA		compcol
	ORA		A
	JNZ		ConsoleOut1
; write the character, then compute the columnPosition
; write console character from C
	PUSH	BC
	CALL	ConBreak						; check for screen stop function
	POP		BC
	PUSH	BC								; recall/save character
	CALL	bcConout						; externally, to console
	POP		BC
	PUSH	BC								; recall/save character
; may be copying to the list device
	LDA		listeningToggle
	ORA		A
	CNZ		bcList							; to printer, if so
	POP		BC								; recall the character
ConsoleOut1:
	MOV		A,C								; recall the character
											; and compute column position
	LXI		HL,columnPosition				; A = char, HL = .columnPosition
	CPI		RUBOUT
	RZ										; no columnPosition change if nulls
	INR		M								; columnPosition = columnPosition + 1
	CPI		SPACE
	RNC										; return if graphic
											; not graphic, reset columnPosition position
	DCR		M								; columnPosition = columnPosition - 1
	MOV		A,M
	ORA		A
	RZ										; return if at zero
											; not at zero, may be backspace or end line
	MOV		A,C								; character back to A
	CPI		CTRL_H
	JNZ		NotBackSpace
											; backspace character
	DCR		M								; columnPosition = columnPosition - 1
	RET
NotBackSpace:								; notbacksp:  not a backspace character  eol?
	CPI		LF
	RNZ										; return if not
											; end of line, columnPosition = 0
	MVI		M,0								; columnPosition = 0
	RET

;********************************************************
;return version number
vGetVersion:								; func12 (12 - 0C)	 Get Verson
	MVI		A,VERSION
	STA		lowReturnStatus 				;lowReturnStatus = VERSION (high = 00)
	RET
;************Error message World*************************
errSelect:
	LXI		HL,evSelection
	JMP		GoToError
errReadOnlyDisk:
	LXI		HL,evReadOnlyDisk
	JMP		GoToError
errReadOnlyFile:
	LXI		HL,evReadOnlyFile
	JMP		GoToError
errPermanent:
	LXI		HL,evPermanent
	JMP		GoToError
;************Error message handler **********************
GoToError:
;HL = .errorhandler, call subroutine
	MOV		E,M
	INX		HL
	MOV		D,M								; address of routine in DE
	XCHG
	PCHL									; vector to subroutine
;************ Error Vectors *****************************
evPermanent: 	DW	erPermanent				; pererr permanent error subroutine
evSelection:	DW	erSelection				; selerr select error subroutine
evReadOnlyDisk:	DW	erReadOnlyDisk			; roderr ro disk error subroutine
evReadOnlyFile:	DW	erReadOnlyFile			; roferr ro file error subroutine
;************Error Routines ******************************
erPermanentNoWait:
	LXI		HL,emPermanent
	JMP		GoToError
erPermanent:
	LXI		HL,emPermanent
	CALL	displayAndWait					; to report the error
	CPI 	CTRL_C
	JZ		WarmBoot						; reboot if response is CTRL_C
	RET										; and ignore the error
;
erSelection:
	LXI		HL,emSelection
	JMP		waitB4boot						; wait console before boot
;
erReadOnlyDisk:
	LXI		HL,emReadOnlyDisk
	JMP		waitB4boot						; wait console before boot
;
erReadOnlyFile:
	LXI		HL,emReadOnlyFile				; drop through to wait for console
;
; wait for response before boot
waitB4boot:
	CALL	displayAndWait
	JMP		WarmBoot

;report error to console, message address in HL
displayAndWait:
	PUSH	HL								; save message pointer
	CALL	showCRLF						; stack mssg address, new line
	LDA		currentDisk
	ADI		ASCII_A
	STA		emDisk							; Problem disk name
	LXI		BC,emDisk0
	CALL	Print							; the error message
	POP		BC
	CALL	Print							; error mssage tail
	JMP		ConIn							; to get the input character
	;ret
;**************Error Messages*******************************
emDisk0:			DB		'Bdos Err On '
emDisk:				DB		' : $'
emPermanent:		DB		'Bad Sector$'
emSelection:		DB		'Select$'
emReadOnlyFile:		DB		'File '
emReadOnlyDisk:		DB		'R/O$'
;*****************************************************************

;********* file control block (fcb) constants ********************
fcbLength			EQU		32				; fcblen file control block size
fcbROfileIndex		EQU		9				; high order of first type char
fcbHiddenfileIndex	EQU		10				; invisible file in dir command
fcbExtIndex			EQU		12				; extent number field index
fcbS1Index			EQU		13				; S1 index
fcbS2Index			EQU		14				; S2 data module number index
fcbRCIndex			EQU		15				; record count field index
fcbDiskMapIndex		EQU		16				; dskmap disk map field

highestRecordNumber	EQU		RecordsPerExtent - 1; last record# in extent

dirEntriesPerRecord	EQU		cpmRecordSize/fcbLength; directory elts / record
dirEntryShift		EQU		2				; log2(dirEntriesPerRecord)
dirEntryMask		EQU		dirEntriesPerRecord-1
fcbShift			EQU		5				; log2(fcbLength)
;



maxExtValue			EQU		31				; largest extent number
moduleMask			EQU		15				; limits module number value
writeFlagMask		EQU		80h				; file write flag is high order fcbS2Index
nameLength			EQU		15				; namlen name length

emptyDir			EQU		0E5H			; empty empty directory entry
NEXT_RECORD			EQU		fcbLength		; nxtrec
RANDOM_REC_FIELD	EQU		NEXT_RECORD + 1	;ranrec random record field (2 bytes)
;
;	reserved file indicators
;	equ	11				; reserved
;*****************************************************************
;*****************************************************************

;***common values shared between bdosi and bdos******************
currentUserNumber:	DB	0					; usrcode current user number
paramDE:			DS	2					; ParamsDE information address
statusBDOSReturn:	DS	2					; address value to return
currentDisk:		DB	-1					; curdsk current disk number
lowReturnStatus		EQU	statusBDOSReturn	; lret low(statusBDOSReturn)

;********************* Local Variables ***************************
;     ************************
;     *** Initialized Data ***

emptyFCB:			DB	emptyDir			; efcb 0E5 = available dir entry
ReadOnlyVector:		DW	0					; rodsk read only disk vector
loggedDisks:		DW	0					; dlog	 logged-in disks
InitDAMAddress:		DW	DMABuffer			; dmaad tbuff initial dma address

;     *** Current Disk attributes ****
; These are set upon disk select
; data must be adjacent, do not insert variables
; address of translate vector, not used
; ca - currentAddress

caDirMaxValue:		DW	0000H				; cdrmaxa pointer to cur dir max value
caTrack:			DW	0000H				; curtrka current track address
caSector:			DW	0000H				; current Sector
caListSizeStart:
caDirectoryDMA:		DW	0000H				; buffa pointer to directory dma address
caDiskParamBlock:	DW	0000H				; dpbaddr current disk parameter block address
caCheckSum:			DW	0000H				; checka current checksum vector address
caAllocVector:		DW	0000H				; alloca current allocation vector address
caListSizeEnd:
caListSize			EQU	caListSizeEnd - caListSizeStart

;     ***** Disk Parameter Block *******
; data must be adjacent, do not insert variables
; dpb - Disk Parameter Block
dpbStart:
dpbSPT:				DW	0000H				; sectpt sectors per track
dpbBSH:				DB	0000H				; blkshf block shift factor
dpbBLM:				DB	00H					; blkmsk block mask
dpbEXM:				DB	00H					; extmsk extent mask
dpbDSM:				DW	0000H				; maxall maximum allocation number
dpbDRM:				DW	0000H				; dirmax largest directory number
dpbDABM:			DW	0000H				; dirblk reserved allocation bits for directory
dpbCKS:				DW	0000H				; chksiz size of checksum vector
dpbOFF:				DW	0000H				; offset offset tracks at beginning
dpbEnd:
dpbSize				EQU	dpbEnd - dpbStart
;

;     ************************

paramE:				DS	BYTE				; ParamE low(info)
caSkewTable:		DW	0000H				; tranv address of translate vector
fcbCopiedFlag:		DB	00H					; fcb$copied set true if CopyFCB called
readModeFlag:		DB	00H					; rmf read mode flag for OpenNextExt
directoryFlag:		DB	00H					; dirloc directory flag in rename, etc.
seqReadFlag:		DB	00H					; seqio  1 if sequential i/o
diskMapIndex:		DB	00H					; dminx  local for DiskWrite
searchLength:		DB	00H					; searchl search length
searchAddress:		DW	0000H				; searcha search address
;tinfo:	ds	word							; temp for info in "make"
single:				DB	00H					; set true if single byte allocation map
fResel:				DB	00H					; resel reselection flag
entryDisk:			DB	00H					; olddsk disk on entry to bdos
fcbDisk:			DB	00H					; fcbdsk disk named in fcb
fcbRecordCount:		DB	00H					; record count from current fcb
extentValue:		DB	00H					; extent number and dpbEXM from current fcb
cpmRecord:			DW	0000H				; current virtual record - NEXT_RECORD
currentBlock:		DW	0000H				; arecord current actual record
;
;	local variables for directory access
dirBlockIndex:		DB	00H					; directory block Index 0,1,2,3
dirEntryIndex:		DW	00H					; directory entry Index  0,1,...,dpbDRM
dirRecord:			DW	00H					; drec:	ds	word	;directory record 0,1,...,dpbDRM/4

;********************** data areas ******************************
Cvalue:				DB	00H					; Reg C on BDOS Entry
compcol:			DB	0					; true if computing column position
startingColumn:		DB	0					; strtcol starting column position after read
columnPosition:		DB	0					; column column position
listeningToggle:	DB	0					; listcp listing toggle
kbchar:				DB	0					; initial key char = 00
usersStack:			DS	2					; entry stack pointer
stackBottom:		DS	STACK_SIZE * 2		; stack size
bdosStack:
;	end of Basic I/O System
;-----------------------------------------------------------------;*****************************************************************

;
CodeEnd: