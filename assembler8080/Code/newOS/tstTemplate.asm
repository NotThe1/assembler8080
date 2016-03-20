;tstTemplate.asm
;


BIOS	EQU		0F600H
;SETTRK	EQU		BIOS + ( 3 * 0AH)

CodeStart:
		ORG		0100H

		LXI		SP, $		
		CALL	tst
		
		HLT
;		
tst:
		RET


	
;------------------------------------------
		$Include ../Headers/debug1Header.asm
				
CodeEnd:
