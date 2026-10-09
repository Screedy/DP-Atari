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

player_col
    .BYTE view_w/2              ; screen column 0..view_w-1
player_y
    .BYTE walk_y_min            ; PMG line of the sprite top

; Function: player_left / player_right
; Description: Walk one tile; near the screen edge scroll the map instead (if the map can scroll)
; INPUT: none
; OUTPUT: none
; DESTROYED: A, X, Y, ZP_TMP
    .LOCAL
player_left
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
; Description: Move step_y PMG lines, staying inside walk_y_min..walk_y_max
; INPUT: none
; OUTPUT: none
; DESTROYED: A, X, Y
    .LOCAL
player_up
    lda player_y
    cmp #walk_y_min
    beq ?done                   ; already on the top walkable row
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
    clc
    adc #step_y
    sta player_y
    jmp draw_player
?done
    rts

; Function: set_player_x
; Description: Put all 4 players at screen column player_col
; INPUT: none
; OUTPUT: none
; DESTROYED: A
set_player_x
    lda player_col
    asl                         ; *8 color clocks per tile
    asl
    asl
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
    jsr clear_pmg
    ldy player_y
    ldx #0
?loop
    lda pmgdata,x
    sta pmg_p0,y
    lda pmgdata+8,x
    sta pmg_p1,y
    lda pmgdata+16,x
    sta pmg_p2,y
    lda pmgdata+24,x
    sta pmg_p3,y
    iny
    inx
    cpx #8
    bne ?loop
    rts
