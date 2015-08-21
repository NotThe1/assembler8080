; SETTRK_0A.asm SETTRK FB58 - 0751
;
;**********************	
;SETTRK - Set logical track for next read or write
;		Track is in BC
;**********************	
SETTRK:
	MOV		H,B					; select track in BC on entry
	MOV		L,C
	SHLD	SelectedTrack		; save for low level driver	
	RET