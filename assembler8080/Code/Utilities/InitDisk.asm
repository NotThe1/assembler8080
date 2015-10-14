; InitDisk.asm


; Track 0                       Sector
;          1      2      3      4      5     6       7     8      9
;Head  +------+------+------+------+------+------+------+------+-------+
;  0   | BOOT |<========== CCP ==========>|<========== BDOS ==========>|
;   1  +------+------+------+------+------+------+------+------+-------+
;      |<====== BDOS ======>|<================= BIOS =================>|
;      +------+------+------+------+------+------+------+------+-------+
;          10     11    12      13     14    15     16     17     18
;                             Sector
MemorySize			EQU 64

CCPLength			EQU 0800H	; Constant
BDOSLength			EQU 0E00H	; Constant	0E00H
BIOSLength			EQU 0A00H	; Constant 0900H

LengthInK			EQU ((CCPLength + BDOSLength + BIOSLength) /1024) + 1
LengthInBytes		EQU (CCPLength + BDOSLength + BIOSLength)


;CCPEntry			EQU	((MemorySize - LengthInK) * (0 + 1024))
CCPEntry			EQU 0E000H		; forced calculation

BDOSEntry			EQU	CCPEntry + CCPLength + 6
BIOSEntry			EQU	CCPEntry + CCPLength + BDOSLength

FirstSectorOnTrack	EQU		1
LastSectorOnTrack	EQU		18
LastSectorOnHead0	EQU		9
SectorSize			EQU		512

StartSector			EQU		1
StartTrack			EQU		0

