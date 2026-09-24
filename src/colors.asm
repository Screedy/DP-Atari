; colors.asm - setup color palette

    .LOCAL

?light_blue = $98
?light_gray = $0A
?light_yellow = $1E
?white = $0E
?dark_gray = $05
?medium_gray = $06
?window_blue = $8E
?sky_blue = $8A

; ---------- Setup color palette ------------
; Reasoning behind loop instead of direct MVA instructions:
; Size: 11 bytes (loop) + 5 bytes (palette) = 16 bytes instead of 25 bytes (5x MVA instructions)
; Speed: +- 70 cycles (loop) instead of 30 cycles (5x MVA instructions) - should be done only once, we will see how it goes
setup_colors
    ldx #4              ; 5 registers to set up (COLOR0 to COLOR4)
?loop
    lda ?palette,x
    sta COLOR0,x        ; Set registers from COLOR0 to COLOR4.
    dex
    bpl ?loop
    rts

?palette
    .BYTE ?dark_gray        ; COLOR0 - %01
    .BYTE ?medium_gray      ; COLOR1 - %10
    .BYTE ?window_blue      ; COLOR2 - %11
    .BYTE ?light_yellow     ; COLOR3 - inverse
    .BYTE ?sky_blue         ; COLOR4 - %00

    .LOCAL