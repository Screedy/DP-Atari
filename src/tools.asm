; =====================================================================================
; tools.asm - general helper routines (not tied to the game)
; =====================================================================================
;
;   atascii_to_intern  convert an ATASCII character to the code used in screen memory
;   copy_mem           copy a block of memory (up to 64 KB)
;   delay              wait a number of frames
;   load_gfx           (retired, kept as a comment)
;
; Needs hw.asm (RTCLOK) to be included before this file.

; -------------------------------------------------------------------------------------
; Function: atascii_to_intern
; Description: Convert an ATASCII character to the internal code for screen memory.
;              Screen memory does not use ATASCII; the character groups are reordered:
;                ATASCII   0- 31 (control chars)  -> internal 64- 95  (+64)
;                ATASCII  32- 95 (space, A-Z, ...) -> internal  0- 63  (-32)
;                ATASCII  96-127 (lower case)      -> internal 96-127  (same)
;              Note: inverse characters (128-255) are returned unchanged, not converted.
; INPUT: A = ATASCII character
; OUTPUT: A = internal code (for screen memory)
; DESTROYED: A
; -------------------------------------------------------------------------------------
    .LOCAL
atascii_to_intern
    cmp #$20            ; carry clear if A < 32
    bcc ?ctrl           ; If less than space, branch to ?ctrl
    cmp #$60            ; carry clear if A < 96
    bcc ?normal         ; If less than backtick, branch to ?normal
    rts                 ; Return, A is already correct (96-127 stay the same)
?normal
    sec                 ; plain subtraction
    sbc #$20            ; Subtract 32 to convert to internal code
    rts                 ; Return
?ctrl
    clc                 ; plain addition
    adc #$40            ; Add 64 to convert control characters
    rts                 ; Return
; ----------- end of function atascii_to_intern -----------

; -------------------------------------------------------------------------------------
; Function: copy_mem
; Description: Copy a block of memory (up to 64 KB) from one location to another.
;              First copies whole 256-byte pages, then the remaining bytes (backwards).
;              The blocks must not overlap.
; INPUT: ZP_SRC = source address
;        ZP_DST = destination address
;        X = >length (number of whole 256-byte pages)
;        A = <length (remaining bytes)
; OUTPUT: none
; DESTROYED: A, X, Y, ZP_SRC, ZP_DST
; -------------------------------------------------------------------------------------
    .LOCAL
copy_mem
    pha                     ; Rest A save on a stack
    ldy #0                  ; Y = offset inside the page, starts at 0
    cpx #0                  ; any whole pages?
    beq ?rest               ; less than 256 B -> only rest
?page
    lda (ZP_SRC),y          ; copy one byte
    sta (ZP_DST),y
    iny                     ; next byte
    bne ?page               ; until Y wraps 255 -> 0 = 256 bytes done
    inc ZP_SRC+1            ; Shift source address to next page
    inc ZP_DST+1            ; ... and the destination too
    dex                     ; one page less
    bne ?page               ; until all pages are copied
?rest
    pla                     ; Restore A from stack
    tay                     ; Y = number of bytes to copy
    beq ?done               ; nothing left
?tail
    dey                     ; Copies from the end: Y-1 .. 0
    lda (ZP_SRC),y
    sta (ZP_DST),y
    cpy #0                  ; needed: lda changed the Z flag, so test Y again
    bne ?tail               ; until byte 0 is copied
?done
    rts
; ----------- end of function copy_mem -----------

; -------------------------------------------------------------------------------------
; Function: delay
; Description: Wait a number of frames (1 frame = 1/50 s PAL, 1/60 s NTSC).
;              Returns right after a vertical blank, so the caller can change the
;              screen (display list, PMG) before ANTIC draws the next picture.
; INPUT: A = frames to wait (1-255; 0 waits 256 frames)
; OUTPUT: none
; DESTROYED: A, X
; -------------------------------------------------------------------------------------
    .LOCAL
delay
    tax                     ; X = frames left
?frame
    lda RTCLOK+2            ; frame counter, changes every VBI
?wait
    cmp RTCLOK+2            ; still the same frame?
    beq ?wait               ; yes: keep waiting
    dex                     ; one frame passed
    bne ?frame              ; until all frames have passed
    rts
; ----------- end of function delay -----------

; -------------------------------------------------------------------------------------
; TODO: This code has been retired, but I will leave it here while I test the new graphics loading method.
; (The charset is now assembled directly at the charset address in gfx.asm, so nothing
;  has to be copied at start-up.)
; Function: load_gfx
; Description: Load the character set and graphics data into memory
; INPUT: none
; OUTPUT: none
; -------------------------------------------------------------------------------------
;    .LOCAL
;load_gfx
    ; Set up character set
;    MVA #>charset CHBAS         ; CHBAS = upper byte of charset address
;    MWA gfx_school ZP_SRC       ; source: definition of the character set
;    MWA charset ZP_DST          ; destination: charset memory
;    LDX #>chars_len              ; X = length of the character set
;    LDA #<chars_len             ; A = remaining length of the character set
;    jmp copy_mem                ; Copy character set to memory
; ----------- end of function load_gfx -----------
