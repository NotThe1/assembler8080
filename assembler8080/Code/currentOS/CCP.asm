; CCP.asm
;
; 2014-01-16
; 2014-05-01  :  Frank Martyn

; replace systemFile with fcbSystemFileIndex

	$Include ../Headers/stdHeader.asm
	$Include ./osHeader.asm
	$Include ./diskHeader.asm


                                                  
;systemFile			EQU	0AH			; sysfile System File Flag Location
fcbSystemFileIndex			EQU		0AH					; extent number field index
; roFile				EQU	09H			; rofile Read Only Flag Location   fcbROfileIndex
;END_OF_FILE			EQU	1AH			; end of file 
                                                  
	                                        
					ORG	CCPEntry

CcpBoundary			EQU	$			

	JMP		CcpStart					;start ccp with possible initial command

	
;*****************************************************************
;enter here from boot loader
CcpStart:
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
	STA		Pg0CurentDisk					; clears low memory user code nibble
	CALL	SelectDisk				; proper disk is selected, now check sub files
									; check for initial command
	LDA		CommandLength
	ORA		A
	JNZ		Ccp0					;assume typed already
	
Ccp:								;enter here on each command or error condition
	LXI		SP,Stack
	CALL	CrLf					; print d> prompt, where d is disk name
	CALL	GetSelectedDrive		; get current disk number
	ADI		ASCII_A	
	CALL	PrintChar
	MVI		A,GREATER_THAN
	CALL	PrintChar
	CALL	ReadCommand				; command buffer filled
Ccp0:								; ccp0 enter here from initialization with command full
	LXI		DE,DMABuffer
	CALL	SetDMA					; default dma address at DMABuffer
	CALL	GetSelectedDrive
	STA		currentDisk				; current disk number saved
	CALL	FillFCB0				; command fcb filled
	CNZ		CommandError			; the name cannot be an ambiguous reference
	LDA		selectedDisk
	ORA		A
	JNZ		ccpUserFunction
	
	CALL	IntrinsicFunction		; check for an intrinsic function
	LXI		HL,intrinsicFunctionsVector		; index is in the accumulator
	MOV		E,A
	MVI		D,0
	DAD		DE
	DAD		DE						; index in d,e
	MOV		A,M
	INX		HL
	MOV		H,M
	MOV		L,A
	PCHL							; pc changes to the proper intrinsic or user function
;.................................................
;.................................................

intrinsicFunctionsVector:					; jmptab
	DW		ccpDirectory					; directory search
	DW		ccpErase						; file erase
	DW		ccpType							; type file
	DW		ccpSave							; save memory image
	DW		ccpRename						; file rename
	DW		ccpUser							; user number
	DW		ccpUserFunction					; user-defined function

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
	CALL	SetPage0CurDisk			; no control c, so restore Pg0CurentDisk
	
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

;----------------------------------------------------------------
;----------------------------------------------------------------
;----------------------------------------------------------------
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
;open the file given by (DE)
OpenFile:						; open
	MVI	C,fOpenFile
	JMP	BDOSandIncA	
;--------
;open file for Command FCB
OpenFile4CmdFCB:					; openc
	XRA	A
	STA	currentRecord			; clear next record to read
	LXI	DE,commandFCB
	JMP	OpenFile
;-----------------------------
;close the file given by (DE)
CloseFile:					; close
	MVI	C,fCloseFile
	JMP	BDOSandIncA
;-----------------------------
;delete the file given by (DE)
DeleteFile:					; delete
	MVI	C,fDeleteFile
	JMP	BDOSE
;-----------------------------
;make the file given by (DE)
MakeFile:						; make
	MVI	C,fMakeFile
	JMP	BDOSandIncA
;-----------------------------
;read the next record from the file given by d,e
DiskRead:						; diskread
	MVI	C,fReadSeq
	JMP	BDOSsetFlags
;-----------
;read next record from Command FCB
DiskReadCmdFCB:					; diskreadc
	LXI	DE,commandFCB
	JMP	DiskRead
;-----------------------------
;write the next record to the file given by (DE)
DiskWrite:					; diskwrite
	MVI	C,fWriteSeq
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
; rename a file give bu (DE)
RenameFile:					; renam
	MVI	C,fRenameFile
	JMP	BDOSE
;-----------------------------
;set default buffer dma address
SetDefaultDMA:					; setdmabuff
	LXI	D,DMABuffer
