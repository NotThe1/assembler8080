;tstTemplate.asm
;

$Include ../Headers/stdHeader.asm
BIOS	EQU	0F600H
BDOSEntry	EQU	0E806H
SYSTEM	EQU	0005H


	ORG	0100H
CodeStart:                    
	LXI	SP, $
	LXI	DE, messBegin
	CALL	sendMessage
	
	CALL	test
;	
	LXI	DE, messOK
	CALL	sendMessage
	HLT
;	
test:     
	RET

;=========================================================================
CRLF:
	LXI	DE,messCRLF
;-----
sendMessage:
	MVI	C,09H
	CALL	SYSTEM				; send CrLf messsage
	RET

;-------------------------------------------------------------------

messBegin:	DB	'Starting the test.',CR,LF,DOLLAR
messOK:		DB	'the test was a success !',CR,LF,DOLLAR
messCRLF:		DB	CR,LF,DOLLAR


;------------------------------------------

CodeEnd:
