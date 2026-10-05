; pmg.asm - Player/Missile graphics setup

; Player memory (double-line resolution: 128 B per player)
pmg_p0 = pmg + $200
pmg_p1 = pmg + $280
pmg_p2 = pmg + $300
pmg_p3 = pmg + $380

; Function: clear_pmg
; Description: Clear the player/missile graphics memory
; INPUT: none
; OUTPUT: none
    .LOCAL
clear_pmg
    ldx #$80            ; load 80, counting down
    lda #0
?loop
    dex
    sta pmg_p0,x
    sta pmg_p1,x
    sta pmg_p2,x
    sta pmg_p3,x
    bne ?loop
    rts

; Function: load_pmg
; Description: Load the player/missile graphics data into memory
; INPUT: none
; OUTPUT: none
    .LOCAL
load_pmg
    ldx #0
?loop
    MVA pmgdata,x pmg_p0+64,x
    MVA pmgdata+8,x pmg_p1+64,x
    MVA pmgdata+16,x pmg_p2+64,x
    MVA pmgdata+24,x pmg_p3+64,x
    inx
    cpx #8
    bne ?loop
    rts

; Function: setup_pmg
; Description: Set up the player/missile graphics registers
; INPUT: none
; OUTPUT: none
    .LOCAL
setup_pmg
    MVA #>pmg PMBASE
    MVA #46 SDMCTL          ; Send 2 to SDMCTL to enable PMG DMA
    MVA #3 GRACTL           ; Enable PMG DMA and set PMG to normal size
    MVA #1 GRPRIOR          ; Set priority to player/missile graphics (Z-indexing - player on top of background)

    lda #120              ; Set position to center of the screen
    sta HPOSP0
    sta HPOSP1
    sta HPOSP2
    sta HPOSP3
    rts
