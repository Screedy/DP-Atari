; =====================================================================================
; player.asm - the walking player: position, movement limits, collision, drawing
; =====================================================================================
;
; The player is drawn with Player/Missile Graphics: all 4 players are placed on top of
; each other, each one adds one colour (hair, skin, clothes, boots). See docs/player_movement.md
; for the full explanation of how and why the movement works this way.
;
; Geometry (ANTIC mode 5, wide playfield, double-line PMG resolution):
;   1 tile     = 2 chars = 8 color clocks = exactly one player width
;                -> screen column c (0..view_w-1) is at HPOS 32 + 8*c
;                   (the outermost column on each side is partly hidden by the TV overscan)
;   1 char row = 16 scanlines = 8 PMG lines = exactly the sprite height
;                -> screen row r (0..11) starts at PMG line 16 + 8*r
;
; Player position:
;   horizontal: player_col = screen column in tiles; map column = scroll_x + player_col
;   vertical:   player_y   = PMG line of the top of the sprite (moves in step_y lines)

; -------------------------------------------------------------------------------------
; Settings (assembly-time constants)
; -------------------------------------------------------------------------------------

pmg_row0        = 16            ; PMG line of screen row 0 (3x blank8 -> scanline 32 -> /2)
                                ; calibration knob: if the sprite is a few lines off, tweak this
hpos_col0       = 32            ; HPOS of screen column 0 (left edge of the wide playfield)
edge_tiles      = 1             ; tiles per side partly hidden in the TV overscan: the player
                                ;   doesn't walk onto them
scroll_margin   = 6             ; while the map can scroll, keep the player this many tiles from the edge
step_y          = 2             ; PMG lines per vertical step
feet_lines      = 2             ; sprite lines that must stand on the walkable rows (legs + boots);
                                ; the rest of the sprite may overlap the row above (e.g. the wall)
walk_y_min      = pmg_row0+walk_row_top*8-[8-feet_lines]  ; highest sprite top: only the feet on the top row
walk_y_max      = pmg_row0+walk_row_bottom*8    ; sprite top on the lowest walkable row

