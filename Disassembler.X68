*---------------------------------------------------------------------------------------*
* Title      : 68K Disassembler
* Written by : Arkar Swar, Sidd Rao, Thinh Dang
* Date       : 05/16/2022
* Description: A 68K Disassembler that converts a memory image to 68K instructions
*---------------------------------------------------------------------------------------*

    ORG    $1000                                ; Origin $1000
    
START:
    
welcomePrompt   LEA     WELCOME_MESSAGE,    A1  ; Load Welcome Message Into A1
                MOVE.B  #13,                D0  ; Move #13 into D0           
                TRAP    #15                     ; Trap #15

startAddr   LEA     START_ADR_PROMPT,   A1  ; Load Starting Address Into A1
            MOVE.B  #13,                D0  ; Move #13 into D0           
            TRAP    #15                     ; Trap #15
            
			LEA     RAW_STARTING_ADDR,  A1  ; Load Raw Starting Address Into A1
			MOVE.B	#2,                 D0  ; Move #2 Into D0
			TRAP	#15                     ; Trap #15

    SIMHALT                                     ; Halt Simulator

*----------------Variables and Constants----------------*

WELCOME_MESSAGE     DC.B    'Welcome to 68k disassembler!', 0
START_ADR_PROMPT    DC.B    'Please Enter The Starting Address', 0
END_ADR_PROMPT      DC.B    'Please Enter The Ending Adress', 0

RAW_STARTING_ADDR   DS.B    20

*----------------END----------------*

    END    START

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
