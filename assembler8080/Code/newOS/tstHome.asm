;tstHome.asm
;


BIOS	EQU		0F600H
HOME	EQU		BIOS + ( 3 * 08H)

t_DataInDiskBuffer	EQU		0F780H
t_MustWriteBuffer	EQU		t_DataInDiskBuffer + 1

CodeStart:
		ORG		0100H

		LXI		SP, $		
		CALL	tstHome
		
		HLT
;		
tstHome:
		LXI		HL,t_DataInDiskBuffer
		MVI		M,-1
		INX		HL
		MVI		M,0
		CALL	HOME
		LDA		t_DataInDiskBuffer
		CPI		00
		JNZ		tstHome1
		
		LXI		HL,t_DataInDiskBuffer
		MVI		M,055H
		INX		HL
		MVI		M,0AAH
		CALL	HOME
		LDA		t_DataInDiskBuffer
		CPI		055H
		JNZ		tstHome1

		LXI		HL, mess1
		CALL	x_displayMessage
		
		RET
tstHome1:
		LXI		HL, mess2
		CALL	x_displayMessage
		RET


mess1:	DB		'Bios call to HOME success !',xx_CR,xx_LF,xx_EOM	
mess2:	DB		'Bios call to HOME failed ***************',xx_CR,xx_LF,xx_EOM	
;------------------------------------------
		$Include ../Headers/debug1Header.asm
				
CodeEnd:
