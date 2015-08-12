;	Page 70/493   Programmers CPM Handbook by Andy Johnston-Laird

TPA			EQU		0100H	; Start of Transient program Area
Space		EQU		020H	; Blan or Space

			ORG		TPA		; set location counter to base of TPA
			
Start:		CALL	CTP		; Test bed for CTP
			NOP
	; This subroutine breaks the command like tail apart, placing each value
	; in a a separate string area
	
	; Return Parameters:
	; A = 0- No error ( Z flag is set)
	; B = Number of parameters
	; HL -> Table of addresses.
	;			Each address points to a null-byte terminated parameter string
	;		If too many parameters are specified, then A = TMP
	;		If one parameter is too long, then A = PTL and D points to the
	;		first character of the offending parameter
	
ComTail				EQU	080H	; Command tail base page
ComTailCount		EQU	ComTail	; first byte in tail buffer
TooManyParameters	EQU	1		; TMP error code
ParameterTooLong	EQU	2		; PTL error code

PTable:						; Table of pointers to Parameters
		DW		P1			; Parameter 1
		DW		P2			; Parameter 2
		DW		P3			; Parameter 3
									; add more pointers if needed
		DW		0			; Terminator
		
		; Parameter Strings. The first byte is 00H so that unused parameters appear
		; to be null strings, The last byte is set to 00H and is used to detect a
		; parameter that is too long
P1:		DB 		0
		DB		1,1,1,1,1,1,1,1,1,1,1,1
		DB		0
P2:		DB 		0
		DB		1,1,1,1,1,1,1,1,1,1,1,1
		DB		0
P3:		DB 		0
		DB		1,1,1,1,1,1,1,1,1,1,1,1
		DB		0
		; add more pointers if needed
		
CTP:
		LXI		H,PTable		; HL -> table of addresses
		MVI		C,0				; Set Parameter count
		LDA		ComTailCount
		ORA		A				; Any parameters?
		RZ						; return if none
		
		PUSH	H				; Save address table for later
		MOV		B,A				; B = CommandTail count
		LXI		H,ComTail + 1	; Point at the actual characters
CTPNextP:
		XTHL					; HL-> Table of Addresses
								; TOS -> CommandTail Pointer
		MOV		E,M				; get LS byte of Parameter address
		INX		H				; update address pointer
		MOV		D,M				; Get MS byte of parameter address
								; DE-> Parameter string ( or is 0)
		MOV		A,D				; Get copy of MS byte of Addr.
		ORA		E				; Combine MS & LS byte
		JZ		CTPExitTMP			; Get out if too many Parameters
		INX		H				; update pointer to next address
		XTHL					; HL-> CommandTail
								; TOS -> update address pointer
				; At this point, we have:
				; HL -> next byte in CommandTail
				; DE -> first byte of next parameter String
CTPSkipB:
		MOV		A,M				; Get the next parameter byte
		INX		H				; update the CommandTail
		DCR		B				; Any more Characters ?
		JM		CTPExit			; No, Get out
		CPI		Space
		JZ		CTPSkipB		; skip spaces
		INR		C				; up the parameter Counter
CTPNextC:
		STAX	D				; Store in parameter string
		INX		D				; increment pointer
		LDAX	D				; check next byte
		ORA		A				; is it a terminator ?
		JZ		CTPexitPTL		; No, exit Parameter Too Long
		XRA		A				; want to put 00 at end
		STAX	D				; Store in parameter String
		MOV		A,M				; Get next character from Tail
		INX		H				; update the tail pointer
		DCR		B				; any more characters ?
		JM		CTPexit			; no, then exit
		CPI		Space			; is it a parameter terminator ?
		JZ		CTPNextP		; Yes so move to next Parameter
		JMP		CTPNextC		; No, so store it in the parameter string
;----------------		
		
CTPexit:						; Normal exit
		XRA		A				; A = 0, Z-Flag set
CTPexitC:						; Common Exit code
		POP		HL				; balance stack
		LXI		H,PTable		; Return ptr to parameter address table
		ORA		A				; ensure z-Flag set correctly
		RET
CTPexitPTL:
		MVI		A,ParameterTooLong	; set error code
		XCHG					; DE -> offending parameter
		JMP		CTPexitC		; common exit
CTPExitTMP:
		MVI		A,TooManyParameters	; set error code
		JMP		CTPexitC		; common exit
		
; 		End		Start

