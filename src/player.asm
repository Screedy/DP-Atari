; player.asm - the walking player: position, movement limits, drawing
;
; Geometry (ANTIC 5, normal playfield, double-line PMG):
;   1 tile = 2 chars = 8 color clocks = one player width   -> screen column c is at HPOS 48+8*c
;   1 char row = 16 scanlines = 8 PMG lines = sprite height -> screen row r starts at PMG line 16+8*r

pmg_row0        = 16            ; PMG line of screen row 0 (3x blank8 -> scanline 32 -> /2)
                                ; calibration knob: if the sprite is a few lines off, tweak this
hpos_col0       = 48            ; HPOS of screen column 0 (left edge of the normal playfield)
scroll_margin   = 6             ; while the map can scroll, keep the player this many tiles from the edge
step_y          = 2             ; PMG lines per vertical step
feet_lines      = 2             ; sprite lines that must stand on the walkable rows (legs + boots);
                                ; the rest of the sprite may overlap the row above (e.g. the wall)
walk_y_min      = pmg_row0+walk_row_top*8-[8-feet_lines]  ; highest sprite top: only the feet on the top row
walk_y_max      = pmg_row0+walk_row_bottom*8    ; sprite top on the lowest walkable row

.IF [walk_y_max-walk_y_min]-[walk_y_max-walk_y_min]/step_y*step_y
    .ERROR "walk range must be a multiple of step_y"
.ENDIF
.IF [8-feet_lines]-[8-feet_lines]/step_y*step_y
    .ERROR "feet must stay inside one map row: 8-feet_lines must be a multiple of step_y"
.ENDIF
.IF map_w*2 > 255
    .ERROR "look_around reads the row below with Y = 2*map_w: maps up to 127 tiles wide"
.ENDIF

player_col
    .BYTE view_w/2              ; screen column 0..view_w-1
player_y
    .BYTE walk_y_min            ; PMG line of the sprite top

; Tiles around the player's feet, refreshed by look_around (tile IDs, see tiles.asm)
up_tile
    .BYTE 0
down_tile
    .BYTE 0
left_tile
    .BYTE 0
right_tile
    .BYTE 0
on_tile
    .BYTE 0                     ; the tile the player stands on (for doors, exits, ... later)
feet_off
    .BYTE 0                     ; feet position inside their map row: 0 = top .. 8-feet_lines = bottom

; Function: player_left / player_right
; Description: Walk one tile; near the screen edge scroll the map instead (if the map can scroll)
; INPUT: none
; OUTPUT: none
; DESTROYED: A, X, Y, ZP_TMP
    .LOCAL
player_left
    lda left_tile
    jsr is_solid
    bne ?done                   ; wall/table on the left: don't move (neither walk nor scroll)
    lda player_col
    cmp #scroll_margin+1
    bcs ?walk                   ; far enough from the edge: just walk
    lda scroll_x
    beq ?walk                   ; map already at its left end: walk to the edge
    dec scroll_x
    lda #2                      ; 1 tile = 2 chars
    jmp scroll_lu
?walk
    lda player_col
    beq ?done                   ; at screen column 0
    dec player_col
    jmp set_player_x
?done
    rts

    .LOCAL
player_right
    lda right_tile
    jsr is_solid
    bne ?done                   ; wall/table on the right: don't move (neither walk nor scroll)
    lda player_col
    cmp #view_w-1-scroll_margin
    bcc ?walk                   ; far enough from the edge: just walk
    lda scroll_x
    cmp #map_w-view_w
    beq ?walk                   ; map already at its right end: walk to the edge
    inc scroll_x
    lda #2
    jmp scroll_rd
?walk
    lda player_col
    cmp #view_w-1
    beq ?done                   ; at the last screen column
    inc player_col
    jmp set_player_x
?done
    rts

; Function: player_up / player_down
; Description: Move step_y PMG lines, staying inside walk_y_min..walk_y_max; a step that would
;              move the feet into the next map row is refused if that row's tile is solid
; INPUT: none
; OUTPUT: none
; DESTROYED: A, X, Y
    .LOCAL
