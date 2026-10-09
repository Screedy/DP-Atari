; dlist.asm - Atari 8-bit display list definition

    .LOCAL              ; start of local scrope for display list definition

?blank8 = $70            ; 8 blank lines
?lms = $40               ; Načíst adresu z paměti (Load Memory Scan)
?jvb = $41               ; Skok při vertikálním blanku

?antic2 = 2              ; Antic mode 2
?antic5 = 5              ; Antic mode 5
?row_bytes = canvas_w    ; canvas bytes per mode line (LMS on every line, scroll_lu/rd move them)

setup_screen
    lda RTCLOK+2            ; $14 - frame counter
?wait
    cmp RTCLOK+2            ; čekat, až VBI proběhne
    beq ?wait
    MWA dlist SDLSTL       ; teď je jistě čas do dalšího VBI, takže můžeme nastavit display list
    rts

dlist
    .BYTE ?blank8, ?blank8, ?blank8                            ; 24 blank lines
    .BYTE ?antic5+?lms, <[canvas+0*?row_bytes], >[canvas+0*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+1*?row_bytes], >[canvas+1*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+2*?row_bytes], >[canvas+2*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+3*?row_bytes], >[canvas+3*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+4*?row_bytes], >[canvas+4*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+5*?row_bytes], >[canvas+5*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+6*?row_bytes], >[canvas+6*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+7*?row_bytes], >[canvas+7*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+8*?row_bytes], >[canvas+8*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+9*?row_bytes], >[canvas+9*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+10*?row_bytes], >[canvas+10*?row_bytes]
    .BYTE ?antic5+?lms, <[canvas+11*?row_bytes], >[canvas+11*?row_bytes]
    .BYTE ?jvb, <dlist, >dlist                               ; Jump to vertical blank
