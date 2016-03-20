;tstSelDsk.asm
;


BIOS	EQU		0F600H
SELDSK	EQU		BIOS + (3 * 9)

CodeStart:
		ORG		0100H

		LXI		SP, $		
		CALL	tstSeldsk
		
		HLT
;		
;tstSelDsk equates need to match current BIOS
; 
; variable that start with t_ need to be set from current BIOS
;
t_SelectedDkTrkSec	EQU	0F76AH		
t_SelectedDisk	EQU		t_SelectedDkTrkSec + 0			; a=1, b=2 ,....
t_DiskType		EQU		0F76EH			; Floppy 5 = 1, Floppy 8 = 2
t_DeblockingReq	EQU		t_DiskType + 1	; 080 = req (Floppy 5)
;t_diskParamHdr	EQU		0F765H
				
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
		RET

; equates for the Select Disk test
; variable that start with t_ need to be set from current BIOS
;		

;dphDiskA		EQU		t_diskParamHdr + 0	; ParameterHeader for A
;dphDiskB		EQU		t_diskParamHdr + 16	; ParameterHeader for B
;dphDiskC		EQU		t_diskParamHdr + 32	; ParameterHeader for C
;dphDiskD		EQU		t_diskParamHdr + 48	; ParameterHeader for D
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
	
;------------------------------------------
		$Include ../Headers/debug1Header.asm
				
CodeEnd:
