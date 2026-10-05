; tiles.asm - map tiles: 1 tile = 2 characters side by side

; Tile IDs (index into tile_left / tile_right)
EMP = 0         ; 0,0       blank
BRA = 1         ; 5,6       brick A
BRB = 2         ; 7,8       brick B
BRC = 3         ; 9,10      brick C
WNL = 4         ; 2,3       window, left half
WNR = 5         ; 3,4       window, right half
LWL = 6         ; 130,131   lit window, left half (inverse = 5th color)
LWR = 7         ; 131,132   lit window, right half
FLW = 8         ; 11,12     bottom window row

; Characters for each tile: left char, right char
tile_left
    .BYTE 0, 5, 7, 9, 2, 3, 130, 131, 11
tile_right
    .BYTE 0, 6, 8, 10, 3, 4, 131, 132, 12