;---------
;set dma address to d,e
SetDMA:						; setdma
	MVI	C,fSetDMA
	JMP	BDOSE
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
	STA	Pg0CurentDisk				; stored away in memory for later
	RET
;-----------------------------
; set Pg0CurentDisk to current disk
SetPage0CurDisk:					; setdiska
	LDA	currentDisk
	STA	Pg0CurentDisk				; user/disk
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
; get number from the command line
GetNumberFromCmdLine:				; getnumber
	CALL	FillFCB0				; should be number
	LDA	selectedDisk
	ORA	A
	JNZ	CommandError			; cannot be prefixed
						; convert the byte value in commandFCB to binary
	LXI	HL,commandFCB + 1
	LXI	BC,11				;(b=0, c=11)
						; value accumulated in b, c counts name length to zero
GetNumericValue:					; conv0:
	MOV	A,M
	CPI	SPACE
	JZ	GetNumericValue1
						; more to scan, convert char to binary and add
	INX	HL
	SUI	ASCII_ZERO
	CPI	10
	JNC	CommandError			; valid?
	MOV	D,A				; save value
	MOV	A,B				; mult by 10
	ANI	11100000B
	JNZ	CommandError
	MOV	A,B				; recover value
	RLC
	RLC
	RLC					; *8
	ADD	B
	JC	CommandError
	ADD	B
	JC	CommandError			; *8+*2 = *10
	ADD	D
	JC	CommandError ;+digit
	MOV	B,A
	DCR	C
	JNZ	GetNumericValue			; for another digit
	RET
GetNumericValue1:					; conv1 end of digits, check for all blanks
	MOV	A,M
	CPI	SPACE
	JNZ	CommandError ;blanks?
	INX	HL
	DCR	C
	JNZ	GetNumericValue1
	MOV	A,B ;recover value
	RET
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
IntrinsicFunctionCount	EQU	(($-intrinsicFunctionNames)/4) + 1
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
serialNumber: DB 0,0,0,0,0,0				; serial
;-----------------------------
;-----------------------------
;check serialization
CheckSerialNumber:					; serialize
	LXI	D,serialNumber
	LXI	H,BDOSBase			; BDOS base address
	MVI	B,6				; check six bytes
CheckSerialNumber0:					; ser0
	LDAX	DE
	CMP	M
	JNZ	BadSerialNumber
	INX	DE
	INX	HL
	DCR	B
	JNZ	CheckSerialNumber0
	RET						; serial number is ok
;-----------------------------	
BadSerialNumber:					; badserial:
	LXI	H,76F3H				; 'DI HLT' instructions  lxi h,di or (hlt shl 8)
	SHLD	CCPEntry
	LXI	H,CCPEntry
	PCHL
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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
;DMABuffer + a + c to h,l followed by fetch
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
;*****************************************************************
;************************ Error messages ******************************
;*****************************************************************
;print the read error message
PrintReadError:					; readerr
	LXI	BC,msgReadErr
	JMP	PrintCrLfStringNull
msgReadErr:					; rdmsg:
	DB 'READ ERROR',0	
;-------------
;-----------------------------
;-----------------------------
;-----------------------------


;*****************************************************************
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
						; c contains base index into DMABuffer for dir entry
	MVI	A,fcbSystemFileIndex			; System File Location in FCB
	CALL	GetByteAtAandCandDMA		; value to A
	RAL
	JC	ccpDir7				; skip if system file c holds index into buffer
						;  another fcb found, new line?
	POP	DE				; get directory entry count (E)
	MOV	A,E
	INR	E
	PUSH	DE				; save dir entry count
	ANI	11B				; e=0,1,2,3,...new line if mod 4 = 0
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
	CALL	GetByteAtAandCandDMA		; DMABuffer+a+c fetched
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
;	LXI	DE,messCmdERA
;	JMP	CcpTemp				; send message and go ack for more
	CALL	FillFCB0				; cannot be all ???'s
	CPI	11
	JNZ	ccpEraseAll
						; erasing all of the disk
	LXI	BC,msgEraseAll
	CALL	PrintCrLfStringNull
	
	CALL	ReadCommand
	LXI	HL,CommandLength
	DCR	M
	JNZ	Ccp ;bad input
	INX	HL
	MOV	A,M
	CPI	ASCII_Y
	JNZ	Ccp
						; ok, erase the entire diskette
	INX	HL
	SHLD	commandAddress			; otherwise error at ResetDiskAtCmdEnd
ccpEraseAll:					; erasefile:
	CALL	SetDisk4Cmd
	LXI	DE,commandFCB
	CALL	DeleteFile
	INR	A				; 255 returned if not found
	CZ	PrintNoFile			; no file message if so
	JMP	ResetDiskAtCmdEnd
;
msgEraseAll:					; ermsg:
	DB	'ALL (Y/N)?',0
;*****************************************************************
; Type file
ccpType:
	CALL	FillFCB0
	JNZ		CommandError			; don't allow ?'s in file name
	CALL	SetDisk4Cmd
	CALL	OpenFile4CmdFCB			; open the file
	JZ		ccpTypeError			; zero flag indicates not found
; file opened, read 'til eof
	CALL	CrLf
	LXI		HL,bufferPointer
	MVI		M,255 					; read first buffer
ccpType1:							; type0 loop on bufferPointer
	LXI		HL,bufferPointer
	MOV		A,M
	CPI		128						; end buffer
	JC		ccpType2
	PUSH	HL						; carry if 0,1,...,127
; read another buffer full
	CALL	DiskReadCmdFCB
	POP		HL						; recover address of bufferPointer
	JNZ		ccpTypeEOF				; hard end of file
	XRA		A
	MOV		M,A						; bufferPointer = 0
; read character at bufferPointer and print
ccpType2:
	INR		M						; bufferPointer = bufferPointer + 1
	LXI		HL,DMABuffer
	CALL	AddA2HL					; h,l addresses char
	MOV		A,M
	CPI		END_OF_FILE
	JZ		ResetDiskAtCmdEnd
	CALL	PrintChar
	CALL	CheckForConsoleChar
	JNZ		ResetDiskAtCmdEnd		; abort if break
	JMP		ccpType1				; for another character
	
ccpTypeEOF:
	DCR		A
	JZ		ResetDiskAtCmdEnd
	CALL	PrintReadError
ccpTypeError:
	CALL	ResetDisk
	JMP		CommandError
;*****************************************************************
; save save memory image
;*****************************************************************
ccpSave:
	CALL	GetNumberFromCmdLine	; value to register a
	PUSH	PSW						; save it for later
									; should be followed by a file to save the memory image
	CALL	FillFCB0
	JNZ		CommandError			; cannot be ambiguous
	CALL	SetDisk4Cmd				; may be a disk change
	LXI		DE,commandFCB
	PUSH	DE
	CALL	DeleteFile				; existing file removed
	POP 	DE
	CALL	MakeFile				; create a new file on disk
	JZ		ccpSaveError			; no directory space
	XRA		A
	STA		currentRecord			; clear next record field
	POP		PSW						; #pages to write is in a, change to #sectors
	MOV		L,A
	MVI		H,0
	DAD		H
	
	LXI		DE,TPA					; h,l is sector count, d,e is load address
ccpSave1:							; save0 check for sector count zero
	MOV		A,H
	ORA		L
	JZ		ccpSave2				; may be completed
	DCX		HL						; sector count = sector count - 1
	PUSH	HL						; save it for next time around
	LXI		HL,128
	DAD		DE
	PUSH	HL						; next dma address saved
	CALL	SetDMA					; current dma address set
	LXI		DE,commandFCB
	CALL	DiskWrite
	POP		DE
	POP		HL						; dma address, sector count
	JNZ		ccpSaveError			; may be disk full case
	JMP		ccpSave1				; for another sector
	
;  end of dump, close the file
ccpSave2:					
	LXI		DE,commandFCB
	CALL	CloseFile
	INR		A						; 255 becomes 00 if error
	JNZ		ccpSaveExit				; for another command
ccpSaveError:						; saverr must be full or read only disk
	LXI		BC,msgNoSpace
	CALL	PrintCrLfStringNull
ccpSaveExit:
	CALL	SetDefaultDMA			; reset dma buffer
	JMP		ResetDiskAtCmdEnd
	
msgNoSpace:					; fullmsg:
	DB 'NO SPACE',0
;*****************************************************************
ccpRename:					; rename file rename
;	LXI	DE,messCmdREN
;	JMP	CcpTemp				; send message and go ack for more
	CALL	FillFCB0
	JNZ	CommandError			; must be unambiguous
	LDA	selectedDisk
	PUSH	PSW				; save for later compare
	CALL	SetDisk4Cmd			; disk selected
	CALL	Searc4CmdFcbFile			; is new name already there?
	JNZ	ccpRenameError3
						; file doesn't exist, move to second half of fcb
	LXI	HL,commandFCB
	LXI	DE,commandFCB + 16
	MVI	B,16
	CALL	CopyHL2DEforB
						; check for = or left arrow
	LHLD	commandAddress
	XCHG
	CALL	NextNonBlankChar
	CPI	EQUAL_SIGN
	JZ	ccpRename1			; ok if =
	CPI	LEFT_ARROW			; la
	JNZ	ccpRenameError2
