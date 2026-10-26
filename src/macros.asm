; =====================================================================================
; macros.asm - assembly macros (short instruction sequences used often)
; =====================================================================================
;
; A macro is copied into the code every time it is used (it is not a subroutine:
; no jsr/rts, no extra cycles, but every use costs its full size in bytes).
; %1, %2, ... are the macro's arguments; %0 is the number of arguments.
; Arguments are separated by spaces or commas, e.g.  MVA #3 GRACTL
;
; This file is included first in main.asm: a macro must be defined before it is used.
;
; Watch out when porting from MADS (e.g. EdVenture): MADS' mwa copies a word from memory
; unless the source has #. Our MWA below always stores the address itself (writing
; MWA #addr ... stops the build); to copy a word from memory use MVW.

; -------------------------------------------------------------------------------------
; Macro: MWA - Move Word Address
; Description: Write a 16-bit address (a constant, NOT the contents of memory) into a
;              word (2 bytes, low byte first) in memory, e.g. to set up a pointer.
; Example: MWA map_area ZP_SRC   ->  ZP_SRC = <map_area, ZP_SRC+1 = >map_area
; INPUT: %1 = 16-bit address, %2 = memory location (word)
; OUTPUT: none
; DESTROYED: A
; -------------------------------------------------------------------------------------
; NOTE: no build check for the "copy a pointer" mistake (MWA ZP_SRC ZP_DST stores $00CB,
;       not the pointer): ATasm's .IF can't evaluate labels defined later in the file,
;       and .DEF doesn't accept expressions, so any check would break correct uses.
;       Use MVW to copy a word.
.MACRO MWA
    lda #<%1                    ; low byte of the address
    sta %2                      ; -> first byte of the word
    lda #>%1                    ; high byte of the address
    sta %2+1                    ; -> second byte of the word
.ENDM

; -------------------------------------------------------------------------------------
; Macro: MVW - Move Word
; Description: Copy a 16-bit word (2 bytes, low byte first) from one place in memory to
;              another, e.g. copy one pointer into another. The counterpart of MWA, which
;              stores an address constant instead.
; Example: MVW ZP_SRC ZP_DST   ->  ZP_DST = ZP_SRC (both bytes)
; INPUT: %1 = source word, %2 = destination word
; OUTPUT: none
; DESTROYED: A
; -------------------------------------------------------------------------------------
.MACRO MVW
    lda %1                      ; low byte of the source
    sta %2                      ; -> low byte of the destination
    lda %1+1                    ; high byte of the source
    sta %2+1                    ; -> high byte of the destination
.ENDM

; -------------------------------------------------------------------------------------
; Macro: MVA - Move Value
; Description: Move a byte from one place to another through A (direct or indexed).
;              The source may be a constant (#value) or an address.
; Examples: MVA #3 GRACTL                    ; GRACTL = 3
;           MVA pmgdata,x pmg_p0+64,x        ; indexed: 4 arguments (the commas split them)
; INPUT: 2 args: %1 = source, %2 = destination
;        4 args: %1 = source, %2 = source index register (x/y),
;                %3 = destination, %4 = destination index register (x/y)
; OUTPUT: none
; DESTROYED: A
;
; NOTE: Uses nested .IF/.ELSE instead of .IF/.ELSEIF/.ELSE - ATasm has a bug
; where .ELSEIF checking a macro's parameter. count (%0) is never taken
; regardless of branch order. Nesting .IF inside .ELSE sidesteps this issue.
; -------------------------------------------------------------------------------------
.MACRO MVA
    .IF %0=2                    ; 2 arguments: plain move
        lda %1                  ; A = source
        sta %2                  ; destination = A
    .ELSE
        .IF %0=4                ; 4 arguments: indexed move
            lda %1,%2           ; A = source,index
            sta %3,%4           ; destination,index = A
        .ELSE                   ; anything else is a typo: stop the build
            .ERROR "Invalid number of arguments for MVA macro"
        .ENDIF
    .ENDIF
.ENDM

; -------------------------------------------------------------------------------------
; Macro: ADW - Add to Word
; Description: Add an 8-bit value to a 16-bit word in memory (carry goes into the high
;              byte). Has no branches, so it needs no labels inside the macro.
; Examples: ADW ZP_DST #2                    ; ZP_DST += 2
;           ADW ZP_SRC ZP_TMP                ; ZP_SRC += the byte stored in ZP_TMP
; INPUT: %1 = word address, %2 = value (#const or address)
; OUTPUT: none
; DESTROYED: A, carry
; -------------------------------------------------------------------------------------
.MACRO ADW
    clc                         ; plain addition
    lda %1                      ; low byte of the word
    adc %2                      ; + value (sets carry if it overflows past 255)
    sta %1
    lda %1+1                    ; high byte of the word
    adc #0                      ; + carry from the low byte
    sta %1+1
.ENDM
