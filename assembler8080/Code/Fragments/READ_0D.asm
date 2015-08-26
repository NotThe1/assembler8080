; READ_0D.asm	READ  FBFB - 0935
;
;************************************************************************************************
;        READ
; Read in the 128-byte CP/M sector specified by previous calls to select disk and to set track  and 
; sector. The sector will be read into the address specified in the previous call to set DMA address
;
; If reading from a disk drive using sectors larger than 128 bytes, de-blocking code will be used
; to unpack a 128-byte sector from  the physical sector. 
;************************************************************************************************
READ:
		LDA		DeblockingRequired
		ORA		A
		JZ		ReadNoDeblock			; if 0 use normal non-blocked read
; The de-blocking algorithm used is such that a read operation can be viewed UP until the actual
; data transfer as though it was the first write to an unallocated allocation block. 
				ReadNoDeblock:
					MVI		A,FloppyReadCode	; get read function code
				CommonNoDeblock:
					STA		FloppyCommand		; set the correct command code
					LXI		H,128				; bytes per sector
					SHLD	FloppyByteCount
					XRA		A					; 8" has only head 0
					STA		FloppyHead
					
					LDA		SelectedDisk		; insure only disk 0 or 1
					ANI		01H
					STA		FloppyUnit			; set the unit number
					
					LDA		SelectedTrack
					STA		FloppyTrack			; set track number
					
					LDA		SelectedSector
					STA		FloppySector		; set sector
					
					LHLD	DMAAddress
					SHLD	FloppyDMAAddress	; set transfer address
					
				;  The disk controller can accept chained disk control tables, but in this case
				; they are not used. so the "Next" pointers must be pointed back at the initial
				; control bytes in the base page. 
					LXI		H,DiskStatusBlock
					SHLD	FloppyNextStatusBlock	; set pointer back to start
					LXI		H,DiskControl8
					SHLD	FloppyNextControlLocation	; set pointer back to start
					LXI		H,FloppyCommand
					SHLD	CommandBlock8
					
					LXI		H,DiskControl8
					MVI		M,080H				; activate the controller to perform operation
					JMP		WaitForDiskComplete
							;Wait until Disk Status Block indicates , operation complete, then check 
							; if any errors occurred. ,On entry HL -> disk control byte	
							WaitForDiskComplete:
								MOV		A,M				; get control bytes
								ORA		A
								JNZ		WaitForDiskComplete	; operation not done
								
								LDA		DiskStatusBlock		; done , so now check status
								CPI		080H
								JC		DiskError
										DiskError:
											MVI		A,1
											STA		DiskErrorFlag		; set the error flag
											RET
								XRA		A
								STA		DiskErrorFlag		; clear the flag
								RET
				; end of ReadNoDeblock *******
		XRA		A					; set record count to 0
		STA		UnalocatedlRecordCount
		INR		A
		STA		ReadOperation			; Indicate that this is a read
		STA		MustPreReadSector		; force pre-read
		MVI		A,WriteUnallocated		; fake de-blocking code into responding as if this
		STA		WriteType				;  is the first write to an unallocated allocation block
		JMP		PerformReadWrite		; use common code to execute read
				PerformReadWrite:
				;*******************************************************
				; Common code to execute both reads and writes of 128-byte sectors	
				;*******************************************************	
						XRA		A				; Assume no disk error will occur
						STA		DiskErrorFlag
						LDA		SelectedSector
						RAR						; Convert selected 128-byte sector
						RAR						; into physical sector by dividing by 4
						ANI		03FH			; remove unwanted bits
						STA		SelectedPhysicalSector
						LXI		H,DataInDiskBuffer	; see if there is any data here ?
						MOV		A,M
						MVI		M,001H				; force there is data
						ORA		A					; any data here ?
						JZ		ReadSectorIntoBuffer	; NO - go read into buffer
				;
				;The buffer does have a physical sector in it.
				; Note: The disk. track. and PHYSICAL sector in the buffer need to be checked,
				; hence the use of the CompareDkTrk subroutine
				;
						LXI		D,InBufferDkTrkSec
						LXI		H,SelectedDkTrkSec	; is it the same 
						CALL	CompareDkTrk		;    Disk and Track as selected ?
								CompareDkTrk:					;Compares just the disk and track   pointed to by DE and HL 
										MVI		C,03H			; Disk(1), Track(2)
										JMP		CompareDkTrkSecLoop
												CompareDkTrkSecLoop:
														LDAX	D
														CMP		M
														RNZ						; Not equal
														INX	D
														INX	H
														DCR		C
														RZ						; return they match (zero flag set)
														JMP		CompareDkTrkSecLoop	; keep going
						JNZ		SectorNotInBuffer	; NO, it must be read
				; it is in the buffer
						LDA		InBufferSector		; get the sector
						LXI		H,SelectedPhysicalSector
						CMP		M					; Check if correct physical sector
						JZ		SectorInBuffer		; Yes - it is already in memory
						
				; No, it will have to be read in over current contents of buffer
				SectorNotInBuffer:
						LDA		MustWriteBuffer
						ORA		A					; do we need to write ?
						CNZ		WritePhysical		; Yes - write it out
								WritePhysical:
									MVI		A,FloppyWriteCode	; get write function
									JMP		CommonPhysical
											CommonPhysical:
												STA		FloppyCommand		; set the command
												
												LDA		DiskType
												CPI		Floppy5				; is it 5 1/4 ?
												JZ		CorrectDisktype		; yes
												MVI		A,1
												STA		DiskError			; no set error and exit
												RET
				ReadSectorIntoBuffer:
						CALL	SetInBufferDkTrkSector
						LDA		MustPrereadSector	; do we need to pre-read
						ORA		A
						CNZ		ReadPhysical		; yes - pre-read the sector
								ReadPhysical:
									MVI		A,FloppyReadCode	; get read function
								CommonPhysical:
									STA		FloppyCommand		; set the command
									
									LDA		DiskType
									CPI		Floppy5				; is it 5 1/4 ?
									JZ		CorrectDisktype		; yes
									MVI		A,1
									STA		DiskError			; no set error and exit
	RET
						XRA		A					; reset the flag
						STA		MustWriteBuffer
						
				; Selected sector on correct track and  disk is already 1n the buffer.
				; Convert the selected CP/M(128-byte sector into relative address down the buffer. 
				SectorInBuffer:
						LDA		SelectedSector
						ANI		SectorMask			; only want the least bits
						MOV		L,A
						MVI		H,00H				; Multiply by 128
						DAD		H					; *2
						DAD		H					; *4
						DAD		H					; *8
						DAD		H					; *16
						DAD		H					; *32
						DAD		H					; *64
						DAD		H					; *128
						LXI		D,DiskBuffer
						DAD		D					; HL -> 128-byte sector number start address
						XCHG						; DE -> sector in the disk buffer
						LHLD	DMAAddress			; Get DMA address (set in SETDMA)
						XCHG						; assume a read so :
													; DE -> DMA Address & HL -> sector in disk buffer
						MVI		C,128/8				; 8 bytes per move (loop count)
				;
				;  At this point -
				;	C	->	loop count
				;	DE	->	DMA address
				;	HL	->	sector in disk buffer
				;
						LDA		ReadOperation		; Move into or out of buffer /
						ORA		A
						JNZ		BufferMove			; Move out of buffer
						
						INR		A					; going to force a write
						STA		MustWriteBuffer
						XCHG						; DE <--> HL
						
				;The following move loop moves eight bytes at a time from (HL> to (DE), C contains the loop count
				BufferMove:
						MOV		A,M					; Get byte from source
						STAX	D					; Put into destination
						INX		D					; update pointers
						INX		H
						
						MOV		A,M					; Get byte from source
						STAX	D					; Put into destination
						INX		D					; update pointers
						INX		H
						
						MOV		A,M					; Get byte from source
						STAX	D					; Put into destination
						INX		D					; update pointers
						INX		H
						
						MOV		A,M					; Get byte from source
						STAX	D					; Put into destination
						INX		D					; update pointers
						INX		H
						
						MOV		A,M					; Get byte from source
						STAX	D					; Put into destination
						INX		D					; update pointers
						INX		H
						
						MOV		A,M					; Get byte from source
						STAX	D					; Put into destination
						INX		D					; update pointers
						INX		H
						
						MOV		A,M					; Get byte from source
						STAX	D					; Put into destination
						INX		D					; update pointers
						INX		H
						
						MOV		A,M					; Get byte from source
						STAX	D					; Put into destination
						INX		D					; update pointers
						INX		H
						
						DCR		C					; count down on loop counter
						JNZ		BufferMove			; repeat till done (CP/M sector moved)
				; end of loop		
						LDA		WriteType			; write to directory ?
						CPI		WriteDirectory
						LDA		DiskErrorFlag		; get flag in case of a delayed read or write
						RNZ							; return if delayed read or write
						
						ORA		A					; Any disk errors ?
						RNZ							; yes - abandon attempt to write to directory
						
						XRA		A
						STA		MustWriteBuffer		; clear flag
						CALL	WritePhysical
						LDA		DiskErrorFlag		; return error flag to caller
						RET
				;********************************************************************