ccpRename1:					; ren1 
	XCHG
	INX	HL
	SHLD	commandAddress			; past delimiter
						; proper delimiter found
	CALL	FillFCB0
	JNZ	ccpRenameError2
						; check for drive conflict
	POP	PSW
	MOV	B,A				; previous drive number
	LXI	HL,selectedDisk
	MOV	A,M
	ORA	A
	JZ	ccpRename2
						; drive name was specified.  same one?
	CMP	B
	MOV	M,B
	JNZ	ccpRenameError2
ccpRename2:					; ren2:
	MOV	M,B				; store the name in case drives switched
	XRA	A
	STA	commandFCB
	CALL	Searc4CmdFcbFile			; is old file there?
	JZ	ccpRenameError1

						; everything is ok, rename the file
	LXI	DE,commandFCB
	CALL	RenameFile
	JMP	ResetDiskAtCmdEnd

ccpRenameError1:					; renerr1 no file on disk
	CALL	PrintNoFile
	JMP	ResetDiskAtCmdEnd
ccpRenameError2:					; renerr2  ambigous reference/name conflict
	CALL	ResetDisk
	JMP	CommandError
ccpRenameError3:					; renerr3 file already exists
	LXI	BC,msgFileExists
	CALL	PrintCrLfStringNull
	JMP	ResetDiskAtCmdEnd
	
msgFileExists:					; renmsg:
	DB	'FILE EXISTS',0

;*****************************************************************
ccpUser:						; user user number
;	LXI	DE,messCmdUSER
;	JMP	CcpTemp				; send message and go ack for more
	CALL	GetNumberFromCmdLine		; leaves the value in the accumulator
	CPI	16
	JNC	CommandError			; must be between 0 and 15
	MOV	E,A				; save for SetUser call
	LDA	commandFCB + 1
	CPI	SPACE
	JZ	CommandError
	CALL	SetUser ;new user number set
	JMP	EndCommand
;*****************************************************************
;User defined function
;*****************************************************************
ccpUserFunction:
	CALL	CheckSerialNumber		; check Serial Number
	LDA		commandFCB + 1
	CPI		SPACE
	JNZ		ccpUserFunction1
; no file name, but may be disk switch
	LDA		selectedDisk
	ORA		A
	JZ		EndCommand				; no disk named if 0
	DCR		A						; adjust so A=>0, B=>1, C=>2 ......
	STA		currentDisk				; update current Disk indicator
	CALL	SetPage0CurDisk			; set user/disk
	CALL	SelectDisk
	JMP		EndCommand
	
;  file name is present	
ccpUserFunction1:					
	LXI	DE,commandFCB + 9
	LDAX	DE
	CPI	SPACE
	JNZ	CommandError			; type SPACE
	PUSH	DE
	CALL	SetDisk4Cmd
	POP	DE
	LXI	HL,comFileType			; .com
	CALL	CopyHL2DE3			; file type is set to .com
	CALL	OpenFile4CmdFCB
	JZ	ccpUserFunctionError1
						; file opened properly, read it into memory
	LXI	HL,TPA				; transient program base
ccpUserFunction2:					; load0:
	PUSH	HL ;save dma address
	XCHG
	CALL	SetDMA
	LXI	DE,commandFCB
	CALL	DiskRead
	JNZ	ccpUserFunction3
						; sector loaded, set new dma address and compare
	POP	HL
	LXI	DE,128
	DAD	DE
	LXI	DE,CcpBoundary			; has the load overflowed?
	MOV	A,L
	SUB	E
	MOV	A,H
	SBB	D
	JNC	ccpUserFunctionError2
	JMP	ccpUserFunction2			; for another sector

ccpUserFunction3:					; load1:
	POP	H
	DCR	A
	JNZ	ccpUserFunctionError2		; end file is 1
	CALL	ResetDisk				; back to original disk
	CALL	FillFCB0
	LXI	HL,selectedDisk
	PUSH	HL
	MOV	A,M
	STA	commandFCB			; drive number set
	MVI	A,16
	CALL	FillFCB				; move entire fcb to memory
	POP	HL
	MOV	A,M
	STA	commandFCB + 16
	XRA	A
	STA	currentRecord			; record number set to zero
	LXI	DE,FCB1				; default FCB in page 0
	LXI	HL,commandFCB
	MVI	B,33
	CALL	CopyHL2DEforB
						; move command line to buff
	LXI	HL,commandBuffer
ccpUserFunction4:					; bmove0:
	MOV	A,M
	ORA	A
	JZ	ccpUserFunction5
	CPI	SPACE
	JZ	ccpUserFunction5
	INX	HL
	JMP	ccpUserFunction4			; for another scan
						; first blank position found
ccpUserFunction5:					; bmove1:
	MVI	B,0
	LXI	DE,DMABuffer + 1
						; ready for the move
ccpUserFunction6:					; bmove2:
	MOV	A,M
	STAX	DE
	ORA	A
	JZ	ccpUserFunction7
			;more to move
	INR	B
	INX	HL
	INX	DE
	JMP	ccpUserFunction6
ccpUserFunction7:					; bmove3 b has character count
	MOV	A,B
	STA	DMABuffer
	CALL	CrLf
						; now go to the loaded program
	CALL	SetDefaultDMA			; default dma
	CALL	SaveUser				; user code saved
						; low memory diska contains user code
	CALL	TPA				; gone to the loaded program
	LXI	SP,Stack				; may come back here
	CALL	SetPage0CurDisk
	CALL	SelectDisk
	JMP	Ccp
	
ccpUserFunctionError1:				; userer arrive here on command error
	CALL	ResetDisk
	JMP	CommandError

ccpUserFunctionError2:				; loaderr cannot load the program
	LXI	BC,msgBadLoad
	CALL	PrintCrLfStringNull
	JMP	ResetDiskAtCmdEnd
	
msgBadLoad:					; loadmsg:
	DB 'BAD LOAD',0
comFileType:					; comtype:
	DB 'COM' ;for com files
;
;
;----------------------------------------------------------
;CcpTemp:
;	MVI	C,09H
;	CALL	BDOSE				; print String at (DE)
;	LXI	SP,Stack				; reset the stack pointer
;	JMP	Ccp				; go back for more
;	
;messCmdDIR:	DB	CR,LF,'Directory Command',CR,LF,DOLLAR
;messCmdERA:	DB	CR,LF,'Erase Command',CR,LF,DOLLAR
;messCmdTYPE:	DB	CR,LF,'Type Command',CR,LF,DOLLAR
;messCmdSAV:	DB	CR,LF,'Save Command',CR,LF,DOLLAR
;messCmdREN:	DB	CR,LF,'Rename Command',CR,LF,DOLLAR
;messCmdUSER:	DB	CR,LF,'User Command',CR,LF,DOLLAR
;messCmdUF:	DB	CR,LF,'User Function Command',CR,LF,DOLLAR
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
;	'submit' file control block
submitFlag:			DB		00H				; 00 if no submit file, ff if submitting
submitFCB:			DB		00H				; file name is $$$
	
subModuleNumber:	DB		00H				; module number
subRecordCount:		DB		00H				; record count filed
subCurrentRecord:	DB		00H				; current record to read
;;                                      	          
;;	command file control block          	    
commandFCB:			DS		32				; fields filled in later
currentRecord:		DB		00H				; current record to read/write
directoryCount:		DB		00H				; disk directory count (used for error codes)
currentDisk:		DB		00H				; current disk
selectedDisk:		DB		00H				; selected disk for current operation none=0, a=1, b=2 ...
;	
bufferPointer:		DB		00H				; buffer pointer
;------------------------------------
fillFCBStart:		DW		0000H			; staddr starting address of current FillFCB request
;----------------------------
; (command executed initially if CommandLength non zero)

MaxBufferLength:	DB		127				; maxlen max buffer length
CommandLength:		DB		0				; comlen command length (filled in by dos)
commandBuffer:								; combuf:
					DB		'        '		; 8 character fill
					DB		'        '		; 8 character fill
					DB		'COPYRIGHT (C) 1979 DIGITAL RESEARCH  '; 38
restOfCmdBuffer:
					DS		cpmRecordSize-(restOfCmdBuffer-commandBuffer)
commandAddress:		DW		commandBuffer	; comaddr address of next to char to scan
	
endOfCommandBuffer:
;-------------------------------
;	DS	16									; 8 level stack
				ORG		BDOSBase-10H
Stack:										; stack




