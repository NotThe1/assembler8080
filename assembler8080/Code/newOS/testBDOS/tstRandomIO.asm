;tstRandomIO.asm
;

;Include ../../Headers/stdHeader.asm
BIOS	EQU	0F600H
BDOSEntry	EQU	0E806H
             
CodeStart:   
	ORG	0100H
	   
	LXI	SP, $		
	LXI	HL, messBegin
	CALL	x_displayMessage
	
	CALL	test
;		
	LXI	HL, messOK
	CALL	x_displayMessage
	HLT
;		
test:
	MVI	E,00
	MVI	C,0EH
	CALL	BDOSEntry		; select disk A
	
	LXI	DE,myFCB
	MVI	C,0FH
	CALL	BDOSEntry		; open file
	CPI	-1
	JZ	BadOpen		; exit if not opened
	CALL	ShowDefaultFCB	; show page 0 - before
; get File Size

	MVI	C,23H
	CALL	BDOSEntry
	CALL	ShowDefaultFCB	; show page 0 - after
		

	RET
;------
ShowDefaultFCB:
	CALL	x_CRLF
	CALL	x_CRLF
	MVI	B,34H
	LXI	HL,myFCB		; Default FCB1
	CALL	x_displayHL	; show location
	CALL	x_CRLF
ShowDefaultFCB1:
	MOV	A,M		; get next char
	CALL	x_showRegAcomma	; display it
	INX	HL
	DCR	B
	JNZ	ShowDefaultFCB1	; show all
	RET			
	
BadOpen:
	LXI	DE,msgBadOpen
	MVI	C,09H
	CALL	BDOSEntry
	HLT

;--------------------------------
messBegin:	DB	'Starting the test.',xx_CR,xx_LF,xx_EOM	
messOK:		DB	'the test was a success !',xx_CR,xx_LF,xx_EOM	
messBad:		DB	'the test was a Failure !',xx_CR,xx_LF,xx_EOM

msgBadOpen:	DB	'Unable to open the file!',0AH,0DH,24H	
		ORG	(($+0100H)/0100H) * 0100H	
myFCB:		DB	0,'CPM9    ARK'
		DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

	
;------------------------------------------
		$Include ../../Headers/debug1Header.asm
				
CodeEnd:
