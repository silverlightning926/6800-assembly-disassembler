*-----------------------------------------------------------
* Title      : Final Project
* Written by : Group 4 - Arkar Kyaw Swar, Siddharth Rao, Eric Dang
* Date       : 06/02/2022
* Description: Disassembler
*-----------------------------------------------------------
HEXBITS                         EQU $100

FIRST_THREE_BITS_AFTER_OPCODE   EQU $200
SECOND_THREE_BITS_AFTER_OPCODE  EQU $210
THIRD_THREE_BITS_AFTER_OPCODE   EQU $220
FOURTH_THREE_BITS_AFTER_OPCODE  EQU $230

CR                              EQU $0D               
LF                              EQU $0A
 
                                ORG $1000  
         
*------------ PROMPT THE USER FOR ADDRESSES -----------------
START:                  

USER_INPUT      LEA            PROMPT1, A1                   * LOAD STARTING ADDRESS PROMPT TO A1
                MOVE.B         #14, D0                       * DISPLAY PROMPT
                TRAP           #15
                LEA            EXTRA1, A1                    * TO READ IN USER INPUT         
                MOVE.B         #2, D0                        * STORE USER INPUT STARTING ADDRESS STRING IN A1
                TRAP           #15
                MOVE.B         #0, D0                        * TO CHECK WHETHER STARTING OR ENDIND ADDRESS IN SUBROUTINE  
                JSR            CONVERT
                
                LEA            PROMPT2, A1                   * LOAD ENDING ADDRESS PROMPT TO A1
                MOVE.B         #14, D0                       * DISPLAY PROMPT
                TRAP           #15
                LEA            EXTRA2, A1                    * TO READ IN USER INPUT                              
                MOVE.B         #2, D0                        * STORE USER INPUT ENDING ADDRESS STRING IN A1
                TRAP           #15
                MOVE.B         #1, D0                        * TO CHECK WHETHER STARTING OR ENDIND ADDRESS IN SUBROUTINE   
                JSR            CONVERT
                BRA            MAIN
                
*------------ CONVERT THE ADDRESS STRINGS TO HEXADECIMAL VALUES -----------------
                
CONVERT         CLR.L          D3                            * TO STORE ASCII VALUES

                MOVE.L         #0, D2                        * LOOP COUNTER 
                MOVE.L         #8, D1                        * TERMINAL VALUE
                MOVE.L         #0, D6                        * TO STORE HEXADECIMAL VALUES OF ADDRESSES 
                
CONVERT_LOOP    CMP.L          D2, D1                        * CHECK TO TERMINATE THE LOOP
                BEQ            EXIT_CONV_LOOP                * BRANCH TO NEXT PART IF ABOVE CONDITION IS MET 
                
                MOVE.B         (A1)+, D3                     * READ A BYTE FROM A1 (A HEXADECIMAL DIGIT)
                
                CMP.B          #$40,D3                       * IF ASCII CODE IS > $40, IT IS A LETTER
                BGT            ASCII_TO_LETTER               * IF SO, BRANCH TO LETTER CONVERTER
                
                CMP.B          #$3A,D3                       * IF ASCII CODE IS < $3A, IT IS A NUMBER
                BLT            ASCII_TO_NUM                  * IF SO, BRANCH TO NUMBER CONVERTER
                
ASCII_TO_LETTER SUB.B          #$37,D3                       * CONVERT TO LETTER              
                BRA            SHIFT_AND_ADD                 

ASCII_TO_NUM    SUB.B          #$30,D3                       * CONVERT TO NUM                    
                
SHIFT_AND_ADD   LSL.L          #4, D6                        * SHIFT 
                ADD.B          D3, D6                        * ADD TO CURRENT VALUE 
                BRA            CONT
            
CONT            ADDQ.L         #1, D2
                BRA            CONVERT_LOOP
                
EXIT_CONV_LOOP  CMP.B          #0, D0
                BNE            RETURN
                MOVE.L         D6, D5
RETURN          RTS
* Here, we have starting address in D5 and ending address in D6 as hexadecimals

*----------------- READ OPCODE: MAIN LOOP -------------------------------

