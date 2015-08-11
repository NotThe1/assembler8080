;	Page 204  Programmers CPM Handbook by Andy Johnston-Laird
VERSION		EQU		03130H		;Equates for the sign-on Screen
MONTH		EQU		03730H		; '08'
DAY			EQU		03930H		; '09'
YEAR		EQU		03531H		; '15'

Debug		EQU		00			; Non zero to debug

;   The layout of the disk is :
;	Track 0, Head0	-> Sector 1:BOOT , Sector 2-5: CCP , Sector 6-9: BDOS >  
;			 Head1  -> Sector 10-12: BDOS , Sector 13-18: BIOS

;		Equates for defining memory size and the base address and length
;		of the system components
MemorySize	EQU		64		; size in K
;
;	The BIOS Length must match that declared in the BIOS
;		 
BIOSLength	EQU 0900H
; 		 
CCPLength	EQU 0800H	; Constant
BDOSLength	EQU 0E00H	; Constant
;
LengthInK	EQU (((CCPLength + BDOSLength + BIOSLength)/1024) + 1)
LengthInBytes	EQU (CCPLength + BDOSLength + BIOSLength)
;
;	IF NOT Debug
CCPEntry	EQU	(MemorySize - LengthInK) * 1024
;	ENDIF

;	IF Debug
;CCPENtry	EQU	3980H	; Read into lower address.
;
; This address is chosen to be above the area into which DDT initially loads
; and the 980H makes the address similar to the SYSGEN values so that
; memory Image can be checked with DDT
;
;	ENDIF
BDOSEntry	EQU		CCPEntry + CCPLength + 6
BIOSEntry	EQU		CCPEntry + CCPLength + BDOSLength
;
;
;			DISK Characteristics
;
;	These equates describes the physical characteristics of the floppy diskette so that
; the program can move from one sector to the next, updating the track and resetting
; the sector when necessary
;
FirstSectorOnTrack	EQU		1
LastSectorOnTrack	EQU		18
LastSectorOnHead0	EQU		9
SectorSize			EQU		512
;
;			CONTROLLER Characteristics
; On this computer system, the floppy disk controller can read multiple sectors in a single command.
; However, in order to produce a more general example it is shown only reading one sector at a time
;
SectorsPerRead 		EQU		1
;
;		Cold boot characteristics
;
StartTrack			EQU		0		; Initial value for CP/M image
StartSector			EQU		2		; ="=
SectorsToRead		EQU		(LengthInBytes + SectorSize-1) / SectorSize
;--------------------------------------------------------------------------------------

			ORG		0100H
ColdBootLoader:
			JMP		MainCode
CR			EQU		0DH		; Carriage Return
LF			EQU		0AH		; Line Feed
;
SignOnMessage:
			DB		CR,LF,043H,050H,02FH		;CR,LF,CP/
			DB		04DH,020H,042H,06FH,06FH	;M Boo
			DB		074H,073H,074H,072H,061H	;tstra
			DB		070H,020H,04CH,06FH,061H		;p Loa
			DB		064H,065H,072H				;der
			DB		CR,LF
			DB		056H,065H,072H,073H,069H,06FH,06EH,020H	; version
			DW		VERSION
			DB		020H
			DW		MONTH
			DB		02FH
			DW		DAY
			DB		02FH
			DW		YEAR
			DB		CR,LF,00
;
;		Disk Control Tables
;
DiskControl5	EQU		045H		; 5 1/4 Control byte
CommandBlock5	EQU		046H		; ControlTable pointer
DiskStatus		EQU		043H		; Completion Status

;  The command table tracks and DMAAddress can also be used as working storage and updated as the
; load process continues. The sector in the command table cannot be used directly as the disk controller
; requires it to be the sector number on the specified head(1-9) rather than the sector number
; on the track. Hence a separate variable is used.

