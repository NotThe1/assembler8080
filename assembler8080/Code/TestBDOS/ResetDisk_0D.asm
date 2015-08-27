;ResetDisk_0D.asm
;
;		MVI		C,0DH
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

			MVI		C,0DH
			CALL 	BDOSVector
			
			HLT
CodeEnd:
			END
			