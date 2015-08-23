* base for clearing stack and setting up SP
TOS	EQU 0200H		; top of stack
	org 0300H
	
CodeStart:
	LXI	SP,TOS		; make sure it set
	MVI A,0FFH		; size to clear for the stack
	LXI HL,TOS	;* bottom of the stack
LOOP:				; Label
	MVI	M,00H		; store zero in memory
	DCX H			; decrement the pointer	
	DCR A
	JNZ LOOP
	LXI	SP,TOS
	HLT
CodeEnd:
	END