Sector:			DB		StartSector
;
CommandTable:	DB		01H			; Command -- read
Unit:			DB		0			; Unit ( drive) number = 0 or 1
Head:			DB		0			; Head Number = 0 or 1
Track:			DB		StartTrack	; used as working variable
SectorOnHead:	DB		0			; Converted by low level driver
ByteCount:		DW		SectorSize * SectorsPerRead
DMAAddress:		DW		CCPEntry
NextStatus:		DW		DiskStatus	; pointer to next status block if chained
NextControl:	DW		DiskControl5	; pointer to next control byte if chained
;
MainCode:
			LXI		SP,ColdBootLoader	; Stack grows below code
			LXI		H,SignOnMessage		;
			CALL	DisplayMessage
				
			LXI		H,CommandTable		; Point the disk controller
			SHLD	CommandBlock5		;  at the command block
				
			MVI		C,SectorsToRead		; Set sector count
LoadLoop:
			CALL	ColdBootRead		; Read data into memory
			DCR		C					; decrement sector count
			JZ		BIOSEntry			; enter Bios when loaded
			
			LXI		H,Sector			; update the sector number
			MVI		A,SectorsPerRead		; by adding on number of sectors read
			ADD		M
			MOV		M,A					; Save result
			MVI		A,LastSectorOnTrack +1	; end of track?
			CMP		M
			JNZ		NotEndTrack
			
			MVI		A,FirstSectorOnTrack
			LHLD	Track				; update the track number
			INX		H
			SHLD	Track
NotEndTrack:
			LHLD	DMAAddress			; update DMA Address
			LXI		D,SectorSize * SectorsPerRead
			DAD		D
			SHLD	DMAAddress
			JMP		LoadLoop
;
ColdBootRead:		; At this point, the description of the operation required is in the
					;variables contained in the command table, along with the sector variable
			
			PUSH	B					; Save sector count in C
; --------------Change this routine to match the disk controller in use --------------

			MVI		B,0					; assume head 0
			LDA		Sector				; get required sector
			MOV		C,A					; Take a copy of it
			CPI		LastSectorOnHead0 + 1	; on Head 0?
			JC		Head0				; No
			
			SUI		LastSectorOnHead0	; bias down for head 0
			MOV		C,A					; save a copy
			INR		B					; set head 1
Head0:
			MOV		A,B					; get head
			STA		Head
			MOV		A,C
			STA		SectorOnHead
			
			LXI		H,DiskControl5		; Activate controller
			MVI		M,080H
			
WaitForBootComolete:
			MOV		A,M					; Get Status byte
			ORA		A					; Complete ?
			JNZ		WaitForBootComolete	; No
			
			LDA		DiskStatus
			CPI		080H
			JC		ColdBootError		; oops have an error
			
; -------------- End Of Physical Read Routine--------------
			POP		B					; recover sector count in C
			RET
			
ColdBootError:
			LXI		H,ColdBootErrorMessage
			CALL	DisplayMessage		; output error message
			JMP		MainCode			; restart the loader
			
ColdBootErrorMessage:
			DB		CR,LF						;CR,LF
			DB		042H,06FH,06FH				;M Boo
			DB		074H,073H,074H,072H,061H	;tstra
			DB		070H,020H,04CH,06FH,061H	;p Loa
			DB		064H,065H,072H,020H,045H	;der E
			DB		072H,072H,06Fh,072H,020H	;rror 
			DB		02DH,020H,072H,065H,074H	;- ret
			DB		072H,079H,069H,06Eh,067H	;rying
			DB		02EH,02EH,02EH				;...
			DB		CR,LF,00					;CR,LF
			;
			;--------Equates for terminal output
			;
TerminalStatusPort	EQU		02H
TerminalDataPort		EQU		01H

TerminalOutPutReady EQU		080H
;
;
DisplayMessage:		;	Displays the specific message on the console. On Entry, HL points
					; to a stream of bytes to be output. A 00H-byte terminates the message.
			MOV		A,M					; get next message byte
			ORA		A					; Terminator ?
			RZ							; yes - return
			MOV		C,A					; prepare for output
OutputNotReady:
			IN		TerminalStatusPort	; check if ready
			ANI		TerminalOutPutReady
			JZ		OutputNotReady		; No, wait
			
			MOV		A,C					; get the data 
			OUT		TerminalDataPort	; output to screen
			
			INX		H					; move to next byte in meaasge
			JMP		DisplayMessage		; loop until complete
			
; The PROM-based bootstrap loader checks to see that the characters "CP/M" are on the
; diskette bootstrap sector before it transfers control to It
			

