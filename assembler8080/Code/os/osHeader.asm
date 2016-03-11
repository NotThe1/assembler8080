; osHeader.asm

MemorySize		EQU		64

CCPLength		EQU		0800H	; Constant
BDOSLength		EQU		0E00H	; Constant	0E00H
BIOSLength		EQU		0A00H	; Constant 0900H

LengthInK		EQU		(CCPLength + BDOSLength + BIOSLength) /1024) + 1
LengthInBytes	EQU		(CCPLength + BDOSLength + BIOSLength)


;CCPEntry		EQU		((MemorySize - LengthInK) * (0 + 1024))
CCPEntry		EQU		0E000H		; forced calculation

BDOSEntry		EQU		CCPEntry + CCPLength + 6
BIOSEntry		EQU		CCPEntry + CCPLength + BDOSLength


SPACE			EQU		020H	; blank
SLASH			EQU		02FH	; /

CR				EQU		0DH		; Carriage Return
LF				EQU		0AH		; Line Feed
EndOfMessage	EQU		00H
