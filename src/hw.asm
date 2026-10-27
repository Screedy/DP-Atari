; =====================================================================================
; hw.asm - names of the Atari hardware and OS registers we use
; =====================================================================================
;
; Only names (equates), no code or data. Must be included before code that uses
; RTCLOK as a zero-page address (tools.asm), otherwise atasm needs an extra pass.
;
; Two kinds of registers:
;   OS shadow registers (page 0 and page 2, $00xx/$02xx): normal RAM. The OS copies
;     them to the hardware during every vertical blank (or reads the hardware into
;     them). Writing a shadow is safe at any time; the change shows on the next frame.
;   Hardware registers ($D0xx GTIA, $D2xx POKEY, $D4xx ANTIC): the chips themselves.
;     Writing one takes effect immediately; the OS does not touch the ones used here.

; -------------------------------------------------------------------------------------
; OS: clock
; -------------------------------------------------------------------------------------
RTCLOK = $0012          ; Real-time clock, 3 bytes; RTCLOK+2 ($14) = frame counter, +1 every VBI

; -------------------------------------------------------------------------------------
; OS shadows: display (ANTIC)
; -------------------------------------------------------------------------------------
; SAVMSC = $0058        ; Screen memory address of the OS screen (not used: we have our own)
SDMCTL = $022F          ; DMA control register (Shadow of DMACTL): playfield width, PMG/DL DMA
SDLSTL = $0230          ; Display list starting address (Shadow of DLISTL), 2 bytes
CHBAS = $02F4           ; Character set base address (high byte, Shadow of CHBASE)

; -------------------------------------------------------------------------------------
; OS shadows: colours and priority (GTIA)
; -------------------------------------------------------------------------------------
GPRIOR = $026F          ; Graphics priority register (Shadow of PRIOR): who is in front
PCOLR0 = $02C0          ; Player 0 color register
PCOLR1 = $02C1          ; Player 1 color register
PCOLR2 = $02C2          ; Player 2 color register
PCOLR3 = $02C3          ; Player 3 color register
COLOR0 = $02C4          ; Color register 0 (%01)
COLOR1 = $02C5          ; Color register 1 (%10)
COLOR2 = $02C6          ; Color register 2 (%11)
COLOR3 = $02C7          ; Color register 3 (inverse)
COLOR4 = $02C8          ; Color register 4 (%00, background)

; -------------------------------------------------------------------------------------
; OS shadows: input (read from the hardware by the OS every VBI)
; -------------------------------------------------------------------------------------
STICK0 = $0278          ; Joystick 0 directions: bit 0 up, 1 down, 2 left, 3 right (0 = pushed)
STRIG0 = $0284          ; Joystick 0 trigger (0 = pressed; not used yet)

; -------------------------------------------------------------------------------------
; OS: interrupt vectors
; -------------------------------------------------------------------------------------
VDSLST = $0200          ; Display list interrupt vector, 2 bytes: the OS jumps here on every DLI

; -------------------------------------------------------------------------------------
; Hardware: GTIA ($D0xx)
; -------------------------------------------------------------------------------------
HPOSP0 = $D000          ; Player 0 horizontal position
HPOSP1 = $D001          ; Player 1 horizontal position
HPOSP2 = $D002          ; Player 2 horizontal position
HPOSP3 = $D003          ; Player 3 horizontal position
COLPF0 = $D016          ; Playfield colour 0 (%01) - hardware, written by DLIs (shadow: COLOR0)
COLPF1 = $D017          ; Playfield colour 1 (%10)                           (shadow: COLOR1)
COLPF2 = $D018          ; Playfield colour 2 (%11)                           (shadow: COLOR2)
COLPF3 = $D019          ; Playfield colour 3 (inverse %11)                   (shadow: COLOR3)
COLBK = $D01A           ; Background colour (%00)                            (shadow: COLOR4)
GRACTL = $D01D          ; Graphics control: bit 0 = show missiles, bit 1 = show players

; -------------------------------------------------------------------------------------
; Hardware: POKEY ($D2xx) - keyboard
; -------------------------------------------------------------------------------------
KBCODE = $D209          ; Keyboard code of the key currently/last pressed (POKEY)
SKSTAT = $D20F          ; Serial/keyboard status (POKEY): bit 2 = 0 while a key is held

; -------------------------------------------------------------------------------------
; Hardware: ANTIC ($D4xx)
; -------------------------------------------------------------------------------------
PMBASE = $D407          ; Player/Missile graphics base address (high byte)
WSYNC = $D40A           ; Write anything: the CPU waits until the end of the current scanline
NMIEN = $D40E           ; Interrupt enable: bit 7 = DLI, bit 6 = VBI
