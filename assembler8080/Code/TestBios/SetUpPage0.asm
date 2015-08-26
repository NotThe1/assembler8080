; SetUpPage0.asm
WarmBootEntry		EQU			0F603H		; BIOS entry
BDOSEntry			EQU			0E806H     	; BDOS entry
DefaultDiskBuffer	EQU			00080H
DefaultDisk			EQU			00H			; disk A:
SETDMA				EQU			0FB65H

		ORG		1000H

EnterCPM:
	MVI		A,0C3H				; JMP op code
	STA		0000H				; set up the jump in location 0000H
	STA		0005H				; and at location 0005H
	
	LXI		H,WarmBootEntry		; get BIOS vector address
	SHLD	0001H				; put address in location 1
	
	LXI		H,BDOSEntry			; Get BDOS entry point address
	SHLD	0006H				; put address at location 5
	
	LXI		B,DefaultDiskBuffer	; set disk I/O address to default
	CALL	SETDMA				; use normal BIOS routine		****************************************************************
	
	EI
	LDA		DefaultDisk		; Transfer current default disk to
	MOV		C,A				; Console Command Processor
	RET						; transfer to Caller