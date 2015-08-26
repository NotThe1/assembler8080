;TestBDOSEntry.asm

BDOSVector	EQU		0005H;
SetPage0	EQU		01000H;

			ORG		0100H

CodeStart:
Start:
			LXI		SP, SetPage0		; Set stack just below SetPage0
			CALL	SetPage0			; make page zero clen
			LXI		HL,0AABBH			; just some dummy value
			LXI		DE,07FF7H
			MVI		B,055H
			
			MVI		C,0DH				; disk reset
			HLT
			
			CALL	BDOSVector			; make call
			HLT
			HLT
CodeEnd:
			END