; main.asm - Main program for Atari 8-bit

.INCLUDE "macros.asm"

    * = $2000

charset = $5000         ; Charset memory start address
screen = $4000          ; Screen memory start address
screen_len = 40*12      ; 12 rows of ANTIC 5 (dlist.asm), 40 B each
                        ; increase when: dlist.asm gets more mode lines, the playfield is
                        ; switched to wide (48 B/row in SDMCTL), or the map scrolls (bigger buffer)
map_area = $8000        ; current room's tile map is loaded/copied here (outside the
                        ; 130XE bank window $4000-$7FFF, so maps can come from banks)
map_area_len = $2000    ; 8 KB reserved for maps; the biggest room must fit
map_w = 80              ; tiles per map row (current room)
map_h = 12              ; map rows
view_w = 20             ; tiles visible on screen (20 tiles = 40 chars)
pmg_len = $400          ; PMG area size: 1 KB for double-line resolution
pmg = map_area-pmg_len  ; Player/Missile graphics, right below the map area ($7C00)

ZP_SRC = $CB            ; source pointer (zero page, $CB-$CC)
ZP_SRC_LEN = 2          ; 16-bit pointer, never grows; add a new ZP_* name for more ZP space
ZP_DST = $CD            ; destination pointer (zero page, $CD-$CE)
ZP_DST_LEN = 2

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

; Function: display_map
; Description: Draw the left view_w tiles of each map row onto the screen
; INPUT: none (reads map_area, writes screen)
; OUTPUT: none
; DESTROYED: A, X, Y, ZP_SRC, ZP_DST
    .LOCAL
; ponytail: always shows map columns 0-19; scrolling (view offset + LMS/HSCROL)
; comes with the DLI/scroll work
display_map
    MWA map_area ZP_SRC        ; source: tile map
    MWA screen ZP_DST          ; destination: screen memory
    MVA #map_h ?rows
?row
    ldx #view_w                ; X = tiles left in this row
?tile
    ldy #0
    lda (ZP_SRC),y             ; A = tile ID
    jsr draw_tile              ; draw it, ZP_DST += 2
    ADW ZP_SRC #1              ; next tile
    dex
    bne ?tile
    ADW ZP_SRC #map_w-view_w   ; skip the tiles right of the view
    dec ?rows
    bne ?row
    rts
?rows
    .BYTE 0

.IF view_w*2*map_h > screen_len
    .ERROR "View bigger than screen memory"
.ENDIF

.IF * > charset
    .ERROR "Charset memory overlap"
.ENDIF
.INCLUDE "gfx.asm"
.INCLUDE "pmg.asm"
.INCLUDE "pmgdata.asm"

; ----------- Map area -----------
    * = map_area
.INCLUDE "maps/university_outside.asm"
.IF * - map_area > map_area_len
    .ERROR "Map bigger than the map area"
.ENDIF

; ----------- Run the program -----------
    .RUN start