player_up
    lda player_y
    cmp #walk_y_min
    beq ?done                   ; already on the top walkable row
    lda feet_off
    bne ?move                   ; feet not at the top of their row: the step stays inside the row
    lda up_tile
    jsr is_solid
    bne ?done                   ; the row above is solid
?move
    lda player_y
    sec
    sbc #step_y
    sta player_y
    jmp draw_player
?done
    rts

    .LOCAL
player_down
    lda player_y
    cmp #walk_y_max
    beq ?done                   ; already on the bottom walkable row
    lda feet_off
    cmp #8-feet_lines
    bne ?move                   ; feet not at the bottom of their row: the step stays inside the row
    lda down_tile
    jsr is_solid
    bne ?done                   ; the row below is solid
?move
    lda player_y
    clc
    adc #step_y
    sta player_y
    jmp draw_player
?done
    rts

; Function: look_around
; Description: Read the tiles around the player's feet into up/down/left/right/on_tile
;              (the EdVenture ep. 13 idea). The feet decide where the player stands, because
;              the rest of the sprite may overlap the row above.
; INPUT: none (player_y, player_col, scroll_x)
; OUTPUT: up_tile, down_tile, left_tile, right_tile, on_tile, feet_off
; DESTROYED: A, X, Y, ZP_SRC, ZP_TMP
    .LOCAL
look_around
    lda player_y
    sec
    sbc #pmg_row0-[8-feet_lines] ; A = PMG line of the feet top, counted from screen row 0
    sta ZP_TMP
    and #7
    sta feet_off                ; position inside the row
    lda ZP_TMP
    lsr
    lsr
    lsr
    tax                         ; X = map row of the feet
    MWA [map_area-map_w] ZP_SRC ; ZP_SRC = start of the row above the feet:
    cpx #0                      ;   map_area + (row-1)*map_w
    beq ?col
?row
    ADW ZP_SRC #map_w
    dex
    bne ?row
?col
    lda scroll_x                ; + map column of the player
    clc
    adc player_col
    sta ZP_TMP
    ADW ZP_SRC ZP_TMP
    ldy #0                      ; ZP_SRC points at the tile above the player
    lda (ZP_SRC),y
    sta up_tile
    ldy #map_w-1                ; one row further, one column left
    lda (ZP_SRC),y
    sta left_tile
    iny
    lda (ZP_SRC),y
    sta on_tile
    iny
    lda (ZP_SRC),y
    sta right_tile
    ldy #map_w*2                ; two rows further: below the player
    lda (ZP_SRC),y
    sta down_tile
    rts

; Function: is_solid
; Description: Is this tile a wall/obstacle?
; INPUT: A = tile ID
; OUTPUT: Z flag: bne = solid, beq = walkable
; DESTROYED: A, X
is_solid
    tax
    lda tile_flags,x
    and #TILE_SOLID
    rts

; Function: set_player_x
; Description: Put all 4 players at screen column player_col
; INPUT: none
; OUTPUT: none
; DESTROYED: A
set_player_x
    lda player_col
    asl                         ; *2
    asl                         ; *4
    asl                         ; *8
    clc
    adc #hpos_col0
    sta HPOSP0
    sta HPOSP1
    sta HPOSP2
    sta HPOSP3
    rts

; Function: draw_player
; Description: Clear the player memory and draw the 4 player layers (pmgdata) at player_y
; INPUT: none
; OUTPUT: none
; DESTROYED: A, X, Y
    .LOCAL
draw_player
    jsr clear_pmg               ; clear old player sprite
    ldy player_y                ; Y = where to draw the sprite (top PMG line)
    ldx #0                      ; X = which line of pmgdata to read (0..7)
?loop
    lda pmgdata,x               ; layer 0 (hair)
    sta pmg_p0,y
    lda pmgdata+8,x             ; layer 1 (skin)
    sta pmg_p1,y
    lda pmgdata+16,x            ; layer 2 (clothes)
    sta pmg_p2,y
    lda pmgdata+24,x            ; layer 3 (boots)
    sta pmg_p3,y
    iny
    inx
    cpx #8
    bne ?loop
    rts
