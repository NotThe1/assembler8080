;Source File name - testDirectives.asm
	DB	'COPYRIGHT (C) 1979 DIGITAL RESEARCH  '; 38	
SOH        EQU     01H        ; Start of Heading       

NULL       EQU     00H        ; Null                   
;BELL       EQU     07H        ; Bell                   
;LF         EQU     0AH        ; Line Feed              
;CR         EQU     0DH        ; Carriage Return        
;DOLLAR     EQU     24H        ; Dollar Sign            
;QMARK      EQU     3FH        ; Question Mark

pg0CommandTail	EQU	080H	; rest of cammand line          


            ORG  00100H
CodeStart:

;     <New code fragment-----from 0100 to 0102 ( 102 :  258)>
            
 ;         JMP	Start  


	DB	'NEXT without FOR'
	DB	NULL
	DS 8
	DB	'Syntax error'
	DB	NULL


              ORG  0200H
        DS  02H
LX0710:	DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
LX0720:	DB	0,0,0
		DS	5
		DB -1
		


BW0725:	DW	00				; init to 0000


B072B:	DW	-1				; init with Buffer1Add


;     <New code fragment-----from 0A99 to 0ABB ( ABB : 2747)>
              ORG  0300H
			  DS	0100H
L400:
Start:
          LXI  H,00004H  
          DAD  SP        
          MOV  A,M 

		  