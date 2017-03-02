; osHeader.asm

; 2017-03-02 Refactored the CP/M Suite

; Contains the Equates used by the CP/M system

;------------------------Page Zero Constants ---------------------------------
RAM					EQU		0					; Start of RAM ( and the Base page)

WarmBoot			EQU		RAM + 0				; Contains a JMP instruction to warm boot in BIOS
BIOSPAGE			EQU		RAM + 2				; BIOS Jump Vector Page
IOBYTE				EQU		RAM + 3				; Input/Output redirection byte

Pg0CurentUser		EQU		RAM + 4				; Current user ( bits 7-4)
Pg0CurentDisk		EQU		Pg0CurentUser				; Default logical disk (bits 0-3)

BDOSE				EQU		RAM + 5				; Contains a JMP to BDOS entry
TopRAM				EQU		BDOSE+2				; Top page of usable RAM

FCB1				EQU		RAM + 05CH			; File Control Block #1
FCB2				EQU		FCB1 + 16			; File Control Block #2

ComTail				EQU		RAM + 080H			; Complete command tail
ComTailCount		EQU 	ComTail + 1			; Count of the number of char in tail
ComTailChars		EQU		ComTailCount + 1	; Complete Command tail up-cased, w/o trailing CR
;-----------------------------------------------------------------------

DMABuffer			EQU		RAM + 080H			; Default "DMA" address used as buffer
;-----------------------------------------------------------------------
TPA					EQU		RAM + 0100H		; Start of Transient program Area
;-----------------------------------------------------------------------
END_OF_FILE			EQU		1AH				; end of file
;-----------------------------------------------------------------------

;--------------- CP/M Constants -----------------------------------------

CCPLength			EQU		0800H			; Constant
BDOSLength			EQU		0E00H			; Constant 0E00H
BIOSLength			EQU		0A00H			; Constant 0900H

LengthInBytes		EQU		CCPLength + BDOSLength + BIOSLength
LengthInK			EQU		(LengthInBytes/1024) + 1

MemorySize			EQU		64

CCPEntry			EQU		(MemorySize * 1024) - LengthInBytes

BDOSBase			EQU		CCPEntry + CCPLength
BDOSEntry			EQU		BDOSBase + 6

BIOSBase			EQU		BDOSBase + BDOSLength
BIOSStart			EQU		CCPEntry + CCPLength + BDOSLength
;-----------------------------------------------------------------------

;------------------- BDOS System Call Equates --------------------------
fConsoleIn			EQU		01H			; rcharf - Console Input
fConsoleOut			EQU		02H			; pcharf - Console Output
fPrintString		EQU		09H			; pbuff	- Print String
fReadString			EQU		0AH			; rbuff	- Read Console String
fGetConsoleStatus	EQU		0BH			; breakf - Get Console Status
fGetVersion			EQU		0CH			; liftf	- Return Version Number
fResetSystem		EQU		0DH			; initf	- Reset Disk System
fSelectDisk			EQU		0EH			; self	- Select Disk
fOpenFile			EQU		0FH			; openf	- Open File
fCloseFile			EQU		10H			; closef - Close File
fSearchFirst		EQU		11H			; searf	- Search For First
fSearchNext			EQU		12H			; searnf - Search for Next
fDeleteFile			EQU		13H			; delf - Delete File
fReadSeq			EQU		14H			; dreadf - Read Sequential
fWriteSeq			EQU		15H			; dwritf - Write Sequential
fMakeFile			EQU		16H			; makef	- Make File
fRenameFile			EQU		17H			; renf	- Rename File
fGetLoginVector		EQU		18H			; logf	- Return Login Vector
fGetCurrentDisk		EQU		19H			; cself	- Return Current Disk
fSetDMA				EQU		1AH			; dmaf	- Set DMA address
fGetSetUserNumber	EQU		20H			; userf	- Set/Get User Code
;-----------------------------------------------------------------------





;*******************************************************************************
; These are the values handed over by the BDOS when it calls the Writer operation
; The allocated.unallocated indicates whether the BDOS is set to write to an
; unallocated allocation block (it only indicates this for the first 128 byte
; sector write) or to an allocation block that has already been allocated to a
; file. The BDOS also indicates if it is set to write to the file directory
;*******************************************************************************
WriteAllocated		EQU	00H
WriteDirectory		EQU	01H
WriteUnallocated	EQU	02H