; -------------------------------------------------------------------------------------
; Build-time checks (stop the build if the settings above don't fit together)
; -------------------------------------------------------------------------------------

; walk_y_min..walk_y_max must be a whole number of steps, otherwise the player would
; step over the limit and the exact "beq" checks in player_up/down would never match
.IF [walk_y_max-walk_y_min]-[walk_y_max-walk_y_min]/step_y*step_y
    .ERROR "walk range must be a multiple of step_y"
.ENDIF
; the feet must never stand on two map rows at once (collision checks one row only)
.IF [8-feet_lines]-[8-feet_lines]/step_y*step_y
    .ERROR "feet must stay inside one map row: 8-feet_lines must be a multiple of step_y"
.ENDIF
; look_around reads the tile below with Y = 2*map_w, and Y is only one byte
.IF map_w*2 > 255
    .ERROR "look_around reads the row below with Y = 2*map_w: maps up to 127 tiles wide"
.ENDIF

; -------------------------------------------------------------------------------------
; Variables (1 byte each; the .BYTE value is the start value)
; -------------------------------------------------------------------------------------

player_col
    .BYTE view_w/2              ; screen column 0..view_w-1 (starts in the middle)
player_y
    .BYTE walk_y_min            ; PMG line of the sprite top (starts on the top walkable row)

; Tiles around the player's feet, refreshed by look_around (tile IDs, see tiles.asm)
up_tile
    .BYTE 0                     ; tile above the feet
down_tile
    .BYTE 0                     ; tile below the feet
left_tile
    .BYTE 0                     ; tile left of the feet
right_tile
    .BYTE 0                     ; tile right of the feet
on_tile
    .BYTE 0                     ; the tile the player stands on (for doors, exits, ... later)
feet_off
    .BYTE 0                     ; feet position inside their map row: 0 = top .. 8-feet_lines = bottom

; -------------------------------------------------------------------------------------
; Function: player_left
; Description: Move the player one tile to the left. Near the left screen edge the map
;              scrolls instead (if it can); at the left end of the map he walks to the edge.
; INPUT: none (left_tile, player_col, scroll_x)
; OUTPUT: none (player_col or scroll_x changed)
; DESTROYED: A, X, Y, ZP_TMP
; -------------------------------------------------------------------------------------
    .LOCAL
player_left
    lda left_tile               ; A = tile on the left of the feet
    jsr is_solid                ; is it a wall/table?
    bne ?done                   ; yes: don't move (neither walk nor scroll)
    lda player_col              ; A = screen column of the player
    cmp #scroll_margin+1        ; carry set if player_col > scroll_margin
    bcs ?walk                   ; far enough from the edge: just walk
    lda scroll_x                ; near the edge: can the map still scroll left?
    beq ?walk                   ; no, map already at its left end: walk to the edge
    dec scroll_x                ; yes: the view starts one map column earlier
    lda #2                      ; 1 tile = 2 chars
    jmp scroll_lu               ; move the display list 2 chars left (its rts returns to our caller)
?walk
    lda player_col              ; A = screen column
    cmp #edge_tiles             ; first fully visible column
    beq ?done                   ; already there: nowhere to go
    dec player_col              ; one column to the left
    jmp set_player_x            ; move the sprite there (its rts returns to our caller)
?done
    rts

; -------------------------------------------------------------------------------------
; Function: player_right
; Description: Mirror of player_left: move one tile right, scroll near the right edge,
;              walk to the edge at the right end of the map.
; INPUT: none (right_tile, player_col, scroll_x)
; OUTPUT: none (player_col or scroll_x changed)
; DESTROYED: A, X, Y, ZP_TMP
; -------------------------------------------------------------------------------------
    .LOCAL
player_right
    lda right_tile              ; A = tile on the right of the feet
    jsr is_solid                ; is it a wall/table?
    bne ?done                   ; yes: don't move (neither walk nor scroll)
    lda player_col              ; A = screen column of the player
    cmp #view_w-1-scroll_margin ; carry clear if player_col is more than scroll_margin from the right edge
    bcc ?walk                   ; far enough from the edge: just walk
    lda scroll_x                ; near the edge: can the map still scroll right?
    cmp #map_w-view_w           ; last possible scroll position (right end of the map on screen)
    beq ?walk                   ; no, map already at its right end: walk to the edge
    inc scroll_x                ; yes: the view starts one map column later
    lda #2                      ; 1 tile = 2 chars
    jmp scroll_rd               ; move the display list 2 chars right (its rts returns to our caller)
?walk
    lda player_col              ; A = screen column
    cmp #view_w-1-edge_tiles    ; last fully visible column
    beq ?done                   ; already there: nowhere to go
    inc player_col              ; one column to the right
    jmp set_player_x            ; move the sprite there (its rts returns to our caller)
?done
    rts

; -------------------------------------------------------------------------------------
; Function: player_up
; Description: Move the sprite step_y PMG lines up, but not above walk_y_min. A step that
;              would move the feet into the row above is refused if that row's tile is solid.
; INPUT: none (player_y, feet_off, up_tile)
; OUTPUT: none (player_y changed, sprite redrawn)
; DESTROYED: A, X, Y
; -------------------------------------------------------------------------------------
    .LOCAL
player_up
    lda player_y                ; A = current sprite top
    cmp #walk_y_min             ; already at the highest allowed position?
    beq ?done                   ; yes: stop
    lda feet_off                ; where are the feet inside their row?
    bne ?move                   ; not at the top of the row: the step stays inside the row, always ok
    lda up_tile                 ; at the top: the step would enter the row above
    jsr is_solid                ; is that tile a wall/table?
    bne ?done                   ; yes: stop
?move
    lda player_y                ; A = sprite top
    sec                         ; set carry = plain subtraction (no borrow)
    sbc #step_y                 ; A = sprite top - step_y
    sta player_y                ; store the new position
    jmp draw_player             ; redraw the sprite there (its rts returns to our caller)
?done
    rts

; -------------------------------------------------------------------------------------
; Function: player_down
; Description: Mirror of player_up: move step_y PMG lines down, but not below walk_y_max;
;              refused if the feet would enter a solid row below.
; INPUT: none (player_y, feet_off, down_tile)
; OUTPUT: none (player_y changed, sprite redrawn)
; DESTROYED: A, X, Y
; -------------------------------------------------------------------------------------
    .LOCAL
player_down
    lda player_y                ; A = current sprite top
    cmp #walk_y_max             ; already at the lowest allowed position?
    beq ?done                   ; yes: stop
    lda feet_off                ; where are the feet inside their row?
    cmp #8-feet_lines           ; at the bottom of the row? (feet end on the row's last line)
    bne ?move                   ; no: the step stays inside the row, always ok
    lda down_tile               ; yes: the step would enter the row below
    jsr is_solid                ; is that tile a wall/table?
    bne ?done                   ; yes: stop
?move
    lda player_y                ; A = sprite top
    clc                         ; clear carry = plain addition
    adc #step_y                 ; A = sprite top + step_y
    sta player_y                ; store the new position
    jmp draw_player             ; redraw the sprite there (its rts returns to our caller)
?done
    rts

; -------------------------------------------------------------------------------------
; Function: look_around
; Description: Read the tiles around the player's feet into up/down/left/right/on_tile
;              The feet decide where the player stands, because the rest of the sprite 
;              may overlap the row above. All 5 tiles are read from one pointer (the 
;              tile above the player) using different Y offsets:
;                                   Y=0 (up)
;                Y=map_w-1 (left)  Y=map_w (on)  Y=map_w+1 (right)
;                                Y=2*map_w (down)
; INPUT: none (player_y, player_col, scroll_x)
; OUTPUT: up_tile, down_tile, left_tile, right_tile, on_tile, feet_off
; DESTROYED: A, X, Y, ZP_SRC, ZP_TMP
; -------------------------------------------------------------------------------------
    .LOCAL
look_around
    ; --- which map row are the feet in, and where inside it? ---
    lda player_y                ; A = sprite top (PMG line)
    sec                         ; plain subtraction
    sbc #pmg_row0-[8-feet_lines] ; A = PMG line of the feet top, counted from screen row 0
    sta ZP_TMP                  ; keep it, we need it twice
    and #7                      ; lowest 3 bits = line inside the row (row = 8 PMG lines)
    sta feet_off                ; 0 = feet at the top of the row
    lda ZP_TMP                  ; A = feet line again
    lsr                         ; /2
    lsr                         ; /4
    lsr                         ; /8 -> A = map row of the feet
    tax                         ; X = map row (loop counter below)

    ; --- ZP_SRC = map_area + (row-1)*map_w = start of the row above the feet ---
    MWA [map_area-map_w] ZP_SRC ; start one row before the map (row -1)
    cpx #0                      ; feet in row 0?
    beq ?col                    ; yes: no rows to add
?row
    ADW ZP_SRC #map_w           ; one map row further
    dex                         ; one row less to go
    bne ?row                    ; until X rows are added

    ; --- + map column of the player ---
?col
    lda scroll_x                ; first map column on the screen
    clc                         ; plain addition
    adc player_col              ; + screen column = map column of the player
    sta ZP_TMP                  ; ADW needs the value in memory
    ADW ZP_SRC ZP_TMP           ; ZP_SRC now points at the tile above the player

    ; --- read the 5 tiles ---
    ldy #0                      ; offset 0: the tile above
    lda (ZP_SRC),y              ; A = tile ID
    sta up_tile
    ldy #map_w-1                ; one row further, one column left
    lda (ZP_SRC),y
    sta left_tile
    iny                         ; one column right: the tile under the feet
    lda (ZP_SRC),y
    sta on_tile
    iny                         ; one more column right
    lda (ZP_SRC),y
    sta right_tile
    ldy #map_w*2                ; two rows further: the tile below
    lda (ZP_SRC),y
    sta down_tile
    rts

; -------------------------------------------------------------------------------------
; Function: is_solid
; Description: Is this tile a wall/obstacle? (looks up tile_flags in tiles.asm)
; INPUT: A = tile ID
; OUTPUT: Z flag: bne = solid, beq = walkable
; DESTROYED: A, X
; -------------------------------------------------------------------------------------
is_solid
    tax                         ; X = tile ID (index into the table)
    lda tile_flags,x            ; A = flags of that tile
    and #TILE_SOLID             ; keep only the "solid" bit -> sets/clears the Z flag
    rts

; -------------------------------------------------------------------------------------
; Function: set_player_x
; Description: Put all 4 players at screen column player_col
;              (HPOS = hpos_col0 + player_col * 8; even the last screen column fits in a byte)
; INPUT: none (player_col)
; OUTPUT: none (HPOSP0-3 set)
; DESTROYED: A
; -------------------------------------------------------------------------------------
set_player_x
    lda player_col              ; A = screen column (0..view_w-1)
    asl                         ; *2
    asl                         ; *4
    asl                         ; *8 color clocks per tile
    clc                         ; plain addition
    adc #hpos_col0              ; + left edge of the playfield
    sta HPOSP0                  ; all 4 layers of the sprite move together
    sta HPOSP1
    sta HPOSP2
    sta HPOSP3
    rts

; -------------------------------------------------------------------------------------
; Function: draw_player
; Description: Clear the player memory and draw the 4 player layers (pmgdata) at player_y.
;              PMG has no vertical position register: moving up/down means drawing the
;              sprite at a different place in player memory.
; INPUT: none (player_y)
; OUTPUT: none (PMG memory updated)
; DESTROYED: A, X, Y
; -------------------------------------------------------------------------------------
    .LOCAL
draw_player
    jsr clear_pmg               ; clear the old sprite (all 4 players)
    ldy player_y                ; Y = where to draw the sprite (top PMG line)
    ldx #0                      ; X = which line of pmgdata to read (0..7)
?loop
    lda pmgdata,x               ; layer 0 (hair), line X
    sta pmg_p0,y                ; -> player 0 memory, line Y
    lda pmgdata+8,x             ; layer 1 (skin), line X
    sta pmg_p1,y                ; -> player 1 memory
    lda pmgdata+16,x            ; layer 2 (clothes), line X
    sta pmg_p2,y                ; -> player 2 memory
    lda pmgdata+24,x            ; layer 3 (boots), line X
    sta pmg_p3,y                ; -> player 3 memory
    iny                         ; next line in player memory
    inx                         ; next line of the sprite data
    cpx #8                      ; all 8 lines done?
    bne ?loop                   ; no: continue
    rts
