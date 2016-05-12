;tstDiag1.asm
;

$Include ../Headers/stdHeader.asm
;BIOS	EQU	0F600H
;BDOSEntry	EQU	0E806H
BDOS	EQU	0005H
WarmBoot	EQU	0000H

bcPrintString	EQU	09H			; Print String
bcResetSystem	EQU	0DH			; Reset Disk System
bcSelectDisk	EQU	0EH			; Select Disk System
bcOpenFile	EQU	0FH			; Open file function 	
bcCloseFile	EQU	10H			; Close file function 	
bcDeleteFile	EQU	13H			; Delete file function
bcReadSeq		EQU	14H			; Read Sequentioal 	
bcWriteSeq	EQU	15H			; Write Sequentioal 	
bcMakeFile	EQU	16H			; Make file function
bcSetDMA		EQU	1AH			; Set DMA
bcReadRandom	EQU	21H			; Read random record 	
bcWriteRandom	EQU	22H			; Write random record 
bcGetFileSize	EQU	23H			; Compute File Size
bcSetRandomRecord	EQU	24H			; Set Random Record	


	ORG	0100H
CodeStart:

Start:                    
	LXI	SP, $
	LXI	H,WarmBoot			; standard procedure
	DAD	SP				; for orderly return
	SHLD	ccpStackSave			; to CCP

	LXI	DE, msgBegin
	CALL	SendMessage
;
	CALL	SetUp
;	CALL	Test1				; playing with Random IO
	CALL	Test1				; playing with Random IO
	CALL	Cleanup
;	
	LXI	DE, msgOK
	CALL	SendMessage
	JMP	WarmBoot				; Exit to CCP
;------------------------------------------------------------------------------
Test1:
	MVI	B,00H
Test1A:
	DCR	B
	JZ	Test1B				; Done with the loop
	PUSH	BC				; save counter
	
	
;	LHLD	Random1				; get the last record number
;	INX	HL
;	SHLD	Random1				; point at next record
;	SHLD	Random2				; point at next record

	MOV	C,B				; set character to counter
	MVI	B,80H				; set count to 0100H
	CALL	FillBuffer1			; fill with iteration count
	
	CALL	Buff2CMABuff1			; fill buuf2 with buff1's complement
	

	LXI	DE,Buffer1
	MVI	C,bcSetDMA
	CALL	BDOS				; set DMA to Buffer1
	
	
	LXI	DE,File1FCB
;	MVI	C,bcWriteRandom
	MVI	C,bcWriteSeq
	CALL	BDOS

	LXI	DE,Buffer2
	MVI	C,bcSetDMA
	CALL	BDOS				; set DMA to Buffer2
	
	LXI	DE,File2FCB
;	MVI	C,bcWriteRandom
	MVI	C,bcWriteSeq
	CALL	BDOS
	
	POP	BC
	JMP	Test1A
Test1B:
	CALL	CloseBothFiles
	CALL	ClearBuffer1
	CALL	ClearBuffer2
;--- start the reads	
Test1C:
	CALL	OpenBothFiles			; get back to start of the file

	LXI	DE,Buffer1
	MVI	C,bcSetDMA
	CALL	BDOS				; set DMA to Buffer1
	
	
	LXI	DE,File1FCB
;	MVI	C,bcWriteRandom
	MVI	C,bcReadSeq
	CALL	BDOS

	LXI	DE,Buffer2
	MVI	C,bcSetDMA
	CALL	BDOS				; set DMA to Buffer2
	
	LXI	DE,File2FCB
;	MVI	C,bcWriteRandom
	MVI	C,bcReadSeq
	CALL	BDOS
		
		
	RET
	
	

;==============================================================================

Cleanup:
	CALL	CloseBothFiles			; close the files before exiting
	RET
;---------------------------
OpenBothFiles:
	LXI	DE,msgFile1Open			; tell what file is being worked on
	CALL	SendMessage
	LXI	DE,File1FCB
	CALL	OpenFile				; Close File1.Dat
	
	LXI	DE,msgFile2Open			; tell what file is being worked on
	CALL	SendMessage
	LXI	DE,File2FCB
	CALL	OpenFile				; Open File1.Dat

	RET
;---------
OpenFile:
	MVI	C,bcOpenFile
	CALL	BDOS
	LXI	DE,msgFileOpened
	CPI	-1
	JNZ	OpenFile1
	LXI	DE,msgFileNotFound
OpenFile1:					
	CALL	SendMessage
	RET
;---------------------------
;---------------------------
CloseBothFiles:
	LXI	DE,msgFile1Close			; tell what file is being worked on
	CALL	SendMessage
	LXI	DE,File1FCB
	CALL	CloseFile				; Close File1.Dat
	
	LXI	DE,msgFile2Close			; tell what file is being worked on
	CALL	SendMessage
	LXI	DE,File2FCB
	CALL	CloseFile				; Close File1.Dat

	RET
;---------
CloseFile:
	MVI	C,bcCloseFile
	CALL	BDOS
	LXI	DE,msgFileClosed
	CPI	-1
	JNZ	CloseFile1
	LXI	DE,msgFileNotFound
CloseFile1:					
	CALL	SendMessage
	RET
;----------------------------------
SetUp:
	MVI	C,bcResetSystem
	CALL	BDOS
		
	LXI	DE,msgFile1Make			; tell what file is being worked on
	CALL	SendMessage
	LXI	DE,File1FCB
	CALL	InitFile				; se up File1.Dat
	
	LXI	DE,msgFile2Make			; tell what file is being worked on
	CALL	SendMessage
	LXI	DE,File2FCB
	CALL	InitFile				; se up File1.Dat
			
	RET					; exit
;--------
InitFile:
	PUSH	DE				; save the FCB
	MVI	C,bcDeleteFile
	CALL	BDOS				; delete it if there
	LXI	DE,msgNoFile
	CPI	-1
	JZ	NoFile				; skip there was no file1
	LXI	DE,msgWasFile	
NoFile:
	CALL	SendMessage			; tell if file was/not there
	POP	DE				; get the FCB again
;	LXI	DE,File1FCB
	MVI	C,bcMakeFile
	CALL	BDOS
	LXI	DE,msgMadeFile
	CPI	-1
	JZ	FileNotMade
	CALL	SendMessage
		
	RET					; exit alls OK
FileNotMade:	
	LXI	DE,msgMadeFileNot
	CALL	SendMessage
	JMP	WarmBoot				; return to CCP
;=========================================================================
;==============================Utilities==================================
;=========================================================================
CRLF:
	LXI	DE,msgCRLF
;-----
SendMessage:
	MVI	C,bcPrintString
	CALL	BDOS				; send CrLf messsage
	RET
;--------------------------------------------------------------------------
Buff2CMABuff1:
	MVI	B,00H				; buffer size = 0100H
	LXI	HL,Buffer1
	LXI	DE,Buffer2	
Buff2CMABuff1A:
	MOV	A,M				; get byte from Buuf1
	CMA					; Flip the bits
	STAX	DE				; put the result into buffer2
	INX	DE
	INX	HL
	DCR	B
	RZ					; exit when done
	JMP	Buff2CMABuff1A			; else loop
ClearBuffer2:
	LXI	BC,0000H				; 0100H Zeros
	LXI	HL,Buffer2
	JMP	FillHLwithCforBbytes
ClearBuffer1:
	LXI	BC,0000H				; 0100H Zeros
FillBuffer1:
	LXI	HL,Buffer1
	JMP	FillHLwithCforBbytes
FillBuffer2:
	LXI	HL,Buffer2	
FillHLwithCforBbytes:				; B = 00 fills 0100H bytes
	MOV	M,C				; get value into target
	INX	HL				; increment the pointer
	DCR	B
	JNZ	FillHLwithCforBbytes		; Loop if not done
	RET					; else exit
	
;=========================================================================
;==============================  Data   ==================================
;=========================================================================
File1FCB:
	DB	0,'FILE1   DAT'
	DS	32H
Random1	EQU	File1FCB + 33
Overflow1	EQU	File1FCB + 35

File2FCB:
	DB	0,'FILE2   DAT'
	DS	32H
Random2	EQU	File2FCB + 33
Overflow2	EQU	File2FCB + 35



msgBegin:		DB	'Starting Diag1.asm.',CR,LF,CR,LF,DOLLAR
msgOK:		DB	CR,LF,'Exiting  Diag1.asm.',CR,LF,DOLLAR
msgCRLF:		DB	CR,LF,DOLLAR
msgFile1Make:	DB	'Makeing File1.Dat',CR,LF,DOLLAR
msgFile2Make:	DB	'Makeing File2.Dat',CR,LF,DOLLAR
msgFile1Close:	DB	CR,LF,'Closing File1.Dat',CR,LF,DOLLAR
msgFile2Close:	DB	CR,LF,'Closing File2.Dat',CR,LF,DOLLAR
msgFile1Open:	DB	CR,LF,'Opening File1.Dat',CR,LF,DOLLAR
msgFile2Open:	DB	CR,LF,'Opening File2.Dat',CR,LF,DOLLAR

msgNoFile:	DB	'    No file to delete',CR,LF,DOLLAR
msgWasFile:	DB	'    File was sucessfully deleted',CR,LF,DOLLAR
msgMadeFile:	DB	'    File was sucessfully Created',CR,LF,DOLLAR
msgMadeFileNot:	DB	'    File Not Created !!!',CR,LF,DOLLAR

msgFileOpened:	DB	'    File was successfully opened',CR,LF,DOLLAR
msgFileClosed:	DB	'    File was successfully closed',CR,LF,DOLLAR
msgFileNotFound:	DB	'    File was NOT found!',CR,LF,DOLLAR


ccpStackSave:	DW	0000H			; orderly exit

Buffer1:
		DS	256
Buffer2:
		DS	256
ZZZ:



;------------------------------------------

CodeEnd:
