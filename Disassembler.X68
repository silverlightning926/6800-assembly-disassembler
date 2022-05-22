*-----------------------------------------------------------
* Title      : Final Project
* Written by : Arkar Kyaw Swar, 
* Date       : 06/02/2022
* Description: Disassembler
*-----------------------------------------------------------
CR              EQU            $0D               
LF              EQU            $0A          
 
                ORG            $1000  
         
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
                
READ_OPCODE     CLR.L          D3                            * WE WILL STORE EACH WORD FROM CURRENT INSTRUCTION IN D3
                CMP.W          A2, D6
                BLT            EXIT_MAIN_LOOP                                                              
                MOVE.W         (A2)+, D3                     * RETRIEVE OPCODE OF CURRENT INSTRUCTION
                
*------------------------- DECODE OPCODE -----------------------------------               

                MOVE.L          D3, D7
                
                CMP.B           #$0D, D3
                BEQ             ADD_OPCODE
                
                CMP.B           #$0B, D3
                BEQ             CMP_OPCODE
                
                CMP.B           #$08, D3
                BEQ             OR_OPCODE
                
                CMP.B           #$09, D3
                BEQ             SUB_OPCODE
                
                CMP.B           #$0C, D3
                BEQ             AND_OPCODE
                
                CMP.B           #$01, D3
                BEQ             MOVEB_OPCODE
                
                CMP.B           #$03, D3
                BEQ             MOVEW_MOVEAW_OPCODE
                
                CMP.B           #$02, D3
                BEQ             MOVEL_MOVEAL_OPCODE
                
                CMP.B           #$06, D3
                BEQ             BCC_BGT_BLE_OPCODE
                
                CMP.B           #$4, D3
                BEQ             LEA_JSR_RTS_MOVEM_OPCODE
                
                CMP.B           #$0E, D3
                BEQ             LSL_ASR_OPCODE
                
                BRA INVALID_OPCODE
                
INVALID_OPCODE  
                LEA            INVALID_OPCODE_STRING, A1
                MOVE.B         #14, D0
                TRAP           #15
                BRA            AFTER_OPCODE_DECODE
    
ADD_OPCODE  
                LEA            ADD_OPCODE_STRING, A1
                MOVE.B         #14, D0
                TRAP           #15  
                BRA            AFTER_OPCODE_DECODE
    
CMP_OPCODE  
                LEA            CMP_OPCODE_STRING, A1
                MOVE.B         #14, D0
                TRAP           #15
                BRA            AFTER_OPCODE_DECODE

OR_OPCODE  
                LEA            OR_OPCODE_STRING, A1
                MOVE.B         #14, D0
                TRAP           #15
                BRA            AFTER_OPCODE_DECODE

SUB_OPCODE  
                LEA            SUB_OPCODE_STRING, A1
                MOVE.B         #14, D0
                TRAP           #15
                BRA            AFTER_OPCODE_DECODE

AND_OPCODE  
                LEA            AND_OPCODE_STRING, A1
                MOVE.B         #14, D0
                TRAP           #15
                BRA            AFTER_OPCODE_DECODE

MOVEB_OPCODE  
                LEA            MOVEB_OPCODE_STRING, A1
                MOVE.B         #14, D0
                TRAP           #15
                BRA            AFTER_OPCODE_DECODE
                
MOVEW_MOVEAW_OPCODE  
                LEA            MOVEW_MOVEAW_OPCODE_STRING, A1
                MOVE.B         #14, D0
                TRAP           #15
                BRA            AFTER_OPCODE_DECODE
        
MOVEL_MOVEAL_OPCODE  
                LEA            MOVEL_MOVEAL_OPCODE_STRING, A1
                MOVE.B         #14, D0
                TRAP           #15
                BRA            AFTER_OPCODE_DECODE
                
BCC_BGT_BLE_OPCODE  
                LEA            BCC_BGT_BLE_OPCODE_STRING, A1
                MOVE.B         #14, D0
                TRAP           #15
                BRA            AFTER_OPCODE_DECODE
                
LEA_JSR_RTS_MOVEM_OPCODE  
                LEA            LEA_JSR_RTS_MOVEM_OPCODE_STRING, A1
                MOVE.B         #14, D0
                TRAP           #15
                BRA            AFTER_OPCODE_DECODE

LSL_ASR_OPCODE  
                LEA            LSL_ASR_OPCODE_STRING, A1
                MOVE.B         #14, D0
                TRAP           #15
                BRA            AFTER_OPCODE_DECODE

*------------------------------- EA ---------------------------------------- 

AFTER_OPCODE_DECODE


*------------------------- PRINT OUT INSTRUCTION ----------------------------

*NOTE: WE NEED A CHECK HERE IF WE WANT TO STOP THE LOOP

               LEA            STR_SPACE, A1 ; NEW LINE PRINT FOR OPCODE DECODING TESTING
               MOVE.B         #13, D0       ; REMOVE WHEN WORKING ON IO
               TRAP           #15

NEXT_INSTRUC    BRA            READ_OPCODE                   * IF DONE PRINTING INSTRUCTION AND THERE ARE MORE, READ ANOTHER 

*-------------------------- PROGRAM END ------------------------------------


EXIT_MAIN_LOOP  LEA            PROMPT3, A1                  * ASK USER IF THEY WANT TO KEEP USING THE PROGRAM
                MOVE.B         #14, D0                      * DISPLAY GOODBYE
                TRAP           #15  
                LEA            EXTRA3, A1                   * TO READ IN USER INPUT
                MOVE.B         #2, D0                       * STORE USER INPUT IN A1
                TRAP           #15    
                MOVE.B         (A1)+, D0           
                CMP.B          #$59, D0                     * CHECK IF USER TYPED IN "Y"
                BEQ            USER_INPUT
                
                LEA            GOODBYE, A1                  * LOAD GOOD BYE MESSAGE INTO A1
                MOVE.B         #14, D0                      * DISPLAY GOODBYE
                TRAP           #15                
                
                SIMHALT    

PROMPT1	        DC.B 'Please enter the starting memory address in hexadecimal (Longword) form: ',0
EXTRA1          DC.B '         ', 0
PROMPT2	        DC.B 'Please enter the ending memory address in hexadecimal (Longword) form: ',0
EXTRA2          DC.B '         ', 0
PROMPT3	        DC.B 'Do you wish to read another program? Type ONLY "Y" for Yes and "N" for No: ',0
EXTRA3          DC.B '  ', 0
GOODBYE	        DC.B 'Thank you for using our disassembler! Good Bye.',0

STR_SPACE       DC.B ' ', 0

INVALID_OPCODE_STRING           DC.B 'Invalid Opcode',0
ADD_OPCODE_STRING               DC.B 'ADD',0
CMP_OPCODE_STRING               DC.B 'CMP',0
OR_OPCODE_STRING                DC.B 'OR',0
SUB_OPCODE_STRING               DC.B 'SUB',0
AND_OPCODE_STRING               DC.B 'AND',0
MOVEB_OPCODE_STRING             DC.B 'MOVE.B',0
MOVEW_MOVEAW_OPCODE_STRING      DC.B 'MOVEW/MOVEAW',0
MOVEL_MOVEAL_OPCODE_STRING      DC.B 'MOVEL/MOVEEAL',0
BCC_BGT_BLE_OPCODE_STRING       DC.B 'BCC/BGT/BLE',0
LEA_JSR_RTS_MOVEM_OPCODE_STRING DC.B 'LEA/JSR/RTS/MOVEM',0
LSL_ASR_OPCODE_STRING           DC.B 'LSL/ASR',0

                END    START

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
