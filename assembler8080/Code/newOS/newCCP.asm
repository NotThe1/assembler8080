; newCCP.asm
; part of newOS
; 2014-05-01  :  Frank Martyn

	$Include ../Headers/osHeader.asm
	$Include ../Headers/stdHeader.asm
;BDOSE		bdos	0005H
;DMABuffer	buff	0080H

fConsoleIn	EQU	01H			; rcharf - Console Input
fConsoleOut	EQU	02H			; pcharf - Console Output
fPrintString	EQU	09H			; pbuff	- Print String
fReadString	EQU	0AH			; rbuff	- Read Console String
fGetConsoleStatus	EQU	0BH			; breakf - Get Console Status
fGetVersion	EQU	0CH			; liftf	- Return Version Number
fResetSystem	EQU	0DH			; initf	- Reset Disk System
fSelectDisk	EQU	0EH			; self	- Select Disk
fOpenFile		EQU	0FH			; openf	- Open File
fCloseFile	EQU	10H			; closef - Close File
fSearchFirst	EQU	11H			; searf	- Search For First
fSearchNext	EQU	12H			; searnf - Search for Next
fDeleteFile	EQU	13H			; delf - Delete File
fReadSeq		EQU	14H			; dreadf - Read Sequential
fWriteSeq		EQU	15H			; dwritf - Write Sequential
fMakeFile		EQU	16H			; makef	- Make File
fRenameFile	EQU	17H			; renf	- Rename File
fGetLoginVector	EQU	18H			; logf	- Return Login Vector
fGetCurrentDisk	EQU	19H			; cself	- Return Current Disk
fSetDMA		EQU	1AH			; dmaf	- Set DMA address
fGetSetUserNumber	EQU	20H			; userf	- Set/Get User Code
                                                  
systemFile	EQU	0AH			;sysfile System File Flag Location
roFile		EQU	09H			;rofile Read Only Flag Location
                                                  
;diskAddress	EQU	0004H			; diska CurDisk	 disk address for current disk
	                                        
	ORG	CCPEntry
CodeStart:
	
	JMP	CcpStart				;start ccp with possible initial command

	
;*****************************************************************
;enter here from boot loader
CcpStart:						; ccpstart
	LXI	SP,Stack
	PUSH	BC				; save initial disk number
						; (high order 4bits=user code, low 4bits=disk#)
	MOV	A,C
	RAR
	RAR
	RAR
	RAR
	ANI	0FH				; user code
	MOV	E,A
	CALL	SetUser				; user code selected
						; initialize for this user, get $ flag
	CALL	Initialize			; 0ffh in accum if $ file present
	STA	submitFlag			; submit flag set if $ file present
	POP	BC				; recall user code and disk number
	MOV	A,C
	ANI	0FH				; disk number in accumulator
	STA	CurDisk				; clears low memory user code nibble
	CALL	SelectDisk			; proper disk is selected, now check sub files
						; check for initial command
	LDA	CommandLength
	ORA	A
	JNZ	Ccp0				;assume typed already
	
Ccp:						; ccp
						;enter here on each command or error condition
	LXI	SP,Stack
	CALL	CrLf				; print d> prompt, where d is disk name
	CALL	GetSelectedDrive			; get current disk number
	ADI	ASCII_A	
	CALL	PrintChar
	MVI	A,GREATER_THAN
	CALL	PrintChar
	CALL	ReadCommand			; command buffer filled
Ccp0:						; ccp0 enter here from initialization with command full
	LXI	DE,DMABuffer
	CALL	SetDMA				; default dma address at DMABuffer
	CALL	GetSelectedDrive
	STA	currentDisk			; current disk number saved
	CALL	FillFCB0				; command fcb filled
	CNZ	CommandError			; the name cannot be an ambiguous reference
	LDA	selectedDisk
	ORA	A
	JNZ	ccpUserFunction
	
	CALL	IntrinsicFunction			; check for an intrinsic function
	LXI	HL,intrinsicFunctionsVector		; index is in the accumulator
	MOV	E,A
	MVI	D,0
	DAD	DE
	DAD	DE				; index in d,e
	MOV	A,M
	INX	HL
	MOV	H,M
	MOV	L,A
	PCHL					; pc changes to the proper intrinsic or user function
;.................................................
;.................................................

intrinsicFunctionsVector:				; jmptab
	DW	ccpDirectory			; directory search
	DW	ccpErase				; file erase
	DW	ccpType				; type file
	DW	ccpSave				; save memory image
	DW	ccpRename				; file rename
	DW	ccpUser				; user number
	DW	ccpUserFunction			; user-defined function
	
badserial:
	LXI	H,76F3H				; 'DI HLT' instructions  lxi h,di or (hlt shl 8)
	SHLD	CCPEntry
	LXI	H,CCPEntry
	PCHL
;----------------------------------------------------------------
;----------------------------------------------------------------
;read the next command into the command buffer
;check for submit file
ReadCommand:				 	; readcom
	LDA	submitFlag
	ORA	A
	JZ	NotSubmitFile
						; scanning a submit file
						; change drives to open and read the file
	LDA	currentDisk
	ORA	A
	MVI	A,0
	CNZ	SelectDisk
						; have to open again in case xsub present
	LXI	DE,submitFCB
	CALL	OpenFile
	JZ	NotSubmitFile			; skip if no submit file
	LDA	subRecordCount
	DCR	A				; read last record(s) first
	STA	subCurrentRecord			; current record to read
	LXI	DE,submitFCB
	CALL	DiskRead				; end of file if last record
	JNZ	NotSubmitFile
						; disk read is ok, transfer to commandBuffer
	LXI	DE,CommandLength
	LXI	HL,DMABuffer
	MVI	B,128				; number of bytes to Copy
	CALL	CopyHL2DEforB
						; line is transferred, close the file with a
						; deleted record
	LXI	HL,subModuleNumber
	MVI	M,0				; clear fwflag
	INX	HL
	DCR	M				; one less record
	LXI	DE,submitFCB
	CALL	CloseFile
	JZ	NotSubmitFile
						; CloseFile went ok, return to original drive
	LDA	currentDisk
	ORA	A
	CNZ	SelectDisk
						; print to the 00
	LXI	HL,commandBuffer
	CALL	PrintStringNull
	CALL	CheckForConsoleChar
	JZ	NoRead
	CALL	DeleteSubmitFile
	JMP	DeleteSubmitFile			; break key depressed
                                                  
NotSubmitFile:					; nosub:	no submit file
	CALL	DeleteSubmitFile
						; translate to upper case, store zero at end
	CALL	SaveUser				; user # save in case control c
	MVI	C,fReadString
	LXI	DE,MaxBufferLength
	CALL	BDOSE
	CALL	SetDiskAddress			; no control c, so restore CurDisk
	
NoRead:						; noread enter here from submit file
						; set the last character to zero for later scans
	LXI	HL,CommandLength
	MOV	B,M				; length is in b
ReadCommand1:					; readcom0
	INX	HL
	MOV	A,B
	ORA	A				; end of scan?
	JZ	ReadCommand2
	MOV	A,M				; get character and translate
	CALL	UpCase
	MOV	M,A
	DCR	B
	JMP	ReadCommand1

ReadCommand2:					; readcom1 end of scan, h,l address end of command
	MOV	M,A ;store a zero             
	LXI	HL,commandBuffer              
	SHLD	commandAddress			; ready to scan to zero
	RET
;----------------------------------------------------------------
;return current user code in A
GetUser:						; getuser
	MVI	E,0FFH				; drop through to setuser
;------
SetUser:						; setuser
    MVI	C,fGetSetUserNumber
	JMP	BDOSE				; sets user number
;-----------------------------
Initialize:					; initialize
	MVI	C,fResetSystem
	JMP	BDOSE
;-----------------------------
SelectDisk:					; select
	MOV	E,A
	MVI	C,fSelectDisk
	JMP	BDOSE
;-----------------------------
;get the currently selected drive number to A
GetSelectedDrive:					; cselect
	MVI	C,fGetCurrentDisk
	JMP	BDOSE
;-----------------------------
;open the file given by d,e
OpenFile:						; open
	MVI	C,fOpenFile
	JMP	BDOSandIncA	
;-----------------------------
;close the file given by d,e
CloseFile:					; close
	MVI	C,fCloseFile
	JMP	BDOSandIncA
;-----------------------------
;delete the file given by d,e
DeleteFile:					; delete
	MVI	C,fDeleteFile
	JMP	BDOSE
;-----------------------------
;read the next record from the file given by d,e
DiskRead:						; diskread
	MVI	C,fReadSeq
	JMP	BDOSsetFlags
;-----------------------------
;search for the file given by d,e
SearchForFirst:					; search
	MVI	C,fSearchFirst
	JMP	BDOSandIncA
;-----
;search for commandFCB file
Searc4CmdFcbFile:					; searchcom
	LXI	DE,commandFCB
	JMP	SearchForFirst
;-----------------------------
;search for the next occurrence of the file given by d,e
SearchForNext:					; searchn
	MVI	C,fSearchNext
	JMP	BDOSandIncA

;-----------------------------
;set dma address to d,e
SetDMA:						; setdma
	MVI	C,fSetDMA
	JMP	BDOSE
;-----------------------------
;-----------------------------
; call BDOS and set Flags
BDOSsetFlags:					; bdos$cond
	CALL	BDOSE
	ORA	A				; set return code flags
	RET
;-----------------------------
;call BDOS  - increment result - store in directory count
BDOSandIncA:					; bdos$inr
	CALL	BDOSE
	STA	directoryCount
	INR	A
	RET
;----------------------------------------------------------------
;----------------------------------------------------------------
;----------------------------------------------------------------
;check for a character ready at the console
CheckForConsoleChar:				; break$key
	MVI	C,fGetConsoleStatus
	CALL	BDOSE
	ORA	A
	RZ					; return no char waiting
	MVI	C,fConsoleIn
	CALL	BDOSE				; character cleared
	ORA	A
	RET
;-----------------------------
;delete the submit file, and set submit flag to false
DeleteSubmitFile:					; del$sub
	LXI	HL,submitFlag
	MOV	A,M
	ORA	A
	RZ					; return if no sub file
	MVI	M,0				; submit flag is set to false
	XRA	A
	CALL	SelectDisk			; on drive a to erase file
	LXI	DE,submitFCB
	CALL	DeleteFile
	LDA	currentDisk
	JMP	SelectDisk ;back to original drive
;-----------------------------
;save user#/disk# before possible ^c or transient
SaveUser:						; saveuser
	CALL	GetUser				; code to a
	ADD	A
	ADD	A
	ADD	A
	ADD	A				; rotate left
	LXI	HL,currentDisk
	ORA	M				; msn 4b=user - lsn 4b=disk
	STA	CurDisk				; stored away in memory for later
	RET
;-----------------------------
; set CurDisk to current disk
SetDiskAddress:					; setdiska
	LDA	currentDisk
	STA	CurDisk				; user/disk
	RET
;-----------------------------
;equivalent to fillfcb(0)
FillFCB0:						; fillfcb0
	MVI	A,0
FillFCB:						; fillfcb
	LXI	HL,commandFCB
	CALL	AddA2HL
	PUSH	HL
	PUSH	HL				; fcb rescanned at end
	XRA	A
	STA	selectedDisk			; clear selected disk (in case A:...)
	LHLD	commandAddress
	XCHG					; command address in d,e
	CALL	NextNonBlankChar			; move to first non-blank character
	XCHG
	SHLD	fillFCBStart			; in case of errors
	XCHG
	POP	HL				; d,e has command, h,l has fcb address
						; look for preceding file name A: B: ...
	LDAX	DE
	ORA	A
	JZ	FillSetCurrentDisk			; use current disk if empty command
	SBI	040H				; ASCII_A-1
	MOV	B,A				; disk name held in b if : follows
	INX	DE
	LDAX	DE
	CPI	COLON
	JZ	FillSetDiskName			; set disk name if :

setcur:						; set current disk
	DCX	DE				; back to first character of command
FillSetCurrentDisk:					; setcur0:
	LDA	currentDisk
	MOV	M,A
	JMP	SetFileName

FillSetDiskName:					; setdsk: ;set disk to name in register b
	MOV	A,B
	STA	selectedDisk			; mark as disk selected
	MOV	M,B
	INX	DE				; past the :
SetFileName:					; setname: ;set the file name field
	MVI	B,8				; file name length (max)
SetFileName1:					; setnam0:
	CALL	NextDelimiter
	JZ	PadTheName			; not a delimiter
	INX	HL	
	CPI	ASTERISK	
	JNZ	SetFileName2			; must be ?'s
	MVI	M,QMARK	
	JMP	SetFileName3			; to dec count
	
SetFileName2:					; setnam1:
	MOV	M,A				; store character to fcb
	INX	DE	
SetFileName3:					; setnam2:
	DCR	B				; count down length	
	JNZ	SetFileName1	
TruncateName:					; trname:
	CALL	NextDelimiter	
	JZ	SetTypeField			; set type field if delimiter
	INX	DE	
	JMP	TruncateName

PadTheName:					; padname:
	INX	HL
	MVI	M,SPACE
	DCR	B
	JNZ	PadTheName
SetTypeField:					; setty set the type field
	MVI	B,3
	CPI	PERIOD
	JNZ	PadTypeField			; skip the type field if no .
	INX	DE				; past the ., to the file type field
SetTypeField1:					; setty0 set the field from the command buffer
	CALL	NextDelimiter
	JZ	PadTypeField
	INX	HL
	CPI	ASTERISK
	JNZ	SetTypeField2
	MVI	M,QMARK ;since * specified
	JMP	SetTypeField3

SetTypeField2:					; setty1 not a *, so copy to type field
	MOV	M,A
	INX	DE
SetTypeField3:					; setty2 decrement count and go again
	DCR	B
	JNZ	SetTypeField1
						; end of type field, truncate the rest
TruncateType:					; trtyp truncate type field
	CALL	NextDelimiter
	JZ	FillRestofFCB
	INX	DE
	JMP	TruncateType

PadTypeField:					; padty pad the type field with blanks
	INX	HL
	MVI	M,SPACE
	DCR	B
	JNZ	PadTypeField
FillRestofFCB:					; efill end of the filename/filetype fill, save command address
						; fill the remaining fields for the fcb
	MVI	B,3
FillRestofFCB1:					; efill0:
	INX	HL
	MVI	M,0
	DCR	B
	JNZ	FillRestofFCB1
	XCHG
	SHLD	commandAddress			; set new starting point
						; recover the start address of the fcb and count ?'s
	POP	H
	LXI	BC,11				; b=0, c=8+3
QuestionMarkCount:					; scnq:
	INX	H
	MOV	A,M
	CPI	QMARK
	JNZ	QuestionMarkCount1
						; ? found, count it in b
	INR	B
QuestionMarkCount1:					; scnq0:
	DCR	C
	JNZ	QuestionMarkCount
						; number of ?'s in c, move to a and return with flags set
	MOV	A,B
	ORA	A
	RET
;-----------------------------
;find the next non blank character in line pointed to by DE
NextNonBlankChar:					; deblank
	LDAX	D
	ORA	A
	RZ 					; treat end of line as blank
	CPI	SPACE
	RNZ
	INX	DE
	JMP	NextNonBlankChar
;-----------------------------
;find thedelimiter in line pointed to by DE
NextDelimiter:					; delim
	LDAX	DE
	ORA	A
	RZ					; not the last element
	CPI	SPACE
	JC	CommandError			; non graphic
	RZ					; treat blank as delimiter
	CPI	EQUAL_SIGN
	RZ
	CPI	UNDER_SCORE			; left arrow ?
	RZ		
	CPI	PERIOD
	RZ
	CPI	COLON
	RZ
	CPI	SEMICOLON
	RZ
	CPI	LESS_THAN
	RZ
	CPI	GREATER_THAN
	RZ
	RET					; delimiter not found
;-----------------------------
;-----------------------------
;intrinsic function names four characters each
intrinsicFunctionNames:					; intvec
	DB	'DIR '
	DB	'ERA '
	DB	'TYPE'
	DB	'SAVE'
	DB	'REN '
     DB	'USER'
IntrinsicFunctionCount	EQU	6
;IntrinsicFunctionCount	EQU	($-intrinsicFunctionNames)/4	 intlen
;intlen EQU ($-intrinsicFunctionNames)/4  ;intrinsic function length
serialNumber: DB 0,0,0,0,0,0				; serial

;-----------------------------
;look for intrinsic functions (commandFCB has been filled)
IntrinsicFunction:					; intrinsic
	LXI	HL,intrinsicFunctionNames
	MVI	C,0				; c counts intrinsics as scanned
IntrinsicFunction1:					; intrin0:
	MOV	A,C
	CPI	IntrinsicFunctionCount		; done with scan?
	RNC					; no, more to scan
	LXI	DE,commandFCB+1			; beginning of name
	MVI	B,4				; length of match is in b
IntrinsicFunction2:					; intrin1:
	LDAX	DE
	CMP	M				; match?
	JNZ	IntrinsicFunction3			; skip if no match
	INX 	DE
	INX	HL
	DCR	B
	JNZ	IntrinsicFunction2			; loop while matching
						; complete match on name, check for blank in fcb
	LDAX	DE
	CPI	SPACE
	JNZ	IntrinsicFunction4			; otherwise matched
	MOV	A,C
	RET					; with intrinsic number in A

IntrinsicFunction3:					; intrin2 mismatch, move to end of intrinsic
	INX	HL
	DCR	B
	JNZ	IntrinsicFunction3

IntrinsicFunction4:					; intrin3 try next intrinsic
	INR	C				; to next intrinsic number
	JMP	IntrinsicFunction1			; for another round
;-----------------------------
;*****************************************************************
;************************ Utilities ******************************
;*****************************************************************
;-----------------------------
PrintSpace:					; blank
	MVI	A,SPACE
	JMP	PrintSaveBC
;-----------------------------
CrLf:						; crlf
	MVI	A,CR
	CALL	PrintSaveBC
	MVI	A,LF
	JMP	PrintSaveBC	
;-----------------------------
;print character, but save b,c registers
PrintSaveBC:					;printbc
	PUSH	BC
	CALL	PrintChar
	POP	BC
	RET
;-----------------------------
PrintChar:					; printchar
	MOV	E,A
	MVI	C,fConsoleOut
	JMP	BDOSE
;-----------------------------
;print CRLF then null terminated string at (BC)
PrintCrLfStringNull:				; print
	PUSH	BC
	CALL	CrLf
	POP	HL ;now print the string
;print null terminated string at (HL)
PrintStringNull:					; prin0
	MOV	A,M
	ORA	A
	RZ					; stop on 00
	INX	HL
	PUSH	HL				; ready for next
	CALL	PrintChar
	POP	HL				; character printed
	JMP	PrintStringNull ;for 
;-----------------------------
;print no file message
PrintNoFile:					;nofile
	LXI	BC,msgNoFile
	JMP	PrintCrLfStringNull
	
msgNoFile: DB 'NO FILE',0	
;-----------------------------
;move 3 characters from h,l to d,e addresses
CopyHL2DE3:					; movename
	MVI	B,3
CopyHL2DEforB:					; move0:
	MOV	A,M
	STAX	DE
	INX	HL
	INX	DE
	DCR	B
	JNZ	CopyHL2DEforB
	RET
;-----------------------------
;return (HL) = (A) + (HL)
AddA2HL:						; addh
	ADD	L
	MOV	L,A
	RNC
	INR	 H
	RET
;-----------------------------
;buff + a + c to h,l followed by fetch
GetByteAtAandCandDMA:				; addhcf
	LXI	HL,DMABuffer			; 0080H
	ADD	C
	CALL	AddA2HL
	MOV	A,M
	RET
;-----------------------------
;convert character in register A to upper case
UpCase:						; translate
	CPI	061H
	RC 					;return if below lower case a
	CPI	07BH	
	RNC					;return if above lower case z
	ANI	05FH
	RET					; translated to upper case
;-----------------------------
;-----------------------------
;-----------------------------
;error in command string
;starting at position;'fillFCBStart' and ending with first delimiter

CommandError:					; comerr
	CALL	CrLf				; space to next line
	LHLD	fillFCBStart			; h,l address first to print
CommandError1:					; comerr0  print characters until blank or zero
	MOV	A,M                           
	CPI	SPACE                         
	JZ	CommandError2			; not blank
	ORA	A                             
	JZ	CommandError2			; not zero, so print it
	PUSH	HL                            
	CALL	PrintChar
	POP	HL
	INX	HL
	JMP	CommandError1			; for another character
CommandError2:					; comerr1 print question mark,and delete sub file
	MVI	A,QMARK
	CALL	PrintChar
	CALL	CrLf
	CALL	DeleteSubmitFile
	JMP	Ccp				; restart with next command
;--------------------------------------------------------
;reset disk 
ResetDisk:					; resetdisk
	LDA	selectedDisk
	ORA	A
	RZ					; no action if not selected
	DCR	A
	LXI	HL,currentDisk
	CMP	M
	RZ					; same disk
	LDA	currentDisk
	JMP	SelectDisk
;--------------------------------------------------------
;reset disk before end of command check
ResetDiskAtCmdEnd:					; retcom
	CALL	ResetDisk
;end of intrinsic command
EndCommand:					; endcom
	CALL	FillFCB0				; to check for garbage at end of line
	LDA	commandFCB + 1
	SUI	SPACE
	LXI	HL,selectedDisk
	ORA	M
						; 0 in accumulator if no disk selected, and blank fcb
	JNZ	CommandError
	JMP	Ccp
;*****************************************************************
;************************ CCP Commands ***************************
;*****************************************************************

;******************** Directory Listing ***************************
;Directory Listing
ccpDirectory:					; direct directory search
;	LXI	DE,messCmdDIR
;	JMP	CcpTemp				; send message and go ack for more
	CALL	FillFCB0				; commandFCB gets file name
	CALL	SetDisk4Cmd			; change disk drives if requested
	LXI	HL,commandFCB+1
	MOV	A,M				; may be empty request
	CPI	SPACE
	JNZ	ccpDir2				; skip fill of ??? if not blank
						; set commandFCB to all ??? for current disk
	MVI	B,11				; length of fill ????????.???
ccpDir1:						; dir0:
	MVI	M,QMARK
	INX	HL
	DCR	B
	JNZ	ccpDir1
						; not a blank request, must be in commandFCB
ccpDir2:						; dir1:
	MVI	E,0
	PUSH	DE				; E counts directory entries
	CALL	Searc4CmdFcbFile			; first one has been found
	CZ	PrintNoFile			; not found message
ccpDir3:						; dir2:
	JZ	ccpDirEnd
						; found, but may be system file
	LDA	directoryCount			; get the location of the element
	RRC
	RRC
	RRC
	ANI	1100000B
	MOV	C,A
						; c contains base index into buff for dir entry
	MVI	A,systemFile			; System File Location in FCB
	CALL	GetByteAtAandCandDMA		; value to A
	RAL
	JC	ccpDir7				; skip if system file c holds index into buffer
						;  another fcb found, new line?
	POP	DE				; get directory entry count (E)
	MOV	A,E
	INR	E
	PUSH	DE				; save dir entry count
						; e=0,1,2,3,...new line if mod 4 = 0
	ANI	11B
	PUSH	PSW				; and save the test
	JNZ	ccpDirHeader			; header on current line
						; print the header drive with Colon ie A:
	CALL	CrLf
	PUSH	BC
	CALL	GetSelectedDrive
	POP	BC
	ADI	ASCII_A	
	CALL	PrintSaveBC
	MVI	A,COLON
	CALL	PrintSaveBC			; just printed drive with Colon ie A:
	JMP	ccpDirHeader1			; skip current line hdr
	
ccpDirHeader:					; dirhdr0:
	CALL	PrintSpace			; after last one
	MVI	A,COLON                       
	CALL	PrintSaveBC                   
ccpDirHeader1:					; dirhdr1:
	CALL	PrintSpace
						; compute position of name in buffer
	MVI	B,1				; start with first character of name
ccpDir4:						; dir3:
	MOV	A,B
	CALL	GetByteAtAandCandDMA		; buff+a+c fetched
	ANI	ASCII_MASK			; mask flags
						; may delete trailing blanks
	CPI	SPACE
	JNZ	ccpDir5				; check for blank type
	POP	PSW
	PUSH	PSW				; may be 3rd item
	CPI	3
	JNZ	ccpDirSpace			; place blank at end if not
	MVI	A,9
	CALL	GetByteAtAandCandDMA		; first char of type
	ANI	ASCII_MASK
	CPI	SPACE
	JZ	ccpDir6
						; not a blank in the file type field
ccpDirSpace:					; dirb:
	MVI	A,SPACE				; restore trailing filename chr
ccpDir5:						; dir4:
	CALL	PrintSaveBC			; char printed
	INR	B
	MOV	A,B
	CPI	12
	JNC	ccpDir6
						; check for break between names
	CPI	9
	JNZ	ccpDir4				; for another char
	
	CALL	PrintSpace			; print a blank between names
	JMP	ccpDir4

ccpDir6:						; dir5 end of current entry
	POP	PSW				; discard the directory counter (mod 4)
ccpDir7:						; dir6:
	CALL	CheckForConsoleChar			; check for interrupt at keyboard
	JNZ	ccpDirEnd				; abort directory search
	CALL	SearchForNext
	JMP	ccpDir3				; for another entry
ccpDirEnd:					; endir end of directory scan
	POP	DE				; discard directory counter
	JMP	ResetDiskAtCmdEnd
;

;*****************************************************************
ccpErase:						; erase file erase
	LXI	DE,messCmdERA
	JMP	CcpTemp				; send message and go ack for more
;*****************************************************************
ccpType:						; type type file
	LXI	DE,messCmdTYPE
	JMP	CcpTemp				; send message and go ack for more
;*****************************************************************
ccpSave:						; save save memory image
	LXI	DE,messCmdSAV
	JMP	CcpTemp				; send message and go ack for more
;*****************************************************************
ccpRename:					; rename file rename
	LXI	DE,messCmdREN
	JMP	CcpTemp				; send message and go ack for more
;*****************************************************************
ccpUser:						; user user number
	LXI	DE,messCmdUSER
	JMP	CcpTemp				; send message and go ack for more
;*****************************************************************
ccpUserFunction:					; userfunc user-defined function
	LXI	DE,messCmdUF
	JMP	CcpTemp				; send message and go ack for more
;----------------------------------------------------------
CcpTemp:
	MVI	C,09H
	CALL	BDOSE				; print String at (DE)
	LXI	SP,Stack				; reset the stack pointer
	JMP	Ccp				; go back for more
	
messCmdDIR:	DB	CR,LF,'Directory Command',CR,LF,DOLLAR
messCmdERA:	DB	CR,LF,'Erase Command',CR,LF,DOLLAR
messCmdTYPE:	DB	CR,LF,'Type Command',CR,LF,DOLLAR
messCmdSAV:	DB	CR,LF,'Save Command',CR,LF,DOLLAR
messCmdREN:	DB	CR,LF,'Rename Command',CR,LF,DOLLAR
messCmdUSER:	DB	CR,LF,'User Command',CR,LF,DOLLAR
messCmdUF:	DB	CR,LF,'User Function Command',CR,LF,DOLLAR
;*****************************************************************
;*****************************************************************
;change disks for this command, if requested
SetDisk4Cmd:					; setdisk
	XRA	A
	STA	commandFCB			; clear disk name from fcb
	LDA	selectedDisk
	ORA	A
	RZ					; no action if not specified
	DCR	A
	LXI	HL,currentDisk
	CMP	M
	RZ					;already selected
	JMP	SelectDisk
;*****************************************************************

;*****************************************************************
;************************ Data Area ******************************
;*****************************************************************
	DS	16				; 8 level stack
Stack:						; stack
;	'submit' file control block
submitFlag:	DB	00H			; submit 00 if no submit file, ff if submitting
submitFCB:	DB	00H			; subfcb file name is $$$
;	db	'SUB',0,0				; file type is sub
subModuleNumber:	DB	00H			; submod module number
subRecordCount:	DB	000H			; subrc record count filed
;	ds	16				; disk map
subCurrentRecord:	DB	000H			; subcr current record to read
;;                                                
;;	command file control block              
commandFCB:	DS	32			; comfcb fields filled in later
;comrec:	ds	1				; current record to read/write
directoryCount:	DB	000H			; dcnt disk directory count (used for error codes)
currentDisk:	DB	000H			; cdisk current disk
selectedDisk:	DB	000H			; sdisk selected disk for current operation
;						; none=0, a=1, b=2 ...
;bptr:	ds	1				; buffer pointer

;----------------------------
MaxBufferLength:	DB	127			; maxlen max buffer length
CommandLength:	DB	0			; comlen command length (filled in by dos)
; (command executed initially if CommandLength non zero)
commandBuffer:					; combuf:
	DB	'        '			; 8 character fill
	DB	'        '			; 8 character fill
	DB	'COPYRIGHT (C) 1979 DIGITAL RESEARCH  '; 38
	DS	128-($-commandBuffer)
;	total buffer length is 128 characters
commandAddress:	DW	commandBuffer		; comaddr address of next to char to scan
fillFCBStart:	DW	0000H			; staddr starting address of current FillFCB request

CodeEnd:


