; hw.asm - Atari 8-bit hardware register definitions

RTCLOK = $0012          ; Real-time clock register
; SAVMSC = $0058        ; Screen memory address
SDLSTL = $0230          ; Display list starting address
SDMCTL = $022F          ; Display list DMA control
CHBAS = $02F4           ; Character set base address
COLOR0 = $02C4          ; Color register 0 (%01)
COLOR1 = $02C5          ; Color register 1 (%10)
COLOR2 = $02C6          ; Color register 2 (%11)
COLOR3 = $02C7          ; Color register 3 (inverse)
COLOR4 = $02C8          ; Color register 4 (%00)

GPRIOR = $026F          ; Graphics priority register
PCOLR0 = $2C0           ; Player 0 color register
PCOLR1 = $2C1           ; Player 1 color register
PCOLR2 = $2C2           ; Player 2 color register
PCOLR3 = $2C3           ; Player 3 color register