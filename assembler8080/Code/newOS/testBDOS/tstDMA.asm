;tstDMA.asm
;

;$Include ../../Headers/stdHeader.asm
BIOS		EQU		0F600H
BDOSEntry	EQU		0E806H
BiosDMA		EQU		0FBFAH		;- DMA in Bios
VALUE1		EQU		0A5A5H
VALUE2		EQU		05A5AH

CodeStart:
		ORG		0100H

		LXI		SP, $		
		LXI		HL, messBegin
		CALL	x_displayMessage
		
		CALL	test
;		
		LXI		HL, messOK
		CALL	x_displayMessage
		HLT
;		
test:
		CALL	showDMA
		
		LXI		DE,VALUE1
		MVI		C,01AH
		CALL	BDOSEntry
		CALL	showDMA
		
		LXI		DE,VALUE2
		MVI		C,01AH
		CALL	BDOSEntry
		CALL	showDMA
		
		RET
		
showDMA:
		LHLD	BiosDMA
		CALL	x_displayHL		; display the address
		CALL	x_CRLF
		
		RET

messBegin:	DB		'Starting the test.',xx_CR,xx_LF,xx_EOM	
messOK:	DB		'the test was a success !',xx_CR,xx_LF,xx_EOM	

	
;------------------------------------------
		$Include ../../Headers/debug1Header.asm
				
CodeEnd:
