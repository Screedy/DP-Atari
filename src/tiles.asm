; =====================================================================================
; tiles.asm - map tiles: IDs, the characters they are drawn with, their properties
; =====================================================================================
;
; A map (maps/*.asm) is a grid of tile IDs, one byte per tile. A tile is 2 characters
; side by side (2 chars wide, 1 char row tall), so one tile is exactly as wide as the
; player sprite. display_map (main.asm) turns every tile ID into its 2 characters with
; draw_tile below.
;
; The tables below are indexed by the tile ID, so all of them must list the tiles in
; the same order as the IDs.
;
; How to add a new tile:
;   1. give it the next free ID below (3-letter name, so map rows stay readable)
;   2. add its left character to tile_left and its right character to tile_right
;   3. add its properties to tile_flags (0 = walkable, TILE_SOLID = blocks the player)
;   4. use the name in a map file
;   The build checks at the end of the tables stop the build if one table is too short.
;
; Character codes: in ANTIC mode 5 a character code + 128 (inverse) draws the
; character's "11" pixels in COLOR3 instead of COLOR2: the 5th colour on screen.

; -------------------------------------------------------------------------------------
; Tile IDs (index into tile_left / tile_right / tile_flags)
; -------------------------------------------------------------------------------------
;               chars       what it is
EMP = 0         ; 0,0       blank
BRA = 1         ; 5,6       brick A
BRB = 2         ; 7,8       brick B
BRC = 3         ; 9,10      brick C
WNL = 4         ; 2,3       window, left half
WNR = 5         ; 3,4       window, right half
LWL = 6         ; 130,131   lit window, left half (inverse = 5th color)
LWR = 7         ; 131,132   lit window, right half
FLW = 8         ; 11,12     bottom window row

; -------------------------------------------------------------------------------------
; Characters for each tile: left char, right char
; -------------------------------------------------------------------------------------
;             EMP  BRA  BRB  BRC  WNL  WNR  LWL  LWR  FLW
tile_left
    .BYTE     0,   5,   7,   9,   2,   3,   130, 131, 11
tile_right
    .BYTE     0,   6,   8,  10,   3,   4,   131, 132, 12

; -------------------------------------------------------------------------------------
; Properties of each tile (bit flags), same order as the tile IDs
; Free bits can later mark e.g. doors or room exits (read through on_tile, player.asm).
; -------------------------------------------------------------------------------------
TILE_SOLID = %00000001          ; the player cannot stand on this tile (wall, table, ...)
tile_flags
    .BYTE 0                                     ; EMP
    .BYTE TILE_SOLID, TILE_SOLID, TILE_SOLID    ; BRA, BRB, BRC
    .BYTE TILE_SOLID, TILE_SOLID                ; WNL, WNR
    .BYTE TILE_SOLID, TILE_SOLID                ; LWL, LWR
    .BYTE TILE_SOLID                            ; FLW
tile_flags_end

; build checks: every table must have one entry per tile
; (tile_flags follows tile_right directly, so tile_flags - tile_right = length of tile_right)
.IF [tile_right-tile_left]-[tile_flags-tile_right]
    .ERROR "tile_right needs one entry per tile (same as tile_left)"
.ENDIF
.IF [tile_right-tile_left]-[tile_flags_end-tile_flags]
    .ERROR "tile_flags needs one entry per tile"
.ENDIF

; -------------------------------------------------------------------------------------
; Function: draw_tile
; Description: Write one tile (2 chars) to the screen and move to the next position
; INPUT: A = tile ID, ZP_DST = screen position
; OUTPUT: ZP_DST += 2 (points right after the tile)
; DESTROYED: A, Y
; -------------------------------------------------------------------------------------
draw_tile
    tay                 ; Y = tile ID (index into the tables)
    lda tile_right,y    ; A = right character
    pha                 ; keep right char (Y is needed for the stores below)
    lda tile_left,y     ; A = left character
    ldy #0              ; (ZP),Y needs Y: offset 0 = first char position
    sta (ZP_DST),y      ; left char
    pla                 ; A = right char again
    iny                 ; offset 1 = next char position
    sta (ZP_DST),y      ; right char
    ADW ZP_DST #2       ; move the screen pointer past the tile
    rts
