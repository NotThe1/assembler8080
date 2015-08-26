; BiosWriteDirectoryTest.asm
;
SELDSK				EQU		0FB2BH
SETTRK				EQU		0FB58H
SETSEC				EQU		0FB5EH
SETDMA				EQU		0FB65H
READ				EQU		0FBFBH
WRITE				EQU		0FC15H
SetPage0			EQU		01000H

WriteDirectory		EQU		01H

DefaultDiskBuffer	EQU		080H
TopOfStack			EQU		DefaultDiskBuffer

Disk				EQU		00H			; A=0, B=1, C=2, D=3
Track				EQU		00H
Sector				EQU		01H

TPA					EQU		0100H

			ORG			TPA
CodeStart:
Start:
			CALL	SetPage0					; initialize
			LXI		SP,TopOfStack				; set the stack
			MVI		C,Disk	
			CALL	SELDSK						; Set Disk
			LXI		B,Track
			CALL	SETTRK						; Set Track
			MVI		C,Sector
			CALL	SETSEC						; Set Sector
			LXI		B,DefaultDiskBuffer
			CALL	SETDMA						; Set DMA
			
			HLT
			MVI		C,WriteDirectory			; Set to write Directory
			CALL	WRITE						; do the Write
			HLT
			
Part2:
			MVI		C,Sector					; Set Sector
			CALL	SETSEC
			LXI		B,ReadBackBuffer
			CALL	SETDMA						; Set DMA
			
			HLT
			CALL	Read						; read it back into memory
			HLT

CodeEnd:
			ORG TPA + TPA
ReadBackBuffer:

END:
			