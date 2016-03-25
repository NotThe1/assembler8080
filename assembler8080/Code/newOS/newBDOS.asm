; newBDOS.asm
; part of newOS
; 2014-03-14  :  Frank Martyn
; TODO ------
		$Include ../Headers/osHeader.asm
		$Include ../Headers/stdHeader.asm
STACK_SIZE	EQU		20H			; make stak big enough

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
	JMP	BdosStart	;past parameter block
	
BdosStart:
	XCHG					; swap DE and HL
	SHLD	paramDE			; save the original value of DE
	XCHG					; restore DE
	MOV		A,E				; Byte argument
	STA		paramE
	LXI		HL,0000H
	SHLD	StatusBDOSReturn	; assume alls well for return
	; Save users Stack pointer
	DAD		SP
	SHLD	usersStack
	LXI		SP,bdosStack	; use our own stack area
	; initialize variables
	XRA		A
	STA		fcbDisk
	STA		fResel
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
;********************** data areas ******************************

;compcol:			db	0	;true if computing column position
;strtcol:			db	0	;starting column position after read
;column:			db	0	;column position
;listcp:			db	0	;listing toggle
;kbchar:			db	0	;initial key char = 00
usersStack:			DS		2	;entry stack pointer
;	ds	ssize*2	;stack size
bdosStack:
;	end of Basic I/O System

;********* common values shared between bdosi and bdos ***********
;	
;
;usrcode:			db		0	;current user number
;curdsk:			db		0	;current disk number
paramDE:			DS		2	;information address
StatusBDOSReturn:	DS		2	;address value to return
;lret	equ	StatusBDOSReturn	;low(StatusBDOSReturn)
;-----------------------------------------------------------------
	;arrive here at end of processing to return to user
RetCaller:
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

	HLT	;*************************** Unfinished routine *************************
; need to code the following line TODO
;	 call curselect

;	return from the disk monitor
RetDiskMon:
	LHLD	 usersStack
	SPHL					; Restore callers stack
	LHLD	StatusBDOSReturn
	MOV		A,L
	MOV		B,H				; BA = StatusBDOSReturn
	RET

;*****************************************************************
;********************* Local Variables ***************************
;	local variables
;tranv:	ds	word	;address of translate vector
;fcb$copied:
;	ds	byte	;set true if copy$fcb called
;rmf:	ds	byte	;read mode flag for open$reel
;dirloc:	ds	byte	;directory flag in rename, etc.
;seqio:	ds	byte	;1 if sequential i/o
paramE:			DS		BYTE		;low(info)
;dminx:	ds	byte	;local for diskwrite
;searchl:ds	byte	;search length
;searcha:ds	word	;search address
;tinfo:	ds	word	;temp for info in "make"
;single:	ds	byte	;set true if single byte allocation map
fResel:			DS		BYTE		; reselection flag
entryDisk:		DS		BYTE		;disk on entry to bdos
fcbDisk:		DS		BYTE		;disk named in fcb
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