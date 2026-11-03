; =====================================================================================
; gfx.asm - the character set (charset): the graphics of all tiles
; =====================================================================================
;
; Assembled straight to the charset address, so nothing has to be copied at start-up;
; main.asm sets CHBAS = >charset to make ANTIC use it.
;
; Format (ANTIC mode 5): 1 character = 8 bytes = 8 rows, top to bottom.
; Every byte is one row of 4 pixels, 2 bits per pixel (left pixel = the 2 highest bits).
; Every row is shown 2 scanlines tall in mode 5, so a character is 4 pixels x 16 scanlines.
; The 2 bits pick the colour register (see the palette in colors.asm):
;   00 = COLOR4 (background)   01 = COLOR0   10 = COLOR1   11 = COLOR2
;   (11 = COLOR3 instead when the character is used inverse: code + 128)
; The comment after every row shows its 4 pixel values (0-3) from left to right.
;
; [n/n+128] after a character's name = its code normal / inverse. Characters are
; numbered in the order they are defined here (8 bytes each). The tiles that use
; them are listed in tiles.asm (tile_left / tile_right).

    * = charset                 ; data starts at the charset address (main.asm)

; ANTIC needs a mode-5 charset (128 chars x 8 bytes = 1 KB) to start on a 1 KB boundary
.IF charset & $3FF
    .ERROR "charset must be 1 KB aligned"
.ENDIF

; Blank tile [0/128], [1/129]                 used by: EMP
    .byte $00, $00, $00, $00, $00, $00, $00, $00   ; char 0: all pixels 0 (background)
    .byte $00, $00, $00, $00, $00, $00, $00, $00   ; char 1: all pixels 0 (background)

; Window tile left [2/130]                    used by: WNL (left), LWL (left, inverse)
    .byte %01011001            ; 1 1 2 1
    .byte %01110111            ; 1 3 1 3
    .byte %01110111            ; 1 3 1 3
    .byte %01110111            ; 1 3 1 3
    .byte %01110111            ; 1 3 1 3
    .byte %01110111            ; 1 3 1 3
    .byte %01110111            ; 1 3 1 3
    .byte %01011001            ; 1 1 2 1

; Window tile center [3/131]                  used by: WNL (right), WNR (left), LWL/LWR (inverse)
    .byte %01010101            ; 1 1 1 1
    .byte %11111111            ; 3 3 3 3
    .byte %11111111            ; 3 3 3 3
    .byte %11111111            ; 3 3 3 3
    .byte %11111111            ; 3 3 3 3
    .byte %11111111            ; 3 3 3 3
    .byte %11111111            ; 3 3 3 3
    .byte %01010101            ; 1 1 1 1

; Window tile right [4/132]                   used by: WNR (right), LWR (right, inverse)
    .byte %01100101            ; 1 2 1 1
    .byte %11011101            ; 3 1 3 1
    .byte %11011101            ; 3 1 3 1
    .byte %11011101            ; 3 1 3 1
    .byte %11011101            ; 3 1 3 1
    .byte %11011101            ; 3 1 3 1
    .byte %11011101            ; 3 1 3 1
    .byte %01100101            ; 1 2 1 1

; Brick A_left [5/133]                        used by: BRA (left)
    .byte %01010110            ; 1 1 1 2
    .byte %01010101            ; 1 1 1 1
    .byte %01101010            ; 1 2 2 2
    .byte %01101010            ; 1 2 2 2
    .byte %01101010            ; 1 2 2 2
    .byte %01010101            ; 1 1 1 1
    .byte %01010110            ; 1 1 1 2
    .byte %01010110            ; 1 1 1 2

; Brick A_right [6/134]                       used by: BRA (right)
    .byte %10101010            ; 2 2 2 2
    .byte %01010101            ; 1 1 1 1
    .byte %10100101            ; 2 2 1 1
    .byte %10100101            ; 2 2 1 1
    .byte %10100101            ; 2 2 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %10101010            ; 2 2 2 2
    .byte %10101010            ; 2 2 2 2

; Brick B_left [7/135]                        used by: BRB (left)
    .byte %10100110            ; 2 2 1 2
    .byte %01010101            ; 1 1 1 1
    .byte %10101010            ; 2 2 2 2
    .byte %10101010            ; 2 2 2 2
    .byte %10101010            ; 2 2 2 2
    .byte %01010101            ; 1 1 1 1
    .byte %10100110            ; 2 2 1 2
    .byte %10100110            ; 2 2 1 2

; Brick B_right [8/136]                       used by: BRB (right)
    .byte %10101010            ; 2 2 2 2
    .byte %01010101            ; 1 1 1 1
    .byte %10011010            ; 2 1 2 2
    .byte %10011010            ; 2 1 2 2
    .byte %10011010            ; 2 1 2 2
    .byte %01010101            ; 1 1 1 1
    .byte %10101010            ; 2 2 2 2
    .byte %10101010            ; 2 2 2 2

; Brick C_left [9/137]                        used by: BRC (left)
    .byte %10101010            ; 2 2 2 2
    .byte %10101010            ; 2 2 2 2
    .byte %01010101            ; 1 1 1 1
    .byte %01011010            ; 1 1 2 2
    .byte %01011010            ; 1 1 2 2
    .byte %01011010            ; 1 1 2 2
    .byte %01010101            ; 1 1 1 1
    .byte %10101010            ; 2 2 2 2

; Brick C_right [10/138]                      used by: BRC (right)
    .byte %10010101            ; 2 1 1 1
    .byte %10010101            ; 2 1 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %10101001            ; 2 2 2 1
    .byte %10101001            ; 2 2 2 1
    .byte %10101001            ; 2 2 2 1
    .byte %01010101            ; 1 1 1 1
    .byte %10010101            ; 2 1 1 1

; Bottom_window_left [11/139]                 used by: FLW (left)
    .byte %10111111            ; 2 3 3 3
    .byte %10111111            ; 2 3 3 3
    .byte %10101010            ; 2 2 2 2
    .byte %10111111            ; 2 3 3 3
    .byte %10111111            ; 2 3 3 3
    .byte %10111111            ; 2 3 3 3
    .byte %10111111            ; 2 3 3 3
    .byte %10111111            ; 2 3 3 3

; Bottom_window_right [12/140]                used by: FLW (right)
    .byte %11111110            ; 3 3 3 2
    .byte %11111110            ; 3 3 3 2
    .byte %10101010            ; 2 2 2 2
    .byte %11111110            ; 3 3 3 2
    .byte %11111110            ; 3 3 3 2
    .byte %11111110            ; 3 3 3 2
    .byte %11111110            ; 3 3 3 2
    .byte %11111110            ; 3 3 3 2

; Cloud_left [13/141]                         used by: CLO (left)
    .byte %00000000            ; 0 0 0 0
    .byte %00001010            ; 0 0 2 2
    .byte %00101010            ; 0 2 2 2
    .byte %00101010            ; 0 2 2 2
    .byte %00001010            ; 0 0 2 2
    .byte %00000000            ; 0 0 0 0
    .byte %00000000            ; 0 0 0 0
    .byte %00000000            ; 0 0 0 0

; Cloud_right [14/142]                        used by: CLO (right)
    .byte %00000000            ; 0 0 0 0
    .byte %10000000            ; 2 0 0 0
    .byte %10100000            ; 2 2 0 0
    .byte %10101000            ; 2 2 2 0
    .byte %10100000            ; 2 2 0 0
    .byte %00000000            ; 0 0 0 0
    .byte %00000000            ; 0 0 0 0
    .byte %00000000            ; 0 0 0 0

; Upper_rail_left [15/143]                    used by: RIL (left)
    .byte %00010101            ; 0 1 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %01010000            ; 1 1 0 0
    .byte %01010000            ; 1 1 0 0
    .byte %01010000            ; 1 1 0 0
    .byte %01010000            ; 1 1 0 0
    .byte %01010000            ; 1 1 0 0
    .byte %01010101            ; 1 1 1 1
; Upper_rail_middle [16/144]                  used by: RIL (right)
    .byte %01010101            ; 1 1 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %00000000            ; 0 0 0 0
    .byte %10000000            ; 2 0 0 0
    .byte %00000000            ; 0 0 0 0
    .byte %00000000            ; 0 0 0 0
    .byte %00000000            ; 0 0 0 0
    .byte %01010101            ; 1 1 1 1
; Rail_middle_right_left [17/145]             used by: RMR (left)
    .byte %01010101            ; 1 1 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %00000000            ; 0 0 0 0
    .byte %00001000            ; 0 0 2 0
    .byte %00000000            ; 0 0 0 0
    .byte %00000000            ; 0 0 0 0
    .byte %00000000            ; 0 0 0 0
    .byte %01010101            ; 1 1 1 1
; Rail_middle_right_right [18/146]            used by: RMR (right)
    .byte %01010101            ; 1 1 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %00000001            ; 0 0 0 1
    .byte %00000001            ; 0 0 0 1
    .byte %00000001            ; 0 0 0 1
    .byte %00000001            ; 0 0 0 1
    .byte %00000001            ; 0 0 0 1
    .byte %01010101            ; 1 1 1 1
; Rail_middle_left_left [19/147]              used by: RML (left)
    .byte %01010101            ; 1 1 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %01000000            ; 1 0 0 0
    .byte %01000010            ; 1 0 0 2
    .byte %01000000            ; 1 0 0 0
    .byte %01000000            ; 1 0 0 0
    .byte %01000000            ; 1 0 0 0
    .byte %01010101            ; 1 1 1 1
; Rail_middle_left_right [20/148]             used by: RML (right)
    .byte %01010101            ; 1 1 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %00000000            ; 0 0 0 0
    .byte %00000000            ; 0 0 0 0
    .byte %00000000            ; 0 0 0 0
    .byte %00000000            ; 0 0 0 0
    .byte %00000000            ; 0 0 0 0
    .byte %01010101            ; 1 1 1 1
; Upper_rail_right_left [21/149]              used by: RIR (left)   = char 16 mirrored
    .byte %01010101            ; 1 1 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %00000000            ; 0 0 0 0
    .byte %00000010            ; 0 0 0 2
    .byte %00000000            ; 0 0 0 0
    .byte %00000000            ; 0 0 0 0
    .byte %00000000            ; 0 0 0 0
    .byte %01010101            ; 1 1 1 1

; Upper_rail_right [22/150]                   used by: RIR (right)  = char 15 mirrored
    .byte %01010100            ; 1 1 1 0
    .byte %01010101            ; 1 1 1 1
    .byte %00000101            ; 0 0 1 1
    .byte %00000101            ; 0 0 1 1
    .byte %00000101            ; 0 0 1 1
    .byte %00000101            ; 0 0 1 1
    .byte %00000101            ; 0 0 1 1
    .byte %01010101            ; 1 1 1 1

; Road_left [23/151]                          used by: ROD (left)
    .byte %10101010            ; 2 2 2 2
    .byte %01010101            ; 1 1 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %01011111            ; 1 1 3 3
    .byte %01010101            ; 1 1 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %01010101            ; 1 1 1 1

; Road_right [24/152]                         used by: ROD (right)
    .byte %10101010            ; 2 2 2 2
    .byte %01010101            ; 1 1 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %11110101            ; 3 3 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %01010101            ; 1 1 1 1
    .byte %01010101            ; 1 1 1 1

; Path_left [25/153]                          used by: PTH (left)
    .byte %10101010            ; 2 2 2 2
    .byte %11111011            ; 3 3 2 3
    .byte %10101010            ; 2 2 2 2
    .byte %11111111            ; 3 3 3 3
    .byte %10101010            ; 2 2 2 2
    .byte %11111011            ; 3 3 2 3
    .byte %10101010            ; 2 2 2 2
    .byte %11111111            ; 3 3 3 3

; Path_right [26/154]                         used by: PTH (right)
    .byte %10101010            ; 2 2 2 2
    .byte %11111111            ; 3 3 3 3
    .byte %10101010            ; 2 2 2 2
    .byte %11101111            ; 3 2 3 3
    .byte %10101010            ; 2 2 2 2
    .byte %11111111            ; 3 3 3 3
    .byte %10101010            ; 2 2 2 2
    .byte %11101111            ; 3 2 3 3

; Bottom_window_pillar_left [27/155]          used by: PIL (left)   = FLW with the pillar (value 1)
    .byte %10101010            ; 2 2 2 2
    .byte %10110101            ; 2 3 1 1
    .byte %10100101            ; 2 2 1 1
    .byte %10110101            ; 2 3 1 1
    .byte %10110101            ; 2 3 1 1
    .byte %10110101            ; 2 3 1 1
    .byte %10110101            ; 2 3 1 1
    .byte %10110101            ; 2 3 1 1

; Bottom_window_pillar_right [28/156]         used by: PIL (right)
    .byte %10101010            ; 2 2 2 2
    .byte %01011110            ; 1 1 3 2
    .byte %01011010            ; 1 1 2 2
    .byte %01011110            ; 1 1 3 2
    .byte %01011110            ; 1 1 3 2
    .byte %01011110            ; 1 1 3 2
    .byte %01011110            ; 1 1 3 2
    .byte %01011110            ; 1 1 3 2

; Door_left_left [29/157]                     used by: DOL (left)
    .byte %10101010            ; 2 2 2 2
    .byte %10111111            ; 2 3 3 3
    .byte %10101010            ; 2 2 2 2
    .byte %10101111            ; 2 2 3 3
    .byte %10111111            ; 2 3 3 3
    .byte %10111111            ; 2 3 3 3
    .byte %10111111            ; 2 3 3 3
    .byte %10111111            ; 2 3 3 3

; Door_left_right [30/158]                    used by: DOL (right)
    .byte %10101010            ; 2 2 2 2
    .byte %11111110            ; 3 3 3 2
    .byte %10101010            ; 2 2 2 2
    .byte %11111110            ; 3 3 3 2
    .byte %11111110            ; 3 3 3 2
    .byte %11111010            ; 3 3 2 2
    .byte %11111110            ; 3 3 3 2
    .byte %11111110            ; 3 3 3 2

; Door_right_left [31/159]                    used by: DOR (left)
    .byte %10101010            ; 2 2 2 2
    .byte %10111111            ; 2 3 3 3
    .byte %10101010            ; 2 2 2 2
    .byte %10111111            ; 2 3 3 3
    .byte %10111111            ; 2 3 3 3
    .byte %10101111            ; 2 2 3 3
    .byte %10111111            ; 2 3 3 3
    .byte %10111111            ; 2 3 3 3

; Door_right_right [32/160]                   used by: DOR (right)
    .byte %10101010            ; 2 2 2 2
    .byte %11111110            ; 3 3 3 2
    .byte %10101010            ; 2 2 2 2
    .byte %11111010            ; 3 3 2 2
    .byte %11111110            ; 3 3 3 2
    .byte %11111110            ; 3 3 3 2
    .byte %11111110            ; 3 3 3 2
    .byte %11111110            ; 3 3 3 2

; Pillar_on_path_left [33/161]                used by: PIP (left)
    .byte %10100101            ; 2 2 1 1
    .byte %11110101            ; 3 3 1 1
    .byte %10100101            ; 2 2 1 1
    .byte %11110101            ; 3 3 1 1
    .byte %10100101            ; 2 2 1 1
    .byte %11110101            ; 3 3 1 1
    .byte %10101010            ; 2 2 2 2
    .byte %11111111            ; 3 3 3 3

; Pillar_on_path_right [34/162]               used by: PIP (right)
    .byte %01011010            ; 1 1 2 2
    .byte %01011111            ; 1 1 3 3
    .byte %01011010            ; 1 1 2 2
    .byte %01011111            ; 1 1 3 3
    .byte %01011010            ; 1 1 2 2
    .byte %01011111            ; 1 1 3 3
    .byte %10101010            ; 2 2 2 2
    .byte %11101111            ; 3 2 3 3

; Bottom_window_middle_left [35/163]
    .byte %10101010            ; 2 2 2 2
    .byte %10111111            ; 2 3 3 3
    .byte %10101010            ; 2 2 2 2
    .byte %10111111            ; 2 3 3 3
    .byte %10111111            ; 2 3 3 3
    .byte %10111111            ; 2 3 3 3
    .byte %10111111            ; 2 3 3 3
    .byte %10111111            ; 2 3 3 3

; Bottom_window_middle_right [36/164]
    .byte %10101010            ; 2 2 2 2
    .byte %11111110            ; 3 3 3 2
    .byte %10101010            ; 2 2 2 2
    .byte %11111110            ; 3 3 3 2
    .byte %11111110            ; 3 3 3 2
    .byte %11111110            ; 3 3 3 2
    .byte %11111110            ; 3 3 3 2
    .byte %11111110            ; 3 3 3 2

; Front window left [37/165]                  used by: WFL (left)   = char 2 with a 2-row sill
    .byte %01011001            ; 1 1 2 1
    .byte %01110111            ; 1 3 1 3
    .byte %01110111            ; 1 3 1 3
    .byte %01110111            ; 1 3 1 3
    .byte %01110111            ; 1 3 1 3
    .byte %01110111            ; 1 3 1 3
    .byte %01011001            ; 1 1 2 1
    .byte %01011001            ; 1 1 2 1

; Front window center [38/166]                used by: WFL (right), WFR (left)
    .byte %01010101            ; 1 1 1 1
    .byte %11111111            ; 3 3 3 3
    .byte %11111111            ; 3 3 3 3
    .byte %11111111            ; 3 3 3 3
    .byte %11111111            ; 3 3 3 3
    .byte %11111111            ; 3 3 3 3
    .byte %01010101            ; 1 1 1 1
    .byte %01010101            ; 1 1 1 1

; Front window right [39/167]                 used by: WFR (right)  = char 4 with a 2-row sill
    .byte %01100101            ; 1 2 1 1
    .byte %11011101            ; 3 1 3 1
    .byte %11011101            ; 3 1 3 1
    .byte %11011101            ; 3 1 3 1
    .byte %11011101            ; 3 1 3 1
    .byte %11011101            ; 3 1 3 1
    .byte %01100101            ; 1 2 1 1
    .byte %01100101            ; 1 2 1 1

; Pillar_sky_left [40/168]                    used by: PIS (left)   pillar (value 1) on the sky background
    .byte %00000101            ; 0 0 1 1
    .byte %00000101            ; 0 0 1 1
    .byte %00000101            ; 0 0 1 1
    .byte %00000101            ; 0 0 1 1
    .byte %00000101            ; 0 0 1 1
    .byte %00000101            ; 0 0 1 1
    .byte %00000101            ; 0 0 1 1
    .byte %00000101            ; 0 0 1 1

; Pillar_sky_right [41/169]                   used by: PIS (right)
    .byte %01010000            ; 1 1 0 0
    .byte %01010000            ; 1 1 0 0
    .byte %01010000            ; 1 1 0 0
    .byte %01010000            ; 1 1 0 0
    .byte %01010000            ; 1 1 0 0
    .byte %01010000            ; 1 1 0 0
    .byte %01010000            ; 1 1 0 0
    .byte %01010000            ; 1 1 0 0

; (retired: chars_len = * - gfx_school, used by the old load_gfx in tools.asm)
;chars_len = * - gfx_school
