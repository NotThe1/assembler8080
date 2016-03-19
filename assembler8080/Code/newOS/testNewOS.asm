; testNewOS.asm
;
;
; displayMessage - (HL) points to 00 terminated string
;
;	Display Ascii values of :
; showAddress1 - (HL) address
; showAddress2 - (HL) address
; showRegA     - (A) 
; displayHL		  HL value to display



BIOS	EQU		0F600H


SELDSK	EQU		BIOS + (3 * 9)
SETTRK	EQU		BIOS + ( 3 * 0AH)
CodeStart:

		ORG		0100H

		LXI		SP, $
		
;		CALL	tstConsole
;		CALL	tstSeldsk
		CALL	tstSetTrk
		HLT
		
;----------------------------------------------------
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
t_SelectedTrack EQU	0F766H

track:	DW		0000
		
mess11:	DB		'Set Track = ',xx_EOM
mess12:	DB		'  SelectedTrack = ',xx_EOM
;----------------------------------------------------				
tstSeldsk:
		MVI		C,numberOfDrives + 1	; bad parameter
		CALL	SELDSK
		MOV		A,H				; if HL = 0000 There is an error
		ORA		L
		JZ		tstSeldsk1		; works correctly found error
		; did not detect bad disk number
		PUSH	HL				; save bad result
		LXI		HL, mess3
		CALL	x_displayMessage
		POP		HL				; get returned value
		CALL	x_displayHL
		HLT

tstSeldsk1:
		MVI		C,0				; point at disk A
		CALL	SELDSK
		MOV		A,H
		ORA		L
		JNZ		tstSeldsk2
		
		LXI		HL, mess4
		CALL	x_displayMessage
		HLT

tstSeldsk2:
		MVI		A,-1					; a = 0, b = 1 ....
tstSeldsk3:
		INR		A
		CPI		numberOfDrives 		; do each drive
		JNC		tstSeldsk4
		
		LXI		HL,mess5
		CALL	x_displayMessage
		CALL	x_showRegA
		CALL	x_CRLF
		
		PUSH	AF						; save counter for later
		MOV		C,A						; set for BIOS call
		CALL	SELDSK
		PUSH	HL						; save for later
		
		LXI		HL,mess7
		CALL	x_displayMessage
		LDA		t_SelectedDisk
		CALL	x_showRegA
;		CALL	x_CRLF

		LXI		HL,mess8
		CALL	x_displayMessage
		LDA		t_DiskType
		CALL	x_showRegA
;		CALL	x_CRLF
		
		LXI		HL,mess9
		CALL	x_displayMessage
		LDA		t_DeblockingReq
		CALL	x_showRegA
		
		LXI		HL,mess10
		CALL	x_displayMessage
		POP		HL
		CALL	x_displayHL
		CALL	x_CRLF
		
		POP		AF
		
;		CMP		t_SelectedDisk
;		LXI		HL,mess6
;		JNZ		errorExit

		JMP		tstSeldsk3		; kkep going
		
tstSeldsk4:		
tstSeldsk99:
		LXI		HL,mess2
		CALL	x_displayMessage
		RET
; check disk parameter header 
checkDPH:
		RET
		
	
; equates for the Select Disk test
; variable that start with t_ need to be set from current BIOS
;		
t_SelectedDisk	EQU		0F75FH			; a=1, b=2 ,....
t_DiskType		EQU		0F763H			; Floppy 5 = 1, Floppy 8 = 2
t_DeblockingReq	EQU		t_DiskType + 1	; 080 = req (Floppy 5)
t_diskParamHdr	EQU		0F765H
dphDiskA		EQU		t_diskParamHdr + 0	; ParameterHeader for A
dphDiskB		EQU		t_diskParamHdr + 16	; ParameterHeader for B
dphDiskC		EQU		t_diskParamHdr + 32	; ParameterHeader for C
dphDiskD		EQU		t_diskParamHdr + 48	; ParameterHeader for D
numberOfDrives	EQU		4
hdrSize			EQU		16					; size of a header

		
mess2:	DB	'tstSeldsk concluded !',xx_LF,xx_CR,xx_LF,xx_CR,xx_EOM
mess3:	DB	'Did not detectect bad disk number'
		DB	' in Select Disk.',xx_LF,xx_CR
		DB	'HL was not 00 it was:',xx_LF,xx_CR,xx_EOM
mess4:	DB	'Did not detectect good disk number'
		DB	' in Select Disk.',xx_LF,xx_CR,xx_EOM
mess5:	DB	'Testing drive ',xx_EOM
;mess6:	DB	't_SelectedDisk in error', xx_LF,xx_CR,xx_EOM
mess7:	DB	' SelctedDisk = ',xx_EOM
mess8:	DB	' DiskType = ',xx_EOM
mess9:	DB	' Deblocking Req = ',xx_EOM
mess10:	DB	' DPH = ',xx_EOM
;----------------------------------------------------
		
tstConsole:			
		MVI		A,45H
		CALL 	xx_PCHAR
		CALL	x_CRLF
	
		MVI		C,00
		LXI		H,0110H
		CALL	x_showAddress1
		
		MVI		C,00
		LXI		H,0110H
		CALL	x_showAddress2
				
		CALL	x_displayHL
		CALL	x_CRLF
		LXI		HL,mess1
		CALL	x_displayMessage
		RET
		
mess1:	DB	'tstConsole concluded !',xx_LF,xx_CR,xx_LF,xx_CR,xx_EOM
;----------------------------------------------------
; utility routines
DEequalsHL:
		MOV		A,D
		XRA		H
		RNZ				; return not equal
		MOV		A,E
		XRA		L
		RET				;set Z flag if equal
		
errorExit:
		CALL	x_displayMessage
		CALL	x_CRLF
		CALL	x_CRLF
		HLT

;----------------------------------------------------		
		
;---------
		$Include ../Headers/debug1Header.asm
				
CodeEnd:
