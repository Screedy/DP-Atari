; Vstup: A = kód znaku, X = low byte zdrojových dat, Y = high byte
; Zapíše 8 bytů do RAM fontu na správnou pozici

WRITE_CUSTOM_CHAR:
        ; vypočti cílovou adresu: $0800 + (A * 8)
        ASL A           ; × 2
        ASL A           ; × 4
        ASL A           ; × 8
        CLC
        ADC #$00        ; low byte offsetu
        STA DST
        LDA #$08        ; high byte základní adresy ($0800)
        ADC #$00        ; přičti případný přenos
        STA DST+1

        ; kopíruj 8 bytů ze zdroje
        LDY #$00
.COPY:
        LDA (SRC),Y
        STA (DST),Y
        INY
        CPY #$08
        BNE .COPY
        RTS