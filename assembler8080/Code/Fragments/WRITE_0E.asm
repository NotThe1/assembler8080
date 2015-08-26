; WRITE_0E.asm	WRITE  FBFB - 0935
;
;************************************************************************************************
;		WRITE
;Write a 128-byte sector from the current DMA address to the previously $elected disk, track, and sector.
;
; On arrival here, the BOOS will have set register C to indicate whether this write operation is to
; an already allocated allocation block (which means a pre-read of the sector may be needed),
; to the directory (in which case the data will be written to the disk immediately),
; or to the first 128-byte sector of a previously unallocated allocation block (In which case no pre-read is required).

; Only writes to the directory take place immediately. In all other cases, the data will be moved
; from the DMA address into the disk buffer, and only written out when circumstance, force the transfer.
; The number of physical disk operations can therefore be reduced considerably.
;************************************************************************************************
WRITE:
		LDA		DeblockingRequired
		ORA		A
		JZ		WriteNoDeblock			; if 0 use normal non-blocked write
				WriteNoDeblock:
					MVI		A,FloppyWriteCode	; get write function code
					JMP		CommonNoDeblock
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
											XRA		A
											STA		DiskErrorFlag		; clear the flag
											RET
											
										DiskError:
											MVI		A,1
											STA		DiskErrorFlag		; set the error flag
											RET

		XRA		A
		STA		ReadOperation			; its a write (Not a read)
		MOV		A,C
		STA		WriteType				; save the BDOS write type
		CPI		WriteUnallocated		; first write to an unallocated allocation block ?
		JNZ		CheckUnallocatedBlock	; No, - in the middle of writing to an unallocated block ?
										; Yes, first write to unallocated allocation block. Initialize
										; variables associated with unallocated writes
										
					; Check if this is not the first write to an unallocated allocation block -- if it is,
					; the unallocated record count has just been set to the number of 128-byte sectors in the allocation block
				CheckUnallocatedBlock:
						LDA		UnalocatedlRecordCount
						ORA		A
						JZ		RequestPreread			; No - write to an unallocated block
								RequestPreread:
										XRA		A
										STA		UnalocatedlRecordCount	; not a write into an unallocated block
										INR		A
										STA		MustPrereadSector		; set flag
								;*******************************************************
								; Common code to execute both reads and writes of 128-byte sectors	
								;*******************************************************	
								PerformReadWrite:
										XRA		A						; Assume no disk error will occur
										STA		DiskErrorFlag
										LDA		SelectedSector
										RAR								; Convert selected 128-byte sector
										RAR								; into physical sector by dividing by 4
										ANI		03FH					; remove unwanted bits
										STA		SelectedPhysicalSector
										LXI		H,DataInDiskBuffer		; see if there is any data here ?
										MOV		A,M
										MVI		M,001H					; force there is data here for after the actual read
										ORA		A						; really is there any data here ?
										JZ		ReadSectorIntoBuffer	; NO - go read into buffer
								;
										; The buffer does have a physical sector in it, Note: The disk, track, and PHYSICAL sector
										; in the buffer need to be checked, hence the use of the CompareDkTrk subroutine.
										LXI		D,InBufferDkTrkSec
										LXI		H,SelectedDkTrkSec		; get the requested sector
										CALL	CompareDkTrk			; is it in the buffer ? 
										JNZ		SectorNotInBuffer		; NO, it must be read
										; Yes, it is in the buffer
										LDA		InBufferSector			; get the sector
										LXI		H,SelectedPhysicalSector
										CMP		M						; Check if correct physical sector
										JZ		SectorInBuffer			; Yes - it is already in memory
										; No, it will have to be read in over current contents of buffer
								SectorNotInBuffer:
										LDA		MustWriteBuffer
										ORA		A						; do we need to write ?
										CNZ		WritePhysical			; if yes - write it out
								
								ReadSectorIntoBuffer:
										; indicate the  selected disk, track, and sector now residing in buffer
										LDA		SelectedDisk
										STA		InBufferDisk
										LHLD	SelectedTrack
										SHLD	InBufferTrack
										LDA		SelectedPhysicalSector
										STA		InBufferSector
										
										LDA		MustPrereadSector		; do we need to pre-read
										ORA		A
										CNZ		ReadPhysical			; yes - pre-read the sector
										XRA		A						; reset the flag
										STA		MustWriteBuffer			; and store it away
										
								; Selected sector on correct track and  disk is already 1n the buffer.
								; Convert the selected CP/M(128-byte sector into relative address down the buffer. 
								SectorInBuffer:
										LDA		SelectedSector
										ANI		SectorMask				; only want the least bits
										MOV		L,A						; to calculate offset into 512 byte buffer
										MVI		H,00H					; Multiply by 128
										DAD		H						; *2
										DAD		H						; *4
										DAD		H						; *8
										DAD		H						; *16
										DAD		H						; *32
										DAD		H						; *64
										DAD		H						; *128
										LXI		D,DiskBuffer
										DAD		D						; HL -> 128-byte sector number start address
										XCHG							; DE -> sector in the disk buffer
										LHLD	DMAAddress				; Get DMA address (set in SETDMA)
										XCHG							; assume a read so :
																		; DE -> DMA Address & HL -> sector in disk buffer
										MVI		C,128/8					; 8 bytes per move (loop count)
								;
								;  At this point -
								;	C	->	loop count
								;	DE	->	DMA address
								;	HL	->	sector in disk buffer
								;
										LDA		ReadOperation			; Move into or out of buffer /
										ORA		A
										JNZ		BufferMove				; Move out of buffer
										
										INR		A						; going to force a write
										STA		MustWriteBuffer
										XCHG							; DE <--> HL
										
								;The following move loop moves eight bytes at a time from (HL> to (DE), C contains the loop count
								BufferMove:
										MOV		A,M						; Get byte from source
										STAX	D						; Put into destination
										INX		D						; update pointers
										INX		H
										
										MOV		A,M	
										STAX	D
										INX		D
										INX		H
										
										MOV		A,M
										STAX	D
										INX		D
										INX		H
										
										MOV		A,M	
										STAX	D
										INX		D
										INX		H
										
										MOV		A,M
										STAX	D
										INX		D
										INX		H
										
										MOV		A,M
										STAX	D
										INX		D
										INX		H
										
										MOV		A,M	
										STAX	D
										INX		D
										INX		H
										
										MOV		A,M
										STAX	D
										INX		D
										INX		H
										
										DCR		C						; count down on loop counter
										JNZ		BufferMove				; repeat till done (CP/M sector moved)
								; end of loop
										
										LDA		WriteType				; write to directory ?
										CPI		WriteDirectory
										LDA		DiskErrorFlag			; get flag in case of a delayed read or write
										RNZ								; return if delayed read or write
										
										ORA		A						; Any disk errors ?
										RNZ								; yes - abandon attempt to write to directory
										
										XRA		A
										STA		MustWriteBuffer			; clear flag
										CALL	WritePhysical
										LDA		DiskErrorFlag			; return error flag to caller
										RET
						DCR		A						; decrement 128 byte sectors left
						STA		UnalocatedlRecordCount
						
						LXI		H,SelectedDkTrkSec		; same Disk, Track & sector as for those in an unallocated block
						LXI		D,UnallocatedDkTrkSec
						CALL	CompareDkTrkSec			; are they the same
						JNZ		RequestPreread			; NO - do a pre-read
														;Compare$DkSTrkSec  returns with  DE -> Unallocated$Sector , HL -> UnallocatedSSector 
						XCHG
						INR	M
						MOV		A,M
						CPI		CPMSecPerTrack			; Sector > maximum on track ?
						JC		NoTrackChange			; No ( A < M)
						MVI		M,00H					; Yes
						LHLD	UnallocatedTrack
						INX		H						; increment track 
						SHLD	UnallocatedTrack
				NoTrackChange:
						XRA		A
						STA		MustPrereadSector		; clear flag
						JMP		PerformReadWrite	
										
		MVI		A,AllocationBlockSize/ 128	; Number of 128 byte sectors
		STA		UnalocatedlRecordCount
		LXI		H,SelectedDkTrkSec		; copy disk, track & sector into unallocated variables
		LXI		D,UnallocatedDkTrkSec
		CALL 	MoveDkTrkSec
		
	; Check if this is not the first write to an unallocated allocation block -- if it is,
	; the unallocated record count has just been set to the number of 128-byte sectors in the allocation block
CheckUnallocatedBlock:
		LDA		UnalocatedlRecordCount
		ORA		A
		JZ		RequestPreread			; No - write to an unallocated block
		DCR		A						; decrement 128 byte sectors left
		STA		UnalocatedlRecordCount
		
		LXI		H,SelectedDkTrkSec		; same Disk, Track & sector as for those in an unallocated block
		LXI		D,UnallocatedDkTrkSec
		CALL	CompareDkTrkSec			; are they the same
		JNZ		RequestPreread			; NO - do a pre-read
										;Compare$DkSTrkSec  returns with  DE -> Unallocated$Sector , HL -> UnallocatedSSector 
		XCHG
		INR	M
		MOV		A,M
		CPI		CPMSecPerTrack			; Sector > maximum on track ?
		JC		NoTrackChange			; No ( A < M)
		MVI		M,00H					; Yes
		LHLD	UnallocatedTrack
		INX		H						; increment track 
		SHLD	UnallocatedTrack
NoTrackChange:
		XRA		A
		STA		MustPrereadSector		; clear flag
		JMP		PerformReadWrite
RequestPreread:
		XRA		A
		STA		UnalocatedlRecordCount	; not a write into an unallocated block
		INR		A
		STA		MustPrereadSector		; set flag
;*******************************************************
; Common code to execute both reads and writes of 128-byte sectors	
;*******************************************************	
PerformReadWrite:
		XRA		A						; Assume no disk error will occur
		STA		DiskErrorFlag
		LDA		SelectedSector
		RAR								; Convert selected 128-byte sector
		RAR								; into physical sector by dividing by 4
		ANI		03FH					; remove unwanted bits
		STA		SelectedPhysicalSector
		LXI		H,DataInDiskBuffer		; see if there is any data here ?
		MOV		A,M
		MVI		M,001H					; force there is data here for after the actual read
		ORA		A						; really is there any data here ?
		JZ		ReadSectorIntoBuffer	; NO - go read into buffer
;
		; The buffer does have a physical sector in it, Note: The disk, track, and PHYSICAL sector
		; in the buffer need to be checked, hence the use of the CompareDkTrk subroutine.
		LXI		D,InBufferDkTrkSec
		LXI		H,SelectedDkTrkSec		; get the requested sector
		CALL	CompareDkTrk			; is it in the buffer ? 
		JNZ		SectorNotInBuffer		; NO, it must be read
		; Yes, it is in the buffer
		LDA		InBufferSector			; get the sector
		LXI		H,SelectedPhysicalSector
		CMP		M						; Check if correct physical sector
		JZ		SectorInBuffer			; Yes - it is already in memory
		; No, it will have to be read in over current contents of buffer
SectorNotInBuffer:
		LDA		MustWriteBuffer
		ORA		A						; do we need to write ?
		CNZ		WritePhysical			; if yes - write it out

ReadSectorIntoBuffer:
		; indicate the  selected disk, track, and sector now residing in buffer
		LDA		SelectedDisk
		STA		InBufferDisk
		LHLD	SelectedTrack
		SHLD	InBufferTrack
		LDA		SelectedPhysicalSector
		STA		InBufferSector
		
		LDA		MustPrereadSector		; do we need to pre-read
		ORA		A
		CNZ		ReadPhysical			; yes - pre-read the sector
		XRA		A						; reset the flag
		STA		MustWriteBuffer			; and store it away
		
; Selected sector on correct track and  disk is already 1n the buffer.
; Convert the selected CP/M(128-byte sector into relative address down the buffer. 
SectorInBuffer:
		LDA		SelectedSector
		ANI		SectorMask				; only want the least bits
		MOV		L,A						; to calculate offset into 512 byte buffer
		MVI		H,00H					; Multiply by 128
		DAD		H						; *2
		DAD		H						; *4
		DAD		H						; *8
		DAD		H						; *16
		DAD		H						; *32
		DAD		H						; *64
		DAD		H						; *128
		LXI		D,DiskBuffer
		DAD		D						; HL -> 128-byte sector number start address
		XCHG							; DE -> sector in the disk buffer
		LHLD	DMAAddress				; Get DMA address (set in SETDMA)
		XCHG							; assume a read so :
										; DE -> DMA Address & HL -> sector in disk buffer
		MVI		C,128/8					; 8 bytes per move (loop count)
;
;  At this point -
;	C	->	loop count
;	DE	->	DMA address
;	HL	->	sector in disk buffer
;
		LDA		ReadOperation			; Move into or out of buffer /
		ORA		A
		JNZ		BufferMove				; Move out of buffer
		
		INR		A						; going to force a write
		STA		MustWriteBuffer
		XCHG							; DE <--> HL
		
;The following move loop moves eight bytes at a time from (HL> to (DE), C contains the loop count
BufferMove:
		MOV		A,M						; Get byte from source
		STAX	D						; Put into destination
		INX		D						; update pointers
		INX		H
		
		MOV		A,M	
		STAX	D
		INX		D
		INX		H
		
		MOV		A,M
		STAX	D
		INX		D
		INX		H
		
		MOV		A,M	
		STAX	D
		INX		D
		INX		H
		
		MOV		A,M
		STAX	D
		INX		D
		INX		H
		
		MOV		A,M
		STAX	D
		INX		D
		INX		H
		
		MOV		A,M	
		STAX	D
		INX		D
		INX		H
		
		MOV		A,M
		STAX	D
		INX		D
		INX		H
		
		DCR		C						; count down on loop counter
		JNZ		BufferMove				; repeat till done (CP/M sector moved)
; end of loop
		
		LDA		WriteType				; write to directory ?
		CPI		WriteDirectory
		LDA		DiskErrorFlag			; get flag in case of a delayed read or write
		RNZ								; return if delayed read or write
		
		ORA		A						; Any disk errors ?
		RNZ								; yes - abandon attempt to write to directory
		
		XRA		A
		STA		MustWriteBuffer			; clear flag
		CALL	WritePhysical
		LDA		DiskErrorFlag			; return error flag to caller
		RET