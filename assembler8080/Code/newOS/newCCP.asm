; newCCP.asm
; part of newOS
; 2014-05-01  :  Frank Martyn

		$Include ../Headers/osHeader.asm
		$Include ../Headers/stdHeader.asm
;BDOSE bdos  0005
fConsoleIn			EQU		01H			; rcharf - Console Input
fConsoleOut			EQU		02H			; pcharf - Console Output
fPrintString		EQU		09H			; pbuff	- Print String
fReadString			EQU		0AH			; rbuff	- Read Console String
fGetConsoleStatus	EQU		0BH			; breakf - Get Console Status
fGetVersion			EQU		0CH			; liftf	- Return Version Number
fResetSystem		EQU		0DH			; initf	- Reset Disk System
fSelectDisk			EQU		0EH			; self	- Select Disk
fOpenFile			EQU		0FH			; openf	- Open File
fCloseFile			EQU		10H			; closef - Close File
fSearchFirst		EQU		11H			; searf	- Search For First
fSearchNext			EQU		12H			; searnf - Search for Next
fDeleteFile			EQU		13H			; delf - Delete File
fReadSeq			EQU		14H			; dreadf - Read Sequential
fWriteSeq			EQU		15H			; dwritf - Write Sequential
fMakeFile			EQU		16H			; makef	- Make File
fRenameFile			EQU		17H			; renf	- Rename File
fGetLoginVector		EQU		18H			; logf	- Return Login Vector
fGetCurrentDisk		EQU		19H			; cself	- Return Current Disk
fSetDMA				EQU		1AH			; dmaf	- Set DMA address
fGetSetUserNumber	EQU		20H			; userf	- Set/Get User Code

diskAddress:		EQU		0004H		; diska	 disk address for current disk
		
	ORG		CCPEntry
CodeStart:
	
	JMP		ccpstart	;start ccp with possible initial command

	
;*****************************************************************
;enter here from boot loader
CcpStart:							; ccpstart
	LXI		SP,Stack
	PUSH	BC						; save initial disk number
									; (high order 4bits=user code, low 4bits=disk#)
	MOV		A,C
	RAR
	RAR
	RAR
	RAR
	ANI		0FH						; user code
	MOV		E,A
	CALL	SetUser					; user code selected
									; initialize for this user, get $ flag
    CALL	Initialize				; 0ffh in accum if $ file present
    STA		submitFlag				; submit flag set if $ file present
    POP		BC						; recall user code and disk number
	MOV		A,C
	ANI		0FH						; disk number in accumulator
    STA		diskAddress				; clears low memory user code nibble
	CALL	SelectDisk				; proper disk is selected, now check sub files
									; check for initial command
	LDA		CommandLength
	ORA		A
	JNZ		ccp0	;assume typed already
	
Ccp:
	;enter here on each command or error condition
	LXI		SP,Stack
	CALL	CrLf					; print d> prompt, where d is disk name
	CALL	GetSelectedDrive		; get current disk number
	ADI		ASCII_A	
	CALL	PrintChar
	MVI		A,GREATER_THAN
	CALL	PrintChar
	CALL	readcom ;command buffer filled
ccp0:	;(enter here from initialization with command full)
	lxi		de,buff
	call	setdma ;default dma address at buff
	call	GetSelectedDrive
	sta		cdisk ;current disk number saved
	call	fillfcb0 ;command fcb filled
	cnz		comerr ;the name cannot be an ambiguous reference
	lda		sdisk
	ora		a
	jnz		userfunc
				;check for an intrinsic function
	call	intrinsic
	lxi		hl,jmptab ;index is in the accumulator
	mov		e,a
	mvi		d,0
	dad		de
	dad		de ;index in d,e
	mov		a,m
	inx		hl
	mov		h,m
	mov		l,a
	pchl
					;pc changes to the proper intrinsic or user function
jmptab:
	dw	direct	;directory search
	dw	erase	;file erase
	dw	type	;type file
	dw	save	;save memory image
	dw	rename	;file rename
	dw	user	;user number
	dw	userfunc;user-defined function
badserial:
	LXI	H,76F3H	;'DI HLT' instructions  lxi h,di or (hlt shl 8)
	shld CCPEntry
	lxi h,CCPEntry
	pchl
;----------------------------------------------------------------
;----------------------------------------------------------------
;read the next command into the command buffer
;check for submit file
ReadCommand:						; readcom
	lda		submit
	ora		a
	jz		nosub
					;scanning a submit file
					;change drives to open and read the file
	lda		cdisk
	ora		a
	mvi		a,0
	cnz		select
					;have to open again in case xsub present
	lxi		de,subfcb
	call	open
	jz		nosub ;skip if no sub
	lda		subrc
	dcr		a ;read last record(s) first
	sta		subcr ;current record to read
	lxi		de,subfcb
	call	diskread ;end of file if last record
	jnz		nosub
				;disk read is ok, transfer to combuf
	lxi		de,comlen
	lxi		hl,buff
	mvi		b,128
	call	move0
				;line is transferred, close the file with a
				;deleted record
	lxi		hl,submod
	mvi		m,0 ;clear fwflag
	inx		hl
	dcr		m ;one less record
	lxi		de,subfcb
	call	close
	jz		nosub
				;close went ok, return to original drive
	lda		cdisk
	ora		a
	cnz		select
				;print to the 00
	lxi		hl,combuf
	call	prin0
	call	break$key
	jz		noread
	call	del$sub
	jmp		ccp ;break key depressed

nosub:	;no submit file
	call	del$sub
				;translate to upper case, store zero at end
	call	saveuser ;user # save in case control c
	mvi		c,rbuff
	lxi		de,maxlen
	call	bdos
	call	setdiska ;no control c, so restore diska
noread:				;enter here from submit file
				;set the last character to zero for later scans
	lxi		hl,comlen
	mov		b,m ;length is in b
readcom0:
	inx		hl
	mov		a,b
	ora		a ;end of scan?
	jz		readcom1
	mov		a,m ;get character and translate
	call	translate
	mov		m,a
	dcr		b
	jmp		readcom0

readcom1: ;end of scan, h,l address end of command
	mov		m,a ;store a zero
	lxi		hl,combuf
	shld	comaddr ;ready to scan to zero
	ret
;----------------------------------------------------------------
;return current user code in A
GetUser:							; getuser
	MVI		E,0FFH					; drop through to setuser
;------
SetUser:							; setuser
    MVI		C,fGetSetUserNumber
	JMP		BDOSE					; sets user number
;-----------------------------
Initialize:							; initialize
	MVI		C,fResetSystem
	JMP		BDOSE
;-----------------------------
SelectDisk:							; select
	MOV		E,A
	MVI		C,fSelectDisk
	JMP		BDOSE
;-----------------------------
;get the currently selected drive number to A
GetSelectedDrive:					; 	cselect
	MVI		C,fGetCurrentDisk
	JMP		BDOSE
;-----------------------------	
;-----------------------------
;*****************************************************************
;************************ Utilities ******************************
;*****************************************************************
CrLf:								; crlf
	MVI		A,CR
	CALL	PrintSaveBC
	MVI		A,LF
	JMP		PrintSaveBC	
;-----------------------------
;print character, but save b,c registers
PrintSaveBC:						;printbc
	PUSH	BC
	CALL	PrintChar
	POP		BC
	RET
;-----------------------------
PrintChar:							; printchar
	MOV		E,A
	MVI		C,fConsoleOut
	JMP		BDOSE
;-----------------------------
;*****************************************************************
;************************ Data Area ******************************
;*****************************************************************
	DS		16					; 8 level stack
Stack:							; stack
;	'submit' file control block
submitFlag:	DB		00H			; submit 00 if no submit file, ff if submitting
;subfcb:	db	0,'$$$     '	;file name is $$$
;	db	'SUB',0,0	;file type is sub
;submod:	db	0	;module number
;subrc:	ds	1	;record count filed
;	ds	16	;disk map
;subcr:	ds	1	;current record to read
;;
;;	command file control block
;comfcb:	ds	32	;fields filled in later
;comrec:	ds	1	;current record to read/write
;dcnt:	ds	1	;disk directory count (used for error codes)
;cdisk:	ds	1	;current disk
;sdisk:	ds	1	;selected disk for current operation
;			;none=0, a=1, b=2 ...
;bptr:	ds	1	;buffer pointer

;----------------------------
;maxlen:	db	127	;max buffer length
CommandLength:	DB		0				; comlen command length (filled in by dos)
;	(command executed initially if comlen non zero)
;combuf:
;	db	'        '	;8 character fill
;	db	'        '	;8 character fill
;	db	'COPYRIGHT (C) 1979 DIGITAL RESEARCH  '; 38
;	ds	128-($-combuf)
;	total buffer length is 128 characters
;comaddr:dw	combuf	;address of next to char to scan
;staddr:	ds	2	;starting address of current fillfcb request

CodeEnd:


