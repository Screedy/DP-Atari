; tools.asm - Atari 8-bit tools and utilities

; Convert ATASCII character to internal code for screen memory
; INPUT: A = ATASCII character
; OUTPUT: A = internal code (for screen memory)
atascii_to_intern
    cmp #$20
    bcc ctrl            ; If less than space, branch to ctrl
    cmp #$60
    bcc normal          ; If less than backtick, branch to normal
    rts                 ; Return, A is already correct
normal
    sec
    sbc #$20            ; Subtract 32 to convert to internal code
    rts                 ; Return
ctrl
    clc
    adc #$40            ; Add 64 to convert control characters
    rts                 ; Return
; ----------- end of function atascii_to_intern -----------
