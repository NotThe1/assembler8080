; BiosWriteTest.asm
;
SELDSK				EQU		0FB2BH
SETTRK				EQU		0FB58H
SETSEC				EQU		0FB5EH
SETDMA				EQU		0FB65H
Read				EQU		0FBFBH
WRITE				EQU		0FC15H
WRITEDIR			EQU		01H

DefaultDiskBuffer	EQU		080H
TopOfStack			EQU		DefaultDiskBuffer
Disk				EQU		00H			; A=0, B=1, C=2, D=3
Track				EQU		00H
Sector				EQU		01H

TPA					EQU		0100H

			ORG			TPA
CodeStart:
Start:
			LXI		SP,TopOfStack				; set the stack
			MVI		C,Disk
			CALL	SELDSK
			LXI		B,Track
			CALL	SETTRK
			MVI		C,Sector
			CALL	SETSEC
			LXI		B,DefaultDiskBuffer
			CALL	SETDMA
			
			HLT
			MVI		C,WRITEDIR
			CALL	WRITE
			HLT
			
Part2:
			MVI		C,Sector + 1
			CALL	SETSEC
			LXI		B,DefaultDiskBuffer
			CALL	SETDMA
			
			HLT
			CALL	WRITE
			HLT
Part2:
			MVI		C,Sector + 12
			CALL	SETSEC
			LXI		B,DefaultDiskBuffer
			CALL	SETDMA
			
			HLT
			CALL	READ
			HLT
CodeEnd:
END:
			