MAIN            MOVEA.L        D5, A2                        * START READING FROM D5(STARTING ADDRESS)            
                
READ_OPCODE     JSR             PRINT_MEM_ADDR
                JSR             PRINT_SPACE
                CLR.L           D3                            * WE WILL STORE EACH WORD FROM CURRENT INSTRUCTION IN D3
                CMP.W           A2, D6
                BLT             EXIT_MAIN_LOOP                                                              
                MOVE.W          (A2)+, D3                     * RETRIEVE OPCODE OF CURRENT INSTRUCTION
                
*------------------------- DECODE OPCODE -----------------------------------
                
                MOVE.W          D3, HEXBITS                 * MOVE D3 INTO HEXBITS
                
                LSR.W           #4, D3                      * SHIFT WORD INSTRUCTION (IN D3) BY 4 BITS
                LSR.W           #4, D3                      * SHIFT WORD INSTRUCTION (IN D3) BY 4 BITS
                LSR.W           #4, D3                      * SHIFT WORD INSTRUCTION (IN D3) BY 4 BITS
                                                            * D3 SHOULD NOW CONTAIN ONLY THE FIRST 4 BITS OF THE WORD (MOST OPCODES)
                
                CMP.B           #%1101, D3                          * COMPARE 4 BITS OF WORD TO ADD OPCODE (1101)
                BEQ             ADD_ADDA_OPCODE                     * IF EQUAL GO TO ADD_ADDA_OPCODE  

                CMP.B           #%0101, D3                          * COMPARE 4 BITS OF WORD TO ADD OPCODE (0101)
                BEQ             ADDQ_OPCODE                         * IF EQUAL GO TO ADDQ_OPCODE     
                
                CMP.B           #%1011, D3                          * COMPARE 4 BITS OF WORD TO CMP OPCODE (1011)
                BEQ             CMP_OPCODE                          * IF EQUAL GO TO CMP_OPCODE
                
                CMP.B           #%1000, D3                          * COMPARE 4 BITS OF WORD TO OR OPCODE (1000)
                BEQ             OR_OPCODE                           * IF EQUAL GO TO OR_OPCODE
                
                CMP.B           #%1001, D3                          * COMPARE 4 BITS OF WORD TO SUB OPCODE (1001)
                BEQ             SUB_OPCODE                          * IF EQUAL GO TO SUB_OPCODE
                
                CMP.B           #%1100, D3                          * COMPARE 4 BITS OF WORD TO ADD OPCODE (1100)                     
                BEQ             AND_OPCODE                          * IF EQUAL GO TO AND_OPCODE
                
                CMP.B           #%0001, D3                          * COMPARE 4 BITS OF WORD TO MOVE.B OPCODE (0001)
                BEQ             MOVEB_OPCODE                        * IF EQUAL GO TO MOVEB_OPCODE
                
                CMP.B           #%0111, D3                          * COMPARE 4 BITS OF THE WORD TO MOVEQ OPCODE (0111)
                BEQ             MOVEQ_OPCODE                        * IF EQUAL GO TO MOVEQ_OPCODE
                
                CMP.B           #%0011, D3                          * COMPARE 4 BITS OF THE WORD TO MOVEW/MOVEAW OPCODE (0011)
                BEQ             MOVEW_MOVEAW_OPCODE                 * IF EQUAL GO TO MOVEW_MOVEAW_OPCODE
                
                CMP.B           #%0010, D3                          * COMPARE 4 BITS OF THE WORD TO MOVEL/MOVEAL OPCODE (0010)
                BEQ             MOVEL_MOVEAL_OPCODE                 * IF EQUAL GO TO MOVEL_MOVEAL_OPCODE
                
                CMP.B           #%0110, D3                          * COMPARE 4 BITS OF THE WORD TO BCC OPCODE (0110)
                BEQ             BCC_BRA_OPCODE                      * IF EQUAL GO TO BCC_BRA_OPCODE
                
                CMP.B           #%0100, D3                          * COMPARE 4 BITS OF WORD TO LEA/NOP/JSR/RTS/MOVEM OPCODE (0100)
                BEQ             LEA_NOP_NOT_JSR_RTS_MOVEM_OPCODE    * IF EQUAL GO TO LEA_NOP_NOT_JSR_RTS_MOVEM_OPCODE
                
                CMP.B           #%1110, D3                          * COMPARE 4 BITS OF THE WORD TO LSL/ASR OPCODE (1110)
                BEQ             LSL_LSR_ASL_ASR_ROL_ROR_OPCODE      * IF EQUAL GO TO LSL_LSR_ASL_ASR_ROL_ROR_OPCODE
                
                JSR INVALID_OPCODE                                  * IF NOT EQUAL TO ABOVE OPCODE, ASSUME INVALID OPCODE/DATA
                
INVALID_OPCODE  
                LEA             INVALID_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                
                
                BRA             AFTER_OPCODE_DECODE
    
ADD_ADDA_OPCODE  


                
                BRA             AFTER_OPCODE_DECODE
                
ADDQ_OPCODE  


                
                BRA             AFTER_OPCODE_DECODE                
    
CMP_OPCODE  
                LEA             CMP_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                            
                JSR             SPLIT_AFTER_OPCODE
                JSR             SANATIZE_OPMODE
                JSR             PRINT_SIZE_CODE
                JSR             PRINT_SPACE
                
                MOVE.W          HEXBITS, D3
                JSR             SPLIT_AFTER_OPCODE
                
                BRA             AFTER_OPCODE_DECODE

OR_OPCODE
                
                
                
                BRA             AFTER_OPCODE_DECODE

SUB_OPCODE
                
                
                
                BRA             AFTER_OPCODE_DECODE

AND_OPCODE
                
                
                
                BRA             AFTER_OPCODE_DECODE

MOVEB_OPCODE
                
                
                
                BRA             AFTER_OPCODE_DECODE
                
MOVEQ_OPCODE
                
                
                
                BRA             AFTER_OPCODE_DECODE
                
MOVEW_MOVEAW_OPCODE
                
                
                
                BRA             AFTER_OPCODE_DECODE
        
MOVEL_MOVEAL_OPCODE
                
                                
                
                BRA             AFTER_OPCODE_DECODE
                
BCC_BRA_OPCODE
                
                
                
                BRA             AFTER_OPCODE_DECODE
                
LEA_NOP_NOT_JSR_RTS_MOVEM_OPCODE  
                
                
                              
                BRA             AFTER_OPCODE_DECODE

LSL_LSR_ASL_ASR_ROL_ROR_OPCODE
                
                
                
                BRA             AFTER_OPCODE_DECODE

*------------------------------- EA ---------------------------------------- 

AFTER_OPCODE_DECODE


*------------------------- PRINT OUT INSTRUCTION ----------------------------

*NOTE: WE NEED A CHECK HERE IF WE WANT TO STOP THE LOOP

                JSR             PRINT_NEWLINE

NEXT_INSTRUC    BRA             READ_OPCODE                   * IF DONE PRINTING INSTRUCTION AND THERE ARE MORE, READ ANOTHER 

*-------------------------- PROGRAM END ------------------------------------


EXIT_MAIN_LOOP  LEA             PROMPT3, A1                  * ASK USER IF THEY WANT TO KEEP USING THE PROGRAM
                MOVE.B          #14, D0                      * DISPLAY GOODBYE
                TRAP            #15  
                LEA             EXTRA3, A1                   * TO READ IN USER INPUT
                MOVE.B          #2, D0                       * STORE USER INPUT IN A1
                TRAP            #15    
                MOVE.B          (A1)+, D0           
                CMP.B           #$59, D0                     * CHECK IF USER TYPED IN "Y"
                BEQ             USER_INPUT
                
                LEA             GOODBYE, A1                  * LOAD GOOD BYE MESSAGE INTO A1
                MOVE.B          #14, D0                      * DISPLAY GOODBYE
                TRAP            #15                
                
                SIMHALT
                
