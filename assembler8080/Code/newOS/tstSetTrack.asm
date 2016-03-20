;tstSetTrack.asm
;
t_SelectedTrack EQU	0F766H

BIOS	EQU		0F600H
SETTRK	EQU		BIOS + ( 3 * 0AH)

CodeStart:
		ORG		0100H

		LXI		SP, $		
		CALL	tstSetTrk
		
		HLT
tstSetTrk:
		LXI		BC,0000
		CALL	tstSetTrk1
		LXI		BC,0FFFFH
		CALL	tstSetTrk1
		LXI		BC,0AAAAH
		CALL	tstSetTrk1
		LXI		BC,05555H
		CALL	tstSetTrk1
		LXI		BC,01234H

tstSetTrk1:
		PUSH	BC
		PUSH	BC
		LXI		HL, mess11
		CALL	x_displayMessage
		POP		HL
		CALL	x_displayHL
		LXI		HL, mess12
		CALL	x_displayMessage
			
		POP		BC
		CALL	SETTRK
		LXI		HL, t_SelectedTrack
		CALL	x_showAddress2
		CALL	x_CRLF
		
		RET

track:	DW		0000
		
mess11:	DB		'Set Track = ',xx_EOM
mess12:	DB		'  SelectedTrack = ',xx_EOM

;------------------------------------------
		$Include ../Headers/debug1Header.asm
				
CodeEnd: