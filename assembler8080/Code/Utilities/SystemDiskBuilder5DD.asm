;SystemDiskBuilder.asm
;
; the actual boot sector code starts at Location 0100.
;
; SystemDiskBuilder program starts at location 0200
;
; Track 0                       Sector
;          1      2      3      4      5     6       7     8      9
;Head  +------+------+------+------+------+------+------+------+-------+
;  0   | BOOT |<========== CCP ==========>|<========== BDOS ==========>|
;   1  +------+------+------+------+------+------+------+------+-------+
;      |<====== BDOS ======>|<================= BIOS =================>|
;      +------+------+------+------+------+------+------+------+-------+
;          1      2      3      4      5     6       7     8      9


DiskStatusBlock	EQU	0043H
DiskControl	EQU	0045H
CommandBlock	EQU	0046H


CCPStart		EQU	0E000H
BDOSEntry		EQU	0E806H
DiskControlTable	EQU	0040H
;CommandBlock	EQU	0046H
BIOSStart		EQU	0F600H
WarmBootEntry	EQU	BIOSStart +3
EnterCPM		EQU	0F840h

CR		EQU	0DH			; Carriage Return
LF		EQU	0AH			; Line Feed
EndOfMessage	EQU	00H

PhysicalSectorSize	EQU	512			; actual disk sector size
FCBsize		EQU	32			; each Directory 
DirectorySize	EQU	8 * PhysicalSectorSize	; size of the whole directory
DirectoryEntries	EQU	DirectorySize/FCBsize	; number of enties in the whole directory
EmptyCode		EQU	0E5H

CodeStart:

	ORG	0100H
Start:
	LXI	SP,Start-1			; stack goes down from here
	CALL	SendBootMessage			; display boot message
	MVI	B,Page0End-Page0Start		; Size of code to move
	LXI	H,Page0Start			; Source of page 0 code
	LXI	D,0000				; Location 0, the target
;   Move (B) bytes from (HL) to (DE).
HL2DE:
	MOV	A,M
	STAX	D
	INX	H
	INX	D
	DCR	B
	JNZ	HL2DE

	LXI	H,BootControl
	SHLD	CommandBlock			; put it into the Command block for drive A:


	LXI	H,DiskControl
	MVI	M,080H				; activate the controller 
	
WaitForBootComplete:
	MOV	A,M				; Get the control byte
	ORA	A				; is it set to 0 (Completed operation) ?
	JNZ	WaitForBootComplete			; if not try again
	          
	LDA	DiskStatusBlock			; after operation what's the status?
	CPI	080H				; any errors ?

	JNC	0000				; now do a warm boot
						; else we have a problem
	HLT
;---------------------------------------------------

BootControl:
	DB	01H				; Read function
	DB	00H				; unit number
	DB	01H				; head number
	DB	00H				; track number
	DB	04H				; Starting sector number ()
	DW	5 * 512				; Number of bytes to read ( rest of the head)
	DW	BIOSStart				; read into this address
	DW	DiskStatusBlock			; pointer to next block - no linking
	DW	DiskControlTable			; pointer to next table- no linking

;---------------------------------------------------

Page0Start:
	JMP	WarmBootEntry			; warm start
IOBYTE:             
	DB	01H				; IOBYTE- Console is assigned the CRT device
DefaultDisk:        
	DB	00H				; Current default drive (A)
	JMP	BDOSEntry				; jump to BDOS entry
	DS	028H				; interrupt locations 1-5 not used
	DS	008H				; interrupt location 6 is reserved
	JMP	0000H				; rst 7 used only by DDT & SID programs
Page0End:

;---------------------------------------------------

	
BootMessage:
	DB	CR,LF
	DB	'CP/M BootStrap'
	DB	' loader'
	DB	CR,LF,EndOfMessage
	
SendBootMessage:
	LXI	H,BootMessage
SendMessage1:
	MOV	A,M
	ORA	A
	RZ
	OUT	01
	INX	H
	JMP	SendMessage1
	

;---------------------------------------------------
;---------------System Builder---------------------
;---------------------------------------------------
	

	ORG	($ / 0100H + 1)	* 0100H		; past the first sector - write boot record out
;	ORG	0200H				; past the first sector - write boot record out
	
;---------------------------------------------------
 

Begin:	
	LXI	SP,Start-1			; stack goes down from here
; write the boot sector	
	LXI	H,WriteCommand1
	CALL	DoWrite
	LXI	H,WriteMessage1
	CALL	SendMessage1
; write the CCP & start of BDOS
	LXI	H,WriteCommand2
	CALL	DoWrite
	LXI	H,WriteMessage2
	CALL	SendMessage1
; Write the rest of BDOS
	LXI	H,WriteCommand3
	CALL	DoWrite
	LXI	H,WriteMessage3
	CALL	SendMessage1
;---------------------------------------------------	
; now we need to address the dirctory 	
	CALL	ClearImages			; clear the image work area
	CALL	SetUpDirectory			; put EmptyCode in all the directory entries 
	JMP	0000H				; JMP EnterCPM 

