; sec13.asm
;
BDOS	EQU		005H

	ORG 0100H
	
	LXI		SP,1000H
	LXI		DE,MyFCB
	MVI		C,0FH			; open file
	CALL	BDOS
	
	MVI		B,29H
	PUSH	BC
Loop:
	POP		BC
	DCR		B
	JZ		EndLoop
	PUSH	BC
	MVI		E,58H
	MVI		C,02
	CALL	BDOS
	CALL	ReadSeq
	JMP		Loop
	

EndLoop:
	CALL	ReadSeq
	
	LXI		DE,MyFCB
	MVI		C,10			; close file
	CALL	BDOS
	
	JMP		0000				; warm boot
	
ReadSeq:
	LXI		DE,MyFCB
	MVI		C,14H		; Read seq
	CALL	BDOS
	Ret;
	

MyFCB:
	DB		00
	DB		'TEST'
	DB		'    '
	DB		'TST'

	ORG		0200H
	
MyBuff:
	DS		200H