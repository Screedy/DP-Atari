; macros.asm - Atari 8-bit assembly macros

; Write a 16bit address to a memory location
; INPUT: %1 = 16bit address, %2 = memory location
; OUTPUT: none
.MACRO MWA
    lda #<%1
    sta %2
    lda #>%1
    sta %2+1
.ENDM

; Move a value from one address to another (direct or indexed)
; INPUT: 2 args: %1 = source, %2 = destination
;        4 args: %1 = source, %2 = source index register (x/y),
;                %3 = destination, %4 = destination index register (x/y)
; OUTPUT: none
;
; NOTE: Uses nested .IF/.ELSE instead of .IF/.ELSEIF/.ELSE - ATasm has a bug
; where .ELSEIF checking a macro's parameter. count (%0) is never taken
; regardless of branch order. Nesting .IF inside .ELSE sidesteps this issue.
.MACRO MVA
    .IF %0=2
        lda %1
        sta %2
    .ELSE
        .IF %0=4
            lda %1,%2
            sta %3,%4
        .ELSE
            .ERROR "Invalid number of arguments for MVA macro"
        .ENDIF
    .ENDIF
.ENDM

; Add an 8-bit value to a 16-bit word in memory (carry goes into the high byte)
; INPUT: %1 = word address, %2 = value (#const or address)
; OUTPUT: none
; DESTROYED: A, carry
.MACRO ADW
    clc
    lda %1
    adc %2
    sta %1
    lda %1+1
    adc #0
    sta %1+1
.ENDM
