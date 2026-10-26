; =====================================================================================
; colors.asm - colour palette: player colours and screen colours
; =====================================================================================
;
; Atari colour values: high 4 bits = hue (0-15), low 4 bits = brightness (0-14, even).
; E.g. $98 = hue 9 (blue), brightness 8. $00 = black, $0E = white.
;
; The colours are written to the OS shadow registers ($02C0-$02C8); the OS copies them
; to the hardware (GTIA) every vertical blank. The 9 shadow registers are next to each
; other in memory, which is why one loop can set all of them:
;   $02C0-$02C3  PCOLR0-3  player 0-3 colours
;   $02C4-$02C8  COLOR0-4  screen colours (which pixel values use them: see ?palette)

    .LOCAL                      ; ?names below are local to this file

; -------------------------------------------------------------------------------------
; Colour names (some are not used yet)
; -------------------------------------------------------------------------------------
?light_blue = $98
?light_gray = $0A
?light_yellow = $1E
?white = $0E
?dark_gray = $05
?medium_gray = $06
?window_blue = $8E
?sky_blue = $8A
?black = $00
?brown = $22
?peach = $2C

; -------------------------------------------------------------------------------------
; Function: setup_colors
; Description: Copy ?palette into the 9 colour shadow registers.
; Reasoning behind loop instead of direct MVA instructions:
;   Size:  11 bytes (loop) + 9 bytes (palette) = 20 bytes instead of 45 bytes (9x MVA)
;   Speed: ~127 cycles (loop) instead of ~54 cycles (9x MVA) - runs only once at start-up
; INPUT: none
; OUTPUT: none
; DESTROYED: A, X
; -------------------------------------------------------------------------------------
setup_colors
    ldx #8              ; 9 registers (PCOLR0-3 + COLOR0-4): X = 8 .. 0
?loop
    lda ?palette,x      ; A = colour number X from the palette
    sta PCOLR0,x        ; -> register PCOLR0+X (X = 4..8 reaches COLOR0-4)
    dex                 ; previous register
    bpl ?loop           ; until X goes below 0
    rts                 ; (the priority, players in front, is set in setup_pmg, pmg.asm)

; -------------------------------------------------------------------------------------
; The palette, in register order ($02C0 .. $02C8)
; -------------------------------------------------------------------------------------
?palette
; Player/Missile colors
    .BYTE ?brown            ; PCOLR0 - Player 0 color register (hair)
    .BYTE ?peach            ; PCOLR1 - Player 1 color register (skin)
    .BYTE ?light_blue       ; PCOLR2 - Player 2 color register (clothes)
    .BYTE ?black            ; PCOLR3 - Player 3 color register (boots)
; Screen colors (ANTIC mode 5: every pixel is 2 bits; the bits pick the colour register)
    .BYTE ?dark_gray        ; COLOR0 - pixel %01
    .BYTE ?medium_gray      ; COLOR1 - pixel %10
    .BYTE ?window_blue      ; COLOR2 - pixel %11
    .BYTE ?light_yellow     ; COLOR3 - pixel %11 in an inverse character (code + 128)
    .BYTE ?sky_blue         ; COLOR4 - pixel %00 = background

    .LOCAL                      ; end of this file's local names