;///// 	
; Write the Directory 
	HLT
	LXI	H,WriteCommand4
	CALL	DoWrite
	LXI	H,WriteMessage4
	CALL	SendMessage1
;	HLT					; temp, until the system is working fully
	JMP	0000H				; JMP EnterCPM  	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; HL points to command block to use
DoWrite:
	SHLD	CommandBlock			; put it into the Command block for drive A:

	LXI	H,DiskControl
	MVI	M,080H				; activate the controller 
	
WaitForWriteComplete:
	MOV	A,M				; Get the control byte
	ORA	A				; is it set to 0 (Completed operation) ?
	JNZ	WaitForWriteComplete		; if not try again
	
	LDA	DiskStatusBlock			; after operation what's the status?
	CPI	080H				; any errors ?
	RNC					; return if no errors
; else we have a problem	
	LXI	H,ErrorMessage
	CALL	SendMessage1			; Send 	eroor message
	HLT
	; and stop
;---------------------------------------------------	
ClearImages:
	LXI	B,DirectorySize  + 1
	LXI	H,DirectoryImage
ClearImages1:				
	MVI	M,0				; clear out the location
	INX	H				; point at the next location
	DCX	B				; count down
	MOV	A,C				; get lo byte
	ORA	B				; AND with Hi byte 
	JNZ	ClearImages1			; keep going if both (B) and (C) not 0
	RET					; we are done
	
SetUpDirectory:
	LXI	H,DirectoryImage
	LXI	D,FCBsize
	LXI	B,DirectoryEntries
SetUpDirectory1:
	MVI	M,EmptyCode			; put in the empty entry flag
	DAD	D				; point at next directory entry
	DCX	B				; count down
	MOV	A,C				; get lo byte
	ORA	B				; AND with Hi byte 
	JNZ	SetUpDirectory1			; keep going if both (B) and (C) not 0
	
;	LXI	H,FATImage			; point at the File Allocation Table
;	MVI	M,0C0H				; allocate the firt two Blocks
	RET					; we are done		
;---------------------------------------------------
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++	
; write the boot sector	
WriteCommand1:
	DB	02H					; Write function
	DB	00H					; unit number
	DB	00H					; head number
	DB	00H					; track number
	DB	01H					; Starting sector number (First one)
	DW	1 * 512					; Number of bytes to write (Boot sector)
	DW	Start					; write from this address
	DW	DiskStatusBlock				; pointer to next block - no linking
	DW	DiskControlTable				; pointer to next table- no linking
;---------------------------------------------------
; write the CCP & start of BDOS
WriteCommand2:
	DB		02H				; Write function
	DB		00H				; unit number
	DB		00H				; head number
	DB		00H				; track number
	DB		02H				; Starting sector number (after boot sector)
	DW		8 * 512				; Number of bytes to write (rest of head)
	DW		CCPStart				; write from this address
	DW		DiskStatusBlock			; pointer to next block - no linking
	DW		DiskControlTable			; pointer to next table- no linking	
;---------------------------------------------------
; Write the rest of BDOS	
WriteCommand3:
	DB	02H					; Write function
	DB	00H					; unit number
	DB	01H					; head number
	DB	00H					; track number
	DB	01H					; Starting sector number (First one)
	DW	8 * 512					; Number of bytes to write (Boot sector)
	DW	CCPStart + (8*512)				; write from this address
	DW	DiskStatusBlock				; pointer to next block - no linking
	DW	DiskControlTable				; pointer to next table- no linking
;---------------------------------------------------
; Write Directory image - all entries show deleted file	
WriteCommand4:
	DB	02H					; Write function
	DB	00H					; unit number
	DB	00H					; head number
	DB	01H					; track number
	DB	01H					; Starting sector number (First one)
	DW	8 * 512					; Number of bytes to write (All sectors in Head 0, Track 1)
	DW	DirectoryImage				; write from this address
	DW	DiskStatusBlock				; pointer to next block - no linking
	DW	DiskControlTable				; pointer to next table- no linking
;---------------------------------------------------

ErrorMessage:
	DB	CR,LF
	DB	'Bad Write '
ErrorCount:         
	DB	' 1'
	DB	CR,LF,EndOfMessage
;---------------------------------------------------
WriteMessage1:
	DB	CR,LF
	DB	'The Boot Sector'
	DB	' has been written'
	DB	CR,LF,EndOfMessage
;---------------------------------------------------
WriteMessage2:
	DB		CR,LF
	DB		'CCP & BDOS'
	DB		' has been written'
	DB		CR,LF,EndOfMessage
;---------------------------------------------------
WriteMessage3:
	DB	CR,LF
	DB	'Rest of BDOS'
	DB	' has been written'
	DB	CR,LF,EndOfMessage
;---------------------------------------------------
WriteMessage4:      
	DB	CR,LF
	DB	'Directory'
	DB	' has been written'
	DB	CR,LF,EndOfMessage
;---------------------------------------------------
	ORG	($ / 0100H + 1) * 0100H		;Make it easier to track in memory
DirectoryImage:
	DS	DirectorySize

;---------------------------------------------------
CodeEnd: