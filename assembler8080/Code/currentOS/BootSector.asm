; BootSector.asm

; 2017-03-02 Refactored the CP/M Suite

	$Include ./stdHeader.asm
	$Include ./osHeader.asm
	$Include ./diskHeader.asm


WarmBootEntry	EQU		BIOSStart + 3

		ORG    TPA
Start:
	LXI		SP,Start-1						; stack goes down from here
	CALL	SendBootMessage					; display boot message
	MVI		B,Page0ImageEnd-Page0Image		; Size of code to move
	LXI		H,Page0Image					; Source of page 0 code
	LXI		D,0000							; Location 0, the target

; Set up page zero,Move (B) bytes from (HL) to (DE).

HL2DE:
	MOV		A,M
	STAX	D
	INX		H
	INX		D
	DCR		B
	JNZ		HL2DE

; Now  start to move data to Disk Control Block

	LXI		H,BootControl
	SHLD	DiskCommandBlock				; put it into the Command block for drive A:


	LXI		H,DiskControlByte
	MVI		M,080H							; activate the controller

WaitForBootComplete:
	MOV		A,M								; Get the control byte
	ORA		A								; is it set to 0 (Completed operation) ?
	JNZ		WaitForBootComplete				; if not try again

	LDA		DiskStatusLocation				; after operation what's the status?
	CPI		080H							; any errors ?

	JNC		0000							; now do a warm boot
											; else we have a problem
	HLT
;---------------------------------------------------

BootControl:
	DB		DiskReadCode					; Read function
	DB		00H								; unit number
	DB		00H								; head number
	DB		00H								; track number
	DB		0DH								; Starting sector number (13)
	DW		5 * 512							; Number of bytes to read ( 0A00 All of BIOS)
	DW		BIOSStart						; read into this address
	DW		DiskStatusLocation				; pointer to next block - no linking
	DW		DiskControlTable				; pointer to next table- no linking

;---------------------------------------------------

Page0Image:
	JMP		WarmBootEntry					; warm start
;IOBYTE:
	DB		01H								; IOBYTE- Console is assigned the CRT device
DefaultDisk:
	DB		00H								; Current default drive (A)
	JMP	BDOSEntry							; jump to BDOS entry
	DS		028H							; interrupt locations 1-5 not used
	DS		008H							; interrupt location 6 is reserved
	JMP		0000H							; rst 7 used only by DDT & SID programs
Page0ImageEnd:

;---------------------------------------------------


BootMessage:
	DB		CR,LF
	DB		'CP/M 2.2 BootStrap'
	DB		' loader'
	DB		CR,LF,
	DB		'Build '
	DB		'1.10  : 1.0 - 1.1 - 1.2'
	DB		CR,LF,EndOfMessage

SendBootMessage:
	LXI		H,BootMessage
SendMessage1:
	MOV		A,M
	ORA		A
	RZ
	OUT		01
	INX		H
	JMP		SendMessage1


;---------------------------------------------------