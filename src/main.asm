; =====================================================================================
; main.asm - main program: memory layout, start-up, game loop, input, scrolling
; =====================================================================================
;
; This is the file that gets assembled; all other files are pulled in with .INCLUDE.
;
; NAME_LEN equates (e.g. canvas_len, ZP_SRC_LEN) tell tools/memmap.py how big an area
; is, so it can reserve it and warn when something else is loaded on top of it.

.INCLUDE "macros.asm"           ; macros first: they must be defined before they are used

    * = $2000                   ; code starts here (above DOS, which ends below $2000)

; -------------------------------------------------------------------------------------
; Memory areas and room settings
; -------------------------------------------------------------------------------------

charset         = $5000         ; Charset memory start address
canvas          = $4000         ; Canvas memory start address
map_area        = $8000         ; Current room's tile map is loaded/copied here (outside the
                                ; 130XE bank window $4000-$7FFF, so maps can come from banks)
map_area_len    = $2000         ; 8 KB reserved for maps; the biggest room must fit
map_w           = 80            ; tiles per map row (current room)
map_h           = 12            ; map rows (current room)
walk_row_top    = 9             ; walkable map rows (current room): grass, sidewalk
walk_row_bottom = 10
view_w          = 20            ; tiles visible on canvas (20 tiles = 40 chars)
view_h          = 12            ; rows visible = mode lines in dlist.asm (set by the screen, not the map)
canvas_w        = map_w*2       ; canvas bytes per row: the whole map row expanded (2 chars/tile)
canvas_len      = canvas_w*map_h ; one canvas row (canvas_w bytes) per map row; follows the map size.
                                ; The canvas must end before the charset, and no canvas row may
                                ; cross a 4 KB boundary (ANTIC's address counter wraps there)
pmg_len         = $400          ; PMG area size: 1 KB for double-line resolution
pmg             = map_area-pmg_len  ; Player/Missile graphics, right below the map area ($7C00)

; -------------------------------------------------------------------------------------
; Zero page variables (fast to access; (ZP),Y indirect addressing only works with them)
; -------------------------------------------------------------------------------------

ZP_SRC          = $CB           ; source pointer (zero page, $CB-$CC)
ZP_SRC_LEN      = 2             ; 16-bit pointer, never grows; add a new ZP_* name for more ZP space
ZP_DST          = $CD           ; destination pointer (zero page, $CD-$CE)
ZP_DST_LEN      = 2
ZP_TMP          = $CF           ; scratch byte (scroll step, look_around)
ZP_TMP_LEN      = 1

; -------------------------------------------------------------------------------------
; Input constants
; -------------------------------------------------------------------------------------

stick_up        = %0001         ; STICK0 bits: a 0 bit means "pushed in this direction"
stick_down      = %0010
stick_left      = %0100
stick_right     = %1000

key_w           = $2E           ; KBCODE values (without SHIFT/CTRL bits)
key_s           = $3E           ; (Atari keyboard codes, not ASCII)
key_a           = $3F
key_d           = $3A

; -------------------------------------------------------------------------------------
; Start-up: runs once (the .RUN at the end of this file jumps here after loading)
; -------------------------------------------------------------------------------------

start
    jsr setup_screen            ; switch to our display list (dlist.asm)
    jsr setup_colors            ; charset and player colours (colors.asm)
;    jsr load_gfx
    MVA #>charset CHBAS         ; Set character set base address (high byte; charset is page aligned)
    jsr clear_pmg               ; empty player/missile memory (pmg.asm)
    jsr setup_pmg               ; turn PMG on (pmg.asm)
    jsr display_map             ; expand the room's tile map onto the canvas
    jsr set_player_x            ; put the sprite at its start column (player.asm)
    jsr draw_player             ; draw the sprite at its start height (player.asm)

; -------------------------------------------------------------------------------------
; Game loop: runs forever, one step per pass
; Controls: joystick or W/A/S/D (held = keeps moving); one direction per step, no diagonals
; -------------------------------------------------------------------------------------

game_loop
    lda #1                      ; wait 1 frame: sets the speed and makes the following
    jsr delay                   ; changes happen right after a vertical blank (no tearing)
    jsr look_around             ; refresh up/down/left/right/on_tile before moving
    jsr read_input              ; A = direction bits, 0 = pressed (like STICK0)
    sta input                   ; keep it: every "and" below destroys A
    and #stick_up               ; up bit = 0?
    beq go_up                   ; yes: move up
    lda input
    and #stick_down             ; down bit = 0?
    beq go_down                 ; yes: move down
    lda input
    and #stick_left             ; left bit = 0?
    beq go_left                 ; yes: move left
    lda input
    and #stick_right            ; right bit = 0?
    beq go_right                ; yes: move right
    jmp game_loop               ; nothing pressed

go_up
    jsr player_up               ; one step up (player.asm)
    jmp game_loop
go_down
    jsr player_down             ; one step down
    jmp game_loop               
go_left
    jsr player_left             ; one tile left (or scroll)
    jmp game_loop
go_right
    jsr player_right            ; one tile right (or scroll)
    jmp game_loop

input
    .BYTE 0                     ; last read_input result

; -------------------------------------------------------------------------------------
; Function: read_input
; Description: Joystick 0 or a held W/A/S/D key, in STICK0 format, so the rest of the
;              program doesn't care where the input came from. The keyboard is read
;              from POKEY directly (not the OS buffer CH), so a held key keeps moving
;              without the auto-repeat pause.
; INPUT: none
; OUTPUT: A = direction bits like STICK0 (bit 0 up, 1 down, 2 left, 3 right; 0 = pressed)
; DESTROYED: A
; -------------------------------------------------------------------------------------
    .LOCAL
read_input
    lda SKSTAT                  ; POKEY keyboard status
    and #%00000100              ; bit 2 = 0 while a key is held
    bne ?stick                  ; no key: use the joystick
    lda KBCODE                  ; A = code of the held key
    and #%00111111              ; ignore SHIFT/CTRL
    cmp #key_w                  ; W?
    beq ?up
    cmp #key_s                  ; S?
    beq ?down
    cmp #key_a                  ; A?
    beq ?left
    cmp #key_d                  ; D?
    beq ?right
?stick
    lda STICK0                  ; no (known) key: joystick
    rts
?up
    lda #%1110                  ; what STICK0 reads when pushed up
    rts
?down
    lda #%1101                  ; ... down
    rts
?left
    lda #%1011                  ; ... left
    rts
?right
    lda #%0111                  ; ... right
    rts

scroll_x
    .BYTE 0                     ; first visible map column (tiles); 0..map_w-view_w

; -------------------------------------------------------------------------------------
; Function: scroll_rd
; Description: Scroll the view right/down by moving every LMS address in the display list
;              forward. Every mode line has its own LMS (dlist.asm): 3 bytes = mode byte,
;              address low, address high. No character data is copied.
; INPUT: A = step in bytes (2 = one tile right, canvas_w = one row down)
; OUTPUT: none
; DESTROYED: A, X, Y, ZP_TMP
; -------------------------------------------------------------------------------------
    .LOCAL
scroll_rd
    sta ZP_TMP                  ; keep the step, A is needed in the loop
    ldy #view_h                 ; one LMS address per mode line of the screen
    ldx #4                      ; dlist+4 = first LMS address (after 3x blank8 and the mode byte)
?loop
    clc                         ; plain addition
    lda dlist,x                 ; address low byte
    adc ZP_TMP                  ; + step
    sta dlist,x
    inx                         ; -> address high byte
    lda dlist,x
    adc #0                      ; + carry from the low byte
    sta dlist,x
    inx                         ; skip the next line's mode byte...
    inx                         ; next mode line (3 bytes each)
    dey                         ; one line less
    bne ?loop                   ; until every mode line is moved
    rts

; -------------------------------------------------------------------------------------
; Function: scroll_lu
; Description: Mirror of scroll_rd: scroll the view left/up by moving every LMS address back
; INPUT: A = step in bytes (2 = one tile left, canvas_w = one row up)
; OUTPUT: none
; DESTROYED: A, X, Y, ZP_TMP
; -------------------------------------------------------------------------------------
    .LOCAL
scroll_lu
    sta ZP_TMP                  ; keep the step
    ldy #view_h                 ; one LMS address per mode line of the screen
    ldx #4                      ; first LMS address
?loop
    sec                         ; plain subtraction (no borrow)
    lda dlist,x                 ; address low byte
    sbc ZP_TMP                  ; - step
    sta dlist,x
    inx                         ; -> address high byte
    lda dlist,x
    sbc #0                      ; - borrow from the low byte
    sta dlist,x
    inx                         ; skip the next line's mode byte...
    inx                         ; next mode line
    dey                         ; one line less
    bne ?loop
    rts

; -------------------------------------------------------------------------------------
; Function: display_map
; Description: Expand the whole tile map onto the canvas (canvas row = map row).
;              Done once per room; scrolling then only moves the display list.
; INPUT: none (reads map_area, writes canvas)
; OUTPUT: none
; DESTROYED: A, X, Y, ZP_SRC, ZP_DST
; -------------------------------------------------------------------------------------
    .LOCAL
display_map
    MWA map_area ZP_SRC        ; source: tile map
    MWA canvas ZP_DST          ; destination: canvas memory
    MVA #map_h ?rows           ; rows to draw (X is busy with the columns)
?row
    ldx #map_w                 ; X = tiles left in this row
?tile
    ldy #0                     ; (ZP),Y needs Y; 0 = the tile ZP_SRC points at
    lda (ZP_SRC),y             ; A = tile ID
    jsr draw_tile              ; draw it, ZP_DST += 2 (tiles.asm)
    ADW ZP_SRC #1              ; next tile
    dex                        ; one tile less in this row
    bne ?tile
    dec ?rows                  ; one row less
    bne ?row
    rts
?rows
    .BYTE 0                    ; row counter

; the canvas must hold the whole expanded map
.IF canvas_w*map_h > canvas_len
    .ERROR "Map bigger than canvas memory"
.ENDIF

; -------------------------------------------------------------------------------------
; Other code files (assembled right after this code, still below the charset)
; -------------------------------------------------------------------------------------

.INCLUDE "hw.asm"               ; hardware/OS register names (before tools.asm, which uses RTCLOK)
.INCLUDE "tools.asm"            ; delay, copy_mem, ATASCII conversion
.INCLUDE "dlist.asm"            ; display list and setup_screen
.INCLUDE "colors.asm"           ; setup_colors
.INCLUDE "tiles.asm"            ; tile IDs, tile tables, draw_tile
.INCLUDE "player.asm"           ; player movement, collision, drawing

; code must end before the charset, or it would be overwritten by it
.IF * > charset
    .ERROR "Charset memory overlap"
.ENDIF
.INCLUDE "gfx.asm"              ; charset data (sets * = charset itself)
.INCLUDE "pmg.asm"              ; PMG routines (assembled after the charset data)
.INCLUDE "pmgdata.asm"          ; the player sprite

; ----------- Map area -----------
    * = map_area                ; the room's tile map is loaded straight into the map area
.INCLUDE "maps/university_outside.asm"
.IF * - map_area > map_area_len
    .ERROR "Map bigger than the map area"
.ENDIF

; ----------- Run the program -----------
    .RUN start                  ; after loading, DOS jumps to start (writes RUNAD $02E0)
