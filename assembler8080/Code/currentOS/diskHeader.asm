; diskHeader.asm

; 2017-03-02 Refactored the CP/M Suite

; needs osHeader.asm declared before this is used !!!!!!!

; Contains the Equates used by the CP/M system to handle disks


;*******************************************************************************
;
;     Disk related values
;
;
;*******************************************************************************
DiskStatusLocation		EQU		043H			; status after disk I/O placed here
DiskControlByte			EQU		045H			; control byte for disk I/O
DiskCommandBlock		EQU		046H			; Control Table Pointer
; for boot
DiskControlTable		EQU		0040H

DiskReadCode			EQU		01H				; Code for Read
DiskWriteCode			EQU		02H				; Code for Write


cpmRecordSize			EQU		080H			; (128) record size that CP/M uses
diskSectorSize			EQU		200H			; (512) size of physical disk I/O
recordsPerSector		EQU		diskSectorSize/cpmRecordSize

DirEntrySize			EQU		20H			; (32)
DirBuffSize				EQU		cpmRecordSize

DirectoryEntryPerRecord	EQU		cpmRecordSize / DirEntrySize

RecordsPerExtent		EQU		080H			; extent Record capacity


;-------------------------------------------------------------------------------------
NumberOfLogicalDisks	EQU		4				; max number of disk in this system

;----------------------3.5 Double Density Disk Geometry----------------------------------------
NumberOfHeads			EQU		02H			; number of heads
TracksPerHead			EQU		50H			; 80
SectorsPerTrack			EQU		12H			; 18 -  1 head only
SectorsPerBlock			EQU		04H			; 2048 bytes
DirectoryBlockCount		EQU		02H			;
;-----------------------------------------------------------------------

BlockSize				EQU		SectorsPerBlock * 	diskSectorSize	; Size in Bytes

RecordsPerBlock			EQU		recordsPerSector * SectorsPerBlock

TotalNumberOfSectors	EQU		SectorsPerTrack * TracksPerHead * NumberOfHeads
TotalNumberOfBlocks		EQU		TotalNumberOfSectors / SectorsPerBlock
SectorsPerCylinder		EQU		SectorsPerTrack * NumberOfHeads

SystemSectors			EQU		LengthInBytes / diskSectorSize + 1 	; need to account for boot sector
myOffset 				EQU		(SystemSectors / SectorsPerCylinder) + 1;
DataSectors				EQU     TotalNumberOfSectors - (SectorsPerCylinder * myOffset)
DataBlocks				EQU		DataSectors / 	SectorsPerBlock

;-----------------------------------------------------------------------
;; Disk block parameters for F3HD - 3.5 HD   1.44 MB Diskette
;-----------------------------------------------------------------------
;dpb3hdSPT				EQU		0090H			; cpmRecords per track- (144)
dpb3hdSPT					EQU		recordsPerSector * SectorsPerTrack * NumberOfHeads											; SPT - records per Clynder
dpb3hdBSH					EQU		04H				; Block Shift Factor - BlockSize = 128 * (2**BSH)											; BSH = Log2(BlockSize/cpmRecordSize)
dpb3hdBLM					EQU		0FH				; BlockMask = (2**BSH) -1
dpb3hdEXM					EQU		00H				; Extent mask = (PhysicalExtents/LogicalExtents) - 1
dpb3hdDSM					EQU		DataBlocks -1	; Maximum allocation block number (710)
dpb3hdDRM					EQU		((BlockSize *  DirectoryBlockCount)	/	DirEntrySize) -1											; DRM Number of directory entries - 1 (127)
dpb3hdAL0					EQU		0C0H			; Bit map for reserving 1 alloc. block
dpb3hdAL1					EQU		00H				;  for each file directory
dpb3hdCKS					EQU		(dpb3hdDRM +1)/ DirectoryEntryPerRecord											; Disk change work area size (32)
dpb3hdOFF					EQU		myOffset		; Number of tracks before directory
dpb3hdNOH					EQU		NumberOfHeads

;*******************************************************************************

SectorMask				EQU		SectorsPerBlock - 1

;***************************************************************************
