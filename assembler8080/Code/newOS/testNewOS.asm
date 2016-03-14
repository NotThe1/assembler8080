; testNewOS.asm
;
CodeStart:
DISPLAYMESSAGE EQU 0F6C3H
	ORG 0100H

	LXI	SP, $
	LXI	HL, Mess1
	CALL DISPLAYMESSAGE
	HLT
	
Mess1: db 'Test message 1',00
	
CodeEnd: