; WBOOT_01.asm
;WBOOT FE29 -1393

;**********************************************************************************	
;						Warm Boot
;  On warm boot. the CCP and BDOS must be reloaded into memory.
; In this BIOS. only the 5 1/4" diskettes will be used.
; Therefore this code is hardware specific to the controller.
; Two prefabricated control tables are used.
;**********************************************************************************	
WBOOT:
	LXI		SP,080H
	LXI		D,BootControlPart1
	CALL	WarmBootRead
		WarmBootRead:
			LXI		H,FloppyDCT			; get pointer to the Floppy's Device Control Table
			SHLD	CommandBlock5		; put it into the Command block for drive A:
			MVI		C,13				; set byte count for move
		WarmByteMove:
			LDAX	D					; Move the coded Control block into the Command Block
			MOV		M,A
			INX		H
			INX		D
			DCR		C
			JNZ		WarmByteMove
			
			LXI		H,DiskControl5
			MVI		M,080H				; activate the controller 
			
		WaitForBootComplete:
			MOV		A,M					; Get the control byte
			ORA		A					; Reset to 0 (Completed operation) ?
			JNZ		WaitForBootComplete	; if not try again
			
			LDA		DiskStatusBlock		; after operation what's the status?
			CPI		080H				; any errors ?
			JC		WarmBootError		; Yup
					WarmBootError:
						LXI		H,WarmBootErroMessage	; point at error message
						CALL	DisplayMessage			; sent it. and
						JMP		WBOOT					; try again.
					
			RET							; else we are done!
		
				
	LXi		D,BootControlPart2
	CALL	WarmBootRead
	JMP		EnterCPM
