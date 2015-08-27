;SelectDisk_0E.asm
;
;		MVI		C,0EH
;		CALL 	BDOSVector

SetUpPage0	EQU		1000H
BDOSVector	EQU		0005H
SetPage0	EQU		01000H
DefaultDiskBuffer	EQU		080H


TPA					EQU		0100H

			ORG			TPA
CodeStart:
Start:
			CALL	SetPage0					; initialize
			LXI		SP,DefaultDiskBuffer		; set the stack
			HLT

			MVI		E,00H						; set Disk 0=A, 1=B...
			MVI		C,0EH
			CALL 	BDOSVector
			
			HLT
CodeEnd:
			END
			