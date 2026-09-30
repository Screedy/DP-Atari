; Start in memory at charset
    * = charset
; Blank tile [0/128], [1/129]
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00

; Window tile left [2/130]
    .byte %01011001
    .byte %01110111
    .byte %01110111
    .byte %01110111
    .byte %01110111
    .byte %01110111
    .byte %01110111
    .byte %01011001

; Window tile center [3/131]
    .byte %01010101
    .byte %11111111
    .byte %11111111
    .byte %11111111
    .byte %11111111
    .byte %11111111
    .byte %11111111
    .byte %01010101

; Window tile right [4/132]
    .byte %01100101
    .byte %11011101
    .byte %11011101
    .byte %11011101
    .byte %11011101
    .byte %11011101
    .byte %11011101
    .byte %01100101
    
; Brick A_left [5/133]
    .byte %01010110
    .byte %01010101
    .byte %01101010
    .byte %01101010
    .byte %01101010
    .byte %01010101
    .byte %01010110
    .byte %01010110

; Brick A_right [6/134]
    .byte %10101010
    .byte %01010101
    .byte %10100101
    .byte %10100101
    .byte %10100101
    .byte %01010101
    .byte %10101010
    .byte %10101010

; Brick B_left [7/135]
    .byte %10100110
    .byte %01010101
    .byte %10101010
    .byte %10101010
    .byte %10101010
    .byte %01010101
    .byte %10100110
    .byte %10100110

; Brick B_right [8/136]
    .byte %10101010
    .byte %01010101
    .byte %10011010
    .byte %10011010
    .byte %10011010
    .byte %01010101
    .byte %10101010
    .byte %10101010

; Brick C_left [9/137]
    .byte %10101010
    .byte %10101010
    .byte %01010101
    .byte %01011010
    .byte %01011010
    .byte %01011010
    .byte %01010101
    .byte %10101010

; Brick C_right [10/138]
    .byte %10010101
    .byte %10010101
    .byte %01010101
    .byte %10101001
    .byte %10101001
    .byte %10101001
    .byte %01010101
    .byte %10010101

; Bottom_window_left [11/139]
    .byte %01111111
    .byte %01111111
    .byte %01010101
    .byte %01111111
    .byte %01111111
    .byte %01111111
    .byte %01111111
    .byte %01111111

; Bottom_window_right [12/140]
    .byte %11111101
    .byte %11111101
    .byte %01010101
    .byte %11111101
    .byte %11111101
    .byte %11111101
    .byte %11111101
    .byte %11111101

;chars_len = * - gfx_school