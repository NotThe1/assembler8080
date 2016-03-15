; testNewOS.asm
;
CodeStart:
DISPLAYMESSAGE EQU 0F6C3H
BIOS	EQU		0F600H		
		ORG 0100H

		LXI		SP, $
		MVI		C,'E'
		CALL	BIOS + (3 * 5) 
		LXI		HL, Mess1
		CALL	DISPLAYMESSAGE
		HLT
	
Mess1: DB 'Test message 1',00
	
CodeEnd: