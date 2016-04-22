; newBDOS.asm
; part of newOS
; 2014-03-14  :  Frank Martyn
; TODO ------
		$Include ../Headers/osHeader.asm
		$Include ../Headers/stdHeader.asm
STACK_SIZE	EQU		20H			; make stak big enough
;WORD		EQU		02			; number of bytes for a word
;BYTE		EQU		01			; number of bytes for a byte

;	bios access constants
bcBoot		EQU	BIOSEntry+3*0	;cold boot function
bcWboot		EQU	BIOSEntry+3*1	;warm boot function
bcConst		EQU	BIOSEntry+3*2	;console status function
bcConin		EQU	BIOSEntry+3*3	;console input function
bcConout	EQU	BIOSEntry+3*4	;console output function
bcList		EQU	BIOSEntry+3*5	;list output function
bcPunch		EQU	BIOSEntry+3*6	;punch output function
bcReader	EQU	BIOSEntry+3*7	;reader input function
bcHome		EQU	BIOSEntry+3*8	;disk home function
bcSeldsk	EQU	BIOSEntry+3*9	;select disk function
bcSettrk	EQU	BIOSEntry+3*10	;set track function
bcSetsec	EQU	BIOSEntry+3*11	;set sector function
bcSetdma	EQU	BIOSEntry+3*12	;set dma function
bcRead		EQU	BIOSEntry+3*13	;read disk function
bcWrite		EQU	BIOSEntry+3*14	;write disk function
bcListst	EQU	BIOSEntry+3*15	;list status function
bcSectran	EQU	BIOSEntry+3*16	;sector translate
		
CodeStart:
	ORG		BDOSBase
	DB		0,0,0,0,0,0
; Enter here from the user's program with function number in c,
;	and information address in d,e
BDOSEntry:
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
	
;------------------- Function Table -------------------------------
functionTable:
	DW		DUMMY			; Function  0 - System Reset
	DW		DUMMY			; Function  1 - Console Input
	DW		DUMMY			; Function  2 - Console Output
	DW		DUMMY			; Function  3 - Reader Input
	DW		DUMMY			; Function  4 - Punch Output
	DW		DUMMY			; Function  5 - List Output
	DW		DUMMY			; Function  6 - Direct Console I/O
	DW		DUMMY			; Function  7 - Get I/O Byte
	DW		DUMMY			; Function  8 - Set I/O Byte
	DW		DUMMY			; Function  9 - Print String
	DW		DUMMY			; Function  A - Read Console String
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
	
fGetIOBYTE:		; (07 - 07) get IOBYTE
	LDA		IOBYTE		; get the byte
	JMP		StoreARet	; store A and return
;
fSetIOBYTE:		; (08 - 08)	set IOBYTE
	LXI		HL,IOBYTE
	MOV		M,C			; put passed value into IOBYTE
	RET					; exit
;
;
StoreARet:			; store A and return
	STA		statusBDOSReturn
	RET					; jmp , go back
	
;*****************************************************************
;********************** data areas ******************************

compcol:			DB	0	; true if computing column position
startingColumn:		DB	0	; strtcol starting column position after read
columnPosition:		DB	0	; column column position
listeningToggle:	DB	0	; listcp listing toggle
kbchar:				DB	0	; initial key char = 00
usersStack:			DS	2	;entry stack pointer
;	ds	ssize*2	;stack size
bdosStack:
;	end of Basic I/O System
;-----------------------------------------------------------------
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
	CALL	RotateHLbyC
	PUSH	HL			; save result
	XCHG				; send to seldsk
	CALL	SelectDisk
	POP		HL			; get back logged disk vector
	CZ		errSelect
	
;*****************************************************************
; select the disk drive given by curdsk, and fill the base addresses
; curtrka - alloca, then fill the values of the disk parameter block
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
	LXI		dptSPT		; start of Disk Parameter Table
	MVI		C,dptSize
	CALL	Move		; load the table
	LHLD	dptDSM		; max entry number
	MOV		A,H			; if 00 then < 255
	LXI		single		; point a the sing byte entry flag
	MVI		M,TRUE		; assume its less than 255
	ORA		A			; assumtion confirmed ?
	JZ		SelectDisk1	; skip if yes
	MVI		M,FALSE		; correct assumption, set falg to false
	
SelectDisk1:
	MVI		A,TRUE
	ORA		A			; Set Carry and Sign reset Zero
	RET
	
;*****************************************************************
RotateHLbyC:		; hlrotr rotate
	INC		C