SPLIT_AFTER_OPCODE
                MOVE.W          HEXBITS, D3
                LSL             #4,D3
                LSR             #4,D3
                LSR             #4,D3
                LSR             #4,D3
                LSR             #1,D3
                
                MOVE.W          D3, FIRST_THREE_BITS_AFTER_OPCODE
                
                MOVE.W          HEXBITS, D3
                
                LSL             #7,D3
                LSR             #7,D3
                LSR             #6,D3
                
                MOVE.W          D3, SECOND_THREE_BITS_AFTER_OPCODE
                
                MOVE.W          HEXBITS, D3
                
                LSL             #4,D3
                LSL             #4,D3
                LSL             #2,D3
                LSR             #4,D3
                LSR             #4,D3
                LSR             #2,D3
                LSR             #3,D3
                
                MOVE.W          D3, THIRD_THREE_BITS_AFTER_OPCODE

                MOVE            HEXBITS, D3
                LSL             #4,D3
                LSL             #4,D3
                LSL             #5,D3
                LSR             #4,D3
                LSR             #4,D3
                LSR             #5,D3

                MOVE.W          D3, FOURTH_THREE_BITS_AFTER_OPCODE

                MOVE.W          HEXBITS, D3
                RTS
                
SANATIZE_OPMODE
                MOVE.W          SECOND_THREE_BITS_AFTER_OPCODE, D3
                LSL             #6,D3
                LSL             #8,D3
                LSR             #6,D3
                LSR             #8,D3
                RTS

PRINT_SIZE_CODE
                CMPI.B          #%00, D3
                BEQ             PRINT_BYTE
                CMPI.B          #%01, D3
                BEQ             PRINT_WORD
                CMPI.B          #%10, D3
                BEQ             PRINT_LONG
                RTS
                
PRINT_BYTE      LEA             BYTE, A1
                MOVE.B          #14, D0
                TRAP            #15
                RTS
                
PRINT_WORD      LEA             WORD, A1
                MOVE.B          #14, D0
                TRAP            #15
                RTS
                
PRINT_LONG      LEA             LONG, A1
                MOVE.B          #14, D0
                TRAP            #15
                RTS
                
PRINT_MEM_ADDR  MOVE.L          A2, HEXBITS      
                JSR             HEX_TO_STRING			
    							
                MOVE.W          A2, HEXBITS   		
                JSR             HEX_TO_STRING
                RTS   
                
NUM_OR_LETTER   CMPI.B          #$09, D3
                BLE             CONVERT_NUM
                BRA             CONVERT_LETTER
                
HEX_TO_STRING   MOVE.W          HEXBITS, D3
                LSR.W           #4, D3
                LSR.W           #4, D3
                LSR.W           #4, D3
                JSR             NUM_OR_LETTER

                MOVE.W          HEXBITS, D3	 									 
                LSL.L           #4, D3  
                LSR.W           #4, D3
                LSR.W           #4, D3
                LSR.W           #4, D3 
                JSR             NUM_OR_LETTER

                MOVE.W          HEXBITS, D3	 										 
                LSL.L           #4, D3    
                LSL.L           #4, D3
                LSR.W           #4, D3
                LSR.W           #4, D3
                LSR.W           #4, D3 
                JSR             NUM_OR_LETTER
    
                MOVE.W          HEXBITS,D3										 
                LSL.L           #4, D3        
                LSL.L           #4, D3    
                LSL.L           #4, D3
                LSR.W           #4, D3
                LSR.W           #4, D3
                LSR.W           #4, D3  
                JSR             NUM_OR_LETTER       
    
                CLR.L           D3
                RTS
    
CONVERT_NUM     ADDI.W          #$30, D3 
                BRA             PRINT_LOOP
                
CONVERT_LETTER  ADDI.W          #$37, D3
                BRA             PRINT_LOOP

