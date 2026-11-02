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
;   ground floor  8      sky          LIGHT GRAY    DARK GRAY     window blue    light yellow
;   grass, path   9-10   GRASS GREEN  light gray    MEDIUM GRAY   SIDEWALK GRAY  light yellow
;   road          11     grass green  DARK GRAY     medium gray   MARKING GRAY   light yellow
;
;   CAPITALS = what the DLI at the start of that zone changes.
;
;   Pixel values on rows 8-11:
;     row 8   FLW, PIL: 2 = dark frame, 3 = glass, 1 = pillar
;     row 9   PTH: 2 = joints, 3 = stones; a pillar standing on the path: 1 = pillar
;             (the TOP line of a row-9 tile must not use value 3: see ?dli_ground)
;     row 10  PTH: 2 = joints, 3 = stones (value 1 unused, so the road DLI can change it)
;     row 11  ROD: 1 = asphalt, 2 = top edge, 3 = marking
;   The pillar is value 1 (COLPF0) on rows 8 and 9: it shares a character with glass (row 8)
;   or with the path's two grays (row 9), so it needs the one register those don't use.
;   (Not the inverse slot: an inverse char turns ALL its %11 pixels into COLPF3.)
;
; How it works:
;   - The top palette goes into the OS colour shadows (COLOR0-4). The OS copies the
;     shadows to the hardware every vertical blank, so every frame starts with the top
;     colours by itself - no vertical blank code is needed.
;   - Mode lines 3, 7, 8 and 10 have the DLI bit (dlist.asm). A DLI runs during the last
;     scanline of its mode line, so the new colours start exactly at rows 4, 8, 9 and 11.
;   - The 4 handlers are chained through VDSLST: each one points VDSLST at the next, and
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
?medium_gray = $06              ; mortar, path joints, road edge
?grass_green = $C4
?sidewalk_gray = $08            ; lighter sidewalk: one brightness step above ?medium_gray,
                                ;   so the paving stones stay close to the joints
?marking_gray = $0C             ; road marking (bright, like the draft)

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
; DLI handler: end of row 7 -> ground floor colours for row 8 (pillar = COLPF0)
; -------------------------------------------------------------------------------------
?dli_ground_floor
    pha                         ; save A
    txa
    pha                         ; save X
    lda #?light_gray            ; preload
    ldx #?dark_gray
    sta WSYNC                   ; wait for the end of the scanline
    sta COLPF0                  ; value 1: dark gray -> pillar gray
    stx COLPF1                  ; value 2: medium gray -> dark gray (window frames)
    MWA ?dli_ground VDSLST      ; next DLI of this frame
    pla
    tax                         ; restore X
    pla                         ; restore A
    rti

; -------------------------------------------------------------------------------------
; DLI handler: end of row 8 -> grass and path colours for rows 9-10 (3 registers)
; -------------------------------------------------------------------------------------
; The prologue must reach WSYNC before the scanline ends; with the wide playfield ANTIC
; leaves the CPU only about half of each scanline. Saving a third register (Y) made it
; one scanline late (a line of sky above the grass), so only 2 colours are preloaded.
; The 3rd colour (COLPF2) is stored right after: it may change during the first scanline
; of row 9, because no tile uses pixel value 3 in its top line on row 9 (PTH's top line is
; all joints, the grass is the background). Keep it that way for new row-9 tiles.
?dli_ground
    pha                         ; save A
    txa
    pha                         ; save X
    lda #?grass_green           ; preload the 2 colours that must be ready at the line start
    ldx #?medium_gray
    sta WSYNC                   ; wait for the end of the scanline
    sta COLBK                   ; background: sky -> grass
    stx COLPF1                  ; value 2: dark gray -> medium gray (path joints)
    lda #?sidewalk_gray         ; value 3: window blue -> sidewalk gray (paving stones);
    sta COLPF2                  ;   not used on the top line of row 9, so a bit later is fine
    MWA ?dli_road VDSLST        ; next DLI of this frame
    pla
    tax                         ; restore X
    pla                         ; restore A
    rti

; -------------------------------------------------------------------------------------
; DLI handler: end of row 10 -> road colours for row 11
; -------------------------------------------------------------------------------------
?dli_road
    pha                         ; save A
    txa
    pha                         ; save X
    lda #?dark_gray             ; preload
    ldx #?marking_gray
    sta WSYNC                   ; wait for the end of the scanline
    sta COLPF0                  ; value 1: pillar gray -> dark gray (asphalt)
    stx COLPF2                  ; value 3: sidewalk gray -> bright marking gray
    MWA ?dli_building VDSLST    ; last DLI of the frame: the next one is row 3 of the next frame
    pla
    tax                         ; restore X
    pla                         ; restore A
    rti
