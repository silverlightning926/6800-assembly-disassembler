*-----------------------------------------------------------
* Title      : Final Project
* Written by : Group 4 - Arkar Kyaw Swar, Siddharth Rao, Phu Thinh Dang
* Date       : 06/02/2022
* Description: 68K Disassembler
*-----------------------------------------------------------
STACK                           EQU $A000
HEXBITS                         EQU $2760
FIRST_THREE_BITS_AFTER_OPCODE   EQU $2770
SECOND_THREE_BITS_AFTER_OPCODE  EQU $2780
THIRD_THREE_BITS_AFTER_OPCODE   EQU $2790
FOURTH_THREE_BITS_AFTER_OPCODE  EQU $2800
DATA_SIZE                       EQU $2810
CURRENT_ADDR                    EQU $2820

CR                              EQU $0D               
LF                              EQU $0A
 
START:         ORG $1000                                     ; FIRST INSTRUCTION OF THE PROG
               LEA STACK, A7                                 ; SET UP THE SP
               
*------------ INTRO AND SOME RULES FOR THE DISASSEMBLER -----------------               
              LEA RULE, A1
              MOVE.B #14, D0
              TRAP #15
              
              LEA STR_SPACE, A1                 * break a line for readability
              MOVE.B #13, D0
              TRAP #15
              
               
         
*------------ PROMPT THE USER FOR ADDRESSES -----------------
USER_INPUT      
                CLR.L          D1                            * NEED TO CLEAR THE PROMPT IF A USER WISHES TO CONTINUE READING A PROGRAM
                * STARTING ADDRESS
                LEA            PROMPT1, A1                   * LOAD STARTING ADDRESS PROMPT TO A1
                MOVE.B         #14, D0                       * DISPLAY PROMPT
                TRAP           #15
                
                LEA            EXTRA1, A1                    * TO READ IN USER INPUT         
                MOVE.B         #2, D0                        * STORE USER INPUT STARTING ADDRESS STRING IN A1
                TRAP           #15
                
                JSR            INPUT_VALID_SIZE              ; IF USER ACCIDENTALLY ENTER INVALID SIZE FOR THE INPUT
                CMP.L          #$FF00, D1                    ; CLEARING SCREEN TASK 11
                BEQ            USER_INPUT                    ; LOOP BACK TO ASK USER INPUT AGAIN
 
                
                MOVE.B         #0, D0                        * TO CHECK WHETHER STARTING OR ENDIND ADDRESS IN SUBROUTINE  
                JSR            CONVERT
                JSR            AFTER_CONVERT_CHECK           * CHECK IF IT IS VALID
                CMP.L          #$FF00, D1                    
                BEQ            USER_INPUT
                
                * ENDING ADDRESS
                LEA            PROMPT2, A1                   * LOAD ENDING ADDRESS PROMPT TO A1
                MOVE.B         #14, D0                       * DISPLAY PROMPT
                TRAP           #15
                
                LEA            EXTRA2, A1                    * TO READ IN USER INPUT                              
                MOVE.B         #2, D0                        * STORE USER INPUT ENDING ADDRESS STRING IN A1
                TRAP           #15
                
                JSR            INPUT_VALID_SIZE              ; IF USER ACCIDENTALLY ENTER INVALID SIZE FOR THE INPUT
                CMP.L          #$FF00, D1                    ; CLEARING SCREEN TASK 11
                BEQ            USER_INPUT
               
                MOVE.B         #1, D0                        * TO CHECK WHETHER STARTING OR ENDIND ADDRESS IN SUBROUTINE   
                JSR            CONVERT
                JSR            AFTER_CONVERT_CHECK           * CHECK IF IF IT IS VAL
                CMP.L          #$FF00, D1                    
                BEQ            USER_INPUT

                CLR.L          D2                             * COUNTER TO READ 30 LOC AT A TIME
                
SAGEA_CHECK     CMP.L          D6, D5                         * IF THE ENDING ADDR > STARTING ADDR AT THE 1ST PLACE
                BGT            NOTIFY           
              
PAGE_SCAN_LOOP  
                * D5 IS THE STARTING ADDRESS
                CMP.L          D5, D6                         * compare starting addr to ending addr
                BLT            EXIT_LOOP
                
                CMP.B          #$14, D7                        * $14 should be 20 In hex
                BEQ            DISASSAMBLY_20_LOC             
                
                MOVE.L         #CURR_ADDRESS, A5
                MOVE.L         D5,  D3
                MOVE.B         #0, (A5)+
                JSR            DISPLAY
                MOVEA.L        D5, A2
                
                
                BRA            READ_OPCODE
                
INCRE_LINE      LEA STR_SPACE ,A1
                MOVE.B  #14,D0
                TRAP    #15

                MOVE.L   A2, D5         ;Increment this BY 2
        
                ;MOVE.L  #$2, StartAddr
                ADD.B   #1, D7          ;Increment the amount of lines displayed by 1

                BRA     PAGE_SCAN_LOOP
                     
DISASSAMBLY_20_LOC 
                CLR.L   D7              
                BRA     NEXT_PROMPT      
                
                
**------------ CONVERT THE ADDRESS STRINGS TO HEXADECIMAL VALUES -----------------
                
CONVERT         CLR.L          D3                            * TO STORE ASCII VALUES

                MOVE.L         #0, D2                        * LOOP COUNTER 
                MOVE.L         #8, D1                        * TERMINAL VALUE
                MOVE.L         #0, D6                        * TO STORE HEXADECIMAL VALUES OF ADDRESSES 
                
CONVERT_LOOP    
                
                CMP.L          D2, D1                        * CHECK TO TERMINATE THE LOOP
                BEQ            EXIT_CONV_LOOP                * BRANCH TO NEXT PART IF ABOVE CONDITION IS MET 
                
                MOVE.B         (A1)+, D3                     * READ A BYTE FROM A1 (A HEXADECIMAL DIGIT)
                
                CMP.B          #$39, D3                      * IF IT IS A LETTER OR NUMBER
                BGT            LETTER_CONVERT                * LETTER
                BLE            NUMBER_CONVERT                * NUMBER
                            
LETTER_CONVERT      
                CMP.B          #$46, D3                      * if it is greater than F -> Invalid
                BGT            INVALID_HEX_STRING                 
                CMP.B          #$41,D3                       * IF ASCII CODE IS [41,46] , IT IS A LETTER
                BGE            ASCII_TO_LETTER               * IF SO, BRANCH TO LETTER CONVERTER
                BLT            INVALID_HEX_STRING            ; IF it is less than A, it's invalid
                
                ; NUMBER CHECK. SHOULD BE [0-9]
NUMBER_CONVERT 
                CMP.B          #$30,D3                      * LESS THAN 0-> INVALID
                BLT            INVALID_HEX_STRING                         
                CMP.B          #$39,D3                       * IF ASCII CODE IS < $3A, IT IS A NUMBER
                BGT            INVALID_HEX_STRING            * GREATER THAN 9 -> INVALID
                BLE            ASCII_TO_NUM                  * IF SO, BRANCH TO NUMBER CONVERTER
                               
ASCII_TO_LETTER SUB.B          #$37,D3                       * CONVERT TO LETTER              
                BRA            SHIFT_AND_ADD                 

ASCII_TO_NUM    SUB.B          #$30,D3                       * CONVERT TO NUM                    
                
SHIFT_AND_ADD   LSL.L          #4, D6                        * SHIFT 
                ADD.B          D3, D6                        * ADD TO CURRENT VALUE
                CMPI.B         #7, D2                        * ACCESS THE LAST BIT TO CHECK THE INPUT IS EVEN OR ODD
                BEQ            EVEN_OR_ODD
                BRA            CONT
            
CONT            ADDQ.L         #1, D2
                BRA            CONVERT_LOOP
                
INVALID_HEX_STRING
                LEA             CANT_CONVERT, A1
                MOVE.B          #14, D0
                TRAP #15
                
                BRA             TRY_AGAIN_PROMPT
                
EXIT_CONV_LOOP  CMP.B          #0, D0
                BNE            RETURN
                MOVE.L         D6, D5
                RTS

EVEN_OR_ODD
               BTST.L          #00, D6             ; ACCESS THE LAST BIT
               BNE             ODD                 ; LAST BIT IS 1 -> ODD
               BRA             EXIT_CONV_LOOP

ODD            LEA             ODD_NUMBER, A1
               MOVE.B          #14, D0
               TRAP            #15
               BRA             TRY_AGAIN_PROMPT 
                                
                
RETURN          RTS

AFTER_CONVERT_CHECK
                CMP.L          #$00001000, D5               * NEED TO DOUBLE CHECK THIS
                BLT            LESS_THAN_START
                
                CMP.L          #$00FFFFF0, D5               
                BGT            GREATER_END
                RTS 
                
LESS_THAN_START
                LEA            LESS_START, A1    * ENTERED NUMBER < START
                MOVE.B         #14, D0
                TRAP           #15
                BRA            TRY_AGAIN_PROMPT
                
GREATER_END
                LEA            MORE_END, A1      * ENTERED NUMBER > END
                MOVE.B         #14, D0
                TRAP           #15
                BRA            TRY_AGAIN_PROMPT

*-----------------------20 lines of code at a time ------------------------------------
NEXT_PROMPT     
                LEA            PROMPT3, A1
                MOVE.B         #14, D0
                TRAP           #15
                
                MOVE.B         #5, D0             * READ THE SINGLE CHARACTER FROM KB
                TRAP           #15
                
                LEA            STR_SPACE, A1
                MOVE.B         #14, D0
                TRAP           #15
                
                CMP.B          #$4E, D1           * "N" IN ASCII
                BEQ            ENDING
                
                CMP.B          #$6E, D1           * "n" in ascii
                BEQ            ENDING      
                
                CMP.B          #$D, D1            * PRESS ENTER
                BEQ            NEXT_PAGE           
                
                LEA            ENTER_OR_N, A1     ; NOTICE USER FOR ERROR INPUT
                MOVE.B         #14, D1
                TRAP           #15
                BRA            NEXT_PROMPT        ; LOOP BACK TO ASK
NEXT_PAGE       
                MOVE.W        #$FF00, D1          * TO CLEAR THE SCREEN
                MOVE.B        #11, D0
                TRAP          #15
                BRA           PAGE_SCAN_LOOP
                
*----------------- PRINT OUT THE CURRENT ADDRESS -------------------------------                
DISPLAY
                LEA         CURR_ADDRESS, A1    * DISPLAY CURRENT ADDRESS
                MOVE.B      #14, D0
                TRAP        #15
                RTS
                
CLR_SCREEN
                MOVE.W      #$FF00, D1              * TO CLR SCREEN FOR TASK 11
                MOVE.B      #11, D0
                TRAP        #15
                RTS         
* Here, we have starting address in D5 and ending address in D6 as hexadecimals
*----------------- READ OPCODE: MAIN LOOP -------------------------------

MAIN            MOVEA.L        D5, A2                        * START READING FROM D5(STARTING ADDRESS)            
                
READ_OPCODE     
                CLR.L           D3                            * WE WILL STORE EACH WORD FROM CURRENT INSTRUCTION IN D3
                CMP.W           A2, D6
                BLT             EXIT_MAIN_LOOP    
                JSR             PRINT_MEM_ADDR
                JSR             PRINT_SPACE
                MOVE.L          A2, CURRENT_ADDR                                                                 
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
                
                CMP.B           #%0100, D3                          * COMPARE 4 BITS OF WORD TO LEA/NOP/JSR/RTS/ OPCODE (0100)
                BEQ             LEA_NOP_NOT_JSR_RTS_OPCODE              * IF EQUAL GO TO LEA_NOP_NOT_JSR_RTS_OPCODE
                
                CMP.B           #%1110, D3                          * COMPARE 4 BITS OF THE WORD TO LSL/ASR OPCODE (1110)
                BEQ             LSL_LSR_ASL_ASR_ROL_ROR_OPCODE      * IF EQUAL GO TO LSL_LSR_ASL_ASR_ROL_ROR_OPCODE
                
                JSR INVALID_OPCODE                                  * IF NOT EQUAL TO ABOVE OPCODE, ASSUME INVALID OPCODE/DATA
    
ADD_ADDA_OPCODE  
                JSR             SPLIT_AFTER_OPCODE
                
                MOVE.W          SECOND_THREE_BITS_AFTER_OPCODE, D3
                
                CMP.B           #%011, D3
                BEQ             ADDA_OPCODE
                
                CMP.B           #%111, D3
                BEQ             ADDA_OPCODE
                
                CMP.B           #%000, D3
                BEQ             ADD_OPCODE
                
                CMP.B           #%001, D3
                BEQ             ADD_OPCODE
                
                CMP.B           #%010, D3
                BEQ             ADD_OPCODE
                
                CMP.B           #%100, D3
                BEQ             ADD_OPCODE
                
                CMP.B           #%101, D3
                BEQ             ADD_OPCODE
                
                CMP.B           #%110, D3
                BEQ             ADD_OPCODE
                
                BRA             INVALID_OPCODE
      
ADD_OPCODE
                LEA             ADD_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_SIZE_CODE
                JSR             PRINT_SPACE
                
                BRA             P_ADD_EA
            
ADDA_OPCODE
                LEA             ADDA_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_ADDA_SIZE_CODE
                JSR             PRINT_SPACE
                
                BRA             P_ADDA_EA

                
ADDQ_OPCODE
                LEA             ADDQ_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             SPLIT_AFTER_OPCODE
                JSR             PRINT_SIZE_CODE
                JSR             PRINT_SPACE
                
                MOVE.W          HEXBITS, D3
                
                BRA             P_ADDQ_EA
                
    
CMP_OPCODE  
                LEA             CMP_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                            
                JSR             SPLIT_AFTER_OPCODE
                JSR             PRINT_SIZE_CODE
                JSR             PRINT_SPACE 
                
                BRA             P_CMP_EA

OR_OPCODE
                LEA             OR_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             SPLIT_AFTER_OPCODE
                JSR             PRINT_SIZE_CODE
                JSR             PRINT_SPACE
                
                BRA             P_AND_OR_EA

SUB_OPCODE
                LEA             SUB_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             SPLIT_AFTER_OPCODE
                JSR             PRINT_SIZE_CODE
                JSR             PRINT_SPACE
                
                BRA             P_SUB_EA

AND_OPCODE      
                LEA             AND_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             SPLIT_AFTER_OPCODE
                JSR             PRINT_SIZE_CODE
                JSR             PRINT_SPACE               
                
                BRA             P_AND_OR_EA

MOVEB_OPCODE
                LEA             MOVEB_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             SPLIT_AFTER_OPCODE
                JSR             PRINT_SPACE
                
                BRA             P_MOVEB_EA
                
MOVEQ_OPCODE
                LEA             MOVEQ_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             SPLIT_AFTER_OPCODE
                JSR             PRINT_SPACE
                
                BRA             P_MOVEQ_EA

                
MOVEW_MOVEAW_OPCODE
                JSR             SPLIT_AFTER_OPCODE
                
                MOVE.W          SECOND_THREE_BITS_AFTER_OPCODE, D3
                
                CMP.B           #%001, D3
                BEQ             MOVEAW_OPCODE
                
                LEA             MOVEW_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_SPACE
                
                BRA             P_MOVEW_EA

                
MOVEAW_OPCODE
                LEA             MOVEAW_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_SPACE
                
                BRA             P_MOVEAW_EA

        
MOVEL_MOVEAL_OPCODE
                JSR             SPLIT_AFTER_OPCODE
                
                MOVE.W          SECOND_THREE_BITS_AFTER_OPCODE, D3
                
                CMP.B           #%001, D3
                BEQ             MOVEAL_OPCODE
                
                LEA             MOVEL_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_SPACE
                                
                BRA             P_MOVEL_EA

                
MOVEAL_OPCODE
                LEA             MOVEAL_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_SPACE
                
                BRA             P_MOVEAL_EA

                
BCC_BRA_OPCODE
                ADD.L           #$2, CURRENT_ADDR       *PC VALUE
                MOVE.W          HEXBITS, D3
                
                LSL             #4, D3
                
                LSR             #4, D3
                LSR             #4, D3
                LSR             #4, D3
                
                CMP.B           #%0000, D3
                BEQ             BRA_OPCODE
                
                CMP.B           #%0111, D3
                BEQ             BEQ_OPCODE
                
                CMP.B           #%1110, D3
                BEQ             BGT_OPCODE
                
                CMP.B           #%1111, D3
                BEQ             BLE_OPCODE
                
                BRA             INVALID_OPCODE
                
BRA_OPCODE
                LEA             BRA_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_SPACE

                BRA             P_BCC_BRA_EA
                
BEQ_OPCODE      
                LEA             BEQ_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_SPACE
                
                BRA             P_BCC_BRA_EA
                
BGT_OPCODE
                LEA             BGT_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_SPACE
                
                BRA             P_BCC_BRA_EA
                
BLE_OPCODE
                LEA             BLE_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_SPACE
                
                BRA             P_BCC_BRA_EA
                
LEA_NOP_NOT_JSR_RTS_OPCODE  
                
                JSR             SPLIT_AFTER_OPCODE
                
                MOVE.W          SECOND_THREE_BITS_AFTER_OPCODE, D3
                
                CMP.B           #%001, D3
                BEQ             NOP_NOTW_RTS_OPCODE
                
                CMP.B           #%111, D3
                BEQ             LEA_OPCODE
                
                CMP.B           #%000, D3
                BEQ             NOTB_OPCODE
                
                CMP.B           #%010, D3
                BEQ             NOTL_JSR_OPCODE
                              
                BRA             INVALID_OPCODE
                
NOP_NOTW_RTS_OPCODE

                MOVE.W          FIRST_THREE_BITS_AFTER_OPCODE, D3
                
                CMP.B           #%111, D3
                BEQ             NOP_RTS_OPCODE
                
                CMP.B           #%011, D3
                BEQ             NOTW_OPCODE

                BRA             INVALID_OPCODE
                
NOP_RTS_OPCODE
                MOVE.W          FOURTH_THREE_BITS_AFTER_OPCODE, D3
                
                CMP.B           #%001, D3
                BEQ             NOP_OPCODE
                
                CMP.B           #%101, D3
                BEQ             RTS_OPCODE
                   
                BRA             INVALID_OPCODE
                
NOP_OPCODE
                LEA             NOP_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_SPACE

                BRA             P_NOP_RTS_EA
                
RTS_OPCODE
                LEA             RTS_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_SPACE
                
                BRA             P_NOP_RTS_EA
                
NOTW_OPCODE
                LEA             NOTW_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_SPACE
                
                BRA             P_NOT_JSR_EA
                
LEA_OPCODE
                LEA             LEA_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_SPACE
                
                BRA             P_LEA_EA

                
NOTB_OPCODE
                LEA             NOTB_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_SPACE
        
                BRA             P_NOT_JSR_EA

                
NOTL_JSR_OPCODE
                MOVE.W          FIRST_THREE_BITS_AFTER_OPCODE, D3
                
                CMP.B           #%111, D3
                BEQ             JSR_OPCODE
                
                CMP.B           #%011, D3
                BEQ             NOTL_OPCODE

                BRA             INVALID_OPCODE
                
JSR_OPCODE
                LEA             JSR_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_SPACE

                BRA             P_NOT_JSR_EA
                
NOTL_OPCODE
                LEA             NOTL_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_SPACE

                BRA             P_NOT_JSR_EA

LSL_LSR_ASL_ASR_ROL_ROR_OPCODE           
                JSR             SPLIT_AFTER_OPCODE
                
                MOVE.W          SECOND_THREE_BITS_AFTER_OPCODE, D3
                
                LSL             #6,D3
                LSL             #8,D3
                LSR             #6,D3
                LSR             #8,D3

                CMP.B           #%11, D3                                       
                BEQ             ADDR_SHIFT
                
                CMP.B           #%00, D3
                BEQ             REGISTER_SHIFT
                CMP.B           #%01, D3
                BEQ             REGISTER_SHIFT
                CMP.B           #%10, D3
                BEQ             REGISTER_SHIFT
                
                BRA             INVALID_OPCODE

REGISTER_SHIFT         
                MOVE.W          THIRD_THREE_BITS_AFTER_OPCODE, D3
                
                LSL             #6,D3
                LSL             #8,D3
                LSR             #6,D3
                LSR             #8,D3
                
                CMP.B           #%01, D3
                BEQ             REGISTER_LSL_LSR_OPCODE
                
                CMP.B           #%00, D3
                BEQ             REGISTER_ASL_ASR_OPCODE
                
                CMP.B           #%11, D3
                BEQ             REGISTER_ROL_ROR_OPCODE
                
                BRA             INVALID_OPCODE

REGISTER_LSL_LSR_OPCODE
                LEA             LS_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_DIRECTION
                JSR             PRINT_SHIFT_SIZE_CODE
                
                JSR             PRINT_SPACE
                            
                BRA             P_LSL_LSR_ASL_ASR_ROL_ROR_EA
                
REGISTER_ASL_ASR_OPCODE
                LEA             AS_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_DIRECTION
                JSR             PRINT_SHIFT_SIZE_CODE
                
                JSR             PRINT_SPACE

                BRA             P_LSL_LSR_ASL_ASR_ROL_ROR_EA
                
REGISTER_ROL_ROR_OPCODE
                LEA             RO_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_DIRECTION
                JSR             PRINT_SHIFT_SIZE_CODE

                JSR             PRINT_SPACE
                
                BRA             P_LSL_LSR_ASL_ASR_ROL_ROR_EA  

ADDR_SHIFT
                MOVE.W          FIRST_THREE_BITS_AFTER_OPCODE, D3
                
                CMP.B           #%000, D3
                BEQ             ADDR_ASL_ASR_OPCODE
                
                CMP.B           #%001, D3
                BEQ             ADDR_LSL_LSR_OPCODE
                
                CMP.B           #%011, D3
                BEQ             ADDR_ROL_ROR_OPCODE                
                
                BRA             INVALID_OPCODE
               
ADDR_LSL_LSR_OPCODE
                LEA             LS_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_DIRECTION
                
                JSR             PRINT_SPACE
                            
                BRA             P_ADDR_SHIFT_EA
                
ADDR_ASL_ASR_OPCODE
                LEA             AS_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_DIRECTION
                
                JSR             PRINT_SPACE

                BRA             P_ADDR_SHIFT_EA
                
ADDR_ROL_ROR_OPCODE
                LEA             RO_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_DIRECTION

                JSR             PRINT_SPACE
                
                BRA             P_ADDR_SHIFT_EA            

INVALID_OPCODE  
                LEA             INVALID_OPCODE_STRING, A1
                MOVE.B          #14, D0
                TRAP            #15
                
                JSR             PRINT_SPACE
                
                BRA             P_INVALID_EA
                
*------------------------------- EA ---------------------------------------- 


P_INVALID_EA
                LEA Dollar_sign, A1
                MOVE.B #14, D0
                TRAP #15
                
                MOVE.W          HEXBITS, D3
                JSR             HEX_TO_STRING
  
                BRA         INSTRUC_DONE
P_ADD_EA  
              CMP.B       #1, D2                                          * CHECK WHICH OPMODE
              BEQ         P_ADD_DnFIRST_EA                                * Dn + < ea > -> < ea >
              
              MOVE.W      THIRD_THREE_BITS_AFTER_OPCODE, D1               * EA MODE , <EA> + Dn -> Dn
              MOVE.W      FOURTH_THREE_BITS_AFTER_OPCODE, D4
              MOVE.W      SECOND_THREE_BITS_AFTER_OPCODE, DATA_SIZE       
              JSR         EA_MODE_TABLE
              JSR         COMMA_PRINT
              
              MOVE.W      FIRST_THREE_BITS_AFTER_OPCODE, D4   
              JSR         Dn_Mode_Print
              
              BRA         INSTRUC_DONE
              
P_ADD_DnFIRST_EA                        * Dn + < ea > -> < ea >

                MOVE.W      FIRST_THREE_BITS_AFTER_OPCODE, D4
                JSR         Dn_Mode_Print         
                JSR         COMMA_PRINT
                
                MOVE.W      THIRD_THREE_BITS_AFTER_OPCODE, D1
                MOVE.W      FOURTH_THREE_BITS_AFTER_OPCODE, D4
                MOVE.W      SECOND_THREE_BITS_AFTER_OPCODE, DATA_SIZE
                JSR         EA_MODE_TABLE 
 
                BRA         INSTRUC_DONE
                
                
P_ADDA_EA                         * ADDA <EA>, AN
               
                MOVE.W     THIRD_THREE_BITS_AFTER_OPCODE, D1
                MOVE.W     FOURTH_THREE_BITS_AFTER_OPCODE, D4
                MOVE.W     SECOND_THREE_BITS_AFTER_OPCODE, DATA_SIZE
                JSR        EA_MODE_TABLE
                
                JSR        COMMA_PRINT
                
                MOVE.W     FIRST_THREE_BITS_AFTER_OPCODE, D4
                JSR        An_Mode_Print
                
                BRA         INSTRUC_DONE

                
P_ADDQ_EA
                LEA        Hash_sign, a1
                MOVE.B     #14, D0
                TRAP       #15
                
                CLR.L        D1
                MOVE.W     FIRST_THREE_BITS_AFTER_OPCODE, D1
                CMP.W      #%0000, D1                         * IF THE DATA IS %000, IT'S 8 (%1000).
                BEQ        ADDQ_OVERFLOW
OVERFLOWA_FIXED JSR        PRINT_IMMEDIATE
                JSR        COMMA_PRINT
                
                MOVE.W     THIRD_THREE_BITS_AFTER_OPCODE, D1
                MOVE.W     FOURTH_THREE_BITS_AFTER_OPCODE, D4
                JSR        EA_MODE_TABLE
                
                BRA         INSTRUC_DONE   
                
ADDQ_OVERFLOW
                MOVE.W     #%1000, D1
                BRA        OVERFLOWA_FIXED
           
    
P_CMP_EA  
                MOVE.W     THIRD_THREE_BITS_AFTER_OPCODE, D1
                MOVE.W     FOURTH_THREE_BITS_AFTER_OPCODE, D4
                MOVE.W     SECOND_THREE_BITS_AFTER_OPCODE, DATA_SIZE
                JSR        EA_MODE_TABLE
                JSR        COMMA_PRINT
                
                MOVE.W      FIRST_THREE_BITS_AFTER_OPCODE, D4
                JSR         Dn_Mode_Print 
                BRA         INSTRUC_DONE

P_SUB_EA
    
                CMP.B       #1, D2                                          * CHECK WHICH OPMODE
                BEQ         P_SUB_DnFIRST_EA                                * SUB OPMODE =>  EA - Dn -> EA
                                                                            * IF DIDN'T BRANCH, SUB OPMODE =>  Dn - EA -> Dn
                
                MOVE.W      THIRD_THREE_BITS_AFTER_OPCODE, D1
                MOVE.W      FOURTH_THREE_BITS_AFTER_OPCODE, D4
                MOVE.W      SECOND_THREE_BITS_AFTER_OPCODE, DATA_SIZE
                JSR         EA_MODE_TABLE
                JSR         COMMA_PRINT
                
                MOVE.W      FIRST_THREE_BITS_AFTER_OPCODE, D4
                JSR         Dn_Mode_Print 
                
                BRA         INSTRUC_DONE 
    
P_SUB_DnFIRST_EA

                MOVE.W      FIRST_THREE_BITS_AFTER_OPCODE, D4
                JSR         Dn_Mode_Print         
                JSR         COMMA_PRINT
                
                MOVE.W      THIRD_THREE_BITS_AFTER_OPCODE, D1
                MOVE.W      FOURTH_THREE_BITS_AFTER_OPCODE, D4
                MOVE.W      SECOND_THREE_BITS_AFTER_OPCODE, DATA_SIZE
                JSR         EA_MODE_TABLE
                
                BRA         INSTRUC_DONE 

P_AND_OR_EA      
                CMP.B       #1, D2                                          * CHECK WHICH OPMODE
                BEQ         P_AND_OR_DnFIRST_EA                                * AND OPMODE =>  Dn /\ EA -> EA
                                                                            * IF DIDN'T BRANCH, AND OPMODE =>  EA /\ Dn -> Dn
                MOVE.W      THIRD_THREE_BITS_AFTER_OPCODE, D1
                MOVE.W      FOURTH_THREE_BITS_AFTER_OPCODE, D4
                MOVE.W      SECOND_THREE_BITS_AFTER_OPCODE, DATA_SIZE
                JSR         EA_MODE_TABLE
                JSR         COMMA_PRINT
                
                MOVE.W      FIRST_THREE_BITS_AFTER_OPCODE, D4
                JSR         Dn_Mode_Print 
                
                BRA         INSTRUC_DONE 


P_AND_OR_DnFIRST_EA

                MOVE.W      FIRST_THREE_BITS_AFTER_OPCODE, D4
                JSR         Dn_Mode_Print         
                JSR         COMMA_PRINT
                
                MOVE.W      THIRD_THREE_BITS_AFTER_OPCODE, D1
                MOVE.W      FOURTH_THREE_BITS_AFTER_OPCODE, D4
                MOVE.W      SECOND_THREE_BITS_AFTER_OPCODE, DATA_SIZE
                JSR         EA_MODE_TABLE
                
                BRA         INSTRUC_DONE       


P_MOVEB_EA       * MOVE <EA>, <EA>
                MOVE.W       THIRD_THREE_BITS_AFTER_OPCODE, D1  
                MOVE.W       FOURTH_THREE_BITS_AFTER_OPCODE, D4
                MOVE.W       #%0001, DATA_SIZE
               
                JSR          EA_MODE_TABLE
                JSR          COMMA_PRINT
                
                MOVE.W       FIRST_THREE_BITS_AFTER_OPCODE, D4
                MOVE.W       SECOND_THREE_BITS_AFTER_OPCODE, D1
               
                JSR          EA_MODE_TABLE
                BRA         INSTRUC_DONE 
                
P_MOVEQ_EA
                LEA        Hash_sign, a1
                MOVE.B     #14, D0
                TRAP       #15
                
                MOVE.W      HEXBITS, D3
                CLR.L         D1
                MOVE.B      D3, D1
                
                
                JSR         PRINT_IMMEDIATE
                JSR         COMMA_PRINT
                
                MOVE.W      FIRST_THREE_BITS_AFTER_OPCODE, D4
                JSR         Dn_Mode_Print 
                
                BRA         INSTRUC_DONE
                
P_MOVEW_EA
                MOVE.W       THIRD_THREE_BITS_AFTER_OPCODE, D1  
                MOVE.W       FOURTH_THREE_BITS_AFTER_OPCODE, D4
                MOVE.W       #%0011, DATA_SIZE
               
                JSR          EA_MODE_TABLE
                JSR          COMMA_PRINT
                
                MOVE.W       FIRST_THREE_BITS_AFTER_OPCODE, D4
                MOVE.W       SECOND_THREE_BITS_AFTER_OPCODE, D1
               
                JSR          EA_MODE_TABLE
                BRA         INSTRUC_DONE 
                
P_MOVEAW_EA
                MOVE.W       THIRD_THREE_BITS_AFTER_OPCODE, D1  
                MOVE.W       FOURTH_THREE_BITS_AFTER_OPCODE, D4
                MOVE.W       #%0011, DATA_SIZE
               
                JSR          EA_MODE_TABLE
                JSR          COMMA_PRINT
                
                MOVE.W       FIRST_THREE_BITS_AFTER_OPCODE, D4
                JSR          An_Mode_Print
                
                BRA         INSTRUC_DONE

        
P_MOVEL_EA
                MOVE.W       THIRD_THREE_BITS_AFTER_OPCODE, D1  
                MOVE.W       FOURTH_THREE_BITS_AFTER_OPCODE, D4
                MOVE.W       #%0010, DATA_SIZE
               
                JSR          EA_MODE_TABLE
                JSR          COMMA_PRINT
                
                MOVE.W       FIRST_THREE_BITS_AFTER_OPCODE, D4
                MOVE.W       SECOND_THREE_BITS_AFTER_OPCODE, D1
               
                JSR          EA_MODE_TABLE
                BRA         INSTRUC_DONE
                
P_MOVEAL_EA
                MOVE.W       THIRD_THREE_BITS_AFTER_OPCODE, D1  
                MOVE.W       FOURTH_THREE_BITS_AFTER_OPCODE, D4
                MOVE.W       #%0010, DATA_SIZE
               
                JSR          EA_MODE_TABLE
                JSR          COMMA_PRINT
                
                MOVE.W       FIRST_THREE_BITS_AFTER_OPCODE, D4
                JSR          An_Mode_Print
                
                BRA         INSTRUC_DONE
                
P_BCC_BRA_EA
                CLR.B       D2
                CLR.B       D3
                CLR.L       D1
                MOVE.W      HEXBITS, D1
                LSL.W       #8, D1
                LSR.W       #8, D1                    
                CMP.B       #$00, D1
                BEQ         BRA_HELPER_16BITS              
                CMP.B       #$FF, D1
                BEQ         BRA_HELPER_32BITS
GOT_DISPLACE    CMP.B       #0, D2
                BEQ         CHECK_NEG_8
                CMP.B       #1, D2
                BEQ         CHECK_NEG_16
                CMP.B       #2, D2
                BEQ         CHECK_NEG_32


DONE            CMP.B       #1, D3
                BNE         JUST_ADD
                
                SUB.L       D1, CURRENT_ADDR
                MOVE.L      CURRENT_ADDR, D1
                
                
                BRA         PRINT
                

JUST_ADD        ADD.L       CURRENT_ADDR, D1            * D1 NOW HAS THE ADDRESS TO BRANCH

PRINT           LEA         Dollar_sign, A1             * PRINT DOLLAR SIGN
                MOVE.B      #14, D0
                TRAP        #15
                
                JSR         TRAP_PRINT 
                BRA         INSTRUC_DONE
BRA_HELPER_16BITS
                MOVE.W      (A2)+, D1  
                MOVE.B      #1, D2                      * FLAG
                BRA         GOT_DISPLACE      
BRA_HELPER_32BITS
                MOVE.L      (A2)+, D1  
                MOVE.B      #2, D2                      * FLAG
                BRA         GOT_DISPLACE         
CHECK_NEG_8
                CMP.B       #$80, D1
                BLT         DONE
                MOVE.B      #1, D3                      * NEGATIVE FLAG
                NOT.B       D1
                ADD.B       #%1, D1
                BRA         DONE
CHECK_NEG_16
                CMP.W       #$8000, D1
                BLT         DONE
                MOVE.B      #1, D3                      * NEGATIVE FLAG
                NOT.W       D1
                ADD.B       #%1, D1
                BRA         DONE
CHECK_NEG_32
                CMP.L       #$80000000, D1
                BLT         DONE
                MOVE.B      #1, D3                      * NEGATIVE FLAG
                NOT.L       D1
                ADD.B       #%1, D1
                BRA         DONE
                
P_LEA_EA  
                MOVE.W      THIRD_THREE_BITS_AFTER_OPCODE, D1
                MOVE.W      FOURTH_THREE_BITS_AFTER_OPCODE, D4
                JSR         EA_MODE_TABLE
                JSR         COMMA_PRINT
                
                MOVE.W       FIRST_THREE_BITS_AFTER_OPCODE, D4
                JSR          An_Mode_Print
                
                BRA         INSTRUC_DONE


P_NOP_RTS_EA 
                BRA         INSTRUC_DONE
P_NOT_JSR_EA 
                MOVE.W      THIRD_THREE_BITS_AFTER_OPCODE, D1
                MOVE.W      FOURTH_THREE_BITS_AFTER_OPCODE, D4
                JSR         EA_MODE_TABLE
                BRA         INSTRUC_DONE
                                    

P_LSL_LSR_ASL_ASR_ROL_ROR_EA
                                                                              * LSd Dx,Dy  (OR) LSd #<data> ,Dy
                                                                              
                MOVE.W      THIRD_THREE_BITS_AFTER_OPCODE, D3
                LSR         #2, D3                                            * GET ACCESS TO I/R BIT
                                                                              
                CMP.B       #0, D3                                           * THIS MEANS IMMEDIATE DATA SHIFT   
                BEQ         IMMEDIATE_SHIFT
                                                                              * LSd Dx,Dy
                                                                              
                MOVE.W      FIRST_THREE_BITS_AFTER_OPCODE, D4    
                JSR         Dn_Mode_Print 
                JSR         COMMA_PRINT

                MOVE.W      FOURTH_THREE_BITS_AFTER_OPCODE, D4    
                JSR         Dn_Mode_Print 
                BRA         INSTRUC_DONE                                                        

                                           
IMMEDIATE_SHIFT 
                CLR.L         D1                                                              * LSd #<data> ,Dy
                MOVE.W      FIRST_THREE_BITS_AFTER_OPCODE, D1
                CMP.W       #%0000, D1                                        * THIS MEANS SHIFT COUNT IS 8
                BEQ         SHIFT_COUNT_OVERFLOW
OVERFLOWS_FIXED LEA         Hash_sign, A1                                     * LOAD AT ADDRESS OF HASH SIGN TO A1
                MOVE.B      #14 , D0
                TRAP        #15
                JSR         PRINT_IMMEDIATE
                JSR         COMMA_PRINT
                
                MOVE.W      FOURTH_THREE_BITS_AFTER_OPCODE, D4    
                JSR         Dn_Mode_Print 
                BRA         INSTRUC_DONE  
                

SHIFT_COUNT_OVERFLOW
                MOVE.W      #%1000, D1
                BRA         OVERFLOWS_FIXED               
                
P_ADDR_SHIFT_EA                                                 * LSd <ea>
                MOVE.W      THIRD_THREE_BITS_AFTER_OPCODE, D1
                MOVE.W      FOURTH_THREE_BITS_AFTER_OPCODE, D4
                JSR         EA_MODE_TABLE
                BRA         INSTRUC_DONE



*------------------------------ EA SUBROUTINES -------------------------------                
             
EA_MODE_TABLE
                CMP.B #%0000, D1            * DATA REGISTER DIRECT
                BEQ Dn_Mode_Print
                
                CMP.B #%0001,D1             * ADDRESS REGISTER DIRECT
                BEQ An_Mode_Print
                
                CMP.B #%0010, D1            * ADDRESS REGISTER INDIRECT
                BEQ INDIRECT_MODE_PRINT

                CMP.B    #%0011,D1                  * Address Register Indirect with Post incrementing
                BEQ      ID_POST_INCRE_PRINT    
           
                CMP.B    #%0100,D1                  * Address Register Indirect with Pre decrementing
                BEQ      ID_PRE_DECRE_PRINT
                
                CMP.B   #%0111, D1
                BNE     INVALID
                
                CMP.B   #%0100,D4           * IMMEDIATE
                BEQ     IMMEDIATE_PRINT
                
                CMP.B    #%0001,D4          * ABSOLUTE DATA LONG
                BEQ      ABS_L_PRINT
           
                CMP.B    #%0000,D4          * ABSOLUTE DATA SHORT
                BEQ      ABS_S_PRINT
  
INVALID         BRA     INVALID_EA_PRINT

                RTS

Dn_Mode_Print                                   * Dn
                LEA     D_Mode, A1                   
                MOVE.B  #14, D0
                TRAP    #15                    
                
                MOVE.L  D4, D1
                MOVE.B  #3, D0
                TRAP    #15
                
                RTS

An_Mode_Print                                    * An
                LEA     A_Mode, A1                   
                MOVE.B  #14, D0
                TRAP    #15                    
                
                MOVE.L  D4, D1
                MOVE.B  #3, D0
                TRAP    #15
                RTS
                
                
INDIRECT_MODE_PRINT                              * (An)
                LEA     Open_pars, A1                * LOAD AT ADDRESS OF OPEN_PARENTHESY TO A1
                MOVE.B  #14, D0
                TRAP    #15
                
                LEA     A_Mode, A1                   * PRINT An MODE
                MOVE.B  #14, D0
                TRAP    #15
                
                MOVE.L  D4, D1
                MOVE.B  #3, D0
                TRAP    #15
                
                LEA     Close_pars, A1               * LOAD AT ADDRESS OF OPEN_PARENTHESY TO A1
                MOVE.B  #14, D0
                TRAP    #15
                
                RTS

ID_POST_INCRE_PRINT                              * (An)+
                LEA Open_pars, A1                * LOAD AT ADDRESS OF OPEN_PARENTHESY TO A1
                MOVE.B #14, D0
                TRAP #15
                
                LEA A_Mode, A1                   * PRINT An MODE
                MOVE.B #14, D0
                TRAP #15
                
                MOVE.L  D4, D1
                MOVE.B  #3, D0
                TRAP    #15
                
                LEA Close_pars, A1                * LOAD AT ADDRESS OF OPEN_PARENTHESY TO A1
                MOVE.B #14, D0
                TRAP #15
                
                LEA Plus_sign, A1                LOAD AT ADDRESS OF PLUS SIGN TO A1
                MOVE.B #14, D0
                TRAP #15
                
                RTS
                
ID_PRE_DECRE_PRINT                               * -(An)
                LEA Minus_sign, A1               * LOAD AT ADDRESS OF PLUS SIGN TO A1
                MOVE.B #14, D0
                TRAP #15                
                
                LEA Open_pars, A1                * LOAD AT ADDRESS OF OPEN_PARENTHESY TO A1
                MOVE.B #14, D0
                TRAP #15
                
                LEA A_Mode, A1                   * PRINT An MODE
                MOVE.B #14, D0
                TRAP #15
                
                MOVE.L  D4, D1
                MOVE.B  #3, D0
                TRAP    #15 
                
                LEA Close_pars, A1               * LOAD AT ADDRESS OF OPEN_PARENTHESY TO A1
                MOVE.B #14, D0
                TRAP #15
                
                RTS

ABS_S_PRINT                                       * It specifies a 16 bit address, sign extended to 24/32 bits
                LEA Dollar_sign, A1               * LOAD A1 TO DOLLAR SIGN ADDRESS
                MOVE.B #14, D0
                TRAP #15
                
                CLR.L   D1
                MOVE.W (A2)+, D1                   * MOVE THE CONTENT OF ADDRESS A2 TO D1 ( IN WORD SIZE)

                JSR TRAP_PRINT                    * JUMP TO SUB ROUNTINE TO PRINT OUT THE TRAP
                CLR.L D1                            * CLEAR D1 TO 0
                RTS
                
ABS_L_PRINT 
                LEA Dollar_sign, A1               * LOAD A1 TO DOLLAR SIGN ADDRESS
                MOVE.B #14, D0
                TRAP #15
                
                MOVE.L  (A2)+, D1                    * MOVE THE CONTENT OF ADDRESS A2 TO D1 ( IN LONG SIZE)

                JSR TRAP_PRINT                    * JUMP TO SUB ROUNTINE TO PRINT OUT THE TRAP
                CLR.L D1                            * CLEAR D1 TO 0
                RTS                
                
IMMEDIATE_PRINT                                      
              LEA Hash_sign, A1                   * LOAD AT ADDRESS OF HASH SIGN TO A1
              MOVE.B #14 , D0
              TRAP #15
              
              CMP.W   #%0010, DATA_SIZE           * COMPARE TO TO SEE THE IMMEDIATE DATA SIZE
              BEQ     IMD_LONG                    * LONG SIZE 
              CMP.W   #%0110, DATA_SIZE           * COMPARE TO TO SEE THE IMMEDIATE DATA SIZE
              BGE     IMD_LONG                    * LONG SIZE 
              BRA     IMD_WORD                    * WORD SIZE 
                
IMD_LONG         
              CLR.L      D1
              MOVE.L  (A2)+,D1                    
              JSR      PRINT_IMMEDIATE   
              RTS                
IMD_WORD
              CLR.L      D1
              MOVE.W  (A2)+,D1                
              JSR     PRINT_IMMEDIATE        
              RTS                
                
PRINT_IMMEDIATE                                   * $# 
              LEA Dollar_sign, A1
              MOVE.B #14, D0
              TRAP #15
              
              JSR TRAP_PRINT
              RTS                

INVALID_EA_PRINT    
              LEA Invalid_EA, A1                  * LOAD A1 TO Invalid ea message
              MOVE.B #14, D0
              TRAP #15                            * HARDWARE INTERUPT
              RTS                           
                
TRAP_PRINT
              MOVEQ #15, D0                      
              MOVEQ #16, D2                       * display data in hex in D2( BASE 16) 
              TRAP #15                            * INTERUPT
              RTS                                 * RETURN 
*------------------------- PRINT OUT INSTRUCTION ----------------------------

*NOTE: WE NEED A CHECK HERE IF WE WANT TO STOP THE LOOP

INSTRUC_DONE    JSR             PRINT_NEWLINE

;NEXT_INSTRUC    BRA             READ_OPCODE                   * IF DONE PRINTING INSTRUCTION AND THERE ARE MORE, READ ANOTHER 
NEXT_INSTRUC    BRA             INCRE_LINE                     * IF DONE PRINTING INSTRUCTION AND THERE ARE MORE, READ ANOTHER 
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
                BRA             ENDING
                
RESTART 
                MOVE.W          #$FF00, D1                   ; CLEAR SCREEN IN TASK 11
                MOVE.B          #11, D0
                TRAP            #15
                
                CLR.L   D0                  ; Clear all data registers
                CLR.L   D1
                CLR.L   D2
                CLR.L   D3
                CLR.L   D4
                CLR.L   D5
                CLR.L   D6
                CLR.L   D7
                
                MOVE.L  #$0, A1             ; Reset all address registers
                MOVE.L  #$0, A2
                MOVE.L  #$0, A3
                MOVE.L  #$0, A4
                MOVE.L  #$0, A5
                MOVE.L  #$0, A6
                BRA     Start
                
NOTIFY
                LEA     SAGEA, A1   ;notify that statting address, or current address is greater than ending address
                MOVE.B  #14, D0
                TRAP #15 
 
EXIT_LOOP       
                BRA             FINISH_PROMPT

FINISH_PROMPT
                LEA     FINISH, A1  ;Finished Diassembling, ask to restart or stop
                MOVE.B  #14, D0    
                TRAP    #15
        
                MOVE.B  #5, D0      ;Read in the character from the keyboard
                TRAP    #15      

                LEA     STR_SPACE, A1     
                MOVE.B  #14, D0         
                TRAP    #15   
        
                CMPI.B  #$52, D1    ;the ASCII string is 'R'
                BEQ     RESTART
        
                CMPI.B  #$72, D1    ;the ASCII string is 'r'
                BEQ     Restart
        
                CMPI.B  #$53, D1    ;ASCII string is 'S'
                BEQ     ENDING

        
                CMPI.B  #$73, D1    ; ASCII string is 's'
                BEQ     ENDING
        
                LEA     R_OR_S, A1     ;Invalid input. Ask for R or S
                MOVE.B  #14, D0     
                TRAP    #15

                BRA     FINISH_PROMPT       ; INVALID INPUT -> LOOP BACK                   
                
ENDING          
                JSR             PRINT_NEWLINE
                LEA             GOODBYE, A1                  * LOAD GOOD BYE MESSAGE INTO A1
                MOVE.B          #14, D0                      * DISPLAY GOODBYE
                TRAP            #15                
                              
                
                SIMHALT
                
*-----------------CHECKING VALID INPUT -----------------------------------
INPUT_VALID_SIZE    
               CMP.L           #0, D1                        * IS IS AN EMPTY INPUT?
               BEQ             EMPTY_INPUT                   * JSR TO EMPTY INPUT SUBROUTINE
               
               CMP.L           #8, D1                        * IS IS 8 DIGITS?
               BGT             MORE_THAN_EIGHT               * INVALID
               BLT             LESS_THAN_EIGHT               * INVALID

               RTS


EMPTY_INPUT
               LEA             EMPTY, A1
               MOVE.B          #14, D0
               TRAP            #15          
               BRA             TRY_AGAIN_PROMPT             

MORE_THAN_EIGHT
               LEA             LONGER, A1
               MOVE.B          #14, D0
               TRAP            #15
               BRA             TRY_AGAIN_PROMPT
               
LESS_THAN_EIGHT
               LEA             LESS, A1
               MOVE.B          #14, D0
               TRAP            #15
               BRA             TRY_AGAIN_PROMPT 
       
TRY_AGAIN_PROMPT
               LEA             TRYAGAIN, A1
               MOVE.B          #14, D0
               TRAP            #15
               
               MOVE.B          #5, D0                       ; READ A SINGLE CHAR FROM KEYBOARD
               TRAP            #15
               
               LEA     SPACE, A1     
               MOVE.B  #14, D0         
               TRAP    #15
        
               CMPI.B  #$59, D1                 ;Check 'Y' in ascii
               BEQ     RESTART

               CMPI.B  #$79, D1                 ;Check 'y' in ascii
               BEQ     RESTART
               
               CMPI.B  #$4E, D1                 ;Check 'N' in ascii
               BEQ     ENDING     
      
               CMPI.B  #$6E, D1                 ;Check 'n' in ascii
               BEQ     ENDING
               BNE     Invalid_Y_N              ;If none of these are inputted, try again      

Invalid_Y_N
               LEA      Y_or_N, A1
               MOVE.B   #14, D0
               TRAP     #15
               BRA      TRY_AGAIN_PROMPT
                            

PRINT_SPACE     LEA             STR_SPACE, A1
                MOVE.B          #14, D0
                TRAP            #15
                RTS

PRINT_NEWLINE   LEA             STR_SPACE, A1
                MOVE.B          #13, D0
                TRAP            #15
                RTS

                
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

PRINT_SIZE_CODE
                CLR             D2
                MOVE.W          SECOND_THREE_BITS_AFTER_OPCODE, D3
                
                CMP.B           #%100, D3
                BLT             NO_CHANGE
                
                MOVE.B          #1, D2                                      *TO INDICATE OPMODE TO ADD AND SUB
               
                CMP.B           #%100, D3
                BEQ             PRINT_BYTE
                CMP.B           #%101, D3
                BEQ             PRINT_WORD
                CMP.B           #%110, D3
                BEQ             PRINT_LONG
                
NO_CHANGE       CMP.B           #%000, D3
                BEQ             PRINT_BYTE
                CMP.B           #%001, D3
                BEQ             PRINT_WORD
                CMP.B           #%010, D3
                BEQ             PRINT_LONG
                
                RTS
                
PRINT_ADDA_SIZE_CODE
                MOVE.W          SECOND_THREE_BITS_AFTER_OPCODE, D3
                
                CMP.B           #%011, D3
                BEQ             PRINT_WORD
                
                CMP.B           #%111, D3
                BEQ             PRINT_LONG
                
                RTS
               
PRINT_DIRECTION 
                MOVE.W          SECOND_THREE_BITS_AFTER_OPCODE, D3
                LSR             #2, D3
                
                CMP.B           #%001, D3
                BEQ             PRINT_LEFT
                
                CMP.B           #%000, D3
                BEQ             PRINT_RIGHT
                
                RTS
                
PRINT_SHIFT_SIZE_CODE
                MOVE.W          SECOND_THREE_BITS_AFTER_OPCODE, D3
                LSL             #6,D3
                LSL             #8,D3
                LSR             #6,D3
                LSR             #8,D3
                
                CMP.B           #%00, D3
                BEQ             PRINT_BYTE
                
                CMP.B           #%01, D3
                BEQ             PRINT_WORD
                
                CMP.B           #%10, D3
                BEQ             PRINT_LONG

                RTS
                
PRINT_LEFT      LEA             LEFT, A1
                MOVE.B          #14, D0
                TRAP            #15
                RTS
                
PRINT_RIGHT     LEA             RIGHT, A1
                MOVE.B          #14, D0
                TRAP            #15
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
                
COMMA_PRINT     LEA Comma, A1                       
                MOVE.B #14, D0
                TRAP #15
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
			    
RULE            DC.B 'Welcome! This is a disassembler program from group 4', CR, LF
                DC.B 'This is some information to enter a valid input:', CR, LF
                DC.B 'Address entered need to be in hexadecimal and in a longword', CR, LF
                DC.B 'Starting memory address must be greater or less than $0x1000', CR, LF
                DC.B 'Ending memory address must be in range [0x1000 - 0xFFFFF0]', CR, LF, 0
                
PROMPT1	        DC.B 'Please enter an even starting memory address in hex: ',0
EXTRA1          DC.B '         ', 0 
EMPTY           DC.B 'Empty input. Program restarting...', CR, LF, 0
LONGER          DC.B 'The entered input was longer than 8 digits', CR, LF, 0
LESS            DC.B 'The entered input was less than 8 digits', CR, LF, 0
LESS_START      DC.B 'You have entered the address that is less than 00001000. Restarting...', CR,LF, 0
MORE_END        DC.B 'You have entered the address that is greater than 00FFFFF0. Restarting..'
TRYAGAIN        DC.B 'Press "Y" to try again. Press "N" for no', CR, LF, 0
SAGEA           DC.B 'Inputed starting address is greater than the inputed ending address', CR, LF, 0
SPACE           DC.B ' ', CR, LF, 0
y_OR_N          DC.B 'Invalid input. Enter "Y" or "N" ', CR, LF, 0
R_OR_S          DC.B 'Invalid input. Enter "R" or "S" ' , CR, LF, 0
CANT_CONVERT    DC.B 'Character input was not in range [A-F]. Restarting...', CR, LF, 0
ODD_NUMBER      DC.B 'The address input was odd which is invalid. Restarting...', CR, LF,0
PROMPT2	        DC.B 'Please enter the ending memory address in hex: ',0
EXTRA2          DC.B '         ', 0
PROMPT3	        DC.B 'Do you wish to disassemble another 20 loc? Press Enter for Yes and "N" for No: ', CR, LF, 0
EXTRA3          DC.B '  ', 0
ENTER_OR_N      DC.B 'Invalid input. Press "Enter" to continue reading, "N" for exitting the program.',CR, LF, 0
FINISH          DC.B 'The disassembler has finished. To Restart press "R", to stop press "S" ',CR ,LF, 0 
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

LEFT            DC.B 'L',0
RIGHT           DC.B 'R',0

BYTE            DC.B '.B',0
WORD            DC.B '.W',0
LONG            DC.B '.L',0

INVALID_OPCODE_STRING   DC.B 'DATA',0
CMP_OPCODE_STRING       DC.B 'CMP',0
ADD_OPCODE_STRING       DC.B 'ADD',0
ADDA_OPCODE_STRING      DC.B 'ADDA',0
ADDQ_OPCODE_STRING      DC.B 'ADDQ',0
SUB_OPCODE_STRING       DC.B 'SUB',0
AND_OPCODE_STRING       DC.B 'AND',0
OR_OPCODE_STRING        DC.B 'OR',0
MOVEB_OPCODE_STRING     DC.B 'MOVE.B',0
MOVEQ_OPCODE_STRING     DC.B 'MOVEQ',0
MOVEW_OPCODE_STRING     DC.B 'MOVE.W',0
MOVEAW_OPCODE_STRING    DC.B 'MOVEA.W',0
MOVEL_OPCODE_STRING     DC.B 'MOVE.L',0
MOVEAL_OPCODE_STRING    DC.B 'MOVEA.L',0
BRA_OPCODE_STRING       DC.B 'BRA',0
BEQ_OPCODE_STRING       DC.B 'BEQ',0
BGT_OPCODE_STRING       DC.B 'BGT',0
BLE_OPCODE_STRING       DC.B 'BLE',0
LEA_OPCODE_STRING       DC.B 'LEA',0
NOTB_OPCODE_STRING      DC.B 'NOT.B',0
NOTW_OPCODE_STRING      DC.B 'NOT.W',0
NOTL_OPCODE_STRING      DC.B 'NOT.L',0
JSR_OPCODE_STRING       DC.B 'JSR',0
RTS_OPCODE_STRING       DC.B 'RTS',0
NOP_OPCODE_STRING       DC.B 'NOP',0
LS_OPCODE_STRING        DC.B 'LS',0
AS_OPCODE_STRING        DC.B 'AS',0
RO_OPCODE_STRING        DC.B 'RO',0


D_Mode          DC.B    'D', 0  * DATA REGISTER DIRECT 
A_Mode          DC.B    'A', 0  * ADDRESS REGISTER DIRECT
Plus_sign       DC.B    '+', 0
Minus_sign      DC.B    '-', 0
Open_pars       DC.B    '(', 0  * OPEN PARENTHESIS
Close_pars      DC.B    ')', 0  * CLOSE PARENTHIS
Hash_sign       DC.B    '#', 0  * HASH SIGN
Dollar_sign     DC.B    '$', 0  * DOLLAR SIGN
Comma           DC.B    ',', 0  * COMMA
Invalid_EA      DC.B    '$WXYZ', 0

CURR_ADDRESS    DS.B    30       ; Initialize and declare the current address

                END    START



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
