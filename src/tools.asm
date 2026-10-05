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

; copy_mem - Copy a block of memory (up to 64 KB) from one location to another
; INPUT: ZP_SRC = source address
;        ZP_DST = destination address
;        X = >length
;        A = <length
; DESTROYED: A, X, Y, ZP_SRC, ZP_DST
    .LOCAL
copy_mem
    pha                     ; Rest A save on a stack
    ldy #0
    cpx #0
    beq ?rest               ; less than 256 B -> only rest
?page
    lda (ZP_SRC),y
    sta (ZP_DST),y
    iny
    bne ?page
    inc ZP_SRC+1            ; Shift source address to next page
    inc ZP_DST+1
    dex
    bne ?page
?rest
    pla                     ; Restore A from stack
    tay                     ; Y = number of bytes to copy
    beq ?done
?tail
    dey                     ; Copies from the end: Y-1 .. 0
    lda (ZP_SRC),y
    sta (ZP_DST),y
    cpy #0
    bne ?tail
?done
    rts
; ----------- end of function copy_mem -----------

; TODO: This code has been retired, but I will leave it here while I test the new graphics loading method.
; Function: load_gfx
; Description: Load the character set and graphics data into memory
; INPUT: none
; OUTPUT: none
;    .LOCAL
;load_gfx
    ; Set up character set
;    MVA #>charset CHBAS         ; CHBAS = upper byte of charset address
;    MWA gfx_school ZP_SRC       ; source: definition of the character set
;    MWA charset ZP_DST          ; destination: charset memory
;    LDX #>chars_len              ; X = length of the character set
;    LDA #<chars_len             ; A = remaining length of the character set
;    jmp copy_mem                ; Copy character set to memory
; ----------- end of function load_gfx -----------
