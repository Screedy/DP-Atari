; main.asm - Main program for Atari 8-bit

.INCLUDE "macros.asm"

    * = $2000

charset = $5000         ; Charset memory start address
screen = $4000          ; Screen memory start address
pmgdata = $6000         ; Player/Missile graphics data start address

ZP_SRC = $CB            ; source pointer (zero page, $CB-$CC)
ZP_DST = $CD            ; destination pointer (zero page, $CD-$CE)

start
    jsr setup_screen
    jsr setup_colors
;    jsr load_gfx
    MVA #>charset CHBAS         ; Set character set base address
    jsr display_map

    jmp *

    .INCLUDE "tools.asm"
    .INCLUDE "hw.asm"
    .INCLUDE "dlist.asm"
    .INCLUDE "colors.asm"

; ----------- Subroutines -----------

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

; Function: display_map
; Description: Display the map on the screen
; INPUT: none
; OUTPUT: none
    .LOCAL
display_map
    MWA map ZP_SRC             ; source: definition of the map
    MWA screen ZP_DST          ; destination: screen memory
    LDX #>map_len               ; X = length of the map
    LDA #<map_len              ; A = remaining length of the map
    jmp copy_mem               ; Copy map to screen memory

map
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 5,6,2,3,3,4,7,8,2,3,3,4,7,8,2,3,3,4,5,6,2,3,3,4,5,6,2,3,3,4,9,10,2,3,3,4,7,8,2,3
    .byte 5,6,2,3,3,4,7,8,130,131,131,132,7,8,2,3,3,4,5,6,2,3,3,4,5,6,2,3,3,4,9,10,2,3,3,4,7,8,2,3
    .byte 5,6,2,3,3,4,7,8,2,3,3,4,7,8,2,3,3,4,5,6,2,3,3,4,5,6,2,3,3,4,9,10,2,3,3,4,7,8,2,3
    .byte 5,6,2,3,3,4,7,8,2,3,3,4,7,8,2,3,3,4,5,6,2,3,3,4,5,6,2,3,3,4,9,10,2,3,3,4,7,8,2,3
    .byte 11,12,11,12,11,12,11,12,11,12,11,12,11,12,11,12,11,12,11,12,11,12,11,12,11,12,11,12,11,12,11,12,11,12,11,12,11,12,11,12
    
map_len = * - map

; copy_mem - Copy a block of memory (up to 64 KB) from one location to another
; INPUT: ZP_SRC = source address
;        ZP_DST = destination address
;        X = >length
;        Y = <length
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


.IF * > charset
    .ERROR "Charset memory overlap"
.ENDIF
.INCLUDE "gfx.asm"
.INCLUDE "pmgdata.asm"
; ----------- Run the program -----------
    .RUN start