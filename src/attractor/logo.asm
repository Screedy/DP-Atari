; =====================================================================================
; attractor/logo.asm - full-screen logo of the department (ANTIC mode E bitmap)
; =====================================================================================
;
; Not a tile map: the logo is one unique picture, so it has its own display list in
; ANTIC mode E (as BASIC's GRAPHICS 15): 160 x 1-scanline pixels, 2 bits per pixel,
; 40 bytes per line. Blank lines above the picture centre it (up to 192 lines, the full
; screen). Everything around the logo, the screen border included, is the background
; colour COLBK, so the logo looks full screen.
;
; Every picture line has its own LMS address (assets/logo_dlist.asm), so the data at
; logo_bitmap (main.asm) holds only what is not white, and each distinct row only once:
; white lines are blank display-list lines, repeated rows share their bytes.
;
; Both files come from assets/logo.png (160 px wide, 4 colours; indexed or RGB):
;   python3 tools/img2bitmap.py assets/logo.png assets/logo
;   -> assets/logo.bin (data) + assets/logo_dlist.asm (logo_lines, logo_data_len, LOGO_DLIST)
; Pixel value = palette index:  0 = COLOR4 (background)  1 = COLOR0  2 = COLOR1  3 = COLOR2
; A mode E pixel is about 1.7x wider than tall: draw with pixel ratio 2:1 in the editor.

    .LOCAL

.INCLUDE "assets/logo_dlist.asm" ; generated: logo_lines, logo_data_len, macro LOGO_DLIST
logo_frames    = 500           ; how long the logo stays without input: 500 = 10 s PAL, 8.3 s NTSC
                               ;   (frames, not seconds: calibration knob)

; -------------------------------------------------------------------------------------
; Colours (high 4 bits = hue, low 4 bits = brightness)
; -------------------------------------------------------------------------------------
?white = $0E                    ; background
?black = $00                    ; INF letters, KATEDRA INFORMATIKY
?upol_blue = $94                ; dot, diagonal, UNIVERZITA PALACKÉHO V OLOMOUCI
?light_gray = $0A               ; spare (pixel value 3), e.g. for smoothing edges

; -------------------------------------------------------------------------------------
; Function: show_logo
; Description: Show the logo until any input (joystick or W/A/S/D) or logo_frames frames.
;              Leaves the logo screen on; the next screen sets its own display list,
;              DMA and colours.
; INPUT: none
; OUTPUT: none
; DESTROYED: A, X
; -------------------------------------------------------------------------------------
show_logo
    lda #1                      ; wait for a vertical blank: the OS copies the shadows below
    jsr delay                   ;   during the next one, never half-written
    MWA ?dlist SDLSTL           ; our display list
    MVA #34 SDMCTL              ; %00100010: display list DMA on, normal playfield (40 bytes)
    MVA #0 GRACTL               ; players and missiles off
    MVA #?black COLOR0          ; pixel value 1
    MVA #?upol_blue COLOR1      ; pixel value 2
    MVA #?light_gray COLOR2     ; pixel value 3
    MVA #?white COLOR4          ; pixel value 0 = background and border
    MWA logo_frames ?left       ; frames left (16-bit counter)
?frame
    lda #1
    jsr delay                   ; one frame
    jsr read_input              ; A = direction bits, %1111 = nothing pressed (main.asm)
    cmp #%1111
    bne ?done                   ; any input: stop
    lda ?left                   ; 16-bit decrement: borrow from the high byte when low = 0
    bne ?low
    dec ?left+1
?low
    dec ?left
    lda ?left
    ora ?left+1                 ; both bytes 0 = time is up
    bne ?frame
?done
    rts
?left
    .WORD 0                     ; frames left

; -------------------------------------------------------------------------------------
; The display list
; -------------------------------------------------------------------------------------
?blank8 = $70                   ; 8 blank scanlines (background colour)
?jvb = $41                      ; jump and wait for vertical blank: the display list loops
?pad = 24+[192-logo_lines]/2    ; blank scanlines above the logo: 24 (top border) + centring

?dlist
    .REPT ?pad/8
    .BYTE ?blank8
    .ENDR
.IF ?pad&7                      ; the rest: blank n lines = (n-1)*16
    .BYTE [[?pad&7]-1]*16
.ENDIF
    LOGO_DLIST                  ; one line per picture line: mode E + LMS, or blank (generated)
    .BYTE ?jvb, <?dlist, >?dlist

; ANTIC's address counter wraps at a 4 KB boundary instead of crossing it. Every line has
; its own LMS, so it is enough that the whole data lies inside one 4 KB block.
.IF [logo_bitmap&$FFF]+logo_data_len > $1000
    .ERROR "logo data crosses a 4 KB boundary: put logo_bitmap at a 4 KB boundary"
.ENDIF
.IF logo_lines > 192
    .ERROR "logo taller than the screen (192 lines)"
.ENDIF

    .LOCAL                      ; end of this file's local names
