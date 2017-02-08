; BootSector.asm

CR					EQU	0DH			; Carriage Return
LF					EQU	0AH			; Line Feed
EndOfMessage		EQU	00H


DiskControlTable	EQU	0040H
DiskStatusBlock		EQU	0043H
DiskControl			EQU	0045H
CommandBlock		EQU	0046H

BDOSEntry			EQU	0E806H
BIOSStart			EQU	0F600H
WarmBootEntry		EQU	BIOSStart + 3

		ORG    0100H  
Start:
	LXI		SP,Start-1				; stack goes down from here
	CALL	SendBootMessage			; display boot message
	MVI		B,Page0End-Page0Start	; Size of code to move
	LXI		H,Page0Start			; Source of page 0 code
	LXI		D,0000					; Location 0, the target
;   Move (B) bytes from (HL) to (DE).
; Set up page zero 
HL2DE:
	MOV		A,M
	STAX	D
	INX		H
	INX		D
	DCR		B
	JNZ		HL2DE
	
; Now get start to move data to disk

	LXI		H,BootControl
	SHLD	CommandBlock			; put it into the Command block for drive A:


	LXI		H,DiskControl
	MVI		M,080H					; activate the controller 
	
WaitForBootComplete:
	MOV		A,M						; Get the control byte
	ORA		A						; is it set to 0 (Completed operation) ?
	JNZ		WaitForBootComplete		; if not try again
	          
	LDA		DiskStatusBlock			; after operation what's the status?
	CPI		080H					; any errors ?

	JNC		0000					; now do a warm boot
									; else we have a problem
	HLT
;---------------------------------------------------

BootControl:
	DB		01H						; Read function
	DB		00H						; unit number
	DB		00H						; head number
	DB		00H						; track number
	DB		0DH						; Starting sector number (13)
	DW		5 * 512					; Number of bytes to read ( 0A00 All of BIOS)
	DW		BIOSStart				; read into this address
	DW		DiskStatusBlock			; pointer to next block - no linking
	DW		DiskControlTable		; pointer to next table- no linking

;---------------------------------------------------

Page0Start:
	JMP		WarmBootEntry			; warm start
IOBYTE:             
	DB		01H						; IOBYTE- Console is assigned the CRT device
DefaultDisk:        
	DB		00H						; Current default drive (A)
	JMP	BDOSEntry					; jump to BDOS entry
	DS		028H					; interrupt locations 1-5 not used
	DS		008H					; interrupt location 6 is reserved
	JMP		0000H					; rst 7 used only by DDT & SID programs
Page0End:

;---------------------------------------------------

	
BootMessage:
	DB	CR,LF
	DB	'CP/M BootStrap'
	DB	' loader'
	DB	CR,LF,EndOfMessage
	
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