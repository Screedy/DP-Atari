# Design decisions

Small implementation choices that were compared before deciding, with the reasoning, so they can be revisited later.

## Keyboard keys in `read_input`: compare chain instead of a lookup table

`read_input` (in `src/main.asm`) returns the player's direction in the same bit format as the joystick register `STICK0`. When a key is held, it has to turn the keyboard code from `KBCODE` into one of four direction values. Two ways of doing that were compared.

### Version A: lookup table with a search loop (the first implementation)

```asm
    ldx #3                      ; search the 4 known keys, from the last one
?find
    cmp ?keys,x                 ; is it this key?
    beq ?key                    ; yes: X = its index
    dex
    bpl ?find
?stick
    lda STICK0                  ; no (known) key: joystick
    rts
?key
    lda ?masks,x                ; the STICK0 value this key stands for
    rts
?keys
    .BYTE key_w, key_s, key_a, key_d
?masks
    .BYTE %1110, %1101, %1011, %0111    ; up, down, left, right
```

### Version B: one compare per key (the current implementation)

```asm
    cmp #key_w                  ; W?
    beq ?up
    cmp #key_s                  ; S?
    beq ?down
    cmp #key_a                  ; A?
    beq ?left
    cmp #key_d                  ; D?
    beq ?right
?stick
    lda STICK0                  ; no (known) key: joystick
    rts
?up
    lda #%1110                  ; what STICK0 reads when pushed up
    rts
    ...                         ; ?down, ?left, ?right the same way
```

### Speed

The table below counts CPU cycles from the moment the key code is in A until the routine returns. The part before that (reading `SKSTAT` and `KBCODE`) is the same in both versions.

| Key held | Version B (compares) | Version A (table) |
|---|---|---|
| W | 13 | 52 |
| S | 17 | 41 |
| A | 21 | 30 |
| D | 25 | 19 |
| no key / other key | 26 | 55 |

In version B, every key that does not match costs 4 cycles (an immediate `cmp` and a `beq` that is not taken), and the matching key adds the taken `beq`, an immediate `lda` and the `rts`. In version A, every pass of the search loop costs 11 cycles (`cmp abs,X`, `beq`, `dex`, `bpl`), and the result has to be loaded from a second table. The loop counts down from the last key, so version A is only faster for the key it checks first (D), and only by 6 cycles.

With two more keys planned (six in total), the worst case would be about 34 cycles for version B and about 77 for version A.

Both numbers are negligible in practice. `read_input` runs once per pass of the game loop, that is once per frame, and a frame has roughly 30,000 CPU cycles, so either version uses well under half a percent of it.

### Size

Version B costs about 7 bytes per key (a compare and a branch, plus a load and a return for the result). Version A costs 2 bytes per key (one entry in each table) plus about 14 bytes for the loop. With six keys, version A would be about 15 bytes smaller, which does not matter with around 30 KB of free memory. Version B also does not use the X register, so it destroys only A.

### Decision

Version B, the compare chain, was chosen. It is faster for every key, it is easier to read, and it fits the keys that will be added next. Those are likely to be action keys (for example "interact" or "open door") rather than directions, so they cannot be expressed as a `STICK0` value and would not fit into the mask table anyway. With the compare chain, a new key is simply another `cmp` and `beq` that branches to whatever handling it needs.

A lookup table would become the better choice only if there were many keys that all map to values of the same kind, for example a dozen keys each selecting a menu item.
