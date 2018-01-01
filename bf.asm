START *= $17FE                 ; start at address 828
MAIN
        LDA #0
        STA TAPE_PTR
        STA DATA_PTR
        STA OUT_CTR             ; clear all our pointer variables

        LDY #0
        LDA #0
CLEAN_LOOP                      ; loop for cleaning tape data        
        STA TAPE_DATA,Y
        INY
        CPY #$FF
        BEQ GET_DATA_START
        JMP CLEAN_LOOP


GET_DATA_START
        LDA #$93
        JSR $FFD2
        LDA #'$'
        JSR $FFD2               ; clear screen and print prompt
GET_DATA_LOOP
        JSR $FFCF               ; get data byte, check for type of bf
        CMP #'+'
        BNE GET_DATA_MINUS
        LDA #1
        JMP GET_DATA_LOOP_END
GET_DATA_MINUS
        CMP #'-'
        BNE GET_DATA_NEXT
        LDA #2
        JMP GET_DATA_LOOP_END
GET_DATA_NEXT
        CMP #'>'
        BNE GET_DATA_PREV
        LDA #3
        JMP GET_DATA_LOOP_END
GET_DATA_PREV
        CMP #'<'
        BNE GET_DATA_LEFT
        LDA #4
        JMP GET_DATA_LOOP_END
GET_DATA_LEFT
        CMP #'('
        BNE GET_DATA_RIGHT
        LDA #5
        JMP GET_DATA_LOOP_END
GET_DATA_RIGHT
        CMP #')'
        BNE GET_DATA_GET
        LDA #6
        JMP GET_DATA_LOOP_END
GET_DATA_GET
        CMP #','
        BNE GET_DATA_PUT
        LDA #7
        JMP GET_DATA_LOOP_END
GET_DATA_PUT
        CMP #'.'
        BNE GET_DATA_CHECK_END
        LDA #8
        JMP GET_DATA_LOOP_END
GET_DATA_CHECK_END
        CMP #'!'
        BNE GET_DATA_LOOP
        JMP PRE_LOOP
GET_DATA_LOOP_END
        LDY OUT_CTR                     ; write brainfuck byte to tape
        STA TAPE_BEGIN,Y
        INC OUT_CTR
        JMP GET_DATA_LOOP        

PRE_LOOP
        LDA #$93
        JSR $FFD2
        LDY OUT_CTR
        LDA #0
        STA TAPE_BEGIN,Y                ; clear screen, put stopper on tape
LOOP    
        LDX TAPE_PTR

        LDA TAPE_BEGIN,X        ; load brainfuck byte
        ASL                     ; multiply A by two to lookup function in table
        
        TAX 
        LDA FUNCTION_TABLE,X    ; load higher address byte from function table
        PHA                     ; push it

        INX
        LDA FUNCTION_TABLE,X    ; load lower address byte from function table
        PHA                     ; push it
        
        RTS                     ; "return" to function

EXIT
        NOP
        JSR $FFCF               ; wait for user input before returning to prompt
        JMP MAIN

FUNC_ADD                        ; add 1 from current cell
        NOP
        LDY DATA_PTR
        LDX TAPE_DATA,Y
        INX
        TXA
        STA TAPE_DATA,Y
        INC TAPE_PTR
        JMP LOOP

FUNC_SUB                        ; sub 1 from current cell
        NOP
        LDY DATA_PTR
        LDX TAPE_DATA,Y
        DEX
        TXA
        STA TAPE_DATA,Y
        INC TAPE_PTR
        JMP LOOP

FUNC_INC_PTR                    ; increments tape pointer
        NOP
        INC DATA_PTR
        INC TAPE_PTR
        JMP LOOP

FUNC_DEC_PTR                    ; decrements tape pointer
        NOP
        DEC DATA_PTR
        INC TAPE_PTR
        JMP LOOP

FUNC_LOOP_LEFT                  ; jumps to next ')' if cell is zero
        NOP
        LDY DATA_PTR
        LDA TAPE_DATA,Y
        CMP #0
        BNE FUNC_LOOP_LEFT_RETURN
        
        LDY #0
        LDX TAPE_PTR
FUNC_LOOP_LEFT_LOOP                                     
                LDA TAPE_BEGIN,X
                CMP #5
                BNE FUNC_LOOP_LEFT_LOOP_CHECK_RIGHT
                INY
                JMP FUNC_LOOP_LEFT_LOOP_END
FUNC_LOOP_LEFT_LOOP_CHECK_RIGHT
                        CMP #6
                        BNE FUNC_LOOP_LEFT_LOOP_END
                        DEY
FUNC_LOOP_LEFT_LOOP_END                        
                        CPY #0
                        BEQ FUNC_LOOP_LEFT_FOUND_MATCH
                        INX
                        JMP FUNC_LOOP_LEFT_LOOP        
FUNC_LOOP_LEFT_FOUND_MATCH
                STX TAPE_PTR
FUNC_LOOP_LEFT_RETURN
                INC TAPE_PTR                
                JMP LOOP

FUNC_LOOP_RIGHT                 ; jumps to prev '(' if cell is non-zero
        NOP
        LDY DATA_PTR
        LDA TAPE_DATA,Y
        CMP #0
        BEQ FUNC_LOOP_LEFT_RETURN

        LDY #0
        LDX TAPE_PTR
FUNC_LOOP_RIGHT_LOOP
                LDA TAPE_BEGIN,X
                CMP #5
                BNE FUNC_LOOP_RIGHT_LOOP_CHECK_RIGHT
                DEY
                JMP FUNC_LOOP_RIGHT_LOOP_END
FUNC_LOOP_RIGHT_LOOP_CHECK_RIGHT
                        CMP #6
                        BNE FUNC_LOOP_RIGHT_LOOP_END
                        INY
FUNC_LOOP_RIGHT_LOOP_END
                        CPY #0
                        BEQ FUNC_LOOP_LEFT_FOUND_MATCH
                        DEX
                        JMP FUNC_LOOP_RIGHT_LOOP

FUNC_GET_CHR
        NOP
        LDA #13
        JSR $FFD2
        LDA #':'
        JSR $FFD2
        JSR $FFCF
        LDY DATA_PTR
        STA TAPE_DATA,Y
        LDA #13
        JSR $FFD2
        INC TAPE_PTR
        JMP LOOP

FUNC_PUT_CHR
        NOP
        LDY DATA_PTR
        LDA TAPE_DATA,Y
        JSR $FFD2
        INC TAPE_PTR
        JMP LOOP

FUNCTION_TABLE
        byte >EXIT
        byte <EXIT
        
        byte >FUNC_ADD
        byte <FUNC_ADD
        
        byte >FUNC_SUB
        byte <FUNC_SUB
        
        byte >FUNC_INC_PTR
        byte <FUNC_INC_PTR
        
        byte >FUNC_DEC_PTR
        byte <FUNC_DEC_PTR
        
        byte >FUNC_LOOP_LEFT
        byte <FUNC_LOOP_LEFT

        byte >FUNC_LOOP_RIGHT
        byte <FUNC_LOOP_RIGHT
        
        byte >FUNC_GET_CHR
        byte <FUNC_GET_CHR
        
        byte >FUNC_PUT_CHR
        byte <FUNC_PUT_CHR
TAPE_PTR byte 0
DATA_PTR byte 0
OUT_CTR byte 0
TAPE_BEGIN
TAPE_DATA = TAPE_BEGIN + $FF