PRINT_LOOP      CMPI.B	        #$30, D3
			    BEQ		        ZERO
			    CMPI.B	        #$31, D3
			    BEQ		        ONE
			    CMPI.B	        #$32, D3
			    BEQ		        TWO
			    CMPI.B	        #$33, D3
			    BEQ		        THREE
                CMPI.B	        #$34, D3
			    BEQ		        FOUR
			    CMPI.B	        #$35, D3
			    BEQ		        FIVE
			    CMPI.B	        #$36, D3
			    BEQ		        SIX
			    CMPI.B	        #$37, D3
			    BEQ		        SEVEN
			    CMPI.B	        #$38, D3
			    BEQ		        EIGHT
			    CMPI.B	        #$39, D3
			    BEQ		        NINE
			    CMPI.B	        #$41, D3
			    BEQ		        A
			    CMPI.B	        #$42, D3
			    BEQ		        B
			    CMPI.B	        #$43, D3
			    BEQ		        C
			    CMPI.B	        #$44, D3
			    BEQ		        D
			    CMPI.B	        #$45, D3
			    BEQ		        E
			    CMPI.B	        #$46, D3
			    BEQ		        F   
			    
PRINT_NUM	    MOVE	        #14, D0
			    TRAP	        #15
			    RTS

PRINT_SPACE     LEA             STR_SPACE, A1
                MOVE.B          #14, D0
                TRAP            #15
                RTS

PRINT_NEWLINE   LEA             STR_SPACE, A1
                MOVE.B          #13, D0
                TRAP            #15
                RTS
                
ZERO		    LEA		        STRING0, A1
			    BRA		        PRINT_NUM
ONE		        LEA		        STRING1, A1
			    BRA		        PRINT_NUM
TWO		        LEA		        STRING2, A1
			    BRA		        PRINT_NUM
THREE		    LEA		        STRING3, A1
			    BRA		        PRINT_NUM
FOUR		    LEA		        STRING4, A1
			    BRA		        PRINT_NUM
FIVE		    LEA		        STRING5, A1
			    BRA		        PRINT_NUM
SIX		        LEA		        STRING6, A1
			    BRA		        PRINT_NUM
SEVEN		    LEA		        STRING7, A1
			    BRA		        PRINT_NUM
EIGHT		    LEA		        STRING8, A1
			    BRA		        PRINT_NUM
NINE		    LEA		        STRING9, A1
			    BRA		        PRINT_NUM
A		        LEA		        STRINGA, A1
			    BRA		        PRINT_NUM
B   		    LEA		        STRINGB, A1
			    BRA		        PRINT_NUM
C   		    LEA		        STRINGC, A1
			    BRA		        PRINT_NUM
D     		    LEA		        STRINGD, A1
			    BRA		        PRINT_NUM
E		        LEA		        STRINGE, A1
			    BRA		        PRINT_NUM
F   		    LEA		        STRINGF, A1
			    BRA		        PRINT_NUM


PROMPT1	        DC.B 'Please enter the starting memory address in hexadecimal (Longword) form: ',0
EXTRA1          DC.B '         ', 0
PROMPT2	        DC.B 'Please enter the ending memory address in hexadecimal (Longword) form: ',0
EXTRA2          DC.B '         ', 0
PROMPT3	        DC.B 'Do you wish to read another program? Type ONLY "Y" for Yes and "N" for No: ',0
EXTRA3          DC.B '  ', 0
GOODBYE	        DC.B 'Thank you for using our disassembler! Good Bye.',0

STR_SPACE       DC.B ' ', 0
STRING_DOT      DC.B '.', 0

STRING0	        DC.B '0',0
STRING1	        DC.B '1',0
STRING2	        DC.B '2',0
STRING3	        DC.B '3',0
STRING4	        DC.B '4',0
STRING5	        DC.B '5',0
STRING6	        DC.B '6',0
STRING7	        DC.B '7',0
STRING8	        DC.B '8',0
STRING9	        DC.B '9',0
STRINGA	        DC.B 'A',0
STRINGB	        DC.B 'B',0
STRINGC	        DC.B 'C',0
STRINGD	        DC.B 'D',0
STRINGE	        DC.B 'E',0
STRINGF	        DC.B 'F',0

BYTE            DC.B 'B',0
WORD            DC.B 'W',0
LONG            DC.B 'L',0

INVALID_OPCODE_STRING   DC.B 'DATA',0
CMP_OPCODE_STRING       DC.B 'CMP.',0

                END    START






*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
