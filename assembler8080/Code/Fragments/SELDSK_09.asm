; SELDSK_09.asm SELDSK FB2B - 0709
;
;**********************
;SELDSK - Select disk in C. C=0 for A: 1 for B: etc.
;  Return the address of the appropriate disk parameter header
;  in HL, or 0000H if selected disk does not exist		
;**********************	
SELDSK:
	LXI		H,00H		; Assume an error
	MOV		A,C 		; Check if  requested disk is valid
	CPI		NumberOfLogicalDisks
	RNC					; return if > max number of Disks
	
	STA		SelectedDisk	; save disk number
	MOV		L,A			; make disk into word number
	MVI		H,0
						; Compute offset down disk parameter
						; table by multiplying by parameter
						; header length (16 bytes)
	DAD		H
	DAD		H
	DAD		H
	DAD		H			; pointing at right one
	LXI		D,DiskParameterHeaders		; get base address
	DAD		D			; DE -> appropriate DPH
	PUSH	H			; save DPH address
						; access disk parameter block to
						; extract special prefix byte that
						; identifies disk type and whether
						; de-blocking is required
	LXI		D,10		; Get DPB pointer offset in DPH
	DAD		D			; DE -> DPB address
	MOV		E,M			; Get DPB address in DE
	INX		H
	MOV		D,M	
	XCHG				; DE ->DPB
	DCX		H			; DE -> prefix byte
	MOV		A,M			; get prefix byte
	ANI		0FH			; isolate disk type
	STA		DiskType	; save for use in low level driver
	MOV		A,M			; get another copy
	ANI		NeedDeblocking
	STA		DeblockingRequired	; save for low level driver
	POP		H			; recover DPH pointer
	RET
