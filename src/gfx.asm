; =====================================================================================
; gfx.asm - the character set (charset): the graphics of all tiles
; =====================================================================================
;
; Assembled straight to the charset address, so nothing has to be copied at start-up;
; main.asm sets CHBAS = >charset to make ANTIC use it.
;
; Format (ANTIC mode 5): 1 character = 8 bytes = 8 rows, top to bottom.
; Every byte is one row of 4 pixels, 2 bits per pixel (left pixel = the 2 highest bits).
; Every row is shown 2 scanlines tall in mode 5, so a character is 4 pixels x 16 scanlines.
; The 2 bits pick the colour register (see the palette in colors.asm):
;   00 = COLOR4 (background)   01 = COLOR0   10 = COLOR1   11 = COLOR2
;   (11 = COLOR3 instead when the character is used inverse: code + 128)
; The comment after every row shows its 4 pixel values (0-3) from left to right.
;
; [n/n+128] after a character's name = its code normal / inverse. Characters are
; numbered in the order they are defined here (8 bytes each). The tiles that use
; them are listed in tiles.asm (tile_left / tile_right).

    * = charset                 ; data starts at the charset address (main.asm)

; ANTIC needs a mode-5 charset (128 chars x 8 bytes = 1 KB) to start on a 1 KB boundary
.IF charset & $3FF
    .ERROR "charset must be 1 KB aligned"
.ENDIF

; Blank tile [0/128], [1/129]                 used by: EMP
    .byte $00, $00, $00, $00, $00, $00, $00, $00   ; char 0: all pixels 0 (background)
    .byte $00, $00, $00, $00, $00, $00, $00, $00   ; char 1: all pixels 0 (background)

; Window tile left [2/130]                    used by: WNL (left), LWL (left, inverse)
    .byte %01011001            ; 1 1 2 1
    .byte %01110111            ; 1 3 1 3
    .byte %01110111            ; 1 3 1 3
    .byte %01110111            ; 1 3 1 3
    .byte %01110111            ; 1 3 1 3
    .byte %01110111            ; 1 3 1 3
    .byte %01110111            ; 1 3 1 3
    .byte %01011001            ; 1 1 2 1

; Window tile center [3/131]                  used by: WNL (right), WNR (left), LWL/LWR (inverse)
    .byte %01010101            ; 1 1 1 1
    .byte %11111111            ; 3 3 3 3
    .byte %11111111            ; 3 3 3 3
    .byte %11111111            ; 3 3 3 3
    .byte %11111111            ; 3 3 3 3
    .byte %11111111            ; 3 3 3 3
    .byte %11111111            ; 3 3 3 3
    .byte %01010101            ; 1 1 1 1

; Window tile right [4/132]                   used by: WNR (right), LWR (right, inverse)
    .byte %01100101            ; 1 2 1 1
    .byte %11011101            ; 3 1 3 1
    .byte %11011101            ; 3 1 3 1
    .byte %11011101            ; 3 1 3 1
    .byte %11011101            ; 3 1 3 1
    .byte %11011101            ; 3 1 3 1
    .byte %11011101            ; 3 1 3 1
    .byte %01100101            ; 1 2 1 1

; Brick A_left [5/133]                        used by: BRA (left)
    .byte %01010110            ; 1 1 1 2
    .byte %01010101            ; 1 1 1 1
    .byte %01101010            ; 1 2 2 2
    .byte %01101010            ; 1 2 2 2
    .byte %01101010            ; 1 2 2 2
    .byte %01010101            ; 1 1 1 1
    .byte %01010110            ; 1 1 1 2
    .byte %01010110            ; 1 1 1 2

; Brick A_right [6/134]                       used by: BRA (right)
    .byte %10101010            ; 2 2 2 2
    .byte %01010101            ; 1 1 1 1
    .byte %10100101            ; 2 2 1 1
    .byte %10100101            ; 2 2 1 1
    .byte %10100101            ; 2 2 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %10101010            ; 2 2 2 2
    .byte %10101010            ; 2 2 2 2

; Brick B_left [7/135]                        used by: BRB (left)
    .byte %10100110            ; 2 2 1 2
    .byte %01010101            ; 1 1 1 1
    .byte %10101010            ; 2 2 2 2
    .byte %10101010            ; 2 2 2 2
    .byte %10101010            ; 2 2 2 2
    .byte %01010101            ; 1 1 1 1
    .byte %10100110            ; 2 2 1 2
    .byte %10100110            ; 2 2 1 2

; Brick B_right [8/136]                       used by: BRB (right)
    .byte %10101010            ; 2 2 2 2
    .byte %01010101            ; 1 1 1 1
    .byte %10011010            ; 2 1 2 2
    .byte %10011010            ; 2 1 2 2
    .byte %10011010            ; 2 1 2 2
    .byte %01010101            ; 1 1 1 1
    .byte %10101010            ; 2 2 2 2
    .byte %10101010            ; 2 2 2 2

; Brick C_left [9/137]                        used by: BRC (left)
    .byte %10101010            ; 2 2 2 2
    .byte %10101010            ; 2 2 2 2
    .byte %01010101            ; 1 1 1 1
    .byte %01011010            ; 1 1 2 2
    .byte %01011010            ; 1 1 2 2
    .byte %01011010            ; 1 1 2 2
    .byte %01010101            ; 1 1 1 1
    .byte %10101010            ; 2 2 2 2

; Brick C_right [10/138]                      used by: BRC (right)
    .byte %10010101            ; 2 1 1 1
    .byte %10010101            ; 2 1 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %10101001            ; 2 2 2 1
    .byte %10101001            ; 2 2 2 1
    .byte %10101001            ; 2 2 2 1
    .byte %01010101            ; 1 1 1 1
    .byte %10010101            ; 2 1 1 1

; Bottom_window_left [11/139]                 used by: FLW (left)
    .byte %01111111            ; 1 3 3 3
    .byte %01111111            ; 1 3 3 3
    .byte %01010101            ; 1 1 1 1
    .byte %01111111            ; 1 3 3 3
    .byte %01111111            ; 1 3 3 3
    .byte %01111111            ; 1 3 3 3
    .byte %01111111            ; 1 3 3 3
    .byte %01111111            ; 1 3 3 3

; Bottom_window_right [12/140]                used by: FLW (right)
    .byte %11111101            ; 3 3 3 1
    .byte %11111101            ; 3 3 3 1
    .byte %01010101            ; 1 1 1 1
    .byte %11111101            ; 3 3 3 1
    .byte %11111101            ; 3 3 3 1
    .byte %11111101            ; 3 3 3 1
    .byte %11111101            ; 3 3 3 1
    .byte %11111101            ; 3 3 3 1

; (retired: chars_len = * - gfx_school, used by the old load_gfx in tools.asm)
;chars_len = * - gfx_school
