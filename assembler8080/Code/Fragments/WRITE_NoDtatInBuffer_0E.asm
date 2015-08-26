; WRITE_NoDtatInBuffer_0E.asm	WRITE  FBFB - 0935
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