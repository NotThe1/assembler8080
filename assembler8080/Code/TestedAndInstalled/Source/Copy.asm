;Copy.asm
;    sample file-to-file copy program
;    at the ccp level, the command;	copy a:x.y b:u.v

boot	EQU	0000h				; system reboot 
bdos	EQU	0005h				; bdos entry point 
fcb1	EQU	005ch				; first file name    
sfcb	EQU	fcb1				; source fcb  
fcb2	EQU	006ch				; second file name 
dbuff	EQU	0080h				; default buffer 
tpa	EQU	0100h				; beginning of tpa; 
printf	EQU	9				; print buffer func# 
openf	EQU	15				; open file func# 
closef	EQU	16				; close file func# 
deletef	EQU	19				; delete file func# 
readf	EQU	20				; sequential read func# 
writef	EQU	21				; sequential write
makef	EQU	22				;   make file func#	
; 


	ORG	tpa				; beginning of tpa 
CodeStart:
	LXI	SP,stack				; set local stack 
	MVI	C,16				; half an fcb 
	LXI	D,fcb2				; source of move 
	LXI	H,dfcb				; destination fcb 
MoveFCB:
	LDAX	D				; source fcb 
	INX	D				; ready next 
	MOV	M,A				; dest fcb 
	INX	H				; ready next 
	DCR	C				; count 16...0 
	JNZ	MoveFCB				; loop 16 times
; name has been removed, zero cr 
	XRA	A				; a = 00h 
	STA	dfcbcr				; current rec = 0
; source and destination fcb's ready 
	LXI	D,sfcb				; source file 
	CALL	OpenFile				; error if 255 
	LXI	D,nofile				; ready message 
	INR	A				; 255 becomes 0 
	CZ	ExitProgram				; done if no file
; source file open, prep destination 
	LXI	D,dfcb				; destination 
	CALL	DeleteFile				; remove if present
	LXI	D,dfcb				; destination 
	CALL	MakeFile				; create the file 
	LXI	D,nodir				; ready message 
	INR	A				; 255 becomes 0 
	CZ	ExitProgram				; done if no dir space
;
;    source file open, dest file open
;    copy until end of file on source
;
Copy:
	LXI	D,sfcb				; source 
	CALL	Read				; read next record 
	ORA	A				; end of file? 
	JNZ	EndOfFile				; skip write if so
; not end of file, write the record 
	LXI	D,dfcb				; destination 
	CALL	Write				; write the record 
	LXI	D,space				; ready message 
	ORA	A				; 00 if write ok 
	CNZ	ExitProgram				; end if so 
	JMP	Copy				; loop until eof
;
EndOfFile:
; end of file, close destination 
	LXI	D,dfcb				; destination 
	CALL	CloseFile				; 255 if error 
	LXI	H,wrprot				; ready message 
	INR	A				; 255 becomes 00 
	CZ	ExitProgram				; shouldn't happen
; Copy operation complete, end 
	LXI	D,normal				; ready message
;
ExitProgram:
; write message given in de, reboot 
	MVI	C,printf 
	CALL	bdos				; write message 
	JMP	boot				; reboot system
;
;    system interface subroutines
;    (all return directly from bdos)
; 
OpenFile:
	MVI	C,openf 
	JMP	bdos
; 
CloseFile:
	MVI	C,closef 
	JMP	bdos
; 
DeleteFile:
	MVI	C,deletef 
	JMP	bdos
;
Read:
	MVI	C,readf 
	JMP	bdos
; 
Write:
	MVI	C,writef 
	JMP	bdos
; 
MakeFile: 
	MVI	C,makef 
	JMP	bdos
;
; console messages 
nofile:   DB	'no source file$' 
nodir:    DB	'no directory space$' 
space:    DB	'out of dat space$' 
wrprot:	DB	'Write protected?$' 
normal:	DB	'Copy complete$'
;
;    data areas 
dfcb:	DS	32				; destination fcb 
dfcbcr:   EQU	dfcb + 32				; current record
; 
	DS	32				; 16 level stack
stack: 

CodeEnd: