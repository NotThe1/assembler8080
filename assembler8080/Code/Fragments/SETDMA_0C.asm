;SETDMA_0C.asm SETDMA FB63 - 0770
;
;**********************
;SetDMA - Set DMA (input/output) address for next read or write
;       Address in BC
;**********************
DMAAddress:	DW	0		; DMA address
SETDMA:
	MOV		L,C					; select address in BC on entry
	MOV		H,B
	SHLD	DMAAddress		; save for low level driver	
	RET
	