; main.asm - Main program for Atari 8-bit

.INCLUDE "macros.asm"

    * = $2000

charset = $5000         ; Charset memory start address
screen = $4000          ; Screen memory start address
pmg = $6000             ; Player/Missile graphics data start address
pmg_len = $400          ; PMG area size: 1 KB for double-line resolution

ZP_SRC = $CB            ; source pointer (zero page, $CB-$CC)
ZP_DST = $CD            ; destination pointer (zero page, $CD-$CE)

start
    jsr setup_screen
    jsr setup_colors
;    jsr load_gfx
    MVA #>charset CHBAS         ; Set character set base address
    jsr clear_pmg
    jsr load_pmg
    jsr setup_pmg
    jsr display_map

    jmp *

    .INCLUDE "tools.asm"
    .INCLUDE "hw.asm"
    .INCLUDE "dlist.asm"
    .INCLUDE "colors.asm"
    .INCLUDE "tiles.asm"

; ----------- Subroutines -----------

; Function: display_map
; Description: Display the map on the screen
; INPUT: none
; OUTPUT: none
    .LOCAL
; map is exactly screen width (20 tiles = 40 chars), so screen rows are contiguous;
; add a row stride when maps get wider or scroll
display_map
    MWA screen ZP_DST          ; destination: screen memory
    ldx #0                     ; X = tile index in the map
?loop
    ldy map,x                  ; Y = tile ID
    lda tile_right,y
    pha                        ; keep right char
    lda tile_left,y
    ldy #0
    sta (ZP_DST),y             ; left char
    pla
    iny
    sta (ZP_DST),y             ; right char
    clc                        ; ZP_DST += 2
    lda ZP_DST
    adc #2
    sta ZP_DST
    bcc ?next
    inc ZP_DST+1
?next
    inx
    cpx #map_len
    bne ?loop
    rts

map                     ; 20 x 9 tiles, see tiles.asm
    .BYTE EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP
    .BYTE EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP
    .BYTE EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP
    .BYTE EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP
    .BYTE BRA,WNL,WNR,BRB,WNL,WNR,BRB,WNL,WNR,BRA,WNL,WNR,BRA,WNL,WNR,BRC,WNL,WNR,BRB,WNL
    .BYTE BRA,WNL,WNR,BRB,LWL,LWR,BRB,WNL,WNR,BRA,WNL,WNR,BRA,WNL,WNR,BRC,WNL,WNR,BRB,WNL
    .BYTE BRA,WNL,WNR,BRB,WNL,WNR,BRB,WNL,WNR,BRA,WNL,WNR,BRA,WNL,WNR,BRC,WNL,WNR,BRB,WNL
    .BYTE BRA,WNL,WNR,BRB,WNL,WNR,BRB,WNL,WNR,BRA,WNL,WNR,BRA,WNL,WNR,BRC,WNL,WNR,BRB,WNL
    .BYTE FLW,FLW,FLW,FLW,FLW,FLW,FLW,FLW,FLW,FLW,FLW,FLW,FLW,FLW,FLW,FLW,FLW,FLW,FLW,FLW

map_len = * - map

.IF map_len > 255
    .ERROR "Map too big for X-indexed display_map"
.ENDIF

.IF * > charset
    .ERROR "Charset memory overlap"
.ENDIF
.INCLUDE "gfx.asm"
.INCLUDE "pmg.asm"
.INCLUDE "pmgdata.asm"
; ----------- Run the program -----------
    .RUN start