RotateHLbyC0:
	DEC		C
	RZ				; exit when done
	MOV		A,H
	ORA		A		; reset carry bit
	RAR				; rotate
	MOV		H,A		; high byte
	MOV		A,L
	RAR		
	MOV		L,A		; low byte
	JMP		RotateHLbyC0	; keep going

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
ConIn:
	;read console character to A
	LXI		HL,kbchar
	MOV		A,M
	MVI		M,0
	ORA		A
	RNZ
	;no previous keyboard character ready
	JMP		bcConin ;get character externally
	;ret
;
;********** Console OUT Routines*******************
ConBreak:			;conbrk for character ready
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

Conout:
	;compute character position/write console char from C
	;compcol = true if computing column position
	LDA 	compcol
	ORA		A
	JNZ		ComputeColumn
			;write the character, then compute the column
			;write console character from C
	PUSH	BC				; save the character in C
	CALL	ConBreak		; check for screen stop function
	POP		BC				; get the characte
	PUSH	BC				; recall/save character
	CALL	bcConout		; externally, to console
	POP		BC
	PUSH	BC				; recall/save character
			;may be copying to the list device
	LDA		listeningToggle
	ORA		A
	CNZ		bcList			;	to printer, if so
	POP		BC				; recall the character
ComputeColumn:				;compout:
	MOV		A,C				; recall the character
			;and compute column position
	LXI		HL,columnPosition ;A = char, HL = .columnPosition
	CPI		RUBOUT
	RZ						; no column change if nulls
	INR		M				; column = column + 1
	CPI		SPACE
	RNC						 ;return if graphic
			;not graphic, reset column position
	DCR		M				; column = column - 1
	MOV		A,M
	ORA		A
	RZ						 ;return if at zero
			;not at zero, may be backspace or end line
	MOV		A,C ;character back to A
	CPI		CTRL_H
	JNZ		NotBackSpace
			;backspace character
	DCR		M				; column = column - 1
	RET
	
NotBackSpace:			; notbacksp:  not a backspace character  eol?
	CPI		LF
	RNZ					; return if not
			;end of line, column = 0
	MVI		M,0			; column = 0
	RET
;
;display #, CR, LF for CTRL_X, CTRL_U, CTRL_R functions
;then move to startingColumn (starting column)
showHashCRLF:			; crlfp:
	MVI		C,HASH_TAG
	CALL	Conout
	CALL	showCRLF
			;column = 0, move to position startingColumn
showHashCRLF0:			; crlfp0:
	LDA		columnPosition
	LXI		HL,startingColumn
	CMP		M
	RNC						; stop when column reaches startingColumn
	MVI		C,SPACE
	CALL	Conout			; display blank
	JMP		showHashCRLF0
;
showCRLF:				;crlf:
	;carriage return line feed sequence
	MVI		C,CR
	CALL	Conout
	MVI		C,LF
	JMP		Conout
	;ret
;
Print:
	;print message until M(BC) = '$'
	LDAX	BC
	CPI		DOLLAR
	RZ					 ; stop on $
	INX		BC
	PUSH	BC
	MOV		C,A
	CALL	TabOut
	POP		BC
	JMP		Print
;----------------
TabOut:
	;expand tabs to console
	MOV		A,C
	CPI		TAB
	JNZ		Conout ;direct to conout if not
		;TAB encountered, move to next TAB position
TabOut0:			; tab0:
	MVI		C,SPACE
	CALL	Conout ;another blank
	LDA		columnPosition
	ANI		111b ;column mod 8 = 0 ?
	JNZ		TabOut0 ;back for another if not
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
jmp WarmBoot

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
;*****************************************************************

;***common values shared between bdosi and bdos******************
;usrcode:			DB		0	;current user number
paramDE:			DS		2	;information address
statusBDOSReturn:	DS		2	;address value to return
currentDisk:		DB		0	; curdsk current disk number
;lret	equ	statusBDOSReturn	;low(statusBDOSReturn)

;********************* Local Variables ***************************
;     ************************
;     *** Initialized Data ***

;efcb:	DB	empty	;0e5=available dir entry
;rodsk:	DW	0	;read only disk vector
loggedDisks:	DW	0		;dlog:	 logged-in disks
;dmaad:	DW	tbuff	;initial dma address

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
caListSize		EQU		$ - caDirectoryDMA	;addlist	equ	$-buffa	 address list size

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
dpbSize			EQU		$ - dpbSPT	;dpblist	equ	$-sectpt	;size of area
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
;arecord:ds	word	;current actual record
;
;	local variables for directory access
;dptr:	ds	byte	;directory pointer 0,1,2,3
;dcnt:	ds	word	;directory counter 0,1,...,dirmax
;drec:	ds	word	;directory record 0,1,...,dirmax/4
;	
CodeEnd: