; osHeader.asm


RAM				EQU	0			; Start of RAM ( and the Base page)

WarmBoot		EQU	RAM + 0				; Contains a JMP instruction to warm boot in BIOS
BIOSPAGE		EQU	RAM + 2				; BIOS Jump Vector Page
IOBYTE			EQU	RAM + 3				; Input/Output redirection byte

CurUser			EQU	RAM + 4				; Current user ( bits 7-4)
CurDisk			EQU	CurUser				; Default logical disk (bits 0-3)
		
BDOSE			EQU	RAM + 5				; Contains a JMP to BDOS entry
TopRAM			EQU	BDOSE+2				; Top page of usable RAM

FCB1			EQU	RAM + 05CH			; File Control Block #1
; Note. If you use it here you will overwrite FCB2 below
FCB2			EQU	FCB1 + 16			; File Control Block #2
; You must move it before using. see above

ComTail			EQU	RAM + 080H			; Complete command tail
ComTailCount	EQU ComTail + 1			; Count of the number of char in tail
ComTailChars	EQU	ComTailCount + 1	; Complete Command tail up-cased, w/o trailing CR


DMABuffer		EQU	RAM + 080H		; Default "DMA" address used as buffer

; where programs are loaded and executed
TPA				EQU	RAM + 0100H		; Start of Transient program Area
						
MemorySize		EQU	64

CCPLength		EQU	0800H			; Constant
BDOSLength		EQU	0E00H			; Constant 0E00H
BIOSLength		EQU	0A00H			; Constant 0900H

LengthInK		EQU	((CCPLength + BDOSLength + BIOSLength) /1024) + 1
LengthInBytes	EQU	CCPLength + BDOSLength + BIOSLength


CCPEntry		EQU	(MemorySize * 1024) - (CCPLength + BDOSLength + BIOSLength)
;CCPEntry		EQU	0E000H			; forced calculation


BDOSBase		EQU	CCPEntry + CCPLength
BDOSEntry		EQU	BDOSBase + 6
BIOSBase		EQU	BDOSBase + BDOSLength
BIOSStart		EQU	CCPEntry + CCPLength + BDOSLength


;*******************************************************************************
;
;     Disk related values
;
;
;*******************************************************************************
DiskStatusLocation		EQU		043H	; status after disk I/O placed here
DiskControlByte			EQU		045H	; control byte for disk I/O
DiskCommandBlock		EQU		046H	; Control Table Pointer

DiskReadCode			EQU		01H		; Code for Read
DiskWriteCode			EQU		02H		; Code for Write

; for boot
DiskControlTable		EQU		0040H

cpmRecordSize			EQU		128		; record size that CP/M uses
diskSectorSize			EQU		512		; size of physical disk I/O




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

