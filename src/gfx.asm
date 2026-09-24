gfx_school
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000

; Window tile left [1/129]
    .byte %01011001
    .byte %01110111
    .byte %01110111
    .byte %01110111
    .byte %01110111
    .byte %01110111
    .byte %01110111
    .byte %01011001

; Window tile center [2/130]
    .byte %01010101
    .byte %11111111
    .byte %11111111
    .byte %11111111
    .byte %11111111
    .byte %11111111
    .byte %11111111
    .byte %01010101

; Window tile right [3/131]
    .byte %01100101
    .byte %11011101
    .byte %11011101
    .byte %11011101
    .byte %11011101
    .byte %11011101
    .byte %11011101
    .byte %01100101
    
; Brick A_left [4/132]
    .byte %01010110
    .byte %01010101
    .byte %01101010
    .byte %01101010
    .byte %01101010
    .byte %01010101
    .byte %01010110
    .byte %01010110

; Brick A_right [5/133]
    .byte %10101010
    .byte %01010101
    .byte %10100101
    .byte %10100101
    .byte %10100101
    .byte %01010101
    .byte %10101010
    .byte %10101010

; Brick B_left [6/134]
    .byte %10100110
    .byte %01010101
    .byte %10101010
    .byte %10101010
    .byte %10101010
    .byte %01010101
    .byte %10100110
    .byte %10100110

; Brick B_right [7/135]
    .byte %10101010
    .byte %01010101
    .byte %10011010
    .byte %10011010
    .byte %10011010
    .byte %01010101
    .byte %10101010
    .byte %10101010

; Brick C_left [8/136]
    .byte %10101010
    .byte %10101010
    .byte %01010101
    .byte %01011010
    .byte %01011010
    .byte %01011010
    .byte %01010101
    .byte %10101010

; Brick C_right [9/137]
    .byte %10010101
    .byte %10010101
    .byte %01010101
    .byte %10101001
    .byte %10101001
    .byte %10101001
    .byte %01010101
    .byte %10010101

chars_len = * - gfx_school