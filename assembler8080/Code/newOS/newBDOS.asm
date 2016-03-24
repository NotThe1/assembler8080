; newBDOS.asm
; part of newOS
; 2014-03-14  :  Frank Martyn

		$Include ../Headers/osHeader.asm
		$Include ../Headers/stdHeader.asm
STACK_SIZE	EQU		20H			; make stak big enough

;	bios access constants
bcBoot		EQU	BIOSEntry+3*0	;cold boot function
bcWboot		EQU	BIOSEntry+3*1	;warm boot function
bcConst		EQU	BIOSEntry+3*2	;console status function
bcConin		EQU	BIOSEntry+3*3	;console input function
bcConout	EQU	BIOSEntry+3*4	;console output function
bcList		EQU	BIOSEntry+3*5	;list output function
bcPunch		EQU	BIOSEntry+3*6	;punch output function
bcReader	EQU	BIOSEntry+3*7	;reader input function
bcHome		EQU	BIOSEntry+3*8	;disk home function
bcSeldsk	EQU	BIOSEntry+3*9	;select disk function
bcSettrk	EQU	BIOSEntry+3*10	;set track function
bcSetsec	EQU	BIOSEntry+3*11	;set sector function
bcSetdma	EQU	BIOSEntry+3*12	;set dma function
bcRead		EQU	BIOSEntry+3*13	;read disk function
bcWrite		EQU	BIOSEntry+3*14	;write disk function
bcListst	EQU	BIOSEntry+3*15	;list status function
bcSectran	EQU	BIOSEntry+3*16	;sector translate
		
CodeStart:
	ORG		BDOSBase
	DB		0,0,0,0,0,0
; Enter here from the user's program with function number in c,
;	and information address in d,e
	JMP	bdosStart	;past parameter block
	
bdosStart:
	XCHG					; swap DE and HL
	SHLD	paramsDE		; save the original value of DE
;*****************************************************************
;*****************************************************************
;
;	common values shared between bdosi and bdos
;usrcode:db	0	;current user number
;curdsk:	db	0	;current disk number
paramsDE:	ds	2	;information address
;StatusBDOSReturn:	ds	2	;address value to return
;lret	equ	StatusBDOSReturn	;low(StatusBDOSReturn)
;*****************************************************************
	
CodeEnd: