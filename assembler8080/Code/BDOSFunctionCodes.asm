fcSysReset	EQU		0		; System Reset
fcConIn		EQU		1		; Read Console Byte
fcConOut	EQU		2		; Write Console Byte
fcReadIn	EQU		3		; Read "Reader" Byte
fcPunOut	EQU		4		; Write "Punch" Byte
fcListOut	EQU		5		; Write Printer Byte
fcDirConIO	EQU		6		; Direct Console I/o
fcGetIO		EQU		7		; Get IOBYTE
fcSetIO		EQU		8		;  Set IOBYTE
fcPrintS	EQU		9		; Print Console String
fcReadConS	EQU		10		; Read Console String
fcConST		EQU		11		;  Read Console Status
fcGetVer	EQU		12		;  Get CP/M Version Number
fcDskReser	EQU		13		; Disk System Reset
fcSelDsk	EQU		14		; Select Disk
fcOpen		EQU		15		; Open File
fcClose		EQU		16		; Close File
fcSearchF	EQU		17		; Search For First Name Match
fcSearchN	EQU		18		; Search For Next Name Match
fcErase		EQU		19		; Erase (Delete) File
fcReadSeq	EQU		20		; Read Sequential
fcWriteSeq	EQU		21		; Write Sequential
fcCreate	EQU		22		; Create File
fcRename	EQU		23		; Rename File
fcGetActDsk	EQU		24		; Get Active(Logger-in) Disks
fcGetCurDsk	EQU		25		; Get Current Default Disk
fcSetDMA	EQU		26		; Set DMA (Read/Write) Address
fcGetAlVec	EQU		27		; Get Allocation Vector aDDRESS
fcSetDskRO	EQU		28		; Set Disk Read-Only
fcGetRODsks	EQU		29		; Get  Read-Only Disks
fcSetFAT	EQU		30		; Set File Attributes
gcGetDPB	EQU		31		; Get Disk Parameter Block Address
fcSetGetUn	EQU		32		; Set/Get Unit Number
fcReadRan	EQU		33		; Read Random
fcWriteRan	EQU		34		; Write Random
fcGetFSiz	EQU		35		; Get File Size
fcSetRanRec	EQU		36		; Set Random Record Number
fcResetD	EQU		37		; Reset Drive
fc38		EQU		38		; Unimplemented code
fc39		EQU		39		; Unimplemented code
fcWriteRanZ	EQU		40		; Write Random with Zero-fill
