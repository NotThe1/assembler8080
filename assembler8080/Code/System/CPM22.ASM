
;**************************************************************
;*
;*             C P / M   version   2 . 2
;*                    Sourced from:
;*  Reconstructed from memory image on February 27, 1981
;*                by Clark A. Calkins
;*
;**************************************************************
;

;
MEM			EQU		64			;for a 64k system 
;
IOBYTE		EQU		3			;i/o definition byte.
TDRIVE		EQU		4			;current drive name and user number.
ENTRY		EQU		5			;entry point for the cp/m bdos.
DefaultFCB	EQU		5CH			;default file control block.
Pg0Buffer	EQU		80H			;i/o buffer and command line storage.
TBASE		EQU		100H		;transiant program storage area.
;
;   Set control character equates.
;
CNTRLC		EQU		03H			;control-c
CNTRLE		EQU		05H			;control-e
BS			EQU		08H			;backspace
TAB			EQU		09H			;tab
LF			EQU		0AH			;line feed
FF			EQU		0CH			;form feed
CR			EQU		0DH			;carriage return
CNTRLP		EQU		10H			;control-p
CNTRLR		EQU		12H			;control-r
CNTRLS		EQU		13H			;control-s
CNTRLU		EQU		15H			;control-u
CNTRLX		EQU		18H			;control-x
CNTRLZ		EQU		1AH			;control-z (end-of-file mark)
DEL			EQU		7FH			;rubout
;
BLANK		EQU		020H		; Space/Blank
BRACKETLEFT		EQU	07BH		; {
BRACKETRIGHT	EQU	07DH		; }
QMARK		EQU		03FH		; ?
EQUALS		EQU		03DH		; =
USCORE		EQU		05FH		; _
PERIOD		EQU		02EH		; .
COLON		EQU		03AH		; :
SEMIC		EQU		03BH		; ;
LESSTH		EQU		03CH		; <
GRTTHAN		EQU		03EH		; >
ASTRK		EQU		02AH		; *
CARET		EQU		05EH		; ^
ATSIGN		EQU		040H		; @
POUNDSN		EQU		023H		; #
DOLLAR		EQU		024H		; $

EndOfMessage	EQU	00H
EmptyFileFlag	EQU	0E5H		; empty file slot in dorectory
;
;   Set origin for CP/M
;
	ORG	(MEM-8)*1024
CodeStart:
;
CBASE:
		JMP		COMMAND		;execute command processor (ccp).
		JMP		CLEARBUF	;entry to empty input buffer before starting ccp.

;
;   Standard cp/m ccp input buffer. Format is (max length),
; (actual length), (char #1), (char #2), (char #3), etc.
;
InBuffStart:
InBuffSize:					;length of input buffer.
		DB		InBuffEnd - InBuffStart		
InBuffCount:			;current Count of contents.
		DB		0
InBuff:
		DB		'Copyright '
		DB		'1979 (c) by '
		DB		'Digital Research'
		DB		00
		DS		86			
InBuffEnd:
		
InBuffAddress:
		DW		InBuff		;input line pointer
ErrorMsgPointer:
		DW		0			; input line pointer used for error message. Points to
							; start of name in error.
;
;   Routine to print (A) on the console. All registers used.
;
PRINT:
	MOV		E,A			;setup bdos call.
	MVI		C,2
	JMP		ENTRY
;
;   Routine to print (A) on the console and to save (BC).
;
PRINTB:
	PUSH	B
	CALL	PRINT
	POP		B
	RET
;
;   Routine to send a carriage return, line feed combination
; to the console.
;
SendEndOfLine:
	MVI		A,CR
	CALL	PRINTB
	MVI		A,LF
	JMP		PRINTB
;
;   Routine to send one space to the console and save (BC).
;
SpaceToConsole:
	MVI		A,BLANK		; blank/Space
	JMP		PRINTB
;
;   Routine to print character string pointed to be (BC) on the
; console. It must terminate with a null byte.
;
PLINE:
	PUSH	B
	CALL	SendEndOfLine
	POP		H
PLINE2:
	MOV		A,M
	ORA		A
	RZ
	INX		H
	PUSH	H
	CALL	PRINT
	POP		H
	JMP		PLINE2
;
;   Routine to reset the disk system.
;
ResetDiskSystem:
	MVI		C,13
	JMP		ENTRY
;
;   Routine to select disk (A).
;
DiskSelect:
	MOV		E,A
	MVI		C,14
	JMP		ENTRY
;
;   Routine to call bdos and save the return code. The zero
; flag is set on a return of 0ffh.
;
ENTRY1:
	CALL	ENTRY
	STA		RTNCODE		;save return code.
	INR		A			;set zero if 0ffh returned.
	RET
;
;   Routine to open a file. (DE) must point to the FCB.
;
OPEN:
	MVI		C,15
	JMP		ENTRY1
;
;   Routine to open file at (FCB).
;
OPENFCB:
	XRA		A		;clear the record number byte at fcb+32
	STA		FCBfromCCP+32
	LXI		D,FCBfromCCP
	JMP		OPEN
;
;   Routine to close a file. (DE) points to FCB.
;
CLOSE:
	MVI		C,16
	JMP		ENTRY1
;
;   Routine to search for the first file with ambigueous name
; (DE).
;
SearchForFirst:
	MVI		C,17
	JMP		ENTRY1
;
;   Search for the next ambigeous file name.
;
SearchForNext:
	MVI		C,18
	JMP		ENTRY1
;
;   Search for file at (FCB).
;
SRCHFCB:
	LXI		D,FCBfromCCP
	JMP		SearchForFirst
;
;   Routine to delete a file pointed to by (DE).
;
DeleteFile:
	MVI		C,19
	JMP		ENTRY
;
;   Routine to call the bdos and set the zero flag if a zero
; status is returned.
;
ENTRY2:
	CALL	ENTRY
	ORA		A		;set zero flag if appropriate.
	RET
;
;   Routine to read the next record from a sequential file.
; (DE) points to the FCB.
;
RDREC:
	MVI		C,20
	JMP		ENTRY2
;
;   Routine to read file at (FCB).
;
READFCB:
	LXI		D,FCBfromCCP
	JMP		RDREC
;
;   Routine to write the next record of a sequential file.
; (DE) points to the FCB.
;
WRTREC:
	MVI		C,21
	JMP		ENTRY2
;
;   Routine to create the file pointed to by (DE).
;
CREATE:
	MVI		C,22
	JMP		ENTRY1
;
;   Routine to rename the file pointed to by (DE). Note that
; the new name starts at (DE+16).
;
RENAM:
	MVI		C,23
	JMP		ENTRY
;
;   Get the current user code.
;
GETUSR:
	MVI		E,0FFH			; make it get
;
;   Routine to get or set the current user code.
; If (E) is FF then this is a GET, else it is a SET.
;
GetSetCurrentUser:
	MVI		C,32			; BDOS vector
	JMP		ENTRY
;
;   Routine to set the current drive byte at (TDRIVE).
;
SetCurrentDrive:
	CALL	GETUSR			;get user number
	ADD		A				;and shift into the upper 4 bits.
	ADD		A
	ADD		A
	ADD		A
	LXI		H,CDRIVE		;now add in the current drive number.
	ORA		M
	STA		TDRIVE			;and save.
	RET
;
;   Move currently active drive down to (TDRIVE).
;
MOVECD:
	LDA		CDRIVE
	STA		TDRIVE
	RET
;
;   Routine to convert (A) into upper case ascii. Only letters
; are affected.
;
UPPER:
	CPI		061H			; 'a'	;check for letters in the range of 'a' to 'z'.
	RC
	CPI		BRACKETLEFT		;'{'
	RNC
	ANI		5FH				;convert it if found.
	RET
;
;   Routine to get a line of input. We must check to see if the
; user is in (BatchFlag) mode. If so, then read the input from file
; ($$$.SUB). At the end, reset to console input.
;
InputLine:
	LDA		BatchFlag			;if =0, then use console input.
	ORA		A
	JZ		InputLineConsole
;
;   Use the submit file ($$$.sub) which is prepared by a
; SUBMIT run. It must be on drive (A) and it will be deleted
; if and error occures (like eof).
;
	LDA		CDRIVE		;select drive 0 if need be.
	ORA		A
	MVI		A,0			;always use drive A for submit.
	CNZ		DiskSelect		;select it if required.
	LXI		D,BATCHFCB
	CALL	OPEN		;look for it.
	JZ		InputLineConsole		;if not there, use normal input.
	LDA		BATCHFCB+15	;get last record number+1.
	DCR		A
	STA		BATCHFCB+32
	LXI		D,BATCHFCB
	CALL	RDREC		;read last record.
	JNZ		InputLineConsole		;quit on end of file.
;
;   Move this record into input buffer.
;
	LXI		D,InBuffCount
	LXI		H,Pg0Buffer	;data was read into buffer here.
	MVI		B,InBuffSize		;all 128 characters may be used.
	CALL	HL2DE		;(HL) to (DE), (B) bytes.
	LXI		H,BATCHFCB+14
	MVI		M,0			;zero out the 's2' byte.
	INX		H			;and decrement the record count.
	DCR		M
	LXI		D,BATCHFCB	;close the batch file now.
	CALL	CLOSE
	JZ		InputLineConsole		;quit on an error.
	LDA		CDRIVE		;re-select previous drive if need be.
	ORA		A
	CNZ		DiskSelect		;don't do needless selects.
;
;   Print line just read on console.
;
	LXI		H,InBuff
	CALL	PLINE2
	CALL	CHKCON		;check console, quit on a key.
	JZ		InputLineConsole1		;jump if no key is pressed.
;
;   Terminate the submit job on any keyboard input. Delete this
; file such that it is not re-started and jump to normal keyboard
; input section.
;
	CALL	DeleteBatchFile	;delete the batch file.
	JMP		CMMND1		;and restart command input.
;
;   Get here for normal keyboard input. Delete the submit file
; incase there was one.
;
InputLineConsole:
	CALL	DeleteBatchFile		; delete file ($$$.sub).
	CALL	SetCurrentDrive		; reset active disk.
	MVI		C,10				; get line from console device.
	LXI		D,InBuffStart		; point at the Inbuff construct (Size, Pos, Buffer)
	CALL	ENTRY				; call BDOS fcConsoleStringIn
	CALL	MOVECD		;reset current drive (again).
;
;   Convert input line to upper case.
;
InputLineConsole1:
	LXI		H,InBuffCount
	MOV		B,M			;(B)=character counter.
InputLineConsole2:
	INX		H
	MOV		A,B			;end of the line?
	ORA		A
	JZ		InputLineConsole3
	MOV		A,M			;convert to upper case.
	CALL	UPPER
	MOV		M,A
	DCR		B			;adjust character count.
	JMP		InputLineConsole2
InputLineConsole3:
	MOV		M,A			;add trailing null.
	LXI		H,InBuff
	SHLD	InBuffAddress		;reset input line pointer.
	RET
;
;   Routine to check the console for a key pressed. The zero
; flag is set is none, else the character is returned in (A).
;
CHKCON:
	MVI		C,11		;check console.
	CALL	ENTRY
	ORA		A
	RZ					;return if nothing.
	MVI		C,1			;else get character.
	CALL	ENTRY
	ORA		A			;clear zero flag and return.
	RET
;
;   Routine to get the currently active drive number.
;
GetCurrentDisk:
	MVI		C,25
	JMP		ENTRY
;
;   Set the stabdard dma address.
;
STDDMA:
	LXI		D,Pg0Buffer
;
;   Routine to set the dma address to (DE).
;
setDMA:
	MVI		C,26
	JMP		ENTRY
;
;  Delete the batch file created by SUBMIT.
;
DeleteBatchFile:
	LXI		H,BatchFlag			;is batch active?
	MOV		A,M
	ORA		A
	RZ
	MVI		M,0				;yes, de-activate it.
	XRA		A
	CALL	DiskSelect			;select drive 0 for sure.
	LXI		D,BATCHFCB		;and delete this file.
	CALL	DeleteFile
	LDA		CDRIVE			;reset current drive.
	JMP		DiskSelect
;
;   Check to two strings at (PATTRN1) and (PATTRN2). They must be
; the same or we halt....
;
;VERIFY:
;	LXI		D,PATTRN1		;these are the serial number bytes.
;	LXI		H,PATTRN2		;ditto, but how could they be different?
;	MVI		B,6				;6 bytes each.
;VERIFY1:
;	LDAX	D
;	CMP		M
;	JNZ		HALT			;jump to halt routine.
;	INX		D
;	INX		H
;	DCR		B
;	JNZ		VERIFY1
;	RET
;
;   Print back file name with a '?' to indicate a syntax error.
;
SYNERR:
	CALL	SendEndOfLine	;end current line.
	LHLD	ErrorMsgPointer	;this points to name in error.
SYNERR1:
	MOV	A,M	;print it until a space or null is found.
	CPI	BLANK		; Space
	JZ	SYNERR2
	ORA	A
	JZ	SYNERR2
	PUSH	H
	CALL	PRINT
	POP	H
	INX	H
	JMP	SYNERR1
SYNERR2:
	MVI	A,QMARK		;add trailing '?'.
	CALL	PRINT
	CALL	SendEndOfLine
	CALL	DeleteBatchFile;delete any batch file.
	JMP	CMMND1	;and restart from console input.
;
;   Check character at (DE) for legal command input. Note that the
; zero flag is set if the character is a delimiter.
;
IsItValidCharacter:
	LDAX	D			; Grab the character
	ORA		A
	RZ					; Exit, its a Null (00)
	
	CPI		BLANK		; Is  less than 020H - controls character
	JC		SYNERR		; Yes,  Syntax error - exit CCP
	RZ					; Exit because Space is valid delimiter.
	
	CPI	EQUALS			; '='
	RZ
	CPI	USCORE			; '_'
	RZ
	CPI	PERIOD			; '.'
	RZ
	CPI	COLON			; ':'
	RZ
	CPI	SEMIC			; ';'
	RZ
	CPI	LESSTH			; '<'
	RZ
	CPI	GRTTHAN			; '>'
	RZ
	RET					; Character is legal, but not a delimiter
;
;   Get the next non-blank character from (DE).
;
NextNonBlankChar:
	LDAX	D			; get the next character
	ORA		A			; since string ends with a null.
	RZ					; we return here if its 00
	CPI		BLANK		; is it a space?
	RNZ					; No, then we have the next non-space char
	
	INX		D			; point at the next character and keep going
	JMP		NextNonBlankChar
;
;   Add (HL)=(HL)+(A)
;
AddAtoHL:
	ADD		L
	MOV		L,A
	RNC					;take care of any carry.
	INR		H
	RET
;
;   Convert the first name in (FCB).
;
ConvertFirstName:
	MVI	A,0		; set up index for first filename
;
;   Format a file name (convert * to '?', etc.). On return,
; (A)=0 is an unambigeous name was specified. Enter with (A) equal to
; the position within the fcb for the name (either 0 or 16).
;
ConvertFileName:
	LXI		H,FCBfromCCP		; point at FCB setup by CCP
	CALL	AddAtoHL			; now pointing at correct FCB
	PUSH	H					; save correct FCBfromCCP
	PUSH	H					; save correct FCBfromCCP
	XRA		A					; clear the Acc.
	STA		ChangeDriveFlag		; initialize drive change flag - no change.
	LHLD	InBuffAddress		; set (HL) as pointer into input line.
	XCHG						; put line pointer in DE for call
	CALL	NextNonBlankChar	; return the next non-blank character in A
	XCHG						; put line buffer pointer in HL for now
	SHLD	ErrorMsgPointer		; save pointer here for any error message.
	XCHG						; put line buffer pointer back in DE
	POP		H					; retreive the CCP created FCB
	LDAX	D					; get first character.
	ORA		A					; is it a null 00 ?
	JZ		CONVRT1				; Yes, this FCB is empty (no argument)
	
	SBI		040H				; 'A'-1	;might be a drive name, convert to binary.
	MOV		B,A					; and save in case its a drive specifier.
	INX		D					; get the next character 
	LDAX	D
	CPI		COLON				; is it ':'
	JZ		CONVRT2				; Yes, then we have a drive specification here
	DCX		D					; No, move pointer back to the start of the line.
CONVRT1:
	LDA		CDRIVE				; get current drive
	MOV		M,A					; put into the correst FCBfromCCP
	JMP		CONVRT3
	
CONVRT2:
	MOV		A,B					; get the saved drive number
	STA		ChangeDriveFlag		; set change in drives flag.
	MOV		M,B					; put new drive number in FCB
	INX		D					; point past drive number
;
;   Convert the basic file name.
;
CONVRT3:
	MVI		B,08H				; File name size
CONVRT4:
	CALL	ExpandName			; Expand all 8 characters in name

CONVRT7:
	CALL	IsItValidCharacter	; Do we have a delimiter ?.
	JZ		GetExtension		; Yes, process the extension
	INX		D					; No, point a the next character
	JMP		CONVRT7				; and see if its a demiliter

GetExtension:
	MVI		B,03H				; file extension size
	CPI		PERIOD				; do we have the Period '.'
;	JNZ		PADEXT				; No, Pad fill the extension
	JZ		GetExtension1		; yes, process the extension
	CALL	PadField			; No, Pad fill the extension
	JMP		ClearS1S2EX			; process the stuff after the extension
GetExtension1:
	INX		D					; get past the period
	CALL	ExpandName			; Expand all 3 characters in extension

GetExtension4:
	CALL	IsItValidCharacter	; Do we have a delimiter ?.
	JZ		ClearS1S2EX			; Yes, Clear the EX, S1 & S2
	INX		D					; No, point a the next character
	JMP		GetExtension4		; and see if its a demiliter
	
ClearS1S2EX:
	MVI		B,03H				; set count for clearing EX, S1 & S2
ClearS1S2EX1:
	INX		H					; point at location in the CCP FCB
	MVI		M,0					; initialize it
	DCR		B					; keep count
	JNZ		ClearS1S2EX1		; loop til done
	XCHG
	SHLD	InBuffAddress		; save current input line pointer.
	POP		H					; point at correct CCP FCB
;
;   Check to see if this is an ambigeous file name specification.
; Set the (A) register to non zero if it is.
;
;AFN - Ambiguous File Name
	LXI		B,11				; set name & Extension length .
AFN:
	INX		H
	MOV		A,M
	CPI		QMARK				; '?'	;any question marks?
	JNZ		AFN1
	INR		B					; increment count
AFN1:
	DCR		C
	JNZ		AFN					; loop if not done
	MOV		A,B					; B has the question mark count 
	ORA		A					; set the Z flag for calling routine
	RET
	
;
; ExpandName -	expands the name/ext to all 8/3 characters by either padding with SPACES
;				or, replaceing *'s with ?s for the remainder of the name/ext
;               Original input is in DE (InBuFF)
;				Expanded result is put in HL (FCBfromCCP)
;
ExpandName:
	CALL	IsItValidCharacter	; Legal input character ?
	JZ		PadField			; its a delimiter, skip the rest of the name/ext 
	INX		HL
	CPI		ASTRK				; '*'	;note that an '*' will fill the remaining
	JNZ		ExpandName1			; with question marks
	MVI		M,QMARK				; '?'
	JMP		ExpandName2
	
ExpandName1:
	MOV		M,A			; put character in FCB
	INX		D			; move to next character in input line buffer
ExpandName2:
	DCR		B			; decrement counter
	JNZ		ExpandName	; loop if not done with fileName
	RET					; exit when done!
	
PadField:            
	INX		H			; blank fill the remaining file name.
	MVI		M,BLANK		; store the blank
	DCR		B			; keep count
	JNZ		PadField	; loop till done
	RET					; exit when done!
		
;
;   CP/M command table. Note commands can be either 3 or 4 characters long.
;

CommandSize		EQU	04
CommandList:
	DB	'DIR '		; 0
	DB	'ERA '		; 1
	DB	'TYPE'		; 2
	DB	'SAVE'		; 3
	DB	'REN '		; 4
	DB	'USER'		; 5
	;Unknown		; 6
CommandListEnd:
CommandCount	EQU	(CommandListEnd-CommandList)/CommandSize
;
;   The following six bytes must agree with those at (PATTRN2)
; or cp/m will HALT. Why?
;
;PATTRN1:
;	DB	0,22,0,0,0,0;(* serial number bytes *).
;
;   Search the command table for a match with what has just
; been entered. If a match is found, then we jump to the
; proper section. Else jump to (UNKNOWN).
; On return, the (C) register is set to the command number
; that matched (or CommandCount+1 if no match).
;
FindDOSCommand:
	LXI		H,CommandList		; point at the CP/M Command List
	MVI		C,0					; index into CommandList
FindDOSCommand1:
	MOV		A,C
	CPI		CommandCount		; Are we still in the list?
	RNC							; no, the command is UNKNOWN, get out
	LXI		D,FCBfromCCP+1		; check this one.
	MVI		B,CommandSize		; max command Size.
FindDOSCommand2:
	LDAX	D					; get next character
	CMP		M					; do we have a match?
	JNZ		FindDOSCommand3		; if not a match, try the next command
	INX		D
	INX		H
	DCR		B					; keep count of characters matched
	JNZ		FindDOSCommand2		; loop until 4 character match
	
	LDAX	D					; allow a 3 character command to match.
	CPI		BLANK
	JNZ		FindDOSCommand4
	MOV		A,C					;s et return register for this command.
	RET
FindDOSCommand3:
	INX		H					; move pointer to the next command in the table
	DCR		B					; insures correct poisting
	JNZ		FindDOSCommand3		; keep going til you reach the next command    
FindDOSCommand4:
	INR		C					; increment the index into CommandList
	JMP		FindDOSCommand1		; try again
;
;   Set the input buffer to empty and then start the command
; processor (ccp).
;
CLEARBUF:
XRA	A
	STA	InBuffCount			;second byte is actual length.
;
;**************************************************************
;*
;*
;* C C P  -   C o n s o l e   C o m m a n d   P r o c e s s o r
;*
;
;   On entry (C) points at Current disk & user (defaultDisk 0004)
;**************************************************************
;*
COMMAND:
	LXI			SP,CCPStack				; Use dedicated stack space.
	PUSH		B						; (C) should be equal to currentDisk where:
	MOV			A,C						; (uuuudddd) where 'uuuu' is the user number
	RAR									; and 'dddd' is the drive number.
	RAR
	RAR
	RAR
	ANI			0FH						; isolate the user number.
	MOV			E,A						; and put into E for call
	CALL		GetSetCurrentUser		; to set the current user
	CALL		ResetDiskSystem			; reset the disk system.
	STA			BatchFlag				; clear batch mode flag.
	POP			B						; Current disk
	MOV			A,C						; move current disk to acc
	AN			0FH						; isolate the drive number.
	STA			CDRIVE					;	and save.
	CALL		DiskSelect					; ...and select.
	LDA			InBuffCount
	ORA			A						; anything in input buffer already?
	JNZ			CMMND2					; yes, then just process it.
;
;   Entry point to get a command line from the console.
;
CMMND1:
	LXI			SP,CCPStack			; set stack straight.
	CALL		SendEndOfLine				; start a new line on the screen.
	CALL		GetCurrentDisk		; get current drive.
	ADI			041H				; 'A' make it printable
	CALL		PRINT				; print current drive.
	MVI			A,GRTTHAN			; '>'
	CALL		PRINT				; and add prompt.
	CALL		InputLine				; get line from user.
;
;   Process command line here.
;
CMMND2:
	LXI			D,Pg0Buffer			; set up command storage
	CALL		setDMA				; set standard dma address.
	CALL		GetCurrentDisk
	STA			CDRIVE				; set current drive.
	CALL		ConvertFirstName				; convert name typed in.
	CNZ			SYNERR				; wild cards are not allowed. report error
	LDA			ChangeDriveFlag		; if a change in drives was indicated,
	ORA			A					; then treat this as an unknown command
	JNZ			UNKNOWN				; which gets executed.
	CALL		FindDOSCommand				; else search command table for a match.
;
;   Note that an unknown command returns
; with (A) pointing to the last address
; in our table which is (UNKNOWN).
;
	LXI			H,CommandVector		; now, look thru our address table for command (A).
	MOV			E,A					; set (DE) to command number.
	MVI			D,0
	DAD			D
	DAD			D					; (HL)=(CommandVector)+2*(command number).
	MOV			A,M					; now pick out this address.
	INX			H
	MOV			H,M
	MOV			L,A					; HL now has the address of the command to execute
	PCHL		;now execute it.
;
;   CP/M command address table.
;
CommandVector:
	DW	DIRECT		; 0
	DW	ERASE		; 1
	DW	TYPE		; 2
	DW	SAVE		; 3
	DW	RENAME		; 4
	DW	USER		; 5
	DW	UNKNOWN		; 6
;
;   Halt the system. Reason for this is unknown at present.
;
HALT:
	LXI	H,76F3H	;'DI HLT' instructions.
	SHLD	CBASE
	LXI	H,CBASE
	PCHL
;
;   Read error while TYPEing a file.
;
RDERROR:
	LXI	B,RDERR
	JMP	PLINE
RDERR:
	DB	'Read error',0
;
;   Required file was not located.
;

FileNotFound:
	LXI	B,NOFILE
	JMP	PLINE
NOFILE:
	DB	'No file',EndOfMessage
;
;   Decode a command of the form 'A>filename number{ filename}.
; Note that a drive specifier is not allowed on the first file
; name. On return, the number is in register (A). Any error
; causes 'filename?' to be printed and the command is aborted.
;
GetCmdNumber:
	CALL	ConvertFirstName				; convert first filename.
	LDA		ChangeDriveFlag		; do not allow a drive to be specified.
	ORA		A
	JNZ		SYNERR				; exit with a syntax error
	LXI		H,FCBfromCCP+1		; convert number now.
	LXI		B,11				;(B)=sum register, (C)=max digit count.
GetCmdNumber1:
	MOV		A,M					; get the caracter from the CCP FCB
	CPI		BLANK				; a space terminates the numeral.
	JZ		PadNumber			; skip, the rest must be blanks
	INX		H					; bump pointer
	SUI		030H  				; '0'	make binary from ascii. ZERO ????
	CPI		10					; legal digit?
	JNC		SYNERR				; exit with syntax error
	MOV		D,A					; yes, save the number in (D).
	;
	MOV		A,B					; compute (B)=(B)*10 and check for overflow.
	ANI		0E0H
	JNZ		SYNERR				; Exit with math overflow error??
	MOV		A,B
	RLC
	RLC
	RLC							;(A)=(B)*8
	ADD		B					;.......*9
	JC		SYNERR				; Exit with math overflow error??	
	ADD		B					;.......*10
	JC		SYNERR				; Exit with math overflow error??
	ADD		D					; add in new digit now.
	JC		SYNERR				; Exit with math overflow error??
	MOV		B,A					; and save result in B (subtotal)
	DCR		C					; only look at 11 digits.
	JNZ		GetCmdNumber1
	RET							; return with value in (A)
PadNumber:
	MOV		A,M					; spaces must follow (why?).
	CPI		BLANK				; is it a blank
	JNZ		SYNERR				; exit with syntax error
	INX		H					; point at next
	DCR		C
	JNZ		PadNumber			; loop till done
	MOV		A,B					; set (A)=the numeric value entered.
	RET
;
;   Move 3 bytes from (HL) to (DE). Note that there is only
; one reference to this at (A2D5h).
;
MOVE3:
	MVI	B,3
;
;   Move (B) bytes from (HL) to (DE).
;
HL2DE:
	MOV	A,M
	STAX	D
	INX	H
	INX	D
	DCR	B
	JNZ	HL2DE
	RET
;
;   Compute (HL)=(Pg0Buffer)+(A)+(C) and get the byte that's here.
;
EXTRACT:
	LXI	H,Pg0Buffer
	ADD	C
	CALL	AddAtoHL
	MOV	A,M
	RET
;
;  Check drive specified. If it means a change, then the new
; drive will be selected. In any case, the drive byte of the
; fcb will be set to null (means use current drive).
;
SelectDrive:
	XRA		A					; clear the Acc
	STA		FCBfromCCP			; null out first byte of fcb. ie make it the default drive.
	LDA		ChangeDriveFlag		; is a drive change indicated?
	ORA		A
	RZ							; No, drive OK
	DCR		A					; yes, is it the same as the current drive?
	LXI		H,CDRIVE
	CMP		M					; FCB drive number same as this?
	RZ							; Yes, return 					
	JMP		DiskSelect			;	no. Select it then.
;
;   Check the drive selection and reset it to the previous
; drive if it was changed for the preceeding command.
;
RESETDR:
	LDA	ChangeDriveFlag	;drive change indicated?
	ORA	A
	RZ
	DCR	A	;yes, was it a different drive?
	LXI	H,CDRIVE
	CMP	M
	RZ
	LDA	CDRIVE	;yes, re-select our old drive.
	JMP	DiskSelect
;
;**************************************************************
;*
;*           D I R E C T O R Y   C O M M A N D
;*
;**************************************************************
;
DIRECT:
	CALL	ConvertFirstName	; convert file name.
	CALL	SelectDrive			; select indicated drive.
	LXI		H,FCBfromCCP + 1	; was any file indicated?
	MOV		A,M
	CPI		BLANK
	JNZ		DIRECT2				; Skip if yes
	
	MVI		B,11				; no. Fill field with '?' - same as *.*.
DIRECT1:
	MVI		M,QMARK				; '?'
	INX		H
	DCR		B
	JNZ		DIRECT1				; stay at it util all 11 bytes are filled with "?"s
	
DIRECT2:
	MVI		E,0					; set initial file name position.
	PUSH	D					; save file name position. (e)
	CALL	SRCHFCB				; get first file name.
	CZ		FileNotFound		; none file found at all?
DIRECT3:
	JZ		DIRECT9				; terminate if no more names.
	LDA		RTNCODE				; get file's position in segment (0-3).
	RRC
	RRC
	RRC
	ANI		60H					;(A)=position*32 ie correct FCB
	MOV		C,A
	MVI		A,10
	CALL	EXTRACT				; get T2 , because it has system file flag
	RAL							; Rotate the flag (msb) to the carry
	JC		DIRECT8				; we don't list it if it is System aka hidden.
	POP		D					; get saved file name position.
	MOV		A,E					;  put in Acc
	INR		E					; increment the file name position
	PUSH	D					; and save it for later
	ANI		03H					; at end of line?
	PUSH	PSW					; save current name position
	JNZ		DIRECT4
	CALL	SendEndOfLine		; yes, end this line and start another.
	PUSH	B
	CALL	GetCurrentDisk		; start line with ('A:').
	POP		B
	ADI		041H				; convert to ascii'A'
	CALL	PRINTB				; send to console
	MVI		A,COLON				; ':'
	CALL	PRINTB				; send to console
	JMP	DIRECT5
DIRECT4:
	CALL	SpaceToConsole		; add seperator between file names.
	MVI		A, COLON			;	':'
	CALL	PRINTB
DIRECT5:
	CALL	SpaceToConsole
	MVI		B,1					; 'extract' each file name character at a time.
DIRECT6:
	MOV		A,B
	CALL	EXTRACT
	ANI		7FH					; strip bit 7 (status bit).
	CPI		BLANK				; are we at the end of the name?
	JNZ		DRECT65
	POP	PSW	;yes, don't print spaces at the end of a line.
	PUSH	PSW
	CPI	3
	JNZ	DRECT63
	MVI	A,9	;first check for no extension.
	CALL	EXTRACT
	ANI	7FH
	CPI	BLANK
	JZ	DIRECT7	;don't print spaces.
DRECT63:
	MVI	A,BLANK	;else print them.
DRECT65:
	CALL	PRINTB
	INR		B				; bump to next character psoition.
	MOV		A,B
	CPI		12				; end of the name?
	JNC		DIRECT7			; yes , we are done with this one
	CPI		9				; nope, starting extension?
	CZ		SpaceToConsole	; yes, add seperating space.
	JMP		DIRECT6
	
DIRECT7:
	POP		PSW				; get the next file name.
DIRECT8:
	CALL	CHKCON	;first check console, quit on anything.
	JNZ	DIRECT9
	CALL	SearchForNext	;get next name.
	JMP	DIRECT3	;and continue with our list.
DIRECT9:
	POP	D	;restore the stack and return to command level.
	JMP	GETBACK
;
;**************************************************************
;*
;*                E R A S E   C O M M A N D
;*
;**************************************************************
;
ERASE:
	CALL	ConvertFirstName	;convert file name.
	CPI	11	;was '*.*' entered?
	JNZ	ERASE1
	LXI	B,YESNO	;yes, ask for confirmation.
	CALL	PLINE
	CALL	InputLine
	LXI	H,InBuffCount
	DCR	M	;must be exactly 'y'.
	JNZ	CMMND1
	INX	H
	MOV	A,M
	CPI	059H	; 'Y'
	JNZ	CMMND1
	INX	H
	SHLD	InBuffAddress	;save input line pointer.
ERASE1:
	CALL	SelectDrive	;select desired disk.
	LXI	D,FCBfromCCP
	CALL	DeleteFile	;delete the file.
	INR	A
	CZ	FileNotFound	;not there?
	JMP	GETBACK	;return to command level now.
YESNO:
	DB	'All (y/n)?',0
;
;**************************************************************
;*
;*            T Y P E   C O M M A N D
;*
;**************************************************************
;
TYPE:
	CALL	ConvertFirstName	;convert file name.
	JNZ	SYNERR	;wild cards not allowed.
	CALL	SelectDrive	;select indicated drive.
	CALL	OPENFCB	;open the file.
	JZ	TYPE5	;not there?
	CALL	SendEndOfLine	;ok, start a new line on the screen.
	LXI	H,NBYTES;initialize byte counter.
	MVI	M,0FFH	;set to read first sector.
TYPE1:
	LXI	H,NBYTES
TYPE2:
	MOV	A,M	;have we written the entire sector?
	CPI	LogicalSecSize
	JC	TYPE3
	PUSH	H	;yes, read in the next one.
	CALL	READFCB
	POP	H
	JNZ	TYPE4	;end or error?
	XRA	A	;ok, clear byte counter.
	MOV	M,A
TYPE3:
	INR	M	;count this byte.
	LXI	H,Pg0Buffer	;and get the (A)th one from the buffer (Pg0Buffer).
	CALL	AddAtoHL
	MOV	A,M
	CPI	CNTRLZ	;end of file mark?
	JZ	GETBACK
	CALL	PRINT	;no, print it.
	CALL	CHKCON	;check console, quit if anything ready.
	JNZ	GETBACK
	JMP	TYPE1
;
;   Get here on an end of file or read error.
;
TYPE4:
	DCR	A	;read error?
	JZ	GETBACK
	CALL	RDERROR	;yes, print message.
TYPE5:
	CALL	RESETDR	;and reset proper drive
	JMP	SYNERR	;now print file name with problem.
;
;**************************************************************
;*
;*            S A V E   C O M M A N D
;*
;**************************************************************
;
SAVE:
	CALL	GetCmdNumber		; get numeric number that follows SAVE.
	PUSH	PSW					; save number of pages to write.
	CALL	ConvertFirstName	; convert file name linepointer past the number.
	JNZ		SYNERR				; exit with syntax error -wild cards not allowed.
	CALL	SelectDrive			; select specified drive.
	LXI		D,FCBfromCCP		; now delete this file.
	PUSH	D					; save the fcb
	CALL	DeleteFile
	POP		D
	CALL	CREATE				; and create it again.
	JZ		SAVE3				; can't create?
	XRA		A					; clear record number byte.
	STA		FCBfromCCP+32
	POP		PSW					; convert pages to sectors.
	MOV		L,A
	MVI		H,0
	DAD		H					;(HL)=number of sectors to write.
	LXI		D,TBASE				; and we start from here.
SAVE1:
	MOV		A,H			;done yet?
	ORA		L
	JZ		SAVE2
	DCX		H			;nope, count this and compute the start
	PUSH	H			;of the next 128 byte sector.
	LXI		H,LogicalSecSize
	DAD		D
	PUSH	H			;save it and set the transfer address.
	CALL	setDMA
	LXI		D,FCBfromCCP	;write out this sector now.
	CALL	WRTREC
	POP		D			;reset (DE) to the start of the last sector.
	POP		H			;restore sector count.
	JNZ		SAVE3		;write error?
	JMP		SAVE1
;
;   Get here after writing all of the file.
;
SAVE2:
	LXI		D,FCBfromCCP	;now close the file.
	CALL	CLOSE
	INR		A			;did it close ok?
	JNZ		SAVE4
;
;   Print out error message (no space).
;
SAVE3:
	LXI		B,NOSPACE
	CALL	PLINE
SAVE4:
	CALL	STDDMA		;reset the standard dma address.
	JMP		GETBACK
NOSPACE:
	DB	'No space',0
;
;**************************************************************
;*
;*           R E N A M E   C O M M A N D
;*
;**************************************************************
;
RENAME:
	CALL	ConvertFirstName	;convert first file name.
	JNZ	SYNERR	;wild cards not allowed.
	LDA	ChangeDriveFlag	;remember any change in drives specified.
	PUSH	PSW
	CALL	SelectDrive	;and select this drive.
	CALL	SRCHFCB	;is this file present?
	JNZ	RENAME6	;yes, print error message.
	LXI	H,FCBfromCCP;yes, move this name into second slot.
	LXI	D,FCBfromCCP+16
	MVI	B,16
	CALL	HL2DE
	LHLD	InBuffAddress	;get input pointer.
	XCHG
	CALL	NextNonBlankChar;get next non blank character.
	CPI	EQUALS		; '='	;only allow an '=' or '_' seperator.
	JZ	RENAME1
	CPI	USCORE		; '_'
	JNZ	RENAME5
RENAME1:
	XCHG
	INX	H	;ok, skip seperator.
	SHLD	InBuffAddress	;save input line pointer.
	CALL	ConvertFirstName	;convert this second file name now.
	JNZ	RENAME5	;again, no wild cards.
	POP	PSW	;if a drive was specified, then it
	MOV	B,A	;must be the same as before.
	LXI	H,ChangeDriveFlag
	MOV	A,M
	ORA	A
	JZ	RENAME2
	CMP	B
	MOV	M,B
	JNZ	RENAME5	;they were different, error.
RENAME2:
	MOV	M,B;	reset as per the first file specification.
	XRA	A
	STA	FCBfromCCP;clear the drive byte of the fcb.
RENAME3:
	CALL	SRCHFCB	;and go look for second file.
	JZ	RENAME4	;doesn't exist?
	LXI	D,FCBfromCCP
	CALL	RENAM	;ok, rename the file.
	JMP	GETBACK
;
;   Process rename errors here.
;
RENAME4:
	CALL	FileNotFound	;file not there.
	JMP	GETBACK
RENAME5:
	CALL	RESETDR	;bad command format.
	JMP	SYNERR
RENAME6:
	LXI	B,EXISTS;destination file already exists.
	CALL	PLINE
	JMP	GETBACK
EXISTS:
	DB	'File exists',0
;
;**************************************************************
;*
;*             U S E R   C O M M A N D
;*
;**************************************************************
;
USER:
	CALL	GetCmdNumber	;get numeric value following command.
	CPI	16	;legal user number?
	JNC	SYNERR
	MOV	E,A	;yes but is there anything else?
	LDA	FCBfromCCP+1
	CPI	BLANK
	JZ	SYNERR	;yes, that is not allowed.
	CALL	GetSetCurrentUser;ok, set user code.
	JMP	GETBACK1
;
;**************************************************************
;*
;*        T R A N S I A N T   P R O G R A M   C O M M A N D
;*
;**************************************************************
;
UNKNOWN:
;e68b	CALL	VERIFY	;check for valid system (why?).
	LDA		FCBfromCCP+1		; anything to execute?
	CPI		BLANK				; is it a Space?
	JNZ		UNKWN1
	LDA		ChangeDriveFlag		; No, only a drive change?
	ORA		A					; Is itEmpty (00)
	JZ		GETBACK1			; Yes, get otta here?
	DCR		A
	STA		CDRIVE				; ok, store new drive.
	CALL	MOVECD				; set (TDRIVE) also.
	CALL	DiskSelect			; and select this drive.
	JMP		GETBACK1			; then return.
;
;   Here a file name was typed. Prepare to execute it.
;
UNKWN1:
	LXI	D,FCBfromCCP+9	;an extension specified?
	LDAX	D
	CPI	BLANK
	JNZ	SYNERR	;yes, not allowed.
UNKWN2:
	PUSH	D
	CALL	SelectDrive	;select specified drive.
	POP	D
	LXI	H,COMFILE	;set the extension to 'COM'.
	CALL	MOVE3
	CALL	OPENFCB	;and open this file.
	JZ	UNKWN9	;not present?
;
;   Load in the program.
;
	LXI	H,TBASE	;store the program starting here.
UNKWN3:
	PUSH	H
	XCHG
	CALL	setDMA	;set transfer address.
	LXI	D,FCBfromCCP;and read the next record.
	CALL	RDREC
	JNZ	UNKWN4	;end of file or read error?
	POP	H	;nope, bump pointer for next sector.
	LXI	D,LogicalSecSize
	DAD	D
	LXI	D,CBASE	;enough room for the whole file?
	MOV	A,L
	SUB	E
	MOV	A,H
	SBB	D
	JNC	UNKWN0	;no, it can't fit.
	JMP	UNKWN3
;
;   Get here after finished reading.
;
UNKWN4:
	POP	H
	DCR	A	;normal end of file?
	JNZ	UNKWN0
	CALL	RESETDR	;yes, reset previous drive.
	CALL	ConvertFirstName	;convert the first file name that follows
	LXI	H,ChangeDriveFlag;command name.
	PUSH	H
	MOV	A,M	;set drive code in default fcb.
	STA	FCBfromCCP
	MVI	A,16	;put second name 16 bytes later.
	CALL	ConvertFileName	;convert second file name.
	POP	H
	MOV	A,M	;and set the drive for this second file.
	STA	FCBfromCCP+16
	XRA	A	;clear record byte in fcb.
	STA	FCBfromCCP+32
	LXI	D,DefaultFCB	;move it into place at(005Ch).
	LXI	H,FCBfromCCP
	MVI	B,33
	CALL	HL2DE
	LXI	H,InBuff			;now move the remainder of the input
UNKWN5:
	MOV	A,M	;line down to (0080h). Look for a non blank.
	ORA	A	;or a null.
	JZ	UNKWN6
	CPI	BLANK
	JZ	UNKWN6
	INX	H
	JMP	UNKWN5
;
;   Do the line move now. It ends in a null byte.
;
UNKWN6:
	MVI	B,0	;keep a character count.
	LXI	D,Pg0Buffer+1;data gets put here.
UNKWN7:
	MOV	A,M	;move it now.
	STAX	D
	ORA	A
	JZ	UNKWN8
	INR	B
	INX	H
	INX	D
	JMP	UNKWN7
UNKWN8:
	MOV	A,B	;now store the character count.
	STA	Pg0Buffer
	CALL	SendEndOfLine	;clean up the screen.
	CALL	STDDMA	;set standard transfer address.
	CALL	SetCurrentDrive	;reset current drive.
	CALL	TBASE	;and execute the program.
;
;   Transiant programs return here (or reboot).
;
	LXI	SP,BatchFlag	;set stack first off.
	CALL	MOVECD	;move current drive into place (TDRIVE).
	CALL	DiskSelect	;and reselect it.
	JMP	CMMND1	;back to comand mode.
;
;   Get here if some error occured.
;
UNKWN9:
	CALL	RESETDR	;inproper format.
	JMP	SYNERR
UNKWN0:
	LXI	B,BADLOAD;read error or won't fit.
	CALL	PLINE
	JMP	GETBACK
BADLOAD:
	DB	'Bad load',EndOfMessage
COMFILE:
	DB	'COM'	;command file extension.
;
;   Get here to return to command level. We will reset the
; previous active drive and then either return to command
; level directly or print error message and then return.
;
GETBACK:
	CALL	RESETDR	;reset previous drive.
GETBACK1:
	CALL	ConvertFirstName	;convert first name in (FCB).
	LDA	FCBfromCCP+1	;if this was just a drive change request,
	SUI	BLANK	;make sure it was valid.
	LXI	H,ChangeDriveFlag
	ORA	M
	JNZ	SYNERR
	JMP	CMMND1	;ok, return to command level.
;
;   ccp stack area.
;
	DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
CCPStack	EQU	$	;end of ccp stack area.
;
;   Batch (or SUBMIT) processing information storage.
;
BatchFlag:
	DB	0	;batch mode flag (0=not active).
BATCHFCB:
DB	0,'$$$     SUB',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;
;   File control block setup by the CCP.
;
FCBfromCCP:
	DB	0,'           ',0,0,0,0,0,'           ',0,0,0,0,0
RTNCODE:
	DB	0	;status returned from bdos call.
CDRIVE:
	DB	0	;currently active drive.
ChangeDriveFlag:
	DB	0	;change in drives flag (0=no change).
NBYTES:
	DW	0	;byte counter used by TYPE.
;
;   Room for expansion?
;
	DB	0,0,0,0,0,0,0,0,0,0,0,0,0
;
;   Note that the following six bytes must match those at
; (PATTRN1) or cp/m will HALT. Why?
;
;PATTRN2:
;	DB	0,22,0,0,0,0;(* serial number bytes *).
;
;**************************************************************
;*
;*                    B D O S   E N T R Y
;*
;**************************************************************
;
;   Entry into bdos.
;			Parameters: (DE) or (E) are the parameters passed. The
;						(C) - function number
;	The user's stack is saved (UserStack) 
;	BDOS uses its own stack  (BDOSstack)
;	The Function number is checked
;	The corect routine is calcualted using the functionTable and (C)
;
	ORG  0E806H					; forces - see start of bios fix later
BDOSEntry:
;	JMP	BDOSSetup
;BDOSSetup:
	XCHG						; Swap  (DE) and (HL). **23**
	SHLD	ParamsDE			; Save (DE)
	XCHG						; Restore (DE) and (HL) to original values
	MOV		A,E	
	STA		ParamE				; Save register (E) in particular.
	LXI		H,0
	SHLD	StatusBDOSReturn	; clear return status.
	DAD		SP
	SHLD	UserStack			; save users stack pointer.
	LXI		SP,BDOSstack		; and set our own.
	XRA		A					; clear A for flags resets
	STA		fcbDisk				; clear auto select storage Flag
	STA		reselectionFlag		; clear reselection Flag
	LXI		H,BDOSExit			; get return address to BDOSExit routine
	PUSH	H					; put it on the stack
	MOV		A,C					; get function number and put into A.
	CPI		functionCount + 1	; valid function number?
	RNC							; Exit if not valid
	MOV		C,E					; keep single register function value in C.
	LXI		H,functionTable	; now look thru the function table.
	MOV		E,A
	MVI		D,0					;(DE)=function number.
	DAD		D
	DAD		D					;(HL)=(start of table)+2*(function number).
	MOV		E,M
	INX		H
	MOV		D,M					; now (DE)=address for this function.
	LHLD	ParamsDE			; retrieve parameters.
	XCHG						;now (DE) has the original parameters.
	PCHL						;execute desired function.
;----------------------------------
ParamsDE:			DW	0	;(DE) parameters saved here on entry to BDOS.
ParamE:				DB	0	;storage for register (E) on entry to bdos.
StatusBDOSReturn:	DW	0	;status returned from bdos function.
UserStack:			DW	0	;save users stack pointer here.
;
;   Stack area for BDOS calls.
;
					DS	030H
BDOSstack	EQU	$	;end of stack area.
;----------------------------------
BDOSExit:
	LDA	reselectionFlag	;was auto select activated?
	ORA	A
	JZ	BDOSExit1
	LHLD	ParamsDE	;yes, but was a change made?
	MVI	M,0	;(* reset first byte of fcb *)
	LDA		fcbDisk		; disk named in FCB
	ORA	A
	JZ	BDOSExit1
	MOV	M,A	;yes, reset first byte properly.
	LDA	OldDrive	;and get the old drive and select it.
	STA	ParamE
	CALL	fcSelectDisk
BDOSExit1:
	LHLD		UserStack			;Get  the users stack pointer.
	SPHL		
	LHLD		StatusBDOSReturn	;get return status.
	MOV	A,L							;force version 1.4 compatability.
	MOV	B,H
	RET			;and go back to user.

	
	
;
;   BDOS function jump table.
;
;NFUNCTS	EQU	41	;number of functions in followin table.
;
functionTable:
	DW	fcSystemReset			;0		Overall system and BDOS reset
	DW	fcConsoleIn				;1		Read a byte from the console keyboard
	DW	fcConsoleOut			;2		Write a byte to the console screen
	DW	fcReaderIn				;3		Read a byte from the logical reader device
	DW	fcPunchOut				;4		Write a byte to the logical PUNCH device
	DW	fcListOut				;5		Write a byte to the logical list device
	DW	fcDirectConsoleOut		;6		Direct console I/O (no CCP-style editing)
	DW	fcGetIOByte				;7		Read the current setting of the IOBYTE
	DW	fcSetIOByte				;8		Set a new value of the IOBYTE
	DW	fcConsoleStringOut		;9		Send a "$"-terminated string to the console
	DW	fcConsoleStringIn		;10		Read a string from the console into a buffer
	DW	fcConsoleStatusIn		;11		Check if a console key is waiting to be read
diskFunctions	EQU	 ($ -functionTable)/2	
	DW	fcGetVersion			;12		Return the CP/M version number	
	DW	fcResetDiskSystem		;13		Reset disk system
	DW	fcSelectDisk			;14		Select specified logical disk drive
	DW	fcOpenFile				;15		Open specified file for reading/writing
	DW	fcCloseFile				;16		Close specified file after reading/writing
	DW	fcSearchForFirst		;17		Search file directory for first match with filename
	DW	fcSearchForNext			;18		Search file directory for next match with filename
	DW	fcDeleteFile			;19		Delete (erase) file
	DW	fcReadSequential		;20		Read the next "record" sequentially
	DW	fcWriteSequential		;21		Write the next "record" sequentially
	DW	fcCreateFile			;22		Create a new file with the specified name
	DW	fcRenameFile			;23		Rename a file to a new name
	DW	fcGetActiveDisks		;24		Indicate which logical disks are active
	DW	fcGetCurrentDisk		;25		Return the current default disk drive number
	DW	fcSetDMA				;26		Set the DMA address (read/write address)
	DW	fcGetFATtable			;27		Return the address of an allocation vector
	DW	fcSetDiskRO				;28		Set disk to Read-Only
	DW	fcGetROdisks			;29		Indicate which disks are currently Read-Only status
	DW	fcSetFileAttributes		;30		Set specified file to System or Read-Only status
	DW	fcGetDPB				;31		Return address of disk parameter block (DPB)
	DW	fcGetUser				;32		Set/Get the current user number
	DW	fcReadRandom			;33		Set/Get the current user number
	DW	fcWriteRandom			;34		Write a "record" randomly
	DW	fcGetFileSize			;35		Return logical file size (even for random files)
	DW	fcSetRecordNumber		;36		Set record number for the next random read/write
	DW	fcResetDrive			;37
	DW	fcReturn				;38		Simple Return
	DW	fcReturn				;39		Simple Return
	DW	fcWriteZeroFill			;40		Write a "record" randomly with zero fill
	
functionCount	EQU	 ($ -functionTable)/2

;
;   Bdos error table.
;
BADSCTR:	DW	ERROR1	;bad sector on read or write.
BADSLCT:	DW	ERROR2	;bad disk select.
RODISK:		DW	ERROR3	;disk is read only.
ROFILE:		DW	ERROR4	;file is read only.
;
;
;   Bdos error message section.
;
ERROR1:
	LXI	H,BADSEC	;bad sector message.
	CALL	PRTERR	;print it and get a 1 char responce.
	CPI	CNTRLC	;re-boot request (control-c)?
	JZ	0	;yes.
	RET		;no, return to retry i/o function.
;
ERROR2:
	LXI	H,BADSEL	;bad drive selected.
	JMP	ERROR5
;
ERROR3:
	LXI	H,DISKRO	;disk is read only.
	JMP	ERROR5
;
ERROR4:
	LXI	H,FILERO	;file is read only.
;
ERROR5:
	CALL	PRTERR
	JMP	0	;always reboot on these errors.
;
BDOSERR:	DB	'Bdos Err On '
BDOSDRV:	DB	' : $'
BADSEC:		DB	'Bad Sector$'
BADSEL:		DB	'Select$'
FILERO:		DB	'File '
DISKRO:		DB	'R/O$'
;
;   Print bdos error message.
;
PRTERR:
	PUSH	H	;save second message pointer.
	CALL	EndOfLineToConsole	;send (cr)(lf).
	LDA	CurrentDrive	;get Current Drive drive.
	ADI	041H	; 'A'	;make ascii.
	STA	BDOSDRV	;and put in message.
	LXI	B,BDOSERR;and print it.
	CALL	PRTMESG
	POP	B	;print second message line now.
	CALL	PRTMESG
;
;   Get an input character. We will check our 1 character
; buffer first. This may be set by the console status routine.
;
GETCHAR:
	LXI	H,CHARBUF;check character buffer.
	MOV	A,M	;anything present already?
	MVI	M,0	;...either case clear it.
	ORA	A
	RNZ		;yes, use it.
	JMP	biosConsoleIn	;nope, go get a character responce.
;
;   Input and echo a character.
;
GETECHO:
	CALL	GETCHAR	;input a character.
	CALL	CHKCHAR	;carriage control?
	RC		;no, a regular control char so don't echo.
	PUSH	PSW	;ok, save character now.
	MOV	C,A
	CALL	fcConsoleOut	;and echo it.
	POP	PSW	;get character and return.
	RET
;
;   Check character in (A). Set the zero flag on a carriage
; control character and the carry flag on any other control
; character.
;
CHKCHAR:
	CPI	CR	;check for carriage return, line feed, backspace,
	RZ		;or a tab.
	CPI	LF
	RZ
	CPI	TAB
	RZ
	CPI	BS
	RZ
	CPI	BLANK	;other control char? Set carry flag.
	RET
;
;   Check the console during output. Halt on a control-s, then
; reboot on a control-c. If anything else is ready, clear the
; zero flag and return (the calling routine may want to do
; something).
;
CKCONSOL:
	LDA	CHARBUF	;check buffer.
	ORA	A	;if anything, just return without checking.
	JNZ	CKCON2
	CALL	biosConsoleStatus	;nothing in buffer. Check console.
	ANI	01H	;look at bit 0.
	RZ		;return if nothing.
	CALL	biosConsoleIn	;ok, get it.
	CPI	CNTRLS	;if not control-s, return with zero cleared.
	JNZ	CKCON1
	CALL	biosConsoleIn	;halt processing until another char
	CPI	CNTRLC	;is typed. Control-c?
	JZ	0	;yes, reboot now.
	XRA	A	;no, just pretend nothing was ever ready.
	RET
CKCON1:
	STA	CHARBUF	;save character in buffer for later processing.
CKCON2:
	MVI	A,1	;set (A) to non zero to mean something is ready.
	RET
;
;   Output (C) to the screen. If the printer flip-flop flag
; is set, we will send character to printer also. The console
; will be checked in the process.
;
OUTCHAR:
	LDA	OutPutFlag	;check output flag.
	ORA	A	;anything and we won't generate output.
	JNZ	OUTCHR1
	PUSH	B
	CALL	CKCONSOL;check console (we don't care whats there).
	POP	B
	PUSH	B
	CALL	biosConsoleOut	;output (C) to the screen.
	POP	B
	PUSH	B
	LDA	PrinterFlag	;check printer flip-flop flag.
	ORA	A
	CNZ	fcListOut	;print it also if non-zero.
	POP	B
OUTCHR1:
	MOV	A,C	;update cursors position.
	LXI	H,CursorPosition
	CPI	DEL	;rubouts don't do anything here.
	RZ
	INR	M	;bump line pointer.
	CPI	BLANK	;and return if a normal character.
	RNC
	DCR	M	;restore and check for the start of the line.
	MOV	A,M
	ORA	A
	RZ		;ingnore control characters at the start of the line.
	MOV	A,C
	CPI	BS	;is it a backspace?
	JNZ	OUTCHR2
	DCR	M	;yes, backup pointer.
	RET
OUTCHR2:
	CPI	LF	;is it a line feed?
	RNZ		;ignore anything else.
	MVI	M,0	;reset pointer to start of line.
	RET
;
;   Output (A) to the screen. If it is a control character
; (other than carriage control), use ^x format.
;
DisplayAcc:
	MOV	A,C
	CALL	CHKCHAR	;check character.
	JNC	fcConsoleOut	;not a control, use normal output.
	PUSH	PSW
	MVI	C, CARET	; '^'	;for a control character, preceed it with '^'.
	CALL	OUTCHAR
	POP	PSW
	ORI	ATSIGN		; '@'	;and then use the letter equivelant.
	MOV	C,A
;
;   Function to output (C) to the console device and expand tabs
; if necessary.
;
fcConsoleOut:
	MOV	A,C
	CPI	TAB	;is it a tab?
	JNZ	OUTCHAR	;use regular output.
fcConsoleOut1:
	MVI	C,BLANK	;yes it is, use spaces instead.
	CALL	OUTCHAR
	LDA	CursorPosition	;go until the cursor is at a multiple of 8

	ANI	07H	;position.
	JNZ	fcConsoleOut1
	RET
;
;   Echo a backspace character. Erase the prevoius character
; on the screen.
;
BackUp:
	CALL	BackUp1	;backup the screen 1 place.
	MVI	C,BLANK	;then blank that character.
	CALL	biosConsoleOut
BackUp1:
	MVI	C,BS	;then back space once more.
	JMP	biosConsoleOut
;
;   Signal a deleted line. Print a '#' at the end and start
; over.
;
NEWLINE:
	MVI	C, POUNDSN		; '#'
	CALL	OUTCHAR	;print this.
	CALL	EndOfLineToConsole	;start new line.
NEWLN1:
	LDA	CursorPosition	;move the cursor to the starting position.
	LXI	H,CursorPositionStart
	CMP	M
	RNC		;there yet?
	MVI	C,BLANK
	CALL	OUTCHAR	;nope, keep going.
	JMP	NEWLN1
;
;   Output a (cr) (lf) to the console device (screen).
;
EndOfLineToConsole:
	MVI	C,CR
	CALL	OUTCHAR
	MVI	C,LF
	JMP	OUTCHAR
;
;   Print message pointed to by (BC). It will end with a '$'.
;
PRTMESG:
	LDAX	B	;check for terminating character.
	CPI	DOLLAR		; '$'
	RZ
	INX	B
	PUSH	B	;otherwise, bump pointer and print it.
	MOV	C,A
	CALL	fcConsoleOut
	POP	B
	JMP	PRTMESG
;
;   Function to execute a buffered read.
;
fcConsoleStringIn:
	LDA		CursorPosition		;use present location as starting one.
	STA		CursorPositionStart
	LHLD	ParamsDE			; get the pointer to maximum buffer space.
	MOV		C,M					; load size in C
	INX		H					; point to first available space.
	PUSH	H					; and save.
	MVI		B,0					; keep a character count.
RDBUF1:
	PUSH	B					; save the buffer size (C) and character count (B)
	PUSH	H					; save buffer position 
RDBUF2:
	CALL	GETCHAR				; get the next input character.
	ANI		7FH					; strip bit 7. - only want 7-bit ascii
	POP		H					; get the buffer position
	POP		B					; save the buffer size (C) and character count (B)
	CPI		CR					; end of the line?
	JZ		RDBUF17				; Yes - then were are done
	CPI		LF
	JZ		RDBUF17				; same goes for Carriage Return
	
	CPI		BS					; how about a backspace?
	JNZ		RDBUF3				; if not skip the following
								; backSpace
	MOV		A,B					; ignore at the beginning of the line.
	ORA		A
	JZ		RDBUF1				; go back if at start of the line
	
	DCR		B					; ok, update counter.
	LDA		CursorPosition		; if we backspace to the start of the line,
	STA		OutPutFlag			; treat as a cancel (control-x).
	JMP		RDBUF10
	
RDBUF3:
	CPI		DEL					; user typed a rubout?
	JNZ		RDBUF4				; no? - skip the following
	MOV		A,B					; at the start of the line?.
	ORA		A
	JZ		RDBUF1				; ignore at the start of the line.
	
	MOV		A,M					; ok, echo the prevoius character.
	DCR		B					; and reset pointers (counters).
	DCX		H
	JMP		RDBUF15
	
RDBUF4:
	CPI		CNTRLE				; physical end of line?
	JNZ		RDBUF5				; yes, skip the following
	PUSH	B					; save the buffer size (C) and character count (B)
	PUSH	H					; save buffer position 
	CALL	EndOfLineToConsole				; send a crlf to the console
	XRA		A					; and update starting position.
	STA		CursorPositionStart
	JMP		RDBUF2				; aqnd keep on trucking
	
RDBUF5:
	CPI		CNTRLP				; control-p? Print flag toggle
	JNZ		RDBUF6				; if not skip the following
	PUSH	H					; yes, flip the print flag filp-flop byte.
	LXI		H,PrinterFlag
	MVI		A,1					; PrinterFlag=1-PrinterFlag
	SUB		M
	MOV		M,A
	POP		H					; get the buffer position
	JMP		RDBUF1				; nothing to put into buffer go back for more
	
RDBUF6:
	CPI		CNTRLX				; control-x (cancel)?
	JNZ		RDBUF8				; no? skip the following
	POP		H					; get the buffer position
RDBUF7:
	LDA		CursorPositionStart ; yes, backup the cursor to here.
	LXI		H,CursorPosition
	CMP		M					; done yet?
	JNC		fcConsoleStringIn	; yes - go back to the start of reading a line of input
	DCR		M					; no, decrement pointer and output back up one space.
	CALL	BackUp				; do the backup
	JMP		RDBUF7				; keep doing until done
	
RDBUF8:
	CPI		CNTRLU				; cntrol-u (cancel line)?
	JNZ		RDBUF9
	CALL	NEWLINE				; start a new line.
	POP		H					; get the buffer position
	JMP		fcConsoleStringIn	; go back to the start of reading a line of input
	
RDBUF9:
	CPI		CNTRLR				; control-r?
	JNZ		RDBUF14
RDBUF10:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUSH	B					; save the buffer size (C) and character count (B)
	CALL	NEWLINE
	POP		H					; get the buffer position
	POP		B					; save the buffer size (C) and character count (B)
	PUSH	B					; save the buffer size (C) and character count (B)
	PUSH	H					; save buffer position 
RDBUF11:
	MOV	A,B	;done whole line yet?
	ORA	A
	JZ	RDBUF12
	INX	H	;nope, get next character.
	MOV	C,M
	DCR	B	;count it.
	PUSH	B					; save the buffer size (C) and character count (B)
	PUSH	H					; save buffer position 
	CALL	DisplayAcc	;and display it.
	POP		H					; get the buffer position
	POP		B					; save the buffer size (C) and character count (B)
	JMP	RDBUF11
RDBUF12:
	PUSH	H					; save buffer position 
	LDA	OutPutFlag	;then update cursor position.
	ORA	A
	JZ	RDBUF2
	LXI	H,CursorPosition;because this line is shorter, we must
	SUB	M	;back up the cursor (not the screen however)
	STA	OutPutFlag	;some number of positions.
RDBUF13:
	CALL	BackUp	;note that as long as (OutPutFlag) is non
	LXI	H,OutPutFlag;zero, the screen will not be changed.
	DCR	M
	JNZ	RDBUF13
	JMP	RDBUF2	;now just get the next character.
;
;   Just a normal character, put this in our buffer and echo.
;
RDBUF14:
	INX		H
	MOV		M,A				; store character.
	INR		B				; and count it.
RDBUF15:
	PUSH	B				; save the buffer size (C) and character count (B)
	PUSH	H				; save buffer position 
	MOV		C,A				;echo it now.
	CALL	DisplayAcc		; put it out to the console
	POP		H				; get the buffer position
	POP		B				; save the buffer size (C) and character count (B)
	MOV		A,M				; was it an abort request?
	CPI		CNTRLC			; control-c abort?
	MOV		A,B				; get character count to Acc
	JNZ		RDBUF16
	CPI		1				; only if at start of line.
	JZ		0				; do we do a reboot
RDBUF16:
	CMP		C				; have we filled the buffer?
	JC		RDBUF1			; no- go back for more		
RDBUF17:
	POP		H				; yes end the line and return.
	MOV		M,B
	MVI		C,CR
	JMP		OUTCHAR	;output (cr) and return.
;
;   Function to get a character from the console device.
;
fcConsoleIn:
	CALL	GETECHO	;get and echo.
	JMP	SetStatusBDOS	;save status and return.
;
;   Function to get a character from the tape reader device.
;
fcReaderIn:
	CALL	biosReaderIn	;get a character from reader, set status and return.
	JMP	SetStatusBDOS
;
;  Function to perform direct console i/o. If (C) contains (FF)
; then this is an input request. If (C) contains (FE) then
; this is a status request. Otherwise we are to output (C).
;
fcDirectConsoleOut:
	MOV	A,C	;test for (FF).
	INR	A
	JZ	DIRC1
	INR	A	;test for (FE).
	JZ	biosConsoleStatus
	JMP	biosConsoleOut	;just output (C).
DIRC1:
	CALL	biosConsoleStatus	;this is an input request.
	ORA	A
	JZ	BDOSExit1	;not ready? Just return (directly).
	CALL	biosConsoleIn	;yes, get character.
	JMP	SetStatusBDOS	;set status and return.
;
;   Function to return the i/o byte.
;
fcGetIOByte:
	LDA	IOBYTE
	JMP	SetStatusBDOS
;
;   Function to set the i/o byte.
;
fcSetIOByte:
	LXI	H,IOBYTE
	MOV	M,C
	RET
;
;   Function to print the character string pointed to by (DE)
; on the console device. The string ends with a '$'.
;
fcConsoleStringOut:
	XCHG
	MOV	C,L
	MOV	B,H	;now (BC) points to it.
	JMP	PRTMESG
;
;   Function to interigate the console device.
;
fcConsoleStatusIn:
	CALL	CKCONSOL
;
;   Get here to set the status and return to the cleanup
; section. Then back to the user.
;
SetStatusBDOS:
	STA		StatusBDOSReturn
fcReturn:
	RET
;
;   Set the status to 1 (read or write error code).
;
IOERR1:
	MVI	A,1
	JMP	SetStatusBDOS
;
OutPutFlag:	DB	0	;output flag (non zero means no output).
CursorPositionStart:	DB	2	;starting position for cursor.
CursorPosition:		DB	0	;cursor position (0=start of line).
PrinterFlag:	DB	0	;printer flag (control-p toggle). List if non zero.
CHARBUF:	DB	0	;single input character buffer.
;
;   Stack area for BDOS calls.
;

;
;	DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;	DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;BDOSstack	EQU	$	;end of stack area.
;
;
;   Select error occured, jump to error routine.
;
SLCTERR:
	LXI		H,BADSLCT
;
;   Jump to (HL) indirectly.
;
JumpToHL:
	MOV		E,M
	INX		H
	MOV		D,M			;now (DE) contain the desired address.
	XCHG
	PCHL
;
;   Block move. (DE) to (HL), (C) bytes total.
;
DEtoHL:
	INR		C			; manage counter
DEtoHL1:
	DCR		C			; decrement counter
	RZ					; Return if done
	
	LDAX	D			; move a byte.
	MOV		M,A
	INX		D
	INX		H
	JMP		DEtoHL1		;	and repeat.
;
;   Select the desired drive.
; it will set up all the disk parameters blocks 
;
SelectDisk:
	LDA		CurrentDrive		; get active disk.
	MOV		C,A					; set up for Bios call, put disk in (C)
	CALL	biosSelectDisk		; call into BIOS to select it.
	MOV		A,H					; HL = 0000 if invalid
	ORA		L					; otherwise it points to the correct Disk Parameter Block
	RZ							; so, return if HL = 0000
;
;   Here, the BIOS returned the address of the parameter block
; in (HL). We will extract the necessary pointers and save them.
;
	MOV		E,M					; first word of DPB points to the drive's skew table
	INX		H
	MOV		D,M					; Get it and put it into (DE)
	INX		H
						;save pointers to BDOS scratch areas
	SHLD	FilePosInDirSegment		; save Relative position for file		.
	INX		H
	INX		H
	SHLD	LastTrackNumber		; save last track referenced			
	INX		H
	INX		H
	SHLD	LastSectorNumber	; save last sector referenced	
	INX		H
	INX		H					; get directory buffer
	XCHG						; been holding the translation table address in DE, now in HL
								; Moved Directory buffer pointer into DE (from HL
	SHLD	XLATE				; save skew table address				
	LXI		H,DirBuffAddr			; get address of the directory buffer vector
	MVI		C,8					; they consist of the directory buffer
	CALL	DEtoHL				; pointer, parameter block pointer,check and allocation vectors.
	LHLD	DiskParamBlock				;  * DISK PARAMTER BLOCK POINTER
	XCHG						; put into DE
	LXI		H,SECTORS			; point at  Sectors per Block
	MVI		C,15				; it is 15 bytes long. 
	CALL	DEtoHL				; move disk parameter block from BIOS to BDOS for current disk
	LHLD	DiskSize			; check disk size.
	MOV		A,H					; more than 256 blocks on this?
	LXI		H,SmallDisk			; should be called SmallDisk [ if SmallDisk =0 then > 256 block long])
	MVI		M,0FFH				; set to small.
	ORA		A
	JZ		SelectDisk1
	MVI		M,0					; wrong, set to large.
SelectDisk1:
	MVI		A,0FFH				; clear the zero flag.
	ORA		A
	RET
;
;   Routine to home the disk track head and clear pointers.
;
HomeDrive:
	CALL	biosHomeDisk			; home the head.
	XRA		A				; set accumulator to 00	
	LHLD	LastTrackNumber	; set track pointer to 00.
	MOV		M,A
	INX		H
	MOV		M,A
	LHLD	LastSectorNumber; set sector pointer to 00.
	MOV		M,A
	INX		H
	MOV		M,A
	RET
;
;   Do the actual disk read and check the error return status.
;
DOREAD:
	CALL	biosReadDisk
	JMP	IORET
;
;   Do the actual disk write and handle any bios error.
;
DOWRITE:
	CALL	biosWriteDisk
IORET:
	ORA	A
	RZ		;return unless an error occured.
	LXI	H,BADSCTR;bad read/write on this sector.
	JMP	JumpToHL
;
;   Routine to select the track and sector that the desired
; block number falls in.
;
TrackSectorForDir:
	LHLD	FilePosInDirectory		; get position of last accessed file
	MVI		C,2						; there are 4 directory entries/Sector.
	CALL	HLrightC				; file-position/4 = sector #
	SHLD	BlockNumber				; save this as the block number of interest.
	SHLD	DirectoryRecord			; (what's it doing here?)
;
;   if the sector number has already been set (BlockNumber), enter
; at this point.
;Save
TrackSectorForBlock:
		;move Desired Block number into (BC).
	LXI		H,BlockNumber
	MOV		C,M				
	INX		H
	MOV		B,M
		;move Last sector number into (DE).
	LHLD	LastSectorNumber
	MOV		E,M	
	INX		H
	MOV		D,M
		;move current track number into (HL).
	LHLD	LastTrackNumber
	MOV		A,M
	INX		H
	MOV		H,M
	MOV		L,A
	
TrackSectorForBlock1:
	MOV		A,C			;is desired sector before current one?
	SUB		E
	MOV		A,B
	SBB		D
	JNC		TrackSectorForBlock2
	PUSH	H			;yes, decrement sectors by one track.
	LHLD	SECTORS		;get sectors per track.
	MOV		A,E
	SUB		L
	MOV		E,A
	MOV		A,D
	SBB		H
	MOV		D,A			;now we have backed up one full track.
	POP		H
	DCX		H			;adjust track counter.
	JMP		TrackSectorForBlock1
TrackSectorForBlock2:
	PUSH	H			;desired sector is after current one.
	LHLD	SECTORS		;get sectors per track.
	DAD	D				;bump sector pointer to next track.
	JC		TrackSectorForBlock3
	MOV		A,C			;is desired sector now before current one?
	SUB		L
	MOV		A,B
	SBB		H
	JC		TrackSectorForBlock3
	XCHG				;not yes, increment track counter
	POP		H			;and continue until it is.
	INX		H
	JMP		TrackSectorForBlock2
;
;   here we have determined the track number that contains the
; desired sector.
;
TrackSectorForBlock3:
	POP		H			;get track number (HL).
	PUSH	B
	PUSH	D
	PUSH	H
	XCHG
	LHLD	OFFSET		;adjust for first track offset.
	DAD		D
	MOV		B,H
	MOV		C,L
	CALL	biosSetTrack		;select this track.
	POP		D			;reset current track pointer.
	LHLD	LastTrackNumber
	MOV		M,E
	INX		H
	MOV		M,D
	POP		D
	LHLD	LastSectorNumber	;reset the first sector on this track.
	MOV		M,E
	INX		H
	MOV		M,D
	POP		B
	MOV		A,C			;now subtract the desired one.
	SUB		E			;to make it relative (1-# sectors/track).
	MOV		C,A
	MOV		A,B
	SBB		D
	MOV		B,A
	LHLD	XLATE		;translate this sector according to this table.
	XCHG
	CALL	biosSectorTranslate		;let the bios translate it.
	MOV		C,L
	MOV		B,H
	JMP		biosSetSector		;and select it.
;
;   Compute block number from record number (SAVNREC) and
; extent number (SAVEXT).
;
GETBLOCK:
	LXI	H,BLKSHFT;get logical to physical conversion.
	MOV	C,M	;note that this is base 2 log of ratio.
	LDA	SAVNREC	;get record number.
GETBLK1:
	ORA	A	;compute (A)=(A)/2^BLKSHFT.
	RAR
	DCR	C
	JNZ	GETBLK1
	MOV	B,A	;save result in (B).
	MVI	A,8
	SUB	M
	MOV	C,A	;compute (C)=8-BLKSHFT.
	LDA	SAVEXT
GETBLK2:
	DCR	C	;compute (A)=SAVEXT*2^(8-BLKSHFT).
	JZ	GETBLK3
	ORA	A
	RAL
	JMP	GETBLK2
GETBLK3:
	ADD	B
	RET
;
;   Routine to extract the (BC) block byte from the fcb pointed
; to by (ParamsDE). If this is a big-disk, then these are 16 bit
; block numbers, else they are 8 bit numbers.
; Number is returned in (HL).
;
EXTBLK:
	LHLD	ParamsDE	;get fcb address.
	LXI	D,16	;block numbers start 16 bytes into fcb.
	DAD	D
	DAD	B
	LDA	SmallDisk	;are we using a big-disk?
	ORA	A
	JZ	EXTBLK1
	MOV	L,M	;no, extract an 8 bit number from the fcb.
	MVI	H,0
	RET
EXTBLK1:
	DAD	B	;yes, extract a 16 bit number.
	MOV	E,M
	INX	H
	MOV	D,M
	XCHG		;return in (HL).
	RET
;
;   Compute block number.
;
COMBLK:
	CALL	GETBLOCK
	MOV	C,A
	MVI	B,0
	CALL	EXTBLK
	SHLD	BlockNumber
	RET
;
;   Check for a zero block number (unused).
;
CHKBLK:
	LHLD	BlockNumber
	MOV	A,L	;is it zero?
	ORA	H
	RET
;
;   Adjust physical block (BlockNumber) and convert to logical
; sector (LOGSECT). This is the starting sector of this block.
; The actual sector of interest is then added to this and the
; resulting sector number is stored back in (BlockNumber). This
; will still have to be adjusted for the track number.
;
LOGICAL:
	LDA	BLKSHFT	;get log2(physical/logical sectors).
	LHLD	BlockNumber	;get physical sector desired.
LOGICL1:
	DAD	H	;compute logical sector number.
	DCR	A	;note logical sectors are 128 bytes long.
	JNZ	LOGICL1
	SHLD	LOGSECT	;save logical sector.
	LDA	BLKMASK	;get block mask.
	MOV	C,A
	LDA	SAVNREC	;get next sector to access.
	ANA	C	;extract the relative position within physical block.
	ORA	L	;and add it too logical sector.
	MOV	L,A
	SHLD	BlockNumber	;and store.
	RET
;
;   Set (HL) to point to extent byte in fcb.
;
SETEXT:
	LHLD	ParamsDE
	LXI	D,12	;it is the twelth byte.
	DAD	D
	RET
;
;   Set (HL) to point to record count byte in fcb and (DE) to
; next record number byte.
;
SETHLDE:
	LHLD	ParamsDE
	LXI	D,15	;record count byte (#15).
	DAD	D
	XCHG
	LXI	H,17	;next record number (#32).
	DAD	D
	RET
;
;   Save current file data from fcb.
;
STRDATA:
	CALL	SETHLDE
	MOV	A,M	;get and store record count byte.
	STA	SAVNREC
	XCHG
	MOV	A,M	;get and store next record number byte.
	STA	SAVNXT
	CALL	SETEXT	;point to extent byte.
	LDA	EXTMASK	;get extent mask.
	ANA	M
	STA	SAVEXT	;and save extent here.
	RET
;
;   Set the next record to access. If (MODE) is set to 2, then
; the last record byte (SAVNREC) has the correct number to access.
; For sequential access, (MODE) will be equal to 1.
;
SETNREC:
	CALL	SETHLDE
	LDA	MODE	;get sequential flag (=1).
	CPI	2	;a 2 indicates that no adder is needed.
	JNZ	STNREC1
	XRA	A	;clear adder (random access?).
STNREC1:
	MOV	C,A
	LDA	SAVNREC	;get last record number.
	ADD	C	;increment record count.
	MOV	M,A	;and set fcb's next record byte.
	XCHG
	LDA	SAVNXT	;get next record byte from storage.
	MOV	M,A	;and put this into fcb as number of records used.
	RET
;
;   Shift HL right (C) bits.
;
HLrightC:
	INR		C			; minor adjustment
HLrightC1:
	DCR		C			; count down
	RZ					; exit if done
	MOV		A,H			; get the hi byte
	ORA		A			; reset carry bit
	RAR					; rotate right thru carry
	MOV		H,A			; return new hi byte
	MOV		A,L			; get lo byte
	RAR					; rotate right thru carry
	MOV		L,A			; return new lo byte
	JMP		HLrightC1		; keep doing it
;
;	Compute the check-sum for the directory buffer.
;	Return integer sum in (A).
;   add all values in the buffer ignoring carrys
;
CheckSum:
	MVI		C,DirBuffSize		; length of buffer.
	LHLD	DirBuffAddr			; get its address.
	XRA		A					; clear summation byte.
CheckSum1:
	ADD		M					; compute running sum ignoring carries.
	INX		H
	DCR		C
	JNZ		CheckSum1			; keep adding until all bytes have been added
	RET

;
;   Extract the write protect status bit for the current drive.
; 	The result is returned in (A), bit 0.
;
GetDiskROStatus:
	LHLD	ROBitMap			;get Read Only Bit Map
	LDA		CurrentDrive		;which drive is current?
	MOV		C,A
	CALL	HLrightC			;shift status such that bit 0 is the
	MOV		A,L					;one of interest for this drive.
	ANI		01H					;and isolate it.
	RET							; Zero if not write protected
;
;   Function to write protect the current disk.
;
fcSetDiskRO:
	LXI	H,ROBitMap	;point to Read Only Bit Map
	MOV	C,M	;set (BC) equal to the status.
	INX	H
	MOV	B,M
	CALL	SetBit	;and set this bit according to current drive.
	SHLD	ROBitMap	;then save.
	LHLD	DrectorySize	;now save directory size limit.
	INX	H	;remember the last one.
	XCHG
	LHLD	FilePosInDirSegment;and store it here.
	MOV	M,E	;put low byte.
	INX	H
	MOV	M,D	;then high byte.
	RET
;
;   Check for a read only file.
;
CHKROFL:
	CALL	FCB2HL	;set (HL) to file entry in directory buffer.
CKROF1:
	LXI	D,9	;look at bit 7 of the ninth byte.
	DAD	D
	MOV	A,M
	RAL
	RNC		;return if ok.
	LXI	H,ROFILE;else, print error message and terminate.
	JMP	JumpToHL
;
;   Check the write protect status of the active disk.
;
IsDiskRO:
	CALL	GetDiskROStatus			; is it write protected ?
	RZ						; NO, return.
	LXI		H,RODISK
	JMP	JumpToHL		; else print message and terminate.
;
;   Routine to set (HL) pointing to the proper entry in the
; directory buffer.
;
FCB2HL:
	LHLD	DirBuffAddr		;get address of buffer.
	LDA		FCBPosition		;relative position of file.
;
;   Routine to add (A) to (HL).
;
ADDA2HL:
	ADD		L
	MOV		L,A
	RNC	
	INR		H			;take care of any carry.
	RET
;
;   Routine to get the 's2' byte(Extent Count) from the fcb supplied in
; the initial parameter specification.
;
GetS2:
	LHLD	ParamsDE	;get address of fcb.
	LXI		D,14		;relative position of 's2'.
	DAD		D
	MOV		A,M			;extract this byte.
	RET
;
;   Clear the 's2' byte in the fcb.
;
ClearS2:
	CALL	GetS2		;this sets (HL) pointing to it.
	MVI		M,0			;now clear it.
	RET
;
;   Set bit 7 in the 's2' byte of the fcb.
;
SetBit7InS2:
	CALL	GetS2		;get the byte.
	ORI		80H			;and set bit 7.
	MOV		M,A			;then store.
	RET
;
;   Compare (FilePosInDirectory) with (FilePosInDirSegment) and set flags based on
; the difference. This checks to see if there are more file
; names in the directory. We are at (FilePosInDirectory) and there are
; (FilePosInDirSegment) of them to check.
;
AnyMoreFiles:
	LHLD	FilePosInDirectory			;we are here.
	XCHG
	LHLD	FilePosInDirSegment	;and don't go past here.
	MOV		A,E				;compute difference but don't keep.
	SUB		M
	INX		H
	MOV		A,D
	SBB		M				;set carry if no more names.
	RET
;
;   Call this routine to prevent (FilePosInDirSegment) from being greater
; than (FilePosInDirectory).
;
CHKNMBR:
	CALL	AnyMoreFiles		;FilePosInDirSegment too big?
	RC
	INX		D		;yes, reset it to (FilePosInDirectory).
	MOV		M,D
	DCX		H
	MOV		M,E
	RET
;
;   Compute (HL)=(DE)-(HL)
;
DEminusHL2HL:
	MOV		A,E		;compute difference.
	SUB		L
	MOV		L,A		;store low byte.
	MOV		A,D
	SBB		H
	MOV		H,A		;and then high byte.
	RET
;
;   Set the directory checksum byte.
;
SETDIR:
	MVI	C,0FFH
;
;   Routine to set or compare the directory checksum byte. If
; (C)=0ffh, then this will set the checksum byte. Else the byte
; will be checked. If the check fails (the disk has been changed),
; then this disk will be write protected.
;
CHECKDIR:
	LHLD	CheckSumTable
	XCHG
	LHLD	DirectoryFAT1
	CALL	DEminusHL2HL
	RNC								; ok if (CheckSumTable) > (DirectoryFAT1), so return.
	PUSH	B						; save set/check flag (c)
	CALL	CheckSum				;else compute checksum.
	LHLD	CHKVECT	;get address of checksum table.
	XCHG
	LHLD	CheckSumTable
	DAD	D	;set (HL) to point to byte for this drive.
	POP	B
	INR	C	;set or check ?
	JZ	CHKDIR1
	CMP	M	;check them.
	RZ		;return if they are the same.
	CALL	AnyMoreFiles	;not the same, do we care?
	RNC
	CALL	fcSetDiskRO	;yes, mark this as write protected.
	RET
CHKDIR1:
	MOV	M,A	;just set the byte.
	RET
;
;   Do a write to the directory of the current disk.
;
DIRWRITE:
	CALL	SETDIR			;set checksum byte.
	CALL	SetDirDMA		;set directory dma address.
	MVI		C,1				;tell the bios to actually write.
	CALL	DOWRITE			;then do the write.
	JMP		Set2UsersDMA
;
;   Read from the directory.
;
DIRREAD:
	CALL	SetDirDMA	;set the directory dma address.
	CALL	DOREAD	;and read it.
;
;   Routine to set the dma address to the users choice.
;
Set2UsersDMA:
	LXI		H,UsersDMA		;reset the default dma address and return.
	JMP		SetDMA0
;
;   Routine to set the dma address for directory work.
;
SetDirDMA:
	LXI		H,DirBuffAddr
;
;   Set the dma address. On entry, (HL) points to
; word containing the desired dma address.
;
SetDMA0:
	MOV		C,M
	INX		H
	MOV		B,M			;setup (BC) and go to the bios to set it.
	JMP		biosSetDMA
;
;   Move the directory buffer into user's dma space.
;
MOVEDIR:
	LHLD	DirBuffAddr	;buffer is located here, and
	XCHG
	LHLD	UsersDMA; put it here.
	MVI	C,DirBuffSize	;this is its length.
	JMP	DEtoHL	;move it now and return.
;
;   Check (FilePosInDirectory) and set the zero flag if it equals 0ffffh.
; if it is -1 then no active file found
;
CheckFilePosition:	
	LXI	H,FilePosInDirectory
	MOV	A,M
	INX	H
	CMP	M	;are both bytes the same?
	RNZ
	INR	A	;yes, but are they each 0ffh?
	RET
;
;   Set location (FilePosInDirectory) to 0ffffh.
;
InitializeFilePosition:
	LXI		H,-1
	SHLD	FilePosInDirectory
	RET
;
;   Move on to the next file position within the current
; directory buffer. If no more exist, set pointer to 0ffffh
; and the calling routine will check for this. Enter with (C)
; equal to 0ffh to cause the checksum byte to be set, else we
; will check this disk and set write protect if checksums are
; not the same (applies only if another directory sector must
; be read).
;
GetNextEntry:
	LHLD	DrectorySize				; get directory entry size limit.
	XCHG
	LHLD	FilePosInDirectory			; get index into directory.
	INX		H					
	SHLD	FilePosInDirectory			; save  the next location
	CALL	DEminusHL2HL				; (HL)=(DrectorySize)-(FilePosInDirectory)
	JC		InitializeFilePosition		; If no more entries, set this flag and exit.

	LDA		FilePosInDirectory		; Get current index for file in the  directory.
	ANI		03H						; only look within this sector (only 4 entries fit).
									; - so taking the mod of position in directory
									;  - gives us the relative position in the sector
	ADD		A						; a * 2  - each directory entry is 32 bytes long.
	ADD		A						; a * 4 - so relative position * 32 gives us the 
	ADD		A						; a * 8  - start of the directory entry for this
	ADD		A						; a * 16 - file
	ADD		A						; a * 32
						; The value in A is: 0,32,64 or 96
	STA		FCBPosition			; save it as position of fcb.
	ORA		A
	RNZ							; return If Not a New Record ?????????
	PUSH	B					; save C, checksum behavior flag
	CALL	TrackSectorForDir		;we need the next directory sector.
	CALL	DIRREAD
	POP		B
	JMP		CHECKDIR
;
;   Routine to to get a bit from the disk space allocation
; map. It is returned in (A), bit position 0. On entry to here,
; set (BC) to the block number on the disk to check.
; On return, (D) will contain the original bit position for
; this block number and (HL) will point to the address for it.
; Bit is determined by Block Number Mod 8
; Byte is determined by Block Number / 8

CKBITMAP:
	MOV		A,C			; Determine Bit  interest.
	ANI		07H			; mod 8
	INR		A			; add 1? and save
	MOV		E,A			; Save particular bit number.
	MOV		D,A			; save it again
;                     
;   compute (BC)=(BC)/8.
;   to determin in which Allocation block the number resides
;
	MOV		A,C			; get the block
	RRC					; now shift right 3 bits.
	RRC      	  		; to divide by 8
	RRC                
	ANI		1FH			; and clear bits 7,6,5.
	MOV		C,A			; put result in c           
	MOV		A,B			           
	ADD		A			; now shift
	ADD		A           ; hi byte's bits 0,1 & 2   
	ADD		A           ; int bit positions 6,7, & 8  
	ADD		A           ; so we can put continue the   
	ADD		A           ; divide by 8 of the whole word  
	ORA		C			; combile with (C)(bits 0,1,2,3 & 4).
	MOV		C,A			; ok, (C), the low byte has been completed.
	MOV		A,B			; Now to finish with
	RRC 	       		; the high order byte                
	RRC        
	RRC 	       		; divide by 8
	ANI		1FH			; zero out bits 5,6 & 7           
	MOV		B,A			;and now (B) is completed.
;                     
;   use this as an offset into the disk space allocation
; table.
;
	LHLD	FATpointer
	DAD	B
	MOV	A,M				; we now have correct byte.
CKBMAP1:
	RLC		;get correct bit into position 0.
	DCR	E
	JNZ	CKBMAP1
	RET
;
;   Set or clear the bit map such that block number (BC) will be marked
; as used. On entry, if (E)=0 then this bit will be cleared, if it equals
; 1 then it will be set (don't use anyother values).
;
STBITMAP:
;	PUSH	D				; Save Set/Clear indicator
	CALL	CKBITMAP		; Get the byte of interest.
	ANI		0FEH			; clear the affected bit.
	MOV		C,A				; Save it in C
	LDA		BitSetFlag		; get the flag
	ORA		C				; and now set(01)/reset(01) acording to flag
;	POP	B
;	ORA	C	;and now set it acording to (C).
;
;  entry to restore the original bit position and then store
; in table. (A) contains the value, (D) contains the bit
; position (1-8), and (HL) points to the address within the
; space allocation table for this byte.
;
STBMAP1:
	RRC		;restore original bit position.
	DCR	D
	JNZ	STBMAP1
	MOV	M,A	;and stor byte in table.
	RET
;
;   Set/clear space used bits in allocation map for this file.
; On entry, (C)=1 to set the map and (C)=0 to clear it.
;
SetClearFATbits:
	CALL	FCB2HL			; Get address of fcb
	LXI		D,16			; Offset to Block Pointers in Directory entry
	DAD		D				; Compute start to block number bytes. (A1..A10)
;	PUSH	B				; Save Set/Clear indicator 
	MVI		C,17			; Check all 16 bytes (max) of table.
SETFL1:
;	POP		D				; Retreive Set/Clear indicator
	DCR		C				; Counter
	RZ						; Done?, then return
	
;	PUSH	D				; Save Set/Clear indicator
	LDA		SmallDisk			; check disk size .
	ORA		A
	JZ		SETFL2			; If it is a big disk, use 16 bits
	
	PUSH	B				; Only 8 bit numbers. Save counter.
	PUSH	H				; Save pointer to current Allocation byte
	MOV		C,M				; Get low byte from table, always
	MVI		B,0				; Set high byte to zero.
	JMP		SETFL3			; skip 16 bit number processing
	
SETFL2:
	DCR		C				; Adjust counter for 16 bit block numbers,.
	PUSH	B				; Save Counter
	MOV		C,M				; Now get both the low and high bytes.
	INX		H
	MOV		B,M
	PUSH	H				; Save pointer to current Allocation byte
SETFL3:
	MOV		A,C				; Block used? if both (b) and (c) are 00
	ORA		B				; the block is NOT used
	JZ		SETFL4			; NOT used move on			
	LHLD	DiskSize		; Is this block number within the
	MOV		A,L	
	SUB		C
	MOV		A,H
	SBB		B
	CNC		STBITMAP		; Yes, set the proper bit.
SETFL4:
	POP	H					; Point to next block number in fcb.
	INX	H
	POP	B					; Retreive the counter
	JMP	SETFL1

;
;   Set the status (StatusBDOSReturn) and return.
;
STSTATUS:
	LDA	FileFoundFlag
	JMP	SetStatusBDOS
;
;   Check extents in (A) and (C). Set the zero flag if they
; are the same. The number of 16k chunks of disk space that
; the directory extent covers is expressad is (EXTMASK+1).
; No registers are modified.
;
SAMEXT:
	PUSH	B
	PUSH	PSW
	LDA	EXTMASK	;get extent mask and use it to
	CMA		;to compare both extent numbers.
	MOV	B,A	;save resulting mask here.
	MOV	A,C	;mask first extent and save in (C).
	ANA	B
	MOV	C,A
	POP	PSW	;now mask second extent and compare
	ANA	B	;with the first one.
	SUB	C
	ANI	1FH	;(* only check buts 0-4 *)
	POP	B	;the zero flag is set if they are the same.
	RET		;restore (BC) and return.
;
;   Search for the first occurence of a file name. On entry,
; register (C) should contain the number of bytes of the fcb
; that must match.
;
FindFirst:
	MVI		A,0FFH
	STA		FileFoundFlag		; set flag to: not match found
	LXI		H,CharCounter		; point at character counter.
	MOV		M,C					; put in number of bytes to match
	LHLD	ParamsDE			; get filename to match.
	SHLD	SaveFCB				; and save.
	CALL	InitializeFilePosition	; clear initial file position (set to 0ffffh).
	CALL	HomeDrive			;home the drive.
;
;   Entry to locate the next occurence of a filename within the
; directory. The disk is not expected to have been changed. If
; it was, then it will be write protected.
;
FindNext:
	MVI		C,0					; write protect the disk if changed.
	CALL	GetNextEntry		; get next filename entry in directory.
	CALL	CheckFilePosition	; is file position = 0ffffh?
	JZ		FindNext6			; yes, exit now then.
	LHLD	SaveFCB				; get (DE) pointing to filename to match.
	XCHG
	LDAX	D
	CPI		EmptyFileFlag		; is it an empty directory entry?
	JZ		FindNext1			; yes - Skip it
						; No process it
	PUSH	D					; Save  pointer to filename to match.	
	CALL	AnyMoreFiles		; more files in directory?
	POP		D					; retreive  pointer to filename to match.	
	JNC		FindNext6				; no more. Exit now.
FindNext1:
	CALL	FCB2HL				; get address of this fcb in directory.
	LDA		CharCounter			; get number of bytes (characters) to check.
	MOV		C,A					; move to Acc
	MVI		B,0					; initialize byte position counter.
FindNext2:
	MOV		A,C					; get counter to reach
	ORA		A
	JZ		FindNext5			; Skip if all characters have been checked
	
	LDAX	D					; check next byte.
	CPI		QMARK				; '?'	;don't care about this character?
	JZ		FindNext4
	
	MOV		A,B					; get bytes position in fcb.
	CPI		13					; don't care about the thirteenth byte either.
	JZ		FindNext4
	CPI		12					; is it an extent byte?
	LDAX	D					; get the next character
	JZ		FindNext3			; skip if extent
	SUB		M					; otherwise compare characters.
	ANI		7FH
	JNZ		FindNext			; not the same, check next entry.
	JMP	FindNext4	;so far so good, keep checking.
FindNext3:
	PUSH	B	;check the extent byte here.
	MOV	C,M
	CALL	SAMEXT
	POP	B
	JNZ	FindNext	;not the same, look some more.
;
;   So far the names compare. Bump pointers to the next byte
; and continue until all (C) characters have been checked.
;
FindNext4:
	INX	D	;bump pointers.
	INX	H
	INR	B
	DCR	C	;adjust character counter.
	JMP	FindNext2
FindNext5:
	LDA	FilePosInDirectory	;return the position of this entry.
	ANI	03H
	STA	StatusBDOSReturn
	LXI	H,FileFoundFlag
	MOV	A,M
	RAL
	RNC
	XRA	A
	MOV	M,A
	RET
;
;   Filename was not found. Set appropriate status.
;
FindNext6:
	CALL	InitializeFilePosition;set (FilePosInDirectory) to 0ffffh.
	MVI	A,0FFH	;say not located.
	JMP	SetStatusBDOS
;
;   Erase files from the directory. Only the first byte of the
; fcb will be affected. It is set to (E5).
;
EraseFile:
	CALL	IsDiskRO		; if disk write is  protected exit via error message
	MVI		C,12			; only compare file names.
	CALL	FindFirst		; get first file name.
ERAFIL1:
	CALL	CheckFilePosition	;any found?
	RZ						; nope, we must be done.
	CALL	CHKROFL			; is file read only?
	CALL	FCB2HL	;nope, get address of fcb and
	MVI	M,EmptyFileFlag	;set first byte to 'empty'.
;	MVI	C,0	;clear the space from the bit map.
	MVI		A,00H		; want to clear the bit
	STA		BitSetFlag	; Flag = 00, clear bit
	CALL	SetClearFATbits
	CALL	DIRWRITE;now write the directory sector back out.
	CALL	FindNext	;find the next file name.
	JMP	ERAFIL1	;and repeat process.
;
;   Look through the space allocation map (bit map) for the
; next available block. Start searching at block number (BC-1).
; The search procedure is to look for an empty block that is
; before the starting block. If not empty, look at a later
; block number. In this way, we return the closest empty block
; on either side of the 'target' block number. This will speed
; access on random devices. For serial devices, this should be
; changed to look in the forward direction first and then start
; at the front and search some more.
;
;   On return, (DE)= block number that is empty and (HL) =0
; if no empry block was found.
;
FNDSPACE:
	MOV	D,B	;set (DE) as the block that is checked.
	MOV	E,C
;
;   Look before target block. Registers (BC) are used as the lower
; pointer and (DE) as the upper pointer.
;
FNDSPA1:
	MOV	A,C	;is block 0 specified?
	ORA	B
	JZ	FNDSPA2
	DCX	B	;nope, check previous block.
	PUSH	D
	PUSH	B
	CALL	CKBITMAP
	RAR		;is this block empty?
	JNC	FNDSPA3	;yes. use this.
;
;   Note that the above logic gets the first block that it finds
; that is empty. Thus a file could be written 'backward' making
; it very slow to access. This could be changed to look for the
; first empty block and then continue until the start of this
; empty space is located and then used that starting block.
; This should help speed up access to some files especially on
; a well used disk with lots of fairly small 'holes'.
;
	POP	B	;nope, check some more.
	POP	D
;
;   Now look after target block.
;
FNDSPA2:
	LHLD	DiskSize	;is block (DE) within disk limits?
	MOV	A,E
	SUB	L
	MOV	A,D
	SBB	H
	JNC	FNDSPA4
	INX	D	;yes, move on to next one.
	PUSH	B
	PUSH	D
	MOV	B,D
	MOV	C,E
	CALL	CKBITMAP;check it.
	RAR		;empty?
	JNC	FNDSPA3
	POP	D	;nope, continue searching.
	POP	B
	JMP	FNDSPA1
;
;   Empty block found. Set it as used and return with (HL)
; pointing to it (true?).
;
FNDSPA3:
	RAL		;reset byte.
	INR	A	;and set bit 0.
	CALL	STBMAP1	;update bit map.
	POP	H	;set return registers.
	POP	D
	RET
;
;   Free block was not found. If (BC) is not zero, then we have
; not checked all of the disk space.
;
FNDSPA4:
	MOV	A,C
	ORA	B
	JNZ	FNDSPA1
	LXI	H,0	;set 'not found' status.
	RET
;
;   Move a complete fcb entry into the directory and write it.
;
FCBSET:
	MVI	C,0
	MVI	E,32	;length of each entry.
;
;   Move (E) bytes from the fcb pointed to by (ParamsDE) into
; fcb in directory starting at relative byte (C). This updated
; directory buffer is then written to the disk.
;
UPDATE:
	PUSH	D
	MVI	B,0	;set (BC) to relative byte position.
	LHLD	ParamsDE	;get address of fcb.
	DAD	B	;compute starting byte.
	XCHG
	CALL	FCB2HL	;get address of fcb to update in directory.
	POP	B	;set (C) to number of bytes to change.
	CALL	DEtoHL
UPDATE1:
	CALL	TrackSectorForDir	;determine the track and sector affected.
	JMP	DIRWRITE	;then write this sector out.
;
;   Routine to change the name of all files on the disk with a
; specified name. The fcb contains the current name as the
; first 12 characters and the new name 16 bytes into the fcb.
;
CHGNAMES:
	CALL	IsDiskRO	;check for a write protected disk.
	MVI	C,12	;match first 12 bytes of fcb only.
	CALL	FindFirst	;get first name.
	LHLD	ParamsDE	;get address of fcb.
	MOV	A,M	;get user number.
	LXI	D,16	;move over to desired name.
	DAD	D
	MOV	M,A	;keep same user number.
CHGNAM1:
	CALL	CheckFilePosition;any matching file found?
	RZ		;no, we must be done.
	CALL	CHKROFL	;check for read only file.
	MVI	C,16	;start 16 bytes into fcb.
	MVI	E,12	;and update the first 12 bytes of directory.
	CALL	UPDATE
	CALL	FindNext	;get te next file name.
	JMP	CHGNAM1	;and continue.
;
;   Update a files attributes. The procedure is to search for
; every file with the same name as shown in fcb (ignoring bit 7)
; and then to update it (which includes bit 7). No other changes
; are made.
;
SAVEATTR:
	MVI	C,12	;match first 12 bytes.
	CALL	FindFirst	;look for first filename.
SAVATR1:
	CALL	CheckFilePosition;was one found?
	RZ		;nope, we must be done.
	MVI	C,0	;yes, update the first 12 bytes now.
	MVI	E,12
	CALL	UPDATE	;update filename and write directory.
	CALL	FindNext	;and get the next file.
	JMP	SAVATR1	;then continue until done.
;
;  Open a file (name specified in fcb).
;
OPENIT:
	MVI	C,15	;compare the first 15 bytes.
	CALL	FindFirst	;get the first one in directory.
	CALL	CheckFilePosition;any at all?
	RZ
OPENIT1:
	CALL	SETEXT	;point to extent byte within users fcb.
	MOV	A,M	;and get it.
	PUSH	PSW	;save it and address.
	PUSH	H
	CALL	FCB2HL	;point to fcb in directory.
	XCHG
	LHLD	ParamsDE	;this is the users copy.
	MVI	C,32	;move it into users space.
	PUSH	D
	CALL	DEtoHL
	CALL	SetBit7InS2	;set bit 7 in 's2' byte (unmodified).
	POP	D	;now get the extent byte from this fcb.
	LXI	H,12
	DAD	D
	MOV	C,M	;into (C).
	LXI	H,15	;now get the record count byte into (B).
	DAD	D
	MOV	B,M
	POP	H	;keep the same extent as the user had originally.
	POP	PSW
	MOV	M,A
	MOV	A,C	;is it the same as in the directory fcb?
	CMP	M
	MOV	A,B	;if yes, then use the same record count.
	JZ	OPENIT2
	MVI	A,0	;if the user specified an extent greater than
	JC	OPENIT2	;the one in the directory, then set record count to 0.
	MVI	A,DirBuffSize	;otherwise set to maximum.
OPENIT2:
	LHLD	ParamsDE	;set record count in users fcb to (A).
	LXI	D,15
	DAD	D	;compute relative position.
	MOV	M,A	;and set the record count.
	RET
;
;   Move two bytes from (DE) to (HL) if (and only if) (HL)
; point to a zero value (16 bit).
;   Return with zero flag set it (DE) was moved. Registers (DE)
; and (HL) are not changed. However (A) is.
;
MOVEWORD:
	MOV	A,M	;check for a zero word.
	INX	H
	ORA	M	;both bytes zero?
	DCX	H
	RNZ		;nope, just return.
	LDAX	D	;yes, move two bytes from (DE) into
	MOV	M,A	;this zero space.
	INX	D
	INX	H
	LDAX	D
	MOV	M,A
	DCX	D	;don't disturb these registers.
	DCX	H
	RET
;
;   Get here to close a file specified by (fcb).
;
CLOSEIT:
	XRA	A	;clear status and file position bytes.
	STA	StatusBDOSReturn
	STA	FilePosInDirectory
	STA	FilePosInDirectory+1
	CALL	GetDiskROStatus	;get write protect bit for this drive.
	RNZ		;just return if it is set.
	CALL	GetS2	;else get the 's2' byte.
	ANI	80H	;and look at bit 7 (file unmodified?).
	RNZ		;just return if set.
	MVI	C,15	;else look up this file in directory.
	CALL	FindFirst
	CALL	CheckFilePosition;was it found?
	RZ		;just return if not.
	LXI	B,16	;set (HL) pointing to records used section.
	CALL	FCB2HL
	DAD	B
	XCHG
	LHLD	ParamsDE	;do the same for users specified fcb.
	DAD	B
	MVI	C,16	;this many bytes are present in this extent.
CLOSEIT1:
	LDA	SmallDisk	;8 or 16 bit record numbers?
	ORA	A
	JZ	CLOSEIT4
	MOV	A,M	;just 8 bit. Get one from users fcb.
	ORA	A
	LDAX	D	;now get one from directory fcb.
	JNZ	CLOSEIT2
	MOV	M,A	;users byte was zero. Update from directory.
CLOSEIT2:
	ORA	A
	JNZ	CLOSEIT3
	MOV	A,M	;directories byte was zero, update from users fcb.
	STAX	D
CLOSEIT3:
	CMP	M	;if neither one of these bytes were zero,
	JNZ	CLOSEIT7	;then close error if they are not the same.
	JMP	CLOSEIT5	;ok so far, get to next byte in fcbs.
CLOSEIT4:
	CALL	MOVEWORD;update users fcb if it is zero.
	XCHG
	CALL	MOVEWORD;update directories fcb if it is zero.
	XCHG
	LDAX	D	;if these two values are no different,
	CMP	M	;then a close error occured.
	JNZ	CLOSEIT7
	INX	D	;check second byte.
	INX	H
	LDAX	D
	CMP	M
	JNZ	CLOSEIT7
	DCR	C	;remember 16 bit values.
CLOSEIT5:
	INX	D	;bump to next item in table.
	INX	H
	DCR	C	;there are 16 entries only.
	JNZ	CLOSEIT1;continue if more to do.
	LXI	B,0FFECH;backup 20 places (extent byte).
	DAD	B
	XCHG
	DAD	B
	LDAX	D
	CMP	M	;directory's extent already greater than the
	JC	CLOSEIT6	;users extent?
	MOV	M,A	;no, update directory extent.
	LXI	B,3	;and update the record count byte in
	DAD	B	;directories fcb.
	XCHG
	DAD	B
	MOV	A,M	;get from user.
	STAX	D	;and put in directory.
CLOSEIT6:
	MVI	A,0FFH	;set 'was open and is now closed' byte.
	STA	CLOSEFLG
	JMP	UPDATE1	;update the directory now.
CLOSEIT7:
	LXI	H,StatusBDOSReturn;set return status and then return.
	DCR	M
	RET
;
;   Routine to get the next empty space in the directory. It
; will then be cleared for use.
;
GetEmptyDirSlot:
	CALL	IsDiskRO	;make sure disk is not write protected.
	LHLD	ParamsDE	;save current parameters (fcb).
	PUSH	H
	LXI		H,EmptyDir	;use special one for empty space.
	SHLD	ParamsDE
	MVI	C,1	;search for first empty spot in directory.
	CALL	FindFirst	;(* only check first byte *)
	CALL	CheckFilePosition;none?
	POP	H
	SHLD	ParamsDE	;restore original fcb address.
	RZ		;return if no more space.
	XCHG
	LXI	H,15	;point to number of records for this file.
	DAD	D
	MVI	C,17	;and clear all of this space.
	XRA	A
GETMT1:
	MOV	M,A
	INX	H
	DCR	C
	JNZ	GETMT1
	LXI	H,13	;clear the 's1' byte also.
	DAD	D
	MOV	M,A
	CALL	CHKNMBR	;keep (FilePosInDirSegment) within bounds.
	CALL	FCBSET	;write out this fcb entry to directory.
	JMP	SetBit7InS2	;set 's2' byte bit 7 (unmodified at present).
;
;   Routine to close the current extent and open the next one
; for reading.
;
GETNEXT:
	XRA	A
	STA	CLOSEFLG;clear close flag.
	CALL	CLOSEIT	;close this extent.
	CALL	CheckFilePosition
	RZ		;not there???
	LHLD	ParamsDE	;get extent byte.
	LXI	B,12
	DAD	B
	MOV	A,M	;and increment it.
	INR	A
	ANI	1FH	;keep within range 0-31.
	MOV	M,A
	JZ	GTNEXT1	;overflow?
	MOV	B,A	;mask extent byte.
	LDA	EXTMASK
	ANA	B
	LXI	H,CLOSEFLG;check close flag (0ffh is ok).
	ANA	M
	JZ	GTNEXT2	;if zero, we must read in next extent.
	JMP	GTNEXT3	;else, it is already in memory.
GTNEXT1:
	LXI	B,2	;Point to the 's2' byte.
	DAD	B
	INR	M	;and bump it.
	MOV	A,M	;too many extents?
	ANI	0FH
	JZ	GTNEXT5	;yes, set error code.
;
;   Get here to open the next extent.
;
GTNEXT2:
	MVI	C,15	;set to check first 15 bytes of fcb.
	CALL	FindFirst	;find the first one.
	CALL	CheckFilePosition;none available?
	JNZ	GTNEXT3
	LDA	RDWRTFLG;no extent present. Can we open an empty one?
	INR	A	;0ffh means reading (so not possible).
	JZ	GTNEXT5	;or an error.
	CALL	GetEmptyDirSlot;we are writing, get an empty entry.
	CALL	CheckFilePosition;none?
	JZ	GTNEXT5	;error if true.
	JMP	GTNEXT4	;else we are almost done.
GTNEXT3:
	CALL	OPENIT1	;open this extent.
GTNEXT4:
	CALL	STRDATA	;move in updated data (rec #, extent #, etc.)
	XRA	A	;clear status and return.
	JMP	SetStatusBDOS
;
;   Error in extending the file. Too many extents were needed
; or not enough space on the disk.
;
GTNEXT5:
	CALL	IOERR1	;set error code, clear bit 7 of 's2'
	JMP	SetBit7InS2	;so this is not written on a close.
;
;   Read a sequential file.
;
RDSEQ:
	MVI	A,1	;set sequential access mode.
	STA	MODE
RDSEQ1:
	MVI	A,0FFH	;don't allow reading unwritten space.
	STA	RDWRTFLG
	CALL	STRDATA	;put rec# and ext# into fcb.
	LDA	SAVNREC	;get next record to read.
	LXI	H,SAVNXT;get number of records in extent.
	CMP	M	;within this extent?
	JC	RDSEQ2
	CPI	LogicalSecSize	;no. Is this extent fully used?
	JNZ	RDSEQ3	;no. End-of-file.
	CALL	GETNEXT	;yes, open the next one.
	XRA	A	;reset next record to read.
	STA	SAVNREC
	LDA	StatusBDOSReturn	;check on open, successful?
	ORA	A
	JNZ	RDSEQ3	;no, error.
RDSEQ2:
	CALL	COMBLK	;ok. compute block number to read.
	CALL	CHKBLK	;check it. Within bounds?
	JZ	RDSEQ3	;no, error.
	CALL	LOGICAL	;convert (BlockNumber) to logical sector (128 byte).
	CALL	TrackSectorForBlock	;set the track and sector for this block #.
	CALL	DOREAD	;and read it.
	JMP	SETNREC	;and set the next record to be accessed.
;
;   Read error occured. Set status and return.
;
RDSEQ3:
	JMP	IOERR1
;
;   Write the next sequential record.
;
WTSEQ:
	MVI	A,1	;set sequential access mode.
	STA	MODE
WTSEQ1:
	MVI	A,0	;allow an addition empty extent to be opened.
	STA	RDWRTFLG
	CALL	IsDiskRO	;check write protect status.
	LHLD	ParamsDE
	CALL	CKROF1	;check for read only file, (HL) already set to fcb.
	CALL	STRDATA	;put updated data into fcb.
	LDA	SAVNREC	;get record number to write.
	CPI	LogicalSecSize	;within range?
	JNC	IOERR1	;no, error(?).
	CALL	COMBLK	;compute block number.
	CALL	CHKBLK	;check number.
	MVI	C,0	;is there one to write to?
	JNZ	WTSEQ6	;yes, go do it.
	CALL	GETBLOCK;get next block number within fcb to use.
	STA	RELBLOCK;and save.
	LXI	B,0	;start looking for space from the start
	ORA	A	;if none allocated as yet.
	JZ	WTSEQ2
	MOV	C,A	;extract previous block number from fcb
	DCX	B	;so we can be closest to it.
	CALL	EXTBLK
	MOV	B,H
	MOV	C,L
WTSEQ2:
	CALL	FNDSPACE;find the next empty block nearest number (BC).
	MOV	A,L	;check for a zero number.
	ORA	H
	JNZ	WTSEQ3
	MVI	A,2	;no more space?
	JMP	SetStatusBDOS
WTSEQ3:
	SHLD	BlockNumber	;save block number to access.
	XCHG		;put block number into (DE).
	LHLD	ParamsDE	;now we must update the fcb for this
	LXI	B,16	;newly allocated block.
	DAD	B
	LDA	SmallDisk	;8 or 16 bit block numbers?
	ORA	A
	LDA	RELBLOCK	;(* update this entry *)
	JZ	WTSEQ4	;zero means 16 bit ones.
	CALL	ADDA2HL	;(HL)=(HL)+(A)
	MOV	M,E	;store new block number.
	JMP	WTSEQ5
WTSEQ4:
	MOV	C,A	;compute spot in this 16 bit table.
	MVI	B,0
	DAD	B
	DAD	B
	MOV	M,E	;stuff block number (DE) there.
	INX	H
	MOV	M,D
WTSEQ5:
	MVI	C,2	;set (C) to indicate writing to un-used disk space.
WTSEQ6:
	LDA	StatusBDOSReturn	;are we ok so far?
	ORA	A
	RNZ
	PUSH	B	;yes, save write flag for bios (register C).
	CALL	LOGICAL	;convert (BlockNumber) over to loical sectors.
	LDA	MODE	;get access mode flag (1=sequential,
	DCR	A	;0=random, 2=special?).
	DCR	A
	JNZ	WTSEQ9
;
;   Special random i/o from function #40. Maybe for M/PM, but the
; current block, if it has not been written to, will be zeroed
; out and then written (reason?).
;
	POP	B
	PUSH	B
	MOV	A,C	;get write status flag (2=writing unused space).
	DCR	A
	DCR	A
	JNZ	WTSEQ9
	PUSH	H
	LHLD	DirBuffAddr	;zero out the directory buffer.
	MOV	D,A	;note that (A) is zero here.
WTSEQ7:
	MOV	M,A
	INX	H
	INR	D	;do 128 bytes.
	JP	WTSEQ7
	CALL	SetDirDMA	;tell the bios the dma address for directory access.
	LHLD	LOGSECT	;get sector that starts current block.
	MVI	C,2	;set 'writing to unused space' flag.
WTSEQ8:
	SHLD	BlockNumber	;save sector to write.
	PUSH	B
	CALL	TrackSectorForBlock	;determine its track and sector numbers.
	POP	B
	CALL	DOWRITE	;now write out 128 bytes of zeros.
	LHLD	BlockNumber	;get sector number.
	MVI	C,0	;set normal write flag.
	LDA	BLKMASK	;determine if we have written the entire
	MOV	B,A	;physical block.
	ANA	L
	CMP	B
	INX	H	;prepare for the next one.
	JNZ	WTSEQ8	;continue until (BLKMASK+1) sectors written.
	POP	H	;reset next sector number.
	SHLD	BlockNumber
	CALL	Set2UsersDMA	;and reset dma address.
;
;   Normal disk write. Set the desired track and sector then
; do the actual write.
;
WTSEQ9:
	CALL	TrackSectorForBlock	;determine track and sector for this write.
	POP	B	;get write status flag.
	PUSH	B
	CALL	DOWRITE	;and write this out.
	POP	B
	LDA	SAVNREC	;get number of records in file.
	LXI	H,SAVNXT;get last record written.
	CMP	M
	JC	WTSEQ10
	MOV	M,A	;we have to update record count.
	INR	M
	MVI	C,2
;
;*   This area has been patched to correct disk update problem
;* when using blocking and de-blocking in the BIOS.
;
WTSEQ10:
	NOP		;was 'dcr c'
	NOP		;was 'dcr c'
	LXI	H,0	;was 'jnz wtseq99'
;
; *   End of patch.
;
	PUSH	PSW
	CALL	GetS2	;set 'extent written to' flag.
	ANI	7FH	;(* clear bit 7 *)
	MOV	M,A
	POP	PSW	;get record count for this extent.
WTSEQ99:
	CPI	127	;is it full?
	JNZ	WTSEQ12
	LDA	MODE	;yes, are we in sequential mode?
	CPI	1
	JNZ	WTSEQ12
	CALL	SETNREC	;yes, set next record number.
	CALL	GETNEXT	;and get next empty space in directory.
	LXI	H,StatusBDOSReturn;ok?
	MOV	A,M
	ORA	A
	JNZ	WTSEQ11
	DCR	A	;yes, set record count to -1.
	STA	SAVNREC
WTSEQ11:
	MVI	M,0	;clear status.
WTSEQ12:
	JMP	SETNREC	;set next record to access.
;
;   For random i/o, set the fcb for the desired record number
; based on the 'r0,r1,r2' bytes. These bytes in the fcb are
; used as follows:
;
;       fcb+35            fcb+34            fcb+33
;  |     'r-2'      |      'r-1'      |      'r-0'     |
;  |7             0 | 7             0 | 7             0|
;  |0 0 0 0 0 0 0 0 | 0 0 0 0 0 0 0 0 | 0 0 0 0 0 0 0 0|
;  |    overflow   | | extra |  extent   |   record #  |
;  | ______________| |_extent|__number___|_____________|
;                     also 's2'
;
;   On entry, register (C) contains 0ffh if this is a read
; and thus we can not access unwritten disk space. Otherwise,
; another extent will be opened (for writing) if required.
;
POSITION:
	XRA	A	;set random i/o flag.
	STA	MODE
;
;   Special entry (function #40). M/PM ?
;
POSITN1:
	PUSH	B	;save read/write flag.
	LHLD	ParamsDE	;get address of fcb.
	XCHG
	LXI	H,33	;now get byte 'r0'.
	DAD	D
	MOV	A,M
	ANI	7FH	;keep bits 0-6 for the record number to access.
	PUSH	PSW
	MOV	A,M	;now get bit 7 of 'r0' and bits 0-3 of 'r1'.
	RAL
	INX	H
	MOV	A,M
	RAL
	ANI	1FH	;and save this in bits 0-4 of (C).
	MOV	C,A	;this is the extent byte.
	MOV	A,M	;now get the extra extent byte.
	RAR
	RAR
	RAR
	RAR
	ANI	0FH
	MOV	B,A	;and save it in (B).
	POP	PSW	;get record number back to (A).
	INX	H	;check overflow byte 'r2'.
	MOV	L,M
	INR	L
	DCR	L
	MVI	L,6	;prepare for error.
	JNZ	POSITN5	;out of disk space error.
	LXI	H,32	;store record number into fcb.
	DAD	D
	MOV	M,A
	LXI	H,12	;and now check the extent byte.
	DAD	D
	MOV	A,C
	SUB	M	;same extent as before?
	JNZ	POSITN2
	LXI	H,14	;yes, check extra extent byte 's2' also.
	DAD	D
	MOV	A,B
	SUB	M
	ANI	7FH
	JZ	POSITN3;same, we are almost done then.
;
;  Get here when another extent is required.
;
POSITN2:
	PUSH	B
	PUSH	D
	CALL	CLOSEIT	;close current extent.
	POP	D
	POP	B
	MVI	L,3	;prepare for error.
	LDA	StatusBDOSReturn
	INR	A
	JZ	POSITN4	;close error.
	LXI	H,12	;put desired extent into fcb now.
	DAD	D
	MOV	M,C
	LXI	H,14	;and store extra extent byte 's2'.
	DAD	D
	MOV	M,B
	CALL	OPENIT	;try and get this extent.
	LDA	StatusBDOSReturn	;was it there?
	INR	A
	JNZ	POSITN3
	POP	B	;no. can we create a new one (writing?).
	PUSH	B
	MVI	L,4	;prepare for error.
	INR	C
	JZ	POSITN4	;nope, reading unwritten space error.
	CALL	GetEmptyDirSlot;yes we can, try to find space.
	MVI	L,5	;prepare for error.
	LDA	StatusBDOSReturn
	INR	A
	JZ	POSITN4	;out of space?
;
;   Normal return location. Clear error code and return.
;
POSITN3:
	POP	B	;restore stack.
	XRA	A	;and clear error code byte.
	JMP	SetStatusBDOS
;
;   Error. Set the 's2' byte to indicate this (why?).
;
POSITN4:
	PUSH	H
	CALL	GetS2
	MVI	M,0C0H
	POP	H
;
;   Return with error code (presently in L).
;
POSITN5:
	POP	B
	MOV	A,L	;get error code.
	STA	StatusBDOSReturn
	JMP	SetBit7InS2
;
;   Read a random record.
;
READRAN:
	MVI	C,0FFH	;set 'read' status.
	CALL	POSITION;position the file to proper record.
	CZ	RDSEQ1	;and read it as usual (if no errors).
	RET
;
;   Write to a random record.
;
WRITERAN:
	MVI	C,0	;set 'writing' flag.
	CALL	POSITION;position the file to proper record.
	CZ	WTSEQ1	;and write as usual (if no errors).
	RET
;
;   Compute the random record number. Enter with (HL) pointing
; to a fcb an (DE) contains a relative location of a record
; number. On exit, (C) contains the 'r0' byte, (B) the 'r1'
; byte, and (A) the 'r2' byte.
;
;   On return, the zero flag is set if the record is within
; bounds. Otherwise, an overflow occured.
;
COMPRAND:
	XCHG		;save fcb pointer in (DE).
	DAD	D	;compute relative position of record #.
	MOV	C,M	;get record number into (BC).
	MVI	B,0
	LXI	H,12	;now get extent.
	DAD	D
	MOV	A,M	;compute (BC)=(record #)+(extent)*128.
	RRC		;move lower bit into bit 7.
	ANI	80H	;and ignore all other bits.
	ADD	C	;add to our record number.
	MOV	C,A
	MVI	A,0	;take care of any carry.
	ADC	B
	MOV	B,A
	MOV	A,M	;now get the upper bits of extent into
	RRC		;bit positions 0-3.
	ANI	0FH	;and ignore all others.
	ADD	B	;add this in to 'r1' byte.
	MOV	B,A
	LXI	H,14	;get the 's2' byte (extra extent).
	DAD	D
	MOV	A,M
	ADD	A	;and shift it left 4 bits (bits 4-7).
	ADD	A
	ADD	A
	ADD	A
	PUSH	PSW	;save carry flag (bit 0 of flag byte).
	ADD	B	;now add extra extent into 'r1'.
	MOV	B,A
	PUSH	PSW	;and save carry (overflow byte 'r2').
	POP	H	;bit 0 of (L) is the overflow indicator.
	MOV	A,L
	POP	H	;and same for first carry flag.
	ORA	L	;either one of these set?
	ANI	01H	;only check the carry flags.
	RET
;
;   Routine to setup the fcb (bytes 'r0', 'r1', 'r2') to
; reflect the last record used for a random (or other) file.
; This reads the directory and looks at all extents computing
; the largerst record number for each and keeping the maximum
; value only. Then 'r0', 'r1', and 'r2' will reflect this
; maximum record number. This is used to compute the space used
; by a random file.
;
RANSIZE:
	MVI	C,12	;look thru directory for first entry with
	CALL	FindFirst	;this name.
	LHLD	ParamsDE	;zero out the 'r0, r1, r2' bytes.
	LXI	D,33
	DAD	D
	PUSH	H
	MOV	M,D	;note that (D)=0.
	INX	H
	MOV	M,D
	INX	H
	MOV	M,D
RANSIZ1:
	CALL	CheckFilePosition;is there an extent to process?
	JZ	RANSIZ3	;no, we are done.
	CALL	FCB2HL	;set (HL) pointing to proper fcb in dir.
	LXI	D,15	;point to last record in extent.
	CALL	COMPRAND;and compute random parameters.
	POP	H
	PUSH	H	;now check these values against those
	MOV	E,A	;already in fcb.
	MOV	A,C	;the carry flag will be set if those
	SUB	M	;in the fcb represent a larger size than
	INX	H	;this extent does.
	MOV	A,B
	SBB	M
	INX	H
	MOV	A,E
	SBB	M
	JC	RANSIZ2
	MOV	M,E	;we found a larger (in size) extent.
	DCX	H	;stuff these values into fcb.
	MOV	M,B
	DCX	H
	MOV	M,C
RANSIZ2:
	CALL	FindNext	;now get the next extent.
	JMP	RANSIZ1	;continue til all done.
RANSIZ3:
	POP	H	;we are done, restore the stack and
	RET		;return.
;
;   Function to return the random record position of a given
; file which has been read in sequential mode up to now.
;
fcSetRecordNumber:
	LHLD	ParamsDE	;point to fcb.
	LXI	D,32	;and to last used record.
	CALL	COMPRAND;compute random position.
	LXI	H,33	;now stuff these values into fcb.
	DAD	D
	MOV	M,C	;move 'r0'.
	INX	H
	MOV	M,B	;and 'r1'.
	INX	H
	MOV	M,A	;and lastly 'r2'.
	RET
;
; This routine selects the drive specified in (CurrentDrive) and
; updates the login vector and bitmap table if this drive was
; not already active.
;
LoginDrive:
	LDA		CurrentDrive		; get the Current Drive.
	MOV		C,A					; Save current drive for later
	LHLD	LoggedBitMap		; point at the "logged In" Bitmap.
	CALL	HLrightC			; Return with CurrentDrive's bit in L's lsb (byte 0)
	PUSH	H					; Save it, so we will know if it is already active
	XCHG
	CALL	SelectDisk			; select this drive to set up Disk Parameter Block.
	JZ		SLCTERR				; If not valid then error exit outta here
	POP	H						; retreive original state of the drive
	MOV	A,L						; and put it into (A) 
	RAR							; move bit 0 into the carry flag if it is set		
	RC							; then return, because this drive has already been activated
				;Else  update the logged Bitmap to reflect this drive.
	LHLD	LoggedBitMap		
	MOV		C,L
	MOV		B,H					; put the map into (BC)
	CALL	SetBit				; Set it in the LoggedBitMap
	SHLD	LoggedBitMap		; and save the Bit map.
;	JMP	BITMAP	;now update the bitmap.
;-----------------------------------------------------------
;
;   Construct the FAT for the active
; drive. If a file name starts with '$' and it is under the
; current user number, then (StatusBDOSReturn) is set to minus 1. Otherwise
; it is not set at all.
;
BITMAP:
								; compute size of allocation table. 1 bit for block,
								; 1 byte for 8 blocks, so size of FAT is:
								; DiskSize/8.
	LHLD		DiskSize		; get maximum  Allocation Block number
	MVI			C,3				; 2 raised to 3rd power = 8
	CALL		HLrightC		;(HL)=(HL)/8.
	INX			H				;at lease 1 byte.
	MOV			B,H
	MOV			C,L				;set (BC) to the allocation table length.
;
;   Initialize the bitmap for this drive. Right now, the first
; two bytes are specified by the disk parameter block. However
; a patch could be entered here if it were necessary to setup
; this table in a special mannor. For example, the bios could
; determine locations of 'bad blocks' and set them as already
; 'used' in the map.
;
	LHLD		FATpointer			;now zero out the File Allocation Table
BITMAP1:
	MVI			M,0					; put zero in vector
	INX			H					; point at next location
	DCX			B					; count down
	MOV			A,B
	ORA			C					; equals zero if both (B) and (B) are Zero
	JNZ			BITMAP1				; loop for more
					; allocation vector is now cleared
	LHLD		DirectoryFAT0		; Point at initial space used by directory.
	XCHG							; pre allocate the space, first 2 bits (0C000H)
	LHLD		FATpointer			; and put this into map.
	MOV			M,E
	INX			H
	MOV			M,D
;
;   End of initialization portion.
;
	CALL		HomeDrive			; now home the drive, H=0,T=0,S=0
	LHLD		FilePosInDirSegment
	MVI			M,3					; force next directory request to read
	INX			H					; in a sector.
	MVI			M,0
	
	CALL		InitializeFilePosition	;clear initial file position also.
BITMAP2:
	MVI		C,0FFH				; Read next file name in directory
	CALL	GetNextEntry		; And set checksum byte.
	
	CALL	CheckFilePosition	; Is there another file?
	RZ						; NO - return
	
	CALL	FCB2HL				; YES, get its address.
	MVI		A,EmptyFileFlag
	CMP		M					; Is it an empty file entry?
	JZ		BITMAP2				; YES - Go back for next entry
	
	LDA		CurrentUser			; NO, Do we have the correct user number?
	CMP		M
	JNZ		BITMAP3				; NO -			
	INX		H					; YES -skip to first character in file name
	MOV		A,M					; Does name start with a '$'?
	SUI		DOLLAR				; Clear acc(if =) and test for equality at the same time
	JNZ		BITMAP3
	DCR		A					; Yes, set atatus to minus one.
	STA		StatusBDOSReturn	; set return status
BITMAP3:
;	MVI		C,1					;now set this file's space as used in bit map.
	MVI		A,01H				; want to set the bit
	STA		BitSetFlag			; Flag = 01, set the bit
	CALL	SetClearFATbits
	CALL	CHKNMBR				;keep (FilePosInDirSegment) in bounds.
	JMP	BITMAP2
;-----------------------------------------------------------
;
;  Routine to set a bit in a 16 bit value contained in (BC).
; The bit set depends on the current drive selection.
;
SetBit:
	LDA		CurrentDrive		; get active drive, a = 00, b = 02, c= 02, d = 03
	LXI		H,1					; Need a bit to move
	INR		A					; Ensure at lest 1 test
SetBit1:
	DCR		A
	JZ		SetBit2				; a = 01, b = 02, c= 04, d = 08
	DAD		H
	JMP		SetBit1
SetBit2:	
	MOV		A,C					; or result with BC
	ORA		L
	MOV		L,A					;low byte done, do high byte.
	MOV		A,B
	ORA		H
	MOV		H,A
	RET							; HL has the result

;
;   Function to set the active disk number.
;
fcSelectDisk:
	LDA	ParamE				;get parameter passed and see if this
	LXI	H,CurrentDrive		;represents a change in drives.
	CMP	M
	RZ						; return the drive is already selected
	MOV	M,A					; It is a change in drives, so log it in.
	JMP	LoginDrive
;
;   This is the 'auto disk select' routine. The firsst byte
; of the fcb is examined for a drive specification. If non
; zero then the drive will be selected and loged in.
;
AutoSelect:
	MVI		A,0FFH				;say 'auto-select activated'.
	STA		reselectionFlag
	LHLD	ParamsDE			; get drive specified.
	MOV		A,M					; (A) should be equal to currentDisk where:
	ANI		1FH					; (uuuudddd) where 'uuuu' is the user number;look at lower 5 bits.
	DCR		A					; adjust for (1=A, 2=B) etc.
	STA		ParamE				; and save for the select routine.
	CPI		1EH					; check for 'no change' condition (00 - 1).
	JNC		AutoSelect1			; yes, don't change.
	
	LDA		CurrentDrive		; we must change
	STA		OldDrive			;  save currently active drive.
	MOV		A,M					; and get first byte of fcb also.
	STA		fcbDisk				; and store it away
	ANI		0E0H				; whats this for (bits 6,7 are used for
	MOV		M,A					; something)? maybe User Number
	CALL	fcSelectDisk		; select and log in this drive.
AutoSelect1:
	LDA		CurrentUser 		; move user number into fcb.
	LHLD	ParamsDE			; (* upper half of first byte *)
	ORA		M
	MOV		M,A
	RET							; and return (all done).
;
;   Function to return the current cp/m version number.
;
fcGetVersion:
	MVI	A,022h	;version 2.2
	JMP	SetStatusBDOS
;
;   Function (0D) to reset the disk system.
;
fcResetDiskSystem:
	LXI		H,0				; clear write protect status and log
	SHLD	ROBitMap		; clear all Read Only Bits
	SHLD	LoggedBitMap	; clear all logged in drives
	XRA		A
	STA		CurrentDrive	;select drive 'A'.
	LXI		H,Pg0Buffer		;setup default dma address.
	SHLD	UsersDMA
	CALL	Set2UsersDMA	; Call BIOS to set DMA
	JMP		LoginDrive		;now log in drive 'A'.
;
;   Function to open a specified file.
;
fcOpenFile:
	CALL	ClearS2	;clear 's2' byte.
	CALL	AutoSelect	;select proper disk.
	JMP	OPENIT	;and open the file.
;
;   Function to close a specified file.
;
fcCloseFile:
	CALL	AutoSelect	;select proper disk.
	JMP	CLOSEIT	;and close the file.
;
;   Function to return the first occurence of a specified file
; name. If the first byte of the fcb is '?' then the name will
; not be checked (get the first entry no matter what).
;
fcSearchForFirst:
	MVI		C,0					; prepare for special search.
	XCHG
	MOV		A,M					; is first byte a '?'?
	CPI		QMARK				; is it '?'?
	JZ		fcSearchForFirst1	; yes, just get very first entry (zero length match).
	CALL	SETEXT				; get the extension byte from fcb.
	MOV		A,M					; is it '?'? if yes, then we want
	CPI		QMARK				; '?'	;an entry with a specific 's2' byte.
	CNZ		ClearS2				; otherwise, look for a zero 's2' byte.
	CALL	AutoSelect			; select proper drive.
	MVI		C,15				; compare bytes 0-14 in fcb (12&13 excluded).
fcSearchForFirst1:
	CALL	FindFirst			; find an entry and then move it into
	JMP		MOVEDIR				; the users dma space.
;
;   Function to return the next occurence of a file name.
;
fcSearchForNext:
	LHLD	SaveFCB				; restore pointers. note that no
	SHLD	ParamsDE			; other dbos calls are allowed.
	CALL	AutoSelect			; no error will be returned, but the
	CALL	FindNext			; results will be wrong.
	JMP		MOVEDIR
;
;   Function to delete a file by name.
;
fcDeleteFile:
	CALL	AutoSelect		; select proper drive.
	CALL	EraseFile		; erase the file.
	JMP		STSTATUS		; set status and return.
;
;   Function to execute a sequential read of the specified
; record number.
;
fcReadSequential:
	CALL	AutoSelect	;select proper drive then read.
	JMP	RDSEQ
;
;   Function to write the net sequential record.
;
fcWriteSequential:
	CALL	AutoSelect	;select proper drive then write.
	JMP	WTSEQ
;
;   Create a file function.
;
fcCreateFile:
	CALL	ClearS2				; clear the 's2' byte ( extents counter hi byte).
	CALL	AutoSelect			; select proper drive and get the next
	JMP		GetEmptyDirSlot			; empty directory space.
;
;   Function to rename a file.
;
fcRenameFile:
	CALL	AutoSelect	;select proper drive and then switch
	CALL	CHGNAMES;file names.
	JMP	STSTATUS
;
;   Function to return the logged in Bit map.
;
fcGetActiveDisks:
	LHLD	LoggedBitMap
	JMP	GETPRM1
;
;   Function to return the current disk assignment.
;
fcGetCurrentDisk:
	LDA	CurrentDrive
	JMP	SetStatusBDOS
;
;   Function to set the dma address.
;
fcSetDMA:
	XCHG
	SHLD	UsersDMA	;save in our space and then get to
	JMP	Set2UsersDMA	;the bios with this also.
;
;   Function to return the allocation vector.
;
fcGetFATtable:
	LHLD	FATpointer
	JMP	GETPRM1
;
;   Function to return the read-only status vector.
;
fcGetROdisks:
	LHLD	ROBitMap
	JMP	GETPRM1
;
;   Function to set the file attributes (read-only, system).
;
fcSetFileAttributes:
	CALL	AutoSelect	;select proper drive then save attributes.
	CALL	SAVEATTR
	JMP	STSTATUS
;
;   Function to return the address of the disk parameter block
; for the current drive.
;
fcGetDPB:
	LHLD	DiskParamBlock
GETPRM1:
	SHLD	StatusBDOSReturn
	RET
;
;   Function to get or set the user number. If (E) was (FF)
; then this is a request to return the current user number.
; Else set the user number from (E).
;
fcGetUser:
	LDA			ParamE			; get controlling parameter.
	CPI			0FFH			; want to get user number?
	JNZ			SetUser			; No, then set it
	LDA			CurrentUser		; yes, just return it in A
	JMP			SetStatusBDOS	; exit while setting return status
	
SetUser:
	ANI			1FH				; no,just keep the low bits (000X XXXX)
	STA			CurrentUser		; and save in Current user
	RET
;
;   Function to read a random record from a file.
;
fcReadRandom:
	CALL	AutoSelect	;select proper drive and read.
	JMP	READRAN
;
;   Function to compute the file size for random files.
;
fcWriteRandom:
	CALL	AutoSelect	;select proper drive and write.
	JMP	WRITERAN
;
;   Function to compute the size of a random file.
;
fcGetFileSize:
	CALL	AutoSelect	;select proper drive and check file length
	JMP	RANSIZE
;
;   Function #37. This allows a program to log off any drives.
; On entry, set (DE) to contain a word with bits set for those
; drives that are to be logged off. The log-in vector and the
; write protect vector will be updated. This must be a M/PM
; special function.
;
fcResetDrive:
	LHLD	ParamsDE	;get drives to log off.
	MOV	A,L	;for each bit that is set, we want
	CMA		;to clear that bit in (LoggedBitMap)
	MOV	E,A	;and (ROBitMap).
	MOV	A,H
	CMA
	LHLD	LoggedBitMap	;reset the login Bit map.
	ANA	H
	MOV	D,A
	MOV	A,L
	ANA	E
	MOV	E,A
	LHLD	ROBitMap
	XCHG
	SHLD	LoggedBitMap	;and save.
	MOV	A,L	;now do the write protect vector.
	ANA	E
	MOV	L,A
	MOV	A,H
	ANA	D
	MOV	H,A
	SHLD	ROBitMap	;and save. all done.
	RET
;
;   Get here to return to the user.
;

;
;   Function #40. This is a special entry to do random i/o.
; For the case where we are writing to unused disk space, this
; space will be zeroed out first. This must be a M/PM special
; purpose function, because why would any normal program even
; care about the previous contents of a sector about to be
; written over.
;
fcWriteZeroFill:
	CALL	AutoSelect	;select proper drive.
	MVI	A,2	;use special write mode.
	STA	MODE
	MVI	C,0	;set write indicator.
	CALL	POSITN1	;position the file.
	CZ	WTSEQ1	;and write (if no errors).
	RET

;**************************************************************
;*
;*     BDOS data storage pool.
;*
;**************************************************************

CurrentUser:			DB	0		; current user number.
CurrentDrive:			DB	0		; currently active drive.
BitSetFlag:				DB	0		; flag to set(01) or reset(00) bit in disk allocation table

;
EmptyDir:				DB	EmptyFileFlag	; empty directory segment indicator.
ROBitMap:				DW	0		; write protect status for all 16 drives.
LoggedBitMap:			DW	0		; drive active word (1 bit per drive).
UsersDMA:				DW	080H	;user's dma address (defaults to 80h).
;
;   Scratch areas from parameter block.
;
FilePosInDirSegment:			DW	0	; relative position within dir segment for file (0-3).
LastTrackNumber:		DW	0	; last selected track number.
LastSectorNumber:		DW	0	; last selected sector number.
;
;   Disk storage areas from parameter block.
;
DirBuffSize				EQU	128	; buffer size
DirBuffAddr:			DW	0	;address of directory buffer to use.
DiskParamBlock:			DW	0	;contains address of disk parameter block.
CHKVECT:				DW	0	;address of check vector.
FATpointer:			DW	0	;address of allocation vector (bit map).
;
;   Disk Parameter block returned from the bios.
;
LogicalSecSize			EQU	128	; Logical sector size
SECTORS:				DW	0	;sectors per track from bios.
BLKSHFT:				DB	0	;block shift.
BLKMASK:				DB	0	;block mask.
EXTMASK:				DB	0	;extent mask.
DiskSize:				DW	0	;disk size from bios (number of blocks-1).
DrectorySize:			DW	0	;directory size, number of entries.
DirectoryFAT0:			DW	0	;storage for first bytes of bit map (dir space used).
DirectoryFAT1:			DW	0
OFFSET:					DW	0	;first usable track number.
XLATE:					DW	0	;sector translation table address.
;
;
CLOSEFLG:				DB	0	;close flag (=0ffh is extent written ok).
RDWRTFLG:				DB	0	;read/write flag (0ffh=read, 0=write).
FileFoundFlag:			DB	0	;filename found status (0=found first entry, -1 not found).
MODE:					DB	0	;I/o mode select (0=random, 1=sequential, 2=special random).
RELBLOCK:				DB	0	;relative position within fcb of block number written.
CharCounter:			DB	0	;byte counter for directory name searches.
SaveFCB:				DW	0,0	;save space for address of fcb (for directory searches).
SmallDisk:				DB	0	;if =0 then disk is > 256 blocks long.
reselectionFlag:		DB	0	;if non-zero auto select activated.
OldDrive:				DB	0	;on auto select, storage for previous drive.
fcbDisk:				DB	0	;(if non-zero auto select changed drives) Disk named in FCB.
SAVNXT:					DB	0	;storage for next record number to access.
SAVEXT:					DB	0	;storage for extent number of file.
SAVNREC:				DW	0	;storage for number of records in file.
BlockNumber:			DW	0	;block number (physical sector) used within a file or logical sector.
LOGSECT:				DW	0	;starting logical (128 byte) sector of block (physical sector).
FCBPosition:			DB	0	; relative position within buffer 0...3
FilePosInDirectory:		DW	0	; files position within directory 0....DirSize.
DirectoryRecord:		DW	0	; Directory record count. 0...DirSize/4
;
;   Disk directory buffer checksum bytes. One for each of the
; 16 possible drives.
;
CheckSumTable:
	DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;
;   Extra space ?
;
	DB	0,0,0,0
;
;**************************************************************
;*
;*        B I O S   J U M P   T A B L E
;*
;**************************************************************
;
BIOSEntry			EQU		0F600H		; start of bios

biosBoot			EQU		BIOSEntry + 000H	;  0
fcSystemReset		EQU		BIOSEntry + 003H	;  1
biosConsoleStatus	EQU		BIOSEntry + 006H	;  2
biosConsoleIn		EQU		BIOSEntry + 009H	;  3
biosConsoleOut		EQU		BIOSEntry + 00CH	;  4
fcListOut			EQU		BIOSEntry + 00FH	;  5
fcPunchOut			EQU		BIOSEntry + 012H	;  6
biosReaderIn		EQU		BIOSEntry + 015H	;  7
biosHomeDisk		EQU		BIOSEntry + 018H	;  8
biosSelectDisk		EQU		BIOSEntry + 01BH	;  9
biosSetTrack		EQU		BIOSEntry + 01EH	; 10 (A)
biosSetSector		EQU		BIOSEntry + 021H	; 11 (B)
biosSetDMA			EQU		BIOSEntry + 024H	; 12 (C)
biosReadDisk		EQU		BIOSEntry + 027H	; 13 (D)
biosWriteDisk		EQU		BIOSEntry + 02AH	; 14 (E)
biosListStatus		EQU		BIOSEntry + 02DH	; 15 (F)
biosSectorTranslate	EQU		BIOSEntry + 030H	; 16 (10)

;*
;******************   E N D   O F   C P / M   *****************
;*
CodeEnd:
		
