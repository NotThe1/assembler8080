
					; listing starts on page 163/493 FIgure 6-2
					; in Programmers CPM Handbook by
					; Andy Johnston-Laird

WBOOT	EQU	03H		; WARM BOOT
CONST	EQU	06H		; CONSOLE STATUS
CONIN	EQU	09H		; CONSOLE INPUT
CONOUT	EQU	0CH		; CONSOLE OUT
LIST	EQU	0FH		; OUTPUT TO LIST DEVICE
PUNCH	EQU	12H		; OUTPUT TO PUNCH DEVICE
READER	EQU	15H		; INPUT FROM REAER
HOME	EQU	18H		; HOME SELECTED DISK TO TRACK 0
SELDSK	EQU	1BH		; SELECT DISK
SETTRK	EQU	1EH		; SET TRACK
SETSEC	EQU	21H		; SET SECTOR
SETDMA	EQU 24H		; SET DMA ADDRESS
READ	EQU	27H		; READ 128 BYTE SECTOR
WRITE	EQU	2AH		; WRITE 128 BYTE SECTOR
LISTST	EQU	2DH		; RETURN LIST STATUS
SECTRAN	EQU	30H		; SECTOR TRANSLATE

;Entry parameters
; L = Code number (page-relative address of the correct JMP instruction in the jump vector
; all other registers are preserved
;
;Exit parameters
; this routine does not CALL the bios routine, therefore when the BIOS routine RETurns,
; it will do so directly to this routine's caller.
;
;calling sequence:
;				MVI		L,Code$Number
;				CALL	BIOS

BIOS:
	PUSH	PSW		; SAVE THE USER'S a REGISTER
	LDA		0002h	; GET BIOS JMP VECTOR PAGE FROM WARM BOOT JMP
	MOV		H,A		; HL-> BIOS JMP VECTOR
	POP		PSW		; RECOVER THE USER'S A REGISTER
	PCHL			; TRANSFER CONTROL ONTO THE BIOS ROUTINE