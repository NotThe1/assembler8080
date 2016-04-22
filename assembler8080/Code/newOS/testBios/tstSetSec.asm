;tstSetSec.asm
;
t_SelectedSector	EQU	0F76DH

BIOS	EQU		0F600H
SETSEC	EQU		BIOS + ( 3 * 0BH)

CodeStart:
		ORG		0100H

		LXI		SP, $		
		CALL	tstSetSec
		
		HLT
;		
tstSetSec:
		MVI		A,01
		STA		sector
		CALL	tstSetSec1
		MVI		A,0FFh
		STA		sector
		CALL	tstSetSec1
		MVI		A,0AAH
		STA		sector

		CALL	tstSetSec1
		MVI		A,055H
		STA		sector
		CALL	tstSetSec1
		MVI		A,09AH
		STA		sector

tstSetSec1:
		LXI		HL, mess1
		CALL	x_displayMessage
		LDA		sector
		CALL	x_showRegA
		LXI		HL, mess2
		CALL	x_displayMessage
			
		LDA		sector
		MOV		C,A
		CALL	SETSEC
		LDA		t_SelectedSector
		CALL	x_showRegA
		CALL	x_CRLF
		
		RET

sector:	DS		1

mess1:	DB		'Set Sector = ',xx_EOM
mess2:	DB		'  SelectedSector = ',xx_EOM	
		
;------------------------------------------
		$Include ../../Headers/debug1Header.asm
				
CodeEnd:
