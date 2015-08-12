;	Page 62/493   Programmers CPM Handbook by Andy Johnston-Laird
RAM		EQU		0		; Star of RAM ( and the Base page)

			ORG		RAM		; set location counter to base of RAM
WarmBoot:	DS		3		; Contains a JMP instruction to warm boot in BIOS

BIOSPAGE	EQU		RAM + 2	; BIOS Jump Vector Page

IOBYTE:		DS		1		; Input/Output redirection byte

CurUser:	DS		1		; Current user ( bits 7-4)
CurDisk	EQU		CurUser	; Default logical disk (bits 0-3)

BDOSE:		DS		3		; Contains a JMP to BDOS entry
TopRAM		EQU		BDOSE+2	; Top page of usable RAM


			ORG		RAM + 05CH	; bypass unused locations
			
FCB1:		DS		16		; File Control Block #1
	; Note. If you use it hear you will overwrite FCB2 below
FCB2:		DS		16		; File Control Block #2
	; You must move it before using. see above
	
	
			ORG		RAM + 080H	; bypass unused locations
			
ComTail:						; Complete command tail
ComTailCount:	DS	1		; Count of the number of char in tail
ComTailChars:	DS	127		; Complete Command tail up-cased, w/o trailing CR

			ORG		RAM + 080H	; redefine command tail area
			
DMABuffer:	DB		128		; Default "DMA" address used as buffer

			ORG		RAM + 0100H		; bypass unused locations
TPA:								; Start of Transient program Area
									; where programs are loaded and executed