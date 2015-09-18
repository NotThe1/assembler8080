			
;**********************************************************************************	
;						Warm Boot
;  On warm boot. the CCP and BDOS must be reloaded into memory.
; In this BIOS. only the 5 1/4" diskettes will be used.
; Therefore this code is hardware specific to the controller.
; Two prefabricated control tables are used.
;**********************************************************************************	

CCPEntry		EQU		0E000H
DiskStatusBlock	EQU		 0043H
DisplayMessage	EQU		0F833H


		ORG		01000H
CodeStart:



WBOOT:
	LXI		SP,080H
	LXI		D,BootControlPart1
	CALL	WarmBootRead
	
	LXi		D,BootControlPart2
	CALL	WarmBootRead
;	JMP		EnterCPM
	HLT
	
WarmBootRead:
	LXI		H,FloppyCommand
	SHLD	CommandBlock5
	MVI		C,13				; set byte count
WarmByteMove:
	LDAX	D
	MOV		M,A
	INX		H
	INX		D
	DCR		C
	JNZ		WarmByteMove
	
	LXI		H,DiskControl5
	MVI		M,080H			; activate the controller
	
WaitForBootComplete:
	MOV		A,M
	ORA		A
	JNZ		WaitForBootComplete
	
	LDA		DiskStatusBlock
	CPI		080H		; any errors ?
	JC		WarmBootError	; Yup
	RET

WarmBootError:
	LXI		H,WarmBootErroMessage
	CALL	DisplayMessage
	JMP		WBOOT
	
WarmBootErroMessage:
	DB		0DH,0AH
	DB		057H,061H,072H,06DH,020H				; Warm
	DB		042H,06FH,06FH,074H,020H				; Boot
	DB		072H,065H,074H,072,079H,069H,06EH,067H	;retrying
	DB		02EH,02EH,02EH,0DH,0AH
	DB		00H
	
DiskControl8	EQU	040H	; 8" control byte
CommandBlock8	EQU	041H	; Control Table Pointer

DiskStatusBlock	EQU	043H	; 8" and 5 1/4" status block

DiskControl5	EQU	045H	; 8" control byte
CommandBlock5	EQU	046H	; Control Table Pointer

;***************************************************************************
;					Floppy Disk Control tables
;***************************************************************************
FloppyCommand:				DB	00H		; Command
FloppyReadCode				EQU	01H
FloppyWriteCode				EQU	02H
FloppyUnit:					DB	00H		; unit (drive) number = 0 or 1
FloppyHead:					DB	00H		; head number = 0 or 1
FloppyTrack:				DB	00H		; track number
FloppySector:				DB	00H		; sector number
FloppyByteCount:			DW	0000H	; number of bytes to read/write
FloppyDMAAddress:			DW	0000H	; transfer address
FloppyNextStatusBlock:		DW	0000H	; pointer to next status block
FloppyNextControlLocation:	DW	0000H	; pointer to next control byte
	
;**********************************************************************************
;		Disk Control table image for warm boot
;**********************************************************************************
BootControlPart1:
	DB	FloppyWriteCode	; Write function
	DB	00H				; unit number
	DB	00H				; head number
	DB	00H				; track number
	DB	02H				; Starting sector number
	DW	8 * 512			; Number of bytes to write
	DW	CCPEntry		; write into this address
	DW	DiskStatusBlock	; pointer to next block
	DW	DiskControl5	; pointer to next table
BootControlPart2:
	DB	FloppyWriteCode	; Write function
	DB	00H				; unit number
	DB	01H				; head number
	DB	00H				; track number
	DB	01H				; Starting sector number
;	DW	3 * 512			; Number of bytes to write
;	DW	9 * 512			; Number of bytes to write
	DW	8 * 512			; Number of bytes to write
	DW	CCPEntry + ( 8 * 512)		; write into this address
	DW	DiskStatusBlock	; pointer to next block
	DW	DiskControl5	; pointer to next table

;
CodeEnd:
	END
