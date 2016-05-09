; Random.asm

;                             
reboot	EQU	0000H		; system reboot 
bdos	EQU	0005H		; bdos entry point
coninp	EQU	1		; console input function 
conout	EQU	2		; console output function 
pstring	EQU	9		; print string function 
rstring	EQU	10		; read console buffer 
version	EQU	12		; retrun version nmber 
openf	EQU	15		; file open function 
closef	EQU	16		; close function 
makef	EQU	22		; make file function 
readr	EQU	33		; read random 
writer	EQU	34		; write random
fcb	EQU	005CH		; default file control block 
ranrec	EQU	fcb + 33		; random record position 
ranovf	EQU	fcb + 35		; high order (overflow)
                              
buff	EQU	0080H		; buffer address
                              
CR		EQU	0DH		; CARRIAGE RETURN 
LF		EQU	0AH		; LINE FEED
SPACE		EQU	20H		; Space
ASCII_ZERO	EQU	'0'		; the number 0
ASCII_Q		EQU	'Q'
ASCII_R		EQU	'R'
ASCII_LO_A	EQU	'a'
TPA		EQU	0100H		; Trasient Program Area

	ORG	TPA

CodeStart:

;
; load sp, set-up file for random access
; 
	LXI     SP,stack
;
; version 2.0 
	MVI	C,version 
	CALL	bdos 
	CPI	20H
; version 2.0 or better? 
	JNC	VersionOK
; bad version, message and go back

	LXI	DE,badver
	CALL	PrintBuff
	JMP	reboot
;                
VersionOK:					; versok:
; correct version for random access 
	MVI	C,openf				; open default fcb 
	LXI	DE,fcb
	CALL	bdos
	INR	A				; err 255 becomes zero
	JNZ	Ready
					; cannot open file, so create it 
	MVI	C,makef
	LXI	DE,fcb
	CALL	bdos
	INR	A				; err 255 becomes zero 
	JNZ	Ready
					; cannot create file, directory full 
	LXI	DE,nospace
	CALL	PrintBuff
	JMP	reboot				; back tp CCP

; loop back to ready after each read command
Ready:						; ready:
						; file is ready for processing
	CALL	ReadCommand				; read next command 
	SHLD	ranrec				; store input record # 
	LXI	HL,ranovf
	MVI	M,0				; clear high byte if set
	CPI	ASCII_Q				; Quit?
	JNZ	NotQuitCommand
; quit processing, close file
	MVI	C,closef
	LXI	DE,fcb
	CALL	bdos

	INR	A				; err 255 becomes 0
	JZ	Error				; error message, retry
	JMP	reboot				; back to ccp
;
; end of command, process write
;
NotQuitCommand:					; notq:
; not the quit command, random write?
	LXI	DE,datmsg
	CALL	PrintBuff				; data prompt
	MVI	C,127				; up to 127 characters
	LXI	HL,buff				; destination
; read next character to buff
CharRead:						; rloop:
	PUSH	BC				; save counter
	PUSH	HL				; next destination
	CALL	GetChar				; character to a
	POP	HL				; RESTORE COUNTER
	POP	BC				; resore next to fill
	CPI	CR				; end of line?
	JZ	CharReadEnd
; not end, store character
	MOV	M,A
	INX	HL				; next to fill
	DCR	C				; counter goes down
	JNZ	CharRead				; end of buffer?
CharReadEnd:					; erloop:
; end of read loop, store 00
	MVI	M,0
;
;	write the record to selected record number
	MVI	C,writer
	LXI	DE,fcb
	CALL	bdos
	ORA	A				; error code zero?
	JNZ	Error				; message if not
	JMP	Ready				; for another record

;
; end of write command, process read
;
notw:
; not a write command, read record?
	CPI	ASCII_R
	JNZ	Error				; skip if not
;
; read random record
	MVI	C,readr
	LXI	DE,fcb
	CALL	bdos
	ORA	A				; return code 00?
	JNZ	Error
;
; read was successful, write to console
	CALL	CrLf				; new line
	MVI	C,128				; max 128 characters
	LXI	HL,buff				; next to get
WriteToConsole:					; wloop:
	MOV	A,M				; next character
	INX	HL				; next to get
	ANI	07FH				; mask parity
	JZ	Ready				; for another command if 00
	PUSH	B				; save counter
	PUSH	H				; save next to get
	CPI	SPACE				; graphic?
	CNC	PutChar				; skip output if not
	POP	H
	POP	B
	DCR	C				; count=count-1
	JNZ	WriteToConsole
	JMP	Ready 
;
;	end of read command, all errors end up here
;
Error:
	LXI	DE,errmsg
	CALL	PrintBuff
	JMP	Ready

GetChar:						; getchr:
; read next console character to a
	MVI	C,coninp
	CALL	bdos
	RET 
;
PutChar:						; putchr:
; write character from a to console
	MVI	C,conout
	MOV	E,A				; char to send
	CALL	bdos				; send char
	RET
;
CrLf:						; crlf:
; send carriage return, line feed
	MVI	A,CR				; carriage return
	CALL	PutChar
	MVI	A,LF				; line feed
	CALL	PutChar
	RET
; 
PrintBuff:					; print  print the buffer addressed by de until $
	PUSH	DE
	CALL	CrLf
	POP	DE				; new line
	MVI	C,pstring
	CALL	bdos				; print the string
	RET
;
ReadCommand:					; readcom read the next command line to the conbuf
	LXI	DE,prompt
	CALL	PrintBuff				; command?
	MVI	C,rstring
	LXI	DE,conbuf
	CALL	bdos
; command line is present, scan it
	LXI	HL,0				; START WITH 0000
	LXI	DE,conlin				; command line


ReadCmdChar:					; readc:
	LDAX	DE				; next command character
	INX	DE				; to next command position
	ORA	A				; cannot be end of command
	RZ
; not zero, numeric?
	SUI	ASCII_ZERO
	CPI	10				; carry if numeric
	JNC	ReadCmdCharExit				; add-in next digit
	DAD	HL				; *2
	MOV	C,L
	MOV	B,H				; bc - value * 2
	DAD	HL				; *4
	DAD	BC				; *2 + *8 = *10
	ADD	L
	MOV	L,A
	JNC	ReadCmdChar				; for another char
	INR	H				; overflow
	JMP	ReadCmdChar			; for another char
ReadCmdCharExit:					; endrd  end of read, restore value in a
	ADI	ASCII_ZERO			; command
	CPI	ASCII_LO_A			; translate case?
	RC
; lower case, mask lower case bits
	ANI	1011111B
	RET
;
;       string data area
;
badver:	DB	'sorry you need cp/m version 2$'
nospace:	DB	'no directory space$'
datmsg:	DB	'type datas: $'
errmsg:	DB	'errordir try again.$'
prompt:	DB	'next command? $'
;
; fixed and variable data area
;
conbuf:
	DB      conlen				; length of console buffer
consiz:
	DS	1				; resulting size after read
conlin:
	DS	32				; length 32 buffer
conlen	EQU	32				; $-consiz

	DS	32
stack:
                  
CodeEnd:

