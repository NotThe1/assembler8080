;tstSecTran.asm
;


BIOS	EQU		0F600H
SECTRAN	EQU		BIOS + ( 3 * 010H)
SELDSK	EQU		BIOS + (3 * 9)


CodeStart:
		ORG		0100H

		LXI		SP, $		
		LXI		HL, messBegin
		CALL	x_displayMessage
		
		CALL	test

		LXI		HL, messOK
		CALL	x_displayMessage
			
		HLT
;		
test:

		LXI		HL,0001
		SHLD	logicalSector	; set test sector	
		MVI		C,0		; drive A
		CALL	test1
		LXI		HL,0012
		SHLD	logicalSector	; set test sector	
		MVI		C,0		; drive A
		CALL	test1
		
		LXI		HL,0002
		SHLD	logicalSector	; set test sector	
		MVI		C,1		; drive B
		CALL	test1
		LXI		HL,0013
		SHLD	logicalSector	; set test sector	
		MVI		C,1		; drive B
		CALL	test1

		LXI		HL,0001
		SHLD	logicalSector	; set test sector	
		MVI		C,2		; drive C
		CALL	test1
		LXI		HL,0012
		SHLD	logicalSector	; set test sector	
		MVI		C,2		; drive C
		CALL	test1
		
		LXI		HL,0002
		SHLD	logicalSector	; set test sector	
		MVI		C,3		; drive D
		CALL	test1
		LXI		HL,0013
		SHLD	logicalSector	; set test sector	
		MVI		C,3		; drive D
		CALL	test1

		
		RET
		
test1:

		CALL	SELDSK
		MOV		A,H
		ORA		L				; if HL = 00 bad select
		JZ		fail
		
;		XCHG						  ; DE has the skew table
		MOV		E,M
		INX		HL
		MOV		D,M					; DE has the skew table 
		
		LXI		HL,logicalSector	; get test sector
		MOV		C,M
		INX		HL
		MOV		B,M					; BC has the test sector
		CALL	SECTRAN				; do the translation
		PUSH	HL					; save the physicl sector number
		LXI		HL,logicalSector	; get test sector
		MOV		E,M
		INX		HL
		MOV		D,M					; DE has the logical sector
		POP		HL					; HL has the physical
		CALL	DEequalsHL			; are they the same 1:1 translation
		RZ							; ok if equal

fail:
		LXI		HL, messBAD			; display error message
		JMP		x_displayMessage
		
		

logicalSector:	DS	2

messBegin:	DB		'Starting the Sector Translation test.',xx_CR,xx_LF,xx_EOM	
messOK:		DB		'the test was a success !',xx_CR,xx_LF,xx_EOM
messBAD:	DB		'the test FAILED ******** !',xx_CR,xx_LF,xx_EOM
messDrive:	DB		'Testing drive '
	
; utility routines
DEequalsHL:
		MOV		A,D
		XRA		H
		RNZ				; return not equal
		MOV		A,E
		XRA		L
		RET				;set Z flag if equal	
;------------------------------------------
		$Include ../Headers/debug1Header.asm
				
CodeEnd:
