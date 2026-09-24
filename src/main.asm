; main.asm - Main program for Atari 8-bit

.INCLUDE "macros.asm"

    * = $2000

charset = $3C00         ; Charset memory start address
screen = $4000          ; Screen memory start address

start
    jsr setup_screen
    jsr setup_colors
    jsr load_gfx
    jsr display_map

    jmp *

    .INCLUDE "tools.asm"
    .INCLUDE "hw.asm"
    .INCLUDE "dlist.asm"
    .INCLUDE "gfx.asm"
    .INCLUDE "colors.asm"

; ----------- Subroutines -----------

; Function: load_gfx
; Description: Load the character set and graphics data into memory
; INPUT: none
; OUTPUT: none
    .LOCAL
load_gfx
    ; Set up character set
    MVA #>charset CHBAS         ; Macro Value Address: Load the high byte of charset into CHBAS
    ldx #0
?loop
    MVA gfx_school,x charset,x       ; Load the address of chars into charset
    inx
    cpx #chars_len
    bne ?loop
    rts

; Function: display_map
; Description: Display the map on the screen
; INPUT: none
; OUTPUT: none
    .LOCAL
display_map
    ldy #0
?loop
    MVA map,y screen,y       ; Load the address of map into charset
    iny
    cpy #map_len
    bne ?loop
    rts

map
    .byte 4,5,1,2,2,3,6,7,129,130,130,131,6,7,1,2,2,3,4,5,1,2,2,3,4,5,1,2,2,3,8,9,1,2,2,3
map_len = * - map


; ----------- Run the program -----------
    .RUN start