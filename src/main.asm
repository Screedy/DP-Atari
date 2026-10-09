; main.asm - Main program for Atari 8-bit

.INCLUDE "macros.asm"

    * = $2000

charset         = $5000         ; Charset memory start address
canvas          = $4000         ; canvas memory start address
map_area        = $8000         ; current room's tile map is loaded/copied here (outside the
                                ; 130XE bank window $4000-$7FFF, so maps can come from banks)
map_area_len    = $2000         ; 8 KB reserved for maps; the biggest room must fit
map_w           = 80            ; tiles per map row (current room)
map_h           = 12            ; map rows
walk_row_top    = 9             ; walkable map rows (current room): grass, sidewalk
walk_row_bottom = 10
view_w          = 20            ; tiles visible on canvas (20 tiles = 40 chars)
canvas_w        = map_w*2       ; canvas bytes per row: the whole map row expanded (2 chars/tile)
canvas_len      = canvas_w*map_h ; 12 rows x 160 B = 1920 B ($4000-$477F)
                                ; increase when: the map gets wider or taller, or dlist.asm gets
                                ; more mode lines; keep every row inside one 4 KB block (ANTIC)
pmg_len         = $400          ; PMG area size: 1 KB for double-line resolution
pmg             = map_area-pmg_len  ; Player/Missile graphics, right below the map area ($7C00)

ZP_SRC          = $CB           ; source pointer (zero page, $CB-$CC)
ZP_SRC_LEN      = 2             ; 16-bit pointer, never grows; add a new ZP_* name for more ZP space
ZP_DST          = $CD           ; destination pointer (zero page, $CD-$CE)
ZP_DST_LEN      = 2
ZP_TMP          = $CF           ; scratch byte (scroll step)
ZP_TMP_LEN      = 1

stick_up        = %0001
stick_down      = %0010
stick_left      = %0100
stick_right     = %1000

key_w           = $2E           ; KBCODE values (without SHIFT/CTRL bits)
key_s           = $3E
key_a           = $3F
key_d           = $3A

start
    jsr setup_screen
    jsr setup_colors
;    jsr load_gfx
    MVA #>charset CHBAS         ; Set character set base address
    jsr clear_pmg
    jsr setup_pmg
    jsr display_map
    jsr set_player_x
    jsr draw_player

; Controls: joystick or W/A/S/D (held = keeps moving); one direction per step, no diagonals
game_loop
    lda #1
    jsr delay                   ; 1 frames between steps
    jsr read_input              ; A = direction bits, 0 = pressed (like STICK0)
    sta input
    and #stick_up
    beq go_up
    lda input
    and #stick_down
    beq go_down
    lda input
    and #stick_left
    beq go_left
    lda input
    and #stick_right
    beq go_right
    jmp game_loop               ; nothing pressed

go_up
    jsr player_up
    jmp game_loop
go_down
    jsr player_down
    jmp game_loop
go_left
    jsr player_left
    jmp game_loop
go_right
    jsr player_right
    jmp game_loop

input
    .BYTE 0                     ; last read_input result

; Function: read_input
; Description: Joystick 0 or a held W/A/S/D key, in STICK0 format
; INPUT: none
; OUTPUT: A = direction bits like STICK0 (bit 0 up, 1 down, 2 left, 3 right; 0 = pressed)
; DESTROYED: A, X
    .LOCAL
read_input
    lda SKSTAT
    and #%00000100              ; bit 2 = 0 while a key is held
    bne ?stick                  ; no key: use the joystick
    lda KBCODE
    and #%00111111              ; ignore SHIFT/CTRL
    ldx #3
?find
    cmp ?keys,x
    beq ?key
    dex
    bpl ?find
?stick
    lda STICK0                  ; no (known) key: joystick
    rts
?key
    lda ?masks,x
    rts
?keys
    .BYTE key_w, key_s, key_a, key_d
?masks
    .BYTE %1110, %1101, %1011, %0111    ; up, down, left, right

scroll_x
    .BYTE 0                     ; first visible map column (tiles)

; Function: scroll_rd
; Description: Scroll the view right/down by moving every LMS address in the display list forward
; INPUT: A = step in bytes (2 = one tile right, canvas_w = one row down)
; OUTPUT: none
; DESTROYED: A, X, Y, ZP_TMP
    .LOCAL
scroll_rd
    sta ZP_TMP
    ldy #map_h                  ; 12 mode lines
    ldx #4                      ; dlist+4 = first LMS address (after 3x blank8 and the mode byte)
?loop
    clc
    lda dlist,x
    adc ZP_TMP
    sta dlist,x
    inx
    lda dlist,x
    adc #0
    sta dlist,x
    inx
    inx                         ; next mode line (3 bytes each)
    dey
    bne ?loop
    rts

; Function: scroll_lu
; Description: Scroll the view left/up by moving every LMS address in the display list back
; INPUT: A = step in bytes (2 = one tile left, canvas_w = one row up)
; OUTPUT: none
; DESTROYED: A, X, Y, ZP_TMP
    .LOCAL
scroll_lu
    sta ZP_TMP
    ldy #map_h
    ldx #4
?loop
    sec
    lda dlist,x
    sbc ZP_TMP
    sta dlist,x
    inx
    lda dlist,x
    sbc #0
    sta dlist,x
    inx
    inx
    dey
    bne ?loop
    rts

; Function: display_map
; Description: Expand the whole tile map onto the canvas (canvas row = map row)
; INPUT: none (reads map_area, writes canvas)
; OUTPUT: none
; DESTROYED: A, X, Y, ZP_SRC, ZP_DST
    .LOCAL
display_map
    MWA map_area ZP_SRC        ; source: tile map
    MWA canvas ZP_DST          ; destination: canvas memory
    MVA #map_h ?rows
?row
    ldx #map_w                 ; X = tiles left in this row
?tile
    ldy #0
    lda (ZP_SRC),y             ; A = tile ID
    jsr draw_tile              ; draw it, ZP_DST += 2
    ADW ZP_SRC #1              ; next tile
    dex
    bne ?tile
    dec ?rows
    bne ?row
    rts
?rows
    .BYTE 0

.IF canvas_w*map_h > canvas_len
    .ERROR "Map bigger than canvas memory"
.ENDIF

.INCLUDE "hw.asm"
.INCLUDE "tools.asm"
.INCLUDE "dlist.asm"
.INCLUDE "colors.asm"
.INCLUDE "tiles.asm"
.INCLUDE "player.asm"

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