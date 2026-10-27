; =====================================================================================
; pmg.asm - Player/Missile Graphics: memory layout, clearing, switching it on
; =====================================================================================
;
; The player sprite is made of all 4 players (see player.asm). This file only sets up
; the hardware and clears the memory; drawing and moving the sprite is in player.asm.
;
; PMG memory in double-line resolution (1 KB, starts at pmg, set in main.asm):
;   pmg+$000 - pmg+$17F   unused
;   pmg+$180 - pmg+$1FF   missiles (not used yet)
;   pmg+$200 - pmg+$27F   player 0   \
;   pmg+$280 - pmg+$2FF   player 1    |  128 bytes each: 1 byte = 1 sprite line
;   pmg+$300 - pmg+$37F   player 2    |  (= 2 scanlines in double-line resolution)
;   pmg+$380 - pmg+$3FF   player 3   /

; -------------------------------------------------------------------------------------
; Player memory (double-line resolution: 128 B per player)
; -------------------------------------------------------------------------------------
pmg_p0 = pmg + $200             ; player 0 (hair)
pmg_p1 = pmg + $280             ; player 1 (skin)
pmg_p2 = pmg + $300             ; player 2 (clothes)
pmg_p3 = pmg + $380             ; player 3 (boots)

; PMBASE only holds the high bits of the address, so in double-line resolution the
; PMG area must start on a 1 KB boundary ($xx00 with the low 10 bits = 0)
.IF pmg & $3FF
    .ERROR "PMG must be 1 KB aligned (PMBASE, double-line resolution)"
.ENDIF

; -------------------------------------------------------------------------------------
; Function: clear_pmg
; Description: Clear the memory of all 4 players (the missiles are not used)
; INPUT: none
; OUTPUT: none
; DESTROYED: A, X
; -------------------------------------------------------------------------------------
    .LOCAL
clear_pmg
    ldx #$80                    ; X = 128 = bytes per player, counting down
    lda #0                      ; value to write: 0 = no pixels
?loop
    dex                         ; X = 127 .. 0 (decrement first, so index 128 is never written)
    sta pmg_p0,x                ; clear line X of all 4 players
    sta pmg_p1,x
    sta pmg_p2,x
    sta pmg_p3,x
    bne ?loop                   ; Z flag still from dex (sta doesn't change flags): stop after X = 0
    rts

; -------------------------------------------------------------------------------------
; Function: setup_pmg
; Description: Tell the hardware where PMG memory is and switch players/missiles on
; INPUT: none
; OUTPUT: none
; DESTROYED: A
; -------------------------------------------------------------------------------------
    .LOCAL
setup_pmg
    MVA #>pmg PMBASE            ; PMG memory address (high byte only, see the alignment check)
    MVA #47 SDMCTL              ; DMA control, 47 = %00101111:
                                ;   bits 0-1 = 11  wide playfield (48 chars): covers the side borders,
                                ;                  which would otherwise show the background colour
                                ;   bit 2    = 1   missile DMA on
                                ;   bit 3    = 1   player DMA on
                                ;   bit 4    = 0   double-line PMG resolution
                                ;   bit 5    = 1   display list DMA on (the screen is shown)
    MVA #3 GRACTL               ; GTIA: bit 0 = show missiles, bit 1 = show players
    MVA #1 GPRIOR               ; priority: players in front of the playfield (the background)
    rts                         ; horizontal position: set_player_x (player.asm)
