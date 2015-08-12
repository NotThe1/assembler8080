;	Pages 165/493 &  204/493  Programmers CPM Handbook by Andy Johnston-Laird
VERSION		EQU		03130H		;Equates for the sign-on Screen
MONTH		EQU		03830H		; '08'
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