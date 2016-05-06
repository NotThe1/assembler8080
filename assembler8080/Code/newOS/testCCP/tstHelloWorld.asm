;tstHelloWorld.asm
;

BDOSE		EQU		0005H

CodeStart:
		ORG		0100H
Start::
		LXI	SP, $		
		LXI	DE, messBegin
		MVI	C,09H
		CALL	BDOSE

		HLT

messBegin:	DB		'Hello World!',0AH,0DH,24H	

CodeEnd:
