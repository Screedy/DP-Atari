; main.asm - Main program for Atari 8-bit

.INCLUDE "macros.asm"

    * = $2000
    .INCLUDE "tools.asm"
    .INCLUDE "hw.asm"

charset = $3C00         ; Charset memory start address
screen = $4000          ; Screen memory start address

start
    jsr setup_screen
    jsr setup_colors

    ; Set up character set
    MVA #>charset CHBAS         ; Macro Value Address: Load the high byte of charset into CHBAS
    ldx #0

loop_x
    MVA chars,x charset,x       ; Load the address of chars into charset
    inx
    cpx #chars_len
    bne loop_x

    ldy #0
loop_y
    MVA scene,y screen,y       ; Load the address of scene into charset
    iny
    cpy #scene_len
    bne loop_y
; Main loop

;    MVA chars charset           ; Load the address of chars into charset

    jmp *

; ---------- Includes ------------
    .INCLUDE "dlist.asm"
    .INCLUDE "colors.asm"

; ---------- Character set -----------
scene
    .byte 4,5,1,2,2,3,6,7,129,130,130,131,6,7,1,2,2,3,4,5,1,2,2,3,4,5,1,2,2,3,8,9,1,2,2,3
scene_len = * - scene

chars
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

chars_len = * - chars
; ----------- Data -----------


; ----------- Run the program -----------
    .RUN start