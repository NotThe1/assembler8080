; ROM3HD.asm
; Rom for bios set up for diskA to be 3.5HD (1.44MB) disk

DiskStatusBlock		EQU	0043H
DiskControl			EQU	0045H
CommandBlock		EQU	0046H
DiskControlTable	EQU	0040H

PhysicalSectorSize	EQU	512			; actual disk sector size
TPA					EQU	0100H

	ORG		0000
CodeStart:
	LXI		HL,ROMControl
	SHLD	CommandBlock			; put it into the Command block for drive A:


	LXI		H,DiskControl
	MVI		M,080H					; activate the controller 
	
WaitForBootComplete:
	MOV		A,M						; Get the control byte
	ORA		A						; is it set to 0 (Completed operation) ?
	JNZ		WaitForBootComplete		; if not try again
	          
	LDA		DiskStatusBlock			; after operation what's the status?
	CPI		080H					; any errors ?

	JNC		TPA						; now execute the boot loader
	HLT
;---------------------------------------
ROMControl:
	DB	01H							; Read function
	DB	00H							; unit number
	DB	00H							; head number
	DB	00H							; track number
	DB	01H							; Starting sector number ()
	DW	PhysicalSectorSize			; Number of bytes to read ( 1 Sector)
	DW	TPA							; read into this address
	DW	DiskStatusBlock				; pointer to next block - no linking
	DW	DiskControlTable			; pointer to next table- no linking
CodeEnd: