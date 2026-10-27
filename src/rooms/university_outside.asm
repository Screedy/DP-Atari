; =====================================================================================
; rooms/university_outside.asm - colours of the university_outside room (DLI zones)
; =====================================================================================
;
; ANTIC mode 5 has only 4 colours + 1 (inverse chars) for the whole screen. To get more,
; Display List Interrupts (DLI) change the colour registers partway down the screen, so
; every horizontal zone of this room has its own palette:
;
;   zone          rows   COLBK (%00)  COLPF0 (%01)  COLPF1 (%10)  COLPF2 (%11)   COLPF3 (inv %11)
;   top           0-3    sky          light gray    white         window blue    light yellow
;   building      4-7    sky          DARK GRAY     MEDIUM GRAY   window blue    light yellow
;   ground floor  8      sky          dark gray     medium gray   window blue    LIGHT GRAY
;   ground        9-11   GRASS GREEN  dark gray     medium gray   SIDEWALK GRAY  light gray
;
;   CAPITALS = what the DLI at the start of that zone changes.
;
; How it works:
;   - The top palette goes into the OS colour shadows (COLOR0-4). The OS copies the
;     shadows to the hardware every vertical blank, so every frame starts with the top
;     colours by itself - no vertical blank code is needed.
;   - Mode lines 3, 7 and 8 have the DLI bit (dlist.asm). A DLI runs during the last
;     scanline of its mode line, so the new colours start exactly at rows 4, 8 and 9.
;   - The 3 handlers are chained through VDSLST: each one points VDSLST at the next, and
;     the last one points it back at the first, ready for the next frame.
;   - Each handler loads the new colours into A/X first, waits for the end of the
;     scanline (WSYNC) and only then stores them (2 stores = 8 cycles, inside the
;     horizontal blank), so the change never shows up in the middle of a line.

    .LOCAL                      ; ?names below are local to this room

; -------------------------------------------------------------------------------------
; Colours of this room (high 4 bits = hue, low 4 bits = brightness)
; -------------------------------------------------------------------------------------
?sky_blue = $8A
?light_gray = $0A               ; roof rail, pillars
?white = $0E                    ; clouds
?window_blue = $8E
?light_yellow = $1E             ; lit windows
?dark_gray = $05                ; walls, road
?medium_gray = $06              ; darker sidewalk
?grass_green = $C4
?sidewalk_gray = $0C            ; lighter sidewalk (its own shade; tweak here)

; -------------------------------------------------------------------------------------
; Function: setup_university_outside_colors
; Description: Set the top-zone palette and start the DLI chain for this room
; INPUT: none
; OUTPUT: none
; DESTROYED: A, X
; -------------------------------------------------------------------------------------
setup_university_outside_colors
    MVA #?light_gray COLOR0     ; top palette into the shadows (the OS copies them to the
    MVA #?white COLOR1          ;   hardware every vertical blank = the start of every frame)
    MVA #?window_blue COLOR2
    MVA #?light_yellow COLOR3
    MVA #?sky_blue COLOR4

    lda #1                      ; wait for a vertical blank: the beam is now above the screen,
    jsr delay                   ;   so the first DLI to fire is the one at row 3 = first in the chain
    MWA ?dli_building VDSLST    ; first handler of the chain
    MVA #$C0 NMIEN              ; enable interrupts: bit 7 = DLI, bit 6 = VBI (keep it on)
    rts

; -------------------------------------------------------------------------------------
; DLI handler: end of row 3 -> building colours for rows 4-7
; (an interrupt handler: must save every register it uses and end with rti)
; -------------------------------------------------------------------------------------
?dli_building
    pha                         ; save A
    txa
    pha                         ; save X
    lda #?dark_gray             ; preload the new colours...
    ldx #?medium_gray
    sta WSYNC                   ; ...wait for the end of this scanline (the value doesn't matter)...
    sta COLPF0                  ; ...and switch colours.
    stx COLPF1
    MWA ?dli_ground_floor VDSLST ; next DLI of this frame
    pla
    tax                         ; restore X
    pla                         ; restore A
    rti

; -------------------------------------------------------------------------------------
; DLI handler: end of row 7 -> ground floor colours for row 8 (pillars in the inverse slot)
; -------------------------------------------------------------------------------------
?dli_ground_floor
    pha                         ; save A (X is not used)
    lda #?light_gray            ; preload
    sta WSYNC                   ; wait for the end of the scanline
    sta COLPF3                  ; inverse chars: lit-window yellow -> pillar gray
    MWA ?dli_ground VDSLST      ; next DLI of this frame
    pla                         ; restore A
    rti

; -------------------------------------------------------------------------------------
; DLI handler: end of row 8 -> ground colours for rows 9-11
; -------------------------------------------------------------------------------------
?dli_ground
    pha                         ; save A
    txa
    pha                         ; save X
    lda #?grass_green           ; preload
    ldx #?sidewalk_gray
    sta WSYNC                   ; wait for the end of the scanline
    sta COLBK                   ; background: sky -> grass
    stx COLPF2                  ; window blue -> lighter sidewalk gray
    MWA ?dli_building VDSLST    ; last DLI of the frame: the next one is row 3 of the next frame
    pla
    tax                         ; restore X
    pla                         ; restore A
    rti
