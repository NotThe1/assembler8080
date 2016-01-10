; BasePageCPM.asm
;
RAM			EQU		0		; Start of RAM (and the base page)

			ORG		RAM		; Set location counter to RAM base
WarmBoot:	DS		3		; Contains a JMP to warm boot entry in BIOS jump vector table

BiosPage	EQU		RAM + 2	; BIOS jump vector page

IOBYTE:		DS		1		; Input/output redirection byte

CurUser:	DS		1		; Current User ( bits 7-4) hi-nibble
CurDisk		EQU		CurUser	; Default logical disk ( bits 3-0) lo-nibble
							;    0 =A, 1 = B ...
BDOSE:		DS		3		; Contains a JMP to BDOS entry
TopRam		EQU		BDOSE+2	; Top palle of usable RAM

			ORG		RAM + 05CH

FCB1:		DS		16		; F11e control block #1. Note, if you use this FCB here
							;   you will overwrite FCB2 below.
FCB2:		DS		16		; File control block #2. You must move this to another
							;   place before using it

			ORG		RAM + 080H
			
ComTail:					; Complete command tail
ComTailCount:	DS	1		; Count of the number of chars in command tail (CR not incl.)
ComtailChars:	DS	127		; Characters in command tail converted to uppercase and
							;   without trailing carriage ret.
							
			ORG		RAM + 080H	; redefine command tail area
			
DMAbuffer:	DS		128		; Default "DMA" address used as a 128-byte record buffer

			ORG		RAM + 0100H
TPA:						; ,Start of transient program area where programs are loaded.