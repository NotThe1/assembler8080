; Index of /cpm/cdrom/CPM/UTILS/SYSUTL
; Lauren Guimont	1-25-80		Ver. 1.0
; 			1-28-80		Ver. 1.1
; 			3-20-80		Ver. 1.2
; 			6-26-80		Ver. 1.3

; Benny D. Miller jr WB8LGH	05-Jan-84	ver. 1.8
; 	added MP/M II information.

; This is an assembly language adaption of a program
; written in NorthStar BASIC called `STATUS'.

; This program will determine the location of numerous
; addresses, depending on the system size being run.
; It will also present various pieces of information
; concerning the status of many of the options available
; under CP/M 2.20, besides presenting a map of the memory
; of the host system.

; 26-july-82	added ports(disk destructive read protect)
; 	at locations 103(low port) and 104(high port),
; 	or at 203,204 if PRL file.  Actually bypasses these
; 	ports if set other than 0.

; 21-july-82	Status now gives the console(user's), and
; 	maximun consoles. Xios jump table, checks for
; 	CP/Net active/non-active, system time of day,
; 	displays all memory segments.

; Set up the equates to use

PERIOD			EQU		'.'		; Period

LF				EQU		0AH			; Line Feed
;CTRL_K			EQU		0BH			; VT - Vertical tab
;CTRL_L			EQU		0CH			; FF - Form feed
CR				EQU		0DH			; Carriage Return
SPACE			EQU		20H			; Space
ASCII_OFFSET	EQU		30H			; base to make binary decimal number ascii

ASCII_M			EQU		'M'			; upper M
ASCII_R			EQU		'R'			; upper R


SYS_CONOUT		EQU		002H	; Console out , char in E		
SYS_GET_IOB		EQU		007H	; get IOByte , Acc returns IOByte		
SYS_STRING_OUT	EQU		009H	; Print String, DE points at $ terminated String		
SYS_GET_VER		EQU		00CH	; get version number, HL returns Version		
SYS_GET_ALLOC	EQU		01BH	; get allocation , HL returns vector address		
;SYS_GET_VER	EQU		00CH	; get version number, HL returns Version		
;SYS_GET_VER	EQU		00CH	; get version number, HL returns Version		
;SYS_GET_VER	EQU		00CH	; get version number, HL returns Version		
;SYS_GET_VER	EQU		00CH	; get version number, HL returns Version		
;SYS_GET_VER	EQU		00CH	; get version number, HL returns Version

MASK_HI_NIBBLE	EQU		0F0H	; mask for high nibble		
MASK_LO_NIBBLE	EQU		00FH	; mask for low  nibble		

true	equ	0ffffh		; true equate.
false	equ	0000	; false equate.

rmac	equ	true		; if assembled with rmac, and link.
hide	equ	true		; if hide disk ports, to stop destructive
				; reads, also check porta, and portb equates.

;	if rmac
;extrn	bdos			; I/O call.
;	endif

;	if not rmac
bdos	equ	5		; bdos equate.
;	endif

ff	equ	0ch	; form feed.

;CONOUT	EQU	2		; CONSOLE CHAR OUT
;giobyte	equ	7		; get the iobyte.
;STROUT	EQU	9		; PRINT STRING OUTPUT
;version	equ	12		; returns version.
mpmvrs	equ	163		; MP/M 2.x revision.
LOGIN	EQU	24		; RETURNS ON-LINE DRIVES
CURDRV	EQU	25		; RETURNS DEFAULT DRIVE#
;ALLOC	EQU	27		; RETURNS ALLOCATION ADDRESS
RONLY	EQU	29		; RETURNS READ ONLY VECTOR
DPARA	EQU	31		; RETURNS DISK PARAMETER BLK
PRUSER	EQU	32		; RETURNS PRESENT USER
console	equ	153		; get console number.
sysdat	equ	154		; get system data address.
systod	equ	155		; get system time of day.

;	if not rmac
	org	0100h
TPAstart:
;	endif
CodeStart:

start:
	jmp	astart

; 	port hide, so that a destructive read doesn't happen.

porta:	db	0c0h		; disk 1 start port address.
portb:	db	0c3h		; disk 1 last port address.

astart:					; Actual program start
	LXI		H,0			; Clear HL
	DAD		SP			; Get SP from CCP
	SHLD	OLDSP		; Save it
	LXI		SP,STACK	; Point to our stack

	MVI		C,SYS_GET_VER	; get CP/M, MP/M version.
	CALL	BDOS
	MOV		A,H			; see if MP/M.
	STA		mpmFlag		; save it.
	MOV		A,L			; version number CP/M 1.x or 2.x.
	STA		cpmVersion	; save it.

	CALL	clearDisplay

	LDA		mpmFlag		; see if MP/M or CP/M.
	ORA		A			; is MP/M if non-zero.
	JZ		isCPM		; go do CP/M message if not.
	
;-----------skip if on a CPM System---------------	
	lxi	d,MSG24		; do MP/M message.
	mvi	c,SYS_STRING_OUT	; print it command.
	call	bdos		; go print it.
	lda	cpmVersion		; get mpm version.
	ani	0f6h		; if bit 1 set mpm 1. only.
	lda	mpmFlag		; re-get byte just in case.
	jz	contmpm		; do mp/m 1.1
	mvi	c,mpmvrs	; go see which MP/M.
	call	bdos		;
	mov	a,l		; save mp/m 2 revision level.
	sta	cpmVersion		; save it.
	mov	a,h		; get 1 for mpm 2
	sta	mpmFlag		; save new MP/M byte.

contmpm:
	adi	ASCII_OFFSET + 1		; add ascii offset.
	call	charDisplay		; output first number.
	mvi	a,PERIOD		; now the seprator.
	call	charDisplay		; out put it.
	lda	cpmVersion		; now the lower version number.
	ani	MASK_LO_NIBBLE		; leave low nibble.
	adi	ASCII_OFFSET		; add ascii offset.
	call	charDisplay		; go print it.
	lxi	d,MSG27		; trailing end of message.
	mvi	c,SYS_STRING_OUT	; print command.
	call	bdos		; go print it.
	call	displayCRLF		; go do cr,lf.
	jmp	memHeader		; bypass CP/M message.
;-----------skip if on a CPM System---------------	

isCPM:
	LXI		D,MSG0
	MVI		C,SYS_STRING_OUT
	CALL	BDOS
	LDA		cpmVersion		; get cpm version.
	ANI		MASK_HI_NIBBLE	; leave upper nibble.
	RAR						; rotate right four times.
	RAR	
	RAR
	RAR						; to put it in low nibble; 
	ADI		ASCII_OFFSET	; add ascii offset.
	CALL	charDisplay		; output first number.
	MVI		A,PERIOD		; now the seprator.
	CALL	charDisplay		; out put it.
	LDA		cpmVersion		; now the lower version number.
	ANI		MASK_LO_NIBBLE	; Leave Low nibble.
	ADI		ASCII_OFFSET	; add ascii offset.
	CALL	charDisplay		; go print it.
	LXI		D,MSG27			; trailing end of message.
	MVI		C,SYS_STRING_OUT	; print command.
	CALL	bdos			; go print it.
	CALL	displayCRLF			; go do cr,lf.

memHeader:
	LXI		D,MSG1
	MVI		C,SYS_STRING_OUT
	CALL	BDOS

; This is the start of the memory map

	LXI	H,0000H		; Start memory map

memProfile:
	MVI		A,-1
	CMP		M		; Memory = -1?
	JZ		missing	; skip it may not be there
	MOV		B,M		; Save memory value
	MOV		M,A		; move -1 to memory
	MOV		A,M		; move mem value to Acc
	CMP		B		; if it is same as original - must be
	JZ		ROM		;     ROM

RAM:
	MOV		M,B		; Replace original byte
	MVI		B,ASCII_M	; set for display of M for RAM
	JMP		SHWBY	; go do the display

ROM:
	MVI		B,ASCII_R	; set for display of R for ROM
	JMP		SHWBY

missing:
	MVI		A,80H		; Double check W/new value
	MOV		B,M
	MOV		M,A
	MOV		A,M
	CMP		B		
	JNZ		RAM		; jump if the original value in Mem was -1
	MVI		B,PERIOD	; set for display of PERIOD for MISSING Memory

SHWBY:
	MOV		A,B				; load display char into Acc
	CALL	charDisplay		; Output ROM, RAM, or empty
	INR		H
	INR		H
	INR		H
	INR		H
	JNZ		memProfile		; 1 K increments / loop thru 64K
	CALL	displayCRLF

; Now we fill in the storage bytes with the proper
; values which are dependent on each particular system.

	LDA		mpmFlag			; is it MP/M ?
	ORA		A				; will be non-zero for MP/M.
	JNZ		alocxios		; do acllocation vectors if MP/M.

	LHLD	BDOS+1			; Get start of BDOS
	MOV		A,L				; get starting page into Acc
	SUI		6
	MOV		L,A				; just needed to load L with 00 to get start of BDOS in HL
	SHLD	startBDOS		; Store it
	LXI		D,0F700H
	LHLD	startBDOS
	DAD		D				; Add wrap around offset
	SHLD	netTPA			; resolves to available TPA without displacing CCP
	LXI		D,TPAstart		; get the address of the TPA start
	LHLD	netTPA			;
	DAD		D
	SHLD	startCCP		; Store CCP= -TPAstart(100H) of netTPA
	MVI		C,SYS_GET_IOB
	CALL	BDOS
	STA		IOBYT		; Store the I/O byte

alocxios:
	LDA		mpmFlag			; is it MP/M ?
	ORA		A				; will be non-zero for MP/M.
	JNZ		mpmaloc			; if MP/M skip to do MP/M allocation vectors.

	LDA		cpmVersion		; if 00, before 2.0 else 2x
	ANI		MASK_HI_NIBBLE	; see if 1.x version.
	JZ		osDisplay		; skip if not at least rel 2.0 of cp/m

mpmaloc:
	MVI		C,SYS_GET_ALLOC
	CALL	BDOS
	SHLD	allocVector

	LDA		mpmFlag			; is it MP/M ?
	ORA		A				; will be non-zero for MP/M.
	JNZ		conmax			; if MP/M do maximun number of consoles.

; Now we must output the gathered information
; to the console

; Get the CCP address and print it

osDisplay:
	LXI		D,MSG2
	MVI		C,SYS_STRING_OUT
	CALL	BDOS
	LHLD	startCCP
	CALL	ADOUT
	CALL	displayCRLF

; Next get the BDOS address and print it

	LXI	D,MSG3
	MVI	C,SYS_STRING_OUT
	CALL	BDOS
	LHLD	startBDOS
	CALL	ADOUT
	CALL	displayCRLF

; Next get address of BIOS and print it

	LXI	D,MSG15
	MVI	C,SYS_STRING_OUT
	CALL	BDOS
	LXI	D,0E00H
	LHLD	startBDOS
	DAD	D
	CALL	ADOUT
	CALL	displayCRLF

; Already computed netTPA without killing CCP and print it

	LXI	D,MSG13
	MVI	C,SYS_STRING_OUT
	CALL	BDOS
	LHLD	netTPA
	CALL	ADOUT
	LXI	D,MSG11
	MVI	C,SYS_STRING_OUT
	CALL	BDOS
	CALL	displayCRLF

	jmp	drvchk


; print the number of consoles supported.

conmax:
	lxi	d,MSG28		; go print message for number of consoles.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,1		; increment to number of consoles.
	call	offset		; dad the d wth the h&l.
	sta	maxcon		; store at maximun number of consoles.
	call	heout		; go print it in hex format.
	call	displayCRLF		; do cr,lf.

; 	do a system console number output.

syscon:
	lxi	d,MSG25		; point to message.
	mvi	c,SYS_STRING_OUT	; print command.
	call	bdos		; print it.
	mvi	c,console	; get console number.
	call	bdos		; comes back in a.
	adi	ASCII_OFFSET		; add ascii offset.
	call	charDisplay		; go do it.
	call	displayCRLF		; do cr,lf.

;	see if extended information bytes at end of bnkxios jmp table.

extended:
	lxi	d,7		; find xios jmp table address.
	call	offset		; dad the d wth the h&l.
	mov	h,m		; get base address of xios.
	mvi	l,0		; always start at base pge of it.
	lxi	d,75		; go past xios jmp table.
	dad	d		; update pointer.
	mov	a,m		; get the byte.
	ani	0ffh		; see if boolean non zero if MPM II jmp table.
	jz	tod		; go do systems time of day.
	inx	h		; must be 2 bytes set to ffh
	shld	exiospt		; extended xios pointer.
	mov	a,m		; get byte.
	ani	0ffh		; ok?
	jz	tod		; do the systems time of day.

	lxi	d,MSG99		; go print the BSR controller is active.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.

	lhld	exiospt		; restore just in case.
	lxi	d,24		; see if bsr on/off, it is,
 				; 25 from base inormation bytes.
	dad	d		; add to pointer.
	mov	a,m		; get byte.
	inx	h		; up next byte.
	inx	h		; up next byte.
	shld	exiospt		; extended xios pointer.
	ani	0ffh		; of ff then it is on.
	jnz	bsract		; go do active message.
	lxi	d,MSG37		; go print the CP/Net is inactive.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	call	displayCRLF		; do cr,lf.
	jmp	cnulls		; go to console and nulls.

bsract:
	lxi	d,MSG38		; go print the CP/Net is active.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	call	displayCRLF		; do cr,lf.

cnulls:
	lxi	d,MSG44		; go print the console number(0-to-end).
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.

	lda	csole		; get console number back.
	adi	30h		; make ascii.
	call	charDisplay		; go print console number.

	lxi	d,MSG45		; go print the 'has' message.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lhld	exiospt		; get pointer back.
	mov	a,m		; get the current number of nulls.
	adi	ASCII_OFFSET		; add ascii offset.
	call	charDisplay		; go print it.

	lxi	d,MSG46		; go print the 'nulls' message.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	call	displayCRLF		; add carriage return, linefeed per message.

	lda	csole		; get console number.
	adi	1		; next console.
	sta	csole		; save it again.
	lhld	exiospt		; just makeing sure it's right.
	inx	h		; next null pointer also.
	shld	exiospt		; resave.
	lda	maxcon		; done 1, now next one,
	sui	1		; one less,
	sta	maxcon		; to do.
	jnz	cnulls		; loop till all consoles are done.

; 	do a TOD, sytem time of day.

tod:
	lxi	d,MSG26		; get tod message.
	mvi	c,SYS_STRING_OUT	; print command.
	call	bdos		; print it.
	mvi	c,systod	; time of day command.
	lxi	d,time		; set up for date, hour, minutes, seconds.
	call	bdos		; go do it.

	lxi	h,time1		; do time hours for now.
	call	dobyte		; go do a byte
	mvi	a,PERIOD		; separater.
	call	charDisplay		; go print it.
	inx	h		; minutes.
	call	dobyte		; go do it.
	mvi	a,PERIOD		; separater.
	call	charDisplay		; go print it.
	inx	h		; seconds.
	call	dobyte		; go do it.
	call	displayCRLF		; do cr,lf.

; now do the restart number.

	lxi	d,MSG29		; go print the restart message.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,2		; increment to the breakpoint number.
	call	offset		; dad the d wth the h&l.
	adi	ASCII_OFFSET		; ascii offset.
	call	charDisplay		; go print it.
	call	displayCRLF		; do cr,lf.

; now do CPU type.

	lxi	d,MSG30		; go print the CPU message.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,5		; increment to the CPU type.
	call	offset		; dad the d wth the h&l.
	ani	0ffh		; if ff then z-80 else 8080(type).
	jnz	z80		; do z-80 if ff.
	lxi	d,MSG31		; go print the 8080 CPU.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	call	displayCRLF		; do cr,lf.
	jmp	bkbdos		; go to xios jmp table.

z80:
	lxi	d,MSG32		; go print the Z-80 CPU.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	call	displayCRLF		; do cr,lf.

; now do the bank bdos function.

bkbdos:
	lxi	d,4		; increment to banked switched memory
	call	offset		; dad the d wth the h&l.
	ani	0ffh		; see if boolean non zero if banked switched.
	jz	rspage		; go do resident page if not.
	lxi	d,MSG33		; go print the bank switched memory indicator.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	call	displayCRLF		; do cr,lf.


; now do the resident page address.

rspage:
	lxi	d,6		; increment to BDOS RSP page address.
	call	offset		; dad the d wth the h&l.
	ani	0ffh		; see if boolean non zero if banked switched.
	jz	xios		; go do xios jm table.
	lxi	d,MSG35		; go print the bdos resident page.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	call	displayCRLF		; do cr,lf.

resbdos:
	lxi	d,MSG43
	mvi	c,SYS_STRING_OUT
	call	bdos

	lxi	d,8		; increment to resident bdos.
	call	offset		; dad the d wth the h&l.
	mov	d,m		; get into d for printing.
	mvi	e,0		; force low order byte to zero.
	xchg			; exchange the de&hl for printing address.
	call	adout		; go print address.
	xchg			; get back hl.
	call	displayCRLF		; then cr,lf.

; 	do XIOS printout, and some other MP/M stuff.
; 	ex: memory segmnts and size, console number, time of day.

xios:
	lxi	d,7		; increment to xios jmp table address.
	call	offset		; dad the d wth the h&l.
	ani	0ffh		; see if boolean non zero if MPM II jmp table.
	jz	xdos		; go do xdos if not.

	lxi	d,MSG20
	mvi	c,SYS_STRING_OUT
	call	bdos

	lxi	d,7		; increment to xios jmp table.
	call	offset		; dad the d wth the h&l.
	mov	d,m		; get into d for printing.
	mvi	e,0		; force low order byte to zero.
	xchg			; exchange the de&hl for printing address.
	call	adout		; go print address.
	xchg			; get back hl.
	call	displayCRLF		; then cr,lf.

; now print the address of the xdos.

xdos:
	lxi	d,11		; increment to banked XDOS address.
	call	offset		; dad the d wth the h&l.
	ani	0ffh		; 
	jz	rsp		; 
	lxi	d,MSG39		; go print the XDOS address start.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,11		; increment to banked XDOS address.
	call	offset		; dad the d wth the h&l.
	mov	d,m		; get into d for printing.
	mvi	e,0		; force low order byte to zero.
	xchg			; exchange the de&hl for printing address.
	call	adout		; go print address.
	xchg			; get back hl.
	call	displayCRLF		; do cr,lf.

; now do the RSP base page address.

rsp:
	lxi	d,12		; increment to banked RSP base page address.
	call	offset		; dad the d wth the h&l.
	ani	0ffh		; 
	jz	bxios		; 
	lxi	d,MSG40		; go print the RSP address start.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,12		; increment to banked RSP base page address.
	call	offset		; dad the d wth the h&l.
	mov	d,m		; get into d for printing.
	mvi	e,0		; force low order byte to zero.
	xchg			; exchange the de&hl for printing address.
	call	adout		; go print address.
	xchg			; get back hl.
	call	displayCRLF		; do cr,lf.

; now do the banked XIOS base pase address.

bxios:
	lxi	d,13		; increment to banked XIOS address.
	call	offset		; dad the d wth the h&l.
	ani	0ffh		; 
	jz	bnkbdos		; 
	lxi	d,MSG41		; go print the banked XIOS address start.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,13		; increment to xios jmp table.
	call	offset		; dad the d wth the h&l.
	mov	d,m		; get into d for printing.
	mvi	e,0		; force low order byte to zero.
	xchg			; exchange the de&hl for printing address.
	call	adout		; go print address.
	xchg			; get back hl.
	call	displayCRLF		; then cr,lf.

; now do the banked BDOS base page.

bnkbdos:
	lxi	d,14		; increment to banked BDOS address.
	call	offset		; dad the d wth the h&l.
	ani	0ffh		; 
	jz	cpnet		; go do CP/Net if not.
	lxi	d,MSG42		; go print the banked BDOS address start.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,14		; increment to banked BDOS address.
	call	offset		; dad the d wth the h&l.
	mov	d,m		; get into d for printing.
	mvi	e,0		; force low order byte to zero.
	xchg			; exchange the de&hl for printing address.
	call	adout		; go print address.
	xchg			; get back hl.
	call	displayCRLF		; do cr,lf.

; now do CP/Net function.

cpnet:
	lxi	d,MSG36		; go print CP/Net.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,09h		; increment to CP/Net active/nonactive.
	call	offset		; dad the d wth the h&l.
	ani	0ffh		; see if boolean non zero if banked switched.
	jnz	active		; go do active message.
	lxi	d,MSG37		; go print the CP/Net is inactive.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	call	displayCRLF		; do cr,lf.
	jmp	memseg		; go to memory segments.

active:
	lxi	d,MSG38		; go print the CP/Net is active.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	call	displayCRLF		; do cr,lf.

memseg:
	lxi	d,MSG21
	mvi	c,SYS_STRING_OUT
	call	bdos
	call	displayCRLF
	lxi	d,MSG22
	mvi	c,SYS_STRING_OUT
	call	bdos
	call	displayCRLF
	lxi	d,0fh		; offset to memory segments address start.
	call	offset		; hl now pointing to memory seg address.
	adi	1		; make one higher.
	sta	segcnt		; store memory segment count in memory.

memore:
	inx	h		; next byte.
	mov	d,m		; get high order address.
	mvi	e,0		; force low byte to zero.
	lda	segcnt		; put into a.
	sui	1		; if none zero then is memory segment.
	sta	segcnt		; less one on the counter.
	jz	numrecd		; go do number of records check.

mem1time:
	push	h		; save hl.
	xchg			; put de into hl.
	call	adout		; output address.
	xchg			; get bck hl.

	lxi	d,MSG23		; output a few spaces.
	mvi	c,SYS_STRING_OUT	; print it.
	call	bdos

	pop	h		; get it back.
	inx	h		; now we are there.
	mov	d,m		; get high address.
				; note high low reversed for memory seg size.
	mvi	e,0		; force to 0.
	xchg			; put de into hl.
	call	adout		; output size.
	xchg			; get back hl.

; add these functions later.
	inx	h		; increment past attrabute.
	inx	h		; increment past segment times.

	push	h		; save it.

	lxi	d,MSG23		; output a few spaces.
	mvi	c,SYS_STRING_OUT	; print it.
	call	bdos

	pop	h		; get it back.
	mov	a,m		; get bnk number.
	push	h		; save it again.
	call	heout		; go print hex output.
	call	displayCRLF		; do cr,lf
	pop	h		; restore pointer.

	jmp	memore		; do till done.

dobyte:
	mov	a,m		; note, this uses nibbles for time.
	ani	0f0h		; drop lower nibble.
	rar			; do four.
	rar			; 
	rar			; 
	rar			; now have in lower nibble, time tens.
	adi	ASCII_OFFSET		; add ascii offset.
	call	charDisplay		; go print it.
	mov	a,m		; get byte again.
	ani	MASK_LO_NIBBLE		; leave low nibble.
	adi	ASCII_OFFSET		; add ascii offset, time units.
	call	charDisplay		; go print it.
	ret			; done.

offset:
	push	d
	mvi	c,sysdat	; get system data address.
	call	bdos		; comes back in hl.
	pop	d
	dad	d		; hl now pointing area in system data
				; for location pointed to by the d&e.
	mov	a,m		; has how many memory segments their are in
	ret			; done here.

; This section allows for future expantion of the MP/M II info at the
; data page address.

numrecd:
	lxi	d,MSG47		; go print MP/M.SYS records.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,79h		; increment
	call	offset		; dad the d wth the h&l.
	call	heout		; go print it in hex format.
	dcx	h		; one less low-order byte.
	mov	a,m		; get it.
	call	heout		; print it.
	call	displayCRLF		; cr lf printed.

	lxi	d,MSG48		; ticks/sec.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,7ah		; increment
	call	offset		; dad the d wth the h&l.
	call	heout		; go print it in hex format.
	call	displayCRLF		; print cr,lf.

	lxi	d,MSG49		; system drive.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,7bh		; increment
	call	offset		; dad the d wth the h&l.
	adi	40h		; add ascii offset for drive indicator.
	call	charDisplay		; go print it.
	call	displayCRLF		; print cr,lf.

	lxi	d,MSG50		; go print the Common memory.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,7ch		; increment
	call	offset		; dad the d wth the h&l.
	call	heout		; go print it in hex format.
	mvi	a,0		; force to zer0.
	call	heout		; go print it in hex format.
	call	displayCRLF		; do cr,lf.

	lxi	d,MSG51		; #RSP's.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,7dh		; increment
	call	offset		; dad the d wth the h&l.
	adi	ASCII_OFFSET		; add ascii offset.
	call	charDisplay		; go print it.
	call	displayCRLF		; print cr,lf.

	lxi	d,MSG52		; go print the listcp array.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,7fh		; increment
	call	offset		; dad the d wth the h&l.
	call	heout		; go print it in hex format.
	dcx	h		; decement.
	mov	a,m		; get low-order byte.
	call	heout		; go print it in hex format.
	call	displayCRLF		; do cr,lf.

	lxi	d,MSG53		; max locked records.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,0bbh		; increment
	call	offset		; dad the d wth the h&l.
	call	heout		; go print it in hex format.
	call	displayCRLF		; print cr,lf.

	lxi	d,MSG54		; max opened files.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,0bch		; increment
	call	offset		; dad the d wth the h&l.
	call	heout		; go print it in hex format.
	call	displayCRLF		; print cr,lf.

	lxi	d,MSG55		; # list items.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,0beh		; increment
	call	offset		; dad the d wth the h&l.
	call	heout		; go print it in hex format.
	dcx	h		; decement.
	mov	a,m		; get low-order byte.
	call	heout		; go print it in hex format.
	call	displayCRLF		; do cr,lf.

	lxi	d,MSG56		; system locked records.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,0c1h		; increment
	call	offset		; dad the d wth the h&l.
	call	heout		; go print it in hex format.
	call	displayCRLF		; print cr,lf.

	lxi	d,MSG57		; system opened files.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,0c2h		; increment
	call	offset		; dad the d wth the h&l.
	call	heout		; go print it in hex format.
	call	displayCRLF		; print cr,lf.

	lxi	d,MSG58		; go print dayfile.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,0c3h		; increment to dayfile active/nonactive.
	call	offset		; dad the d wth the h&l.	ani	0ffh		; see if boolean non zero if banked switched.
	jnz	dactive		; go do active message.
	lxi	d,MSG59		; go print the dayfile is inactive.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	call	displayCRLF		; do cr,lf.

dactive:
	lxi	d,MSG60		; go print the dayfile is active.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	call	displayCRLF		; do cr,lf.

	lxi	d,MSG61		; temporary drive.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,0c4h		; increment
	call	offset		; dad the d wth the h&l.
	adi	40h		; add ascii offset for drive indicator.
	call	charDisplay		; go print it.
	call	displayCRLF		; print cr,lf.

	lxi	d,MSG62		; # of list devices.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,0c5h		; increment
	call	offset		; dad the d wth the h&l.
	adi	ASCII_OFFSET		; add ascii offset.
	call	charDisplay		; go print it.
	call	displayCRLF		; print cr,lf.

	lxi	d,MSG63		; go print the XDOS base page.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,0f2h		; increment
	call	offset		; dad the d wth the h&l.
 	call	heout		; go print it in hex format.
	mvi	a,0		; force to zer0.
	call	heout		; go print it in hex format.
	call	displayCRLF		; do cr,lf.

	lxi	d,MSG64		; go print the TMP base page.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,0f3h		; increment
	call	offset		; dad the d wth the h&l.
	call	heout		; go print it in hex format.
	mvi	a,0		; force to zer0.
	call	heout		; go print it in hex format.
	call	displayCRLF		; do cr,lf.

	lxi	d,MSG65		; go print the console.dat base.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,0f4h		; increment
	call	offset		; dad the d wth the h&l.
	call	heout		; go print it in hex format.
	mvi	a,0		; force to zer0.
	call	heout		; go print it in hex format.
	call	displayCRLF		; do cr,lf.

	lxi	d,MSG66		; BDOS / XDOS entry point.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,0f6h		; increment
	call	offset		; dad the d wth the h&l.
	call	heout		; go print it in hex format.
	dcx	h		; decement.
	mov	a,m		; get low-order byte.
	call	heout		; go print it in hex format.
	call	displayCRLF		; do cr,lf.

	lxi	d,MSG67		; TMP.spr base page.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,0f7h		; increment
	call	offset		; dad the d wth the h&l.
	call	heout		; go print it in hex format.
	mvi	a,0		; force to zer0.
	call	heout		; go print it in hex format.
	call	displayCRLF		; do cr,lf.

	lxi	d,MSG68		; number of banked RSP's.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,0f8h		; increment
	call	offset		; dad the d wth the h&l.
	call	heout		; go print it in hex format.
	mvi	a,0		; force to zer0.
	call	heout		; go print it in hex format.
	call	displayCRLF		; do cr,lf.

	lxi	d,MSG69		; XDOS internal data segment address.
	mvi	c,SYS_STRING_OUT	; string output function.
	call	bdos		; do it.
	lxi	d,0fch		; increment
	call	offset		; dad the d wth the h&l.
	call	heout		; go print it in hex format.
	dcx	h		; decement.
	mov	a,m		; get low-order byte.
	call	heout		; go print it in hex format.
	call	displayCRLF		; do cr,lf.

; Determine which drive is the current drive in
; use, and print the result

drvchk:
	LXI	D,MSG18
	MVI	C,SYS_STRING_OUT
	CALL	BDOS
	MVI	C,CURDRV
	CALL	BDOS
	ADI	41H
	STA	CDRV
	CALL	charDisplay
	MVI	A,PERIOD
	CALL	charDisplay
	CALL	displayCRLF

; Determine Allocation address of current drive, and print it

	lda	mpmFlag		; see if MP/M.
	ora	a		; none zero if so.
	jnz	mpmcurt		; do MP/M current allocation.

	lda	cpmVersion
	ani	0f0h		; see if 1.x version.
	jz	rport		; go to do the i/o ports, if not 2.x CP/M.

mpmcurt:
	LXI	D,MSG5
	MVI	C,SYS_STRING_OUT
	CALL	BDOS
	LDA	CDRV
	CALL	charDisplay
	LXI	D,MSG6
	MVI	C,SYS_STRING_OUT
	CALL	BDOS
	LHLD	allocVector
	CALL	ADOUT
	MVI	A,48H
	CALL	charDisplay
	CALL	displayCRLF

; Find out which drives are logged in and print them

	MVI	C,LOGIN
	CALL	BDOS
	ANI	MASK_LO_NIBBLE		; leave low nibble.
	STA	VECTOR
	LXI	D,MSG4
	MVI	C,SYS_STRING_OUT
	CALL	BDOS
	LDA	VECTOR
	RRC
	STA	VECTOR
	LXI	D,MSG7
	MVI	C,SYS_STRING_OUT
	CC	BDOS
	LDA	VECTOR
	RRC
	STA	VECTOR
	LXI	D,MSG8
	MVI	C,SYS_STRING_OUT
	CC	BDOS
	LDA	VECTOR
	RRC
	STA	VECTOR
	LXI	D,MSG9
	MVI	C,SYS_STRING_OUT
	CC	BDOS
	LDA	VECTOR
	RRC
	LXI	D,MSG10
	MVI	C,SYS_STRING_OUT
	CC	BDOS
	CALL	displayCRLF

; Find and show the read only vectors

	MVI	C,RONLY
	CALL	BDOS
	ANI	MASK_LO_NIBBLE		; leave low nibble.
	STA	VECTOR
	LXI	D,MSG14
	MVI	C,SYS_STRING_OUT
	CALL	BDOS
	LDA	VECTOR
	ORA	A
	LXI	D,MSG17
	MVI	C,SYS_STRING_OUT
	CZ	BDOS
	LDA	VECTOR
	RRC
	STA	VECTOR
	LXI	D,MSG7
	MVI	C,SYS_STRING_OUT
	CC	BDOS
	LDA	VECTOR
	RRC
	STA	VECTOR
	LXI	D,MSG8
	MVI	C,SYS_STRING_OUT
	CC	BDOS
	LDA	VECTOR
	RRC
	STA	VECTOR
	LXI	D,MSG9
	MVI	C,SYS_STRING_OUT
	CC	BDOS
	LDA	VECTOR
	RRC
	LXI	D,MSG10
	MVI	C,SYS_STRING_OUT
	CC	BDOS
	CALL	displayCRLF

; Get the disk parameter block and display it

	LXI	D,MSG12
	MVI	C,SYS_STRING_OUT
	CALL	BDOS
	MVI	C,DPARA
	CALL	BDOS
	CALL	ADOUT
	MVI	A,48H
	CALL	charDisplay
	CALL	displayCRLF

; Determine the present USER, and print the result

	LXI	D,MSG19
	MVI	C,SYS_STRING_OUT
	CALL	BDOS
	MVI	E,0FFH
	MVI	C,PRUSER
	CALL	BDOS
	CALL	HEOUT
	MVI	A,48H
	CALL	charDisplay
	CALL	displayCRLF

; Check all ports (0-255), and determine if they
; are active. If they are, print the port number
; and then do a warm boot (control C)

; BE ADVISED!!

; The lable PORT1 gets a byte from storage from a
; lable called BYTE. This value is incremented from
; 0-255 and then is written to the second byte from
; the lable PORT2. What I'm saying is that this
; portion of code is SELF MODIFYING!!

rport:
	LXI	D,MSG16
	MVI	C,SYS_STRING_OUT
	CALL	BDOS
	lda	porta
	sta	aport+1
	lda	portb
	sta	bport+1

PORT1:
	LDA	BYTE
	STA	PORT3+1

aport:
	cpi	0	; original code had a d0 or something
	jm	port3
bport:
	cpi	0
	jm	port2
	jmp	port3

port2:
	call	portout
	jmp	port4

port3:
	IN	0
	CPI	0FFH
	CNZ	PORTOUT

	lda	byte
	cpi	0ffh
	jz	finish

port4:
	LDA	BYTE
	INR	A
	STA	BYTE
	JMP	PORT1

finish:
	LHLD	OLDSP
	SPHL
	RET

PORTOUT:
	LDA	BYTE
	CALL	HEOUT
	CALL	displaySpace
	RET

charDisplay:				; Character output
	PUSH	B
	PUSH	D
	PUSH	H
	MOV		E,A
	MVI		C,SYS_CONOUT
	CALL	BDOS
	POP		H
	POP		D
	POP		B
	RET

; The following routine will print the value of
; HL to the console. If entered at HEOUT, it will
; only print the value of the A register

ADOUT:				; Output HL to console
	MOV	A,H		; H is first
	CALL	HEOUT
	MOV	A,L		; L is next
HEOUT:
	MOV	C,A		; Save it
	RRC
	RRC
	RRC
	RRC
	CALL	HEOUT1		; Put it out
	MOV	A,C		; Get it back

HEOUT1:
	ANI	MASK_LO_NIBBLE		; leave low nibble.
	ADI	48
	CPI	58		; 0-9?
	JC	OUTCH
	ADI	7		; Make it a letter

OUTCH:
	CALL	charDisplay
	RET

clearDisplay:				; Clear console
	MVI		C,25			; number of display lines + 1
	MVI		A,CR		; C/R
	CALL	charDisplay

clearDisplay1:
	MVI		A,LF		; Linefeed
	CALL	charDisplay
	DCR		C
	JNZ		clearDisplay1		; Loop for 25 LF
	RET

displayCRLF:				; Send C/R, LF
	MVI		A,CR
	CALL	charDisplay
	MVI		A,LF
	CALL	charDisplay
	RET

displaySpace:
	MVI		A,SPACE
	CALL	charDisplay
	RET

; PROGRAM MESSAGES

MSG0:	db	'Status report CP/M version $'
MSG1:	DB	'    M=RAM memory           R=ROM memory'
	DB	'          .=no memory',CR,LF
	DB	'0   1   2   3   4   5   6   7   8   9'
	DB	'   A   B   C   D   E   F'
	DB	CR,LF,'$'
MSG2:	DB	'CCP starts at $'
MSG3:	DB	'BDOS starts at $'
MSG4:	DB	'Current logged in drives -  $'
MSG5:	DB	'The Allocation address of drive $'
MSG6:	DB	'- is $'
MSG7:	DB	'A$'
MSG8:	DB	' - B$'
MSG9:	DB	' - C$'
MSG10:	DB	' - D$'
MSG11:	DB	' bytes$'
MSG12:	DB	'The address of the disk '
	DB	'parameter block is $'
MSG13:	DB	'Available TPA without '
	DB	'killing the CCP is $'
MSG14:	DB	'These drives are vectored'
	DB	' as read only.  $'
MSG15:	DB	'BIOS starts at $'
MSG16:	DB	'Active I/O ports: $'
MSG17:	DB	'None$'
MSG18:	DB	'Current drive in use is $'
MSG19:	DB	'The present USER number is $'
MSG20:	db	'XIOS jmp table starts at $'
MSG21:	db	'Memory segments are $'
MSG22:	db	'base         size        bank $'
MSG23:	db	'         $'
MSG25:	db	'Your console number is $'
MSG26:	db	'The system time of day is $'
MSG24:	db	'Status report for the P.H.O.T.U.S.'
	db	' system - MP/M version $'
MSG27:	db	' system',CR,LF
	db	'              - Program Version 1.8'
		; version as of (05-Jan-84)
	DB	CR,LF,LF,'$'
MSG28:	db	'The number of consoles supported in this system is $'
MSG29:	db	'Restart number is #$'
MSG30:	db	'CPU is a $'
MSG31:	db	'8080$'
MSG32:	db	'Z-80$'
MSG33:	db	'There is Banked switched memory$'
MSG35:	db	'Bdos resident page is active$'
MSG36:	db	'CP/Net is $'
MSG37:	db	'Inactive$'
MSG38:	db	'Active$'
MSG39:	db	'Xdos starts at $'
MSG40:	db	'RSP base page is at $'
MSG41:	db	'The banked Xios base page is at $'
MSG42:	db	'The banked Bdos base page is at $'
MSG43:	db	'The RESident BDOS base page is at $'
MSG44:	db	'Console number $'
MSG45:	db	' has $'
MSG46:	db	' nulls$'
MSG47:	db	'Number of records in MP/M.SYS file: $'
MSG48:	db	'System number of ticks/second: $'
MSG49:	db	'System drive is $'
MSG50:	db	'Common memory base page is at $'
MSG51:	db	'Number of RSPs is $'
MSG52:	db	'Listcp array address $'
MSG53:	db	'Maximun number of locked records per process $'
MSG54:	db	'Maximun number of opened files per process $'
MSG55:	db	'Number of list items $'
MSG56:	db	'Total of system locked records $'
MSG57:	db	'Total of system opened files $'
MSG58:	db	'Day file logging is $'
MSG59:	db	'Inactive$'
MSG60:	db	'Active$'
MSG61:	db	'Temporary file drive is $'
MSG62:	db	'The number of list devices supported in this system is $'
MSG63:	db	'Banked XDOS base page starts at $'
MSG64:	db	'TMP.spr process discriptor base $'
MSG65:	db	'Console.dat base $'
MSG66:	db	'BDOS / XDOS entry address is at $'
MSG67:	db	'TMP.spr base is $'
MSG68:	db	'Number of banked RSPs $'
MSG69:	db	'XDOS internal data segment address $'

MSG99:	db	'BSR controller is $'

	DS	80h		; Set up a stack area
STACK	EQU	$

startBDOS:	DS	2		; memory location of start of BDOS
netTPA:		DS	2		; available TPA without displacing the CCP
startCCP:	DS	2		; CCP starting address
CONTLR:	DS	1
OLDSP:	DS	2
BYTE:	DB	0
IOBYT:	DS	1
VECTOR:	DS	2
CDRV:	DS	1
allocVector:	DS	2	; address for allocation table
mpmFlag:	DS	1		; non-zero if MP/M
cpmVersion:	DS	1		; Current version
time:	ds	2
time1:	ds	3
timeend:	db	'$'
segcnt:	db	0
csole:	db	0
maxcon:	db	0
exiospt:	db	0

last:	db	0	; for MP/M prl file.
CodeEnd:
	END
