; SETSEC_0B.asm		SETSEC FB5E - 0758
;
;**********************	
;SETSEC - Set logical sector for next read or write
;		Sector is in C
;**********************
SETSEC:
	MOV		A,C
	STA		SelectedSector		; save for low level driver	
	RET