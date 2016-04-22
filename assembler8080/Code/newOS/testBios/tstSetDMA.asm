;tstSetDMA.asm
;


BIOS	EQU		0F600H
SELDMA	EQU		BIOS + ( 3 * 0CH)
t_DMAAddress	EQU	0F774H
CodeStart:
		ORG		0100H

		LXI		SP, $		
		CALL	tstSetDMA
		
		HLT
;		
tstSetDMA:
		LXI		BC,0000
		CALL	tstSetDMA1
		LXI		BC,0FFFFH
		CALL	tstSetDMA1
		LXI		BC,0AAAAH
		CALL	tstSetDMA1
		LXI		BC,05555H
		CALL	tstSetDMA1
		LXI		BC,01234H

tstSetDMA1:
		PUSH	BC
		PUSH	BC
		LXI		HL, mess1
		CALL	x_displayMessage
		POP		HL
		CALL	x_displayHL
		LXI		HL, mess2
		CALL	x_displayMessage
			
		POP		BC
		CALL	SELDMA
		LXI		HL, t_DMAAddress
		CALL	x_showAddress2
		CALL	x_CRLF
		
		RET


		
mess1:	DB		'Set DMA = ',xx_EOM
mess2:	DB		'  DMAAddress = ',xx_EOM
		RET


	
;------------------------------------------
		$Include ../../Headers/debug1Header.asm
				
CodeEnd:
