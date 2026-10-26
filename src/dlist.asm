; =====================================================================================
; dlist.asm - the display list: what ANTIC shows on the screen, and switching to it
; =====================================================================================
;
; A display list is a small program for the ANTIC chip. Every instruction describes one
; part of the screen from top to bottom: blank lines, or a "mode line" (one row of
; characters) together with where in memory its characters are.
;
; Our screen: 24 blank lines, then 12 mode lines of ANTIC mode 5 (40 chars, 16 scanlines
; each, 4 colours + 1 via inverse chars). Every mode line has its own LMS (Load Memory
; Scan) address pointing at its row of the canvas. Scrolling (scroll_lu/rd in main.asm)
; works by changing these 12 addresses, so their layout matters:
;
;   dlist+0..2    3x blank8
;   dlist+3       mode line 0: mode byte (?antic5+?lms)
;   dlist+4..5    mode line 0: LMS address, low byte, high byte   <- scroll starts at dlist+4
;   dlist+6..8    mode line 1: mode byte, address low, address high (3 bytes per line)
;   ...
;   last 3 bytes  JVB back to dlist

    .LOCAL                      ; ?names below are local to this file

; -------------------------------------------------------------------------------------
; ANTIC instructions
; -------------------------------------------------------------------------------------
?blank8 = $70                   ; 8 blank scanlines
?lms = $40                      ; Load Memory Scan: add to a mode; the next 2 bytes are the
                                ; address of this line's characters
?jvb = $41                      ; Jump and wait for Vertical Blank: the next 2 bytes are the
                                ; display list's start; ends the screen, starts again next frame

?antic2 = 2                     ; ANTIC mode 2: text, 40 chars, 8 scanlines, 2 colours (not used)
?antic5 = 5                     ; ANTIC mode 5: 40 chars, 16 scanlines, 4 colours (+1 inverse)
?row_bytes = canvas_w           ; canvas bytes per mode line (LMS on every line, scroll_lu/rd move them)

; -------------------------------------------------------------------------------------
; Function: setup_screen
; Description: Switch the screen to our display list. The OS copies SDLSTL to the hardware
;              during every vertical blank (VBI); writing the 2 bytes right after a VBI
;              makes sure the OS never copies a half-written address.
; INPUT: none
; OUTPUT: none
; DESTROYED: A
; -------------------------------------------------------------------------------------
setup_screen
    lda RTCLOK+2                ; $14 - frame counter, +1 every vertical blank
?wait
    cmp RTCLOK+2                ; wait until it changes = a VBI has just happened
    beq ?wait
    MWA dlist SDLSTL            ; now there's a whole frame until the next VBI: set the display list
    rts

; -------------------------------------------------------------------------------------
; The display list
; -------------------------------------------------------------------------------------
dlist
    .BYTE ?blank8, ?blank8, ?blank8                            ; 24 blank lines (top border)
    .BYTE ?antic5+?lms, <[canvas+0*?row_bytes], >[canvas+0*?row_bytes]     ; mode line 0 = canvas row 0
    .BYTE ?antic5+?lms, <[canvas+1*?row_bytes], >[canvas+1*?row_bytes]     ; mode line 1 = canvas row 1
    .BYTE ?antic5+?lms, <[canvas+2*?row_bytes], >[canvas+2*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+3*?row_bytes], >[canvas+3*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+4*?row_bytes], >[canvas+4*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+5*?row_bytes], >[canvas+5*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+6*?row_bytes], >[canvas+6*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+7*?row_bytes], >[canvas+7*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+8*?row_bytes], >[canvas+8*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+9*?row_bytes], >[canvas+9*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+10*?row_bytes], >[canvas+10*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+11*?row_bytes], >[canvas+11*?row_bytes]   ; last mode line
?lines_end
    .BYTE ?jvb, <dlist, >dlist                               ; Jump to vertical blank

; view_h (main.asm) = number of mode lines; scroll_lu/rd move exactly view_h LMS addresses
.IF [?lines_end-dlist-3]/3-view_h
    .ERROR "view_h must equal the number of mode lines in the display list"
.ENDIF
