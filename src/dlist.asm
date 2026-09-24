; dlist.asm - Atari 8-bit display list definition

    .LOCAL              ; start of local scrope for display list definition

?blank8 = $70            ; 8 blank lines
?lms = $40               ; Načíst adresu z paměti (Load Memory Scan)
?jvb = $41               ; Skok při vertikálním blanku

?antic2 = 2              ; Antic mode 2
?antic5 = 5              ; Antic mode 5

setup_screen
    lda RTCLOK+2            ; $14 - frame counter
?wait
    cmp RTCLOK+2            ; čekat, až VBI proběhne
    beq ?wait
    MWA ?dlist SDLSTL       ; teď je jistě čas do dalšího VBI, takže můžeme nastavit display list
    rts

?dlist
    .BYTE ?blank8, ?blank8, ?blank8                            ; 24 blank lines
    .BYTE ?antic5+?lms, <screen, >screen                      ; screen mode, address, left shift and right shift
    .BYTE ?antic5, ?antic5, ?antic5, ?antic5, ?antic5, ?antic5
    .BYTE ?antic5, ?antic5, ?antic5, ?antic5, ?antic5

    .BYTE ?jvb, <?dlist, >?dlist                               ; Jump to vertical blank

    .LOCAL