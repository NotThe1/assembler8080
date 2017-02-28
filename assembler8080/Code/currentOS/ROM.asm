; ROM.asm
; Rom for bios set up for diskA to be 3.5HD (1.44MB) disk


	$Include ./osHeader.asm
	$Include ./diskHeader.asm

	ORG		0000
	
CodeStart:
	LXI		HL,ROMControl	
	SHLD	DiskCommandBlock			; put it into the Command block for drive A:
	
	
	LXI		H,DiskControlByte	
	MVI		M,080H						; activate the controller 
		
WaitForBootComplete:	
	MOV		A,M							; Get the control byte
	ORA		A							; is it set to 0 (Completed operation) ?
	JNZ		WaitForBootComplete			; if not try again
				
	LDA		DiskStatusLocation			; after operation what's the status?
	CPI		080H						; any errors ?
	
	JNC		TPA							; now execute the boot loader
	HLT
;---------------------------------------
ROMControl:
	DB		DiskReadCode				; Read function
	DB		00H							; unit number
	DB		00H							; head number
	DB		00H							; track number
	DB		01H							; Starting sector number ()
	DW		diskSectorSize				; Number of bytes to read ( 1 Sector)
	DW		TPA							; read into this address
	DW		DiskStatusLocation			; pointer to next block - no linking
	DW		DiskControlTable			; pointer to next table- no linking
CodeEnd: