# Oživení historického koutku katedry informatiky

Prezentační aplikace pro osmibitový počítač **Atari 130XE** demonstrující grafické a zvukové možnosti dobového hardware.

**Klíčová slova:** Atari 130XE · assembler 6502 · retro computing · grafické režimy GTIA/ANTIC · POKEY

---

## O projektu

Aplikace provází uživatele interaktivní mapou budovy fakulty, kde každá místnost představuje ukázku konkrétní hardwarové techniky — od grafických režimů čipů GTIA a ANTIC přes čtyřhlasý zvukový syntezátor POKEY až po pokročilé metody jako přerušení displeje (DLI) nebo přepínání paměťových bank. Každá ukázka je doplněna didaktickým výkladem zasazujícím techniku do historického kontextu.

Aplikace má tři hlavní stavy:

- **Attractor mód** — automatická prezentace běžící při nečinnosti
- **Mapa budovy** — interaktivní top-down navigace po budově fakulty
- **Ukázková místnost** — dedicated demo konkrétní hardwarové techniky s info panelem

---

## Hardware a požadavky

| Komponenta | Popis |
|---|---|
| Počítač | Atari 130XE (nebo kompatibilní 800XL) |
| Procesor | MOS 6502C @ 1,79 MHz |
| RAM | 128 KB (64 KB základní + 64 KB rozšířená) |
| Klávesnice | Moderní USB klávesnice s adaptérem na joystick port |
| Síťový modul | FujiNet (volitelné — pro načítání obsahu ze sítě) |

---

## Struktura repozitáře

```
/
├── src/
│   ├── main.asm          ; hlavní vstupní bod, stavový automat
│   ├── attractor/        ; attractor mód — grafické efekty, zvuk
│   ├── map/              ; mapa budovy, pohyb hráče
│   ├── rooms/            ; jednotlivé ukázkové místnosti
│   │   ├── room_pc.asm       ; počítačová učebna — P/M grafika
│   │   ├── room_server.asm   ; serverovna — DLI, horizontal scroll
│   │   ├── room_office.asm   ; kancelář — POKEY syntezátor
│   │   ├── room_seminar.asm  ; seminární místnost — mixed display list
│   │   ├── room_hall.asm     ; chodba / exteriér — vertical scroll
│   │   └── room_secret.asm   ; tajná místnost — bankswitching
│   ├── charset/          ; custom český charset (8×8 px, 1 KB)
│   ├── display_list/     ; display list rutiny a DLI handlery
│   └── lib/              ; sdílené rutiny (VBI, SIO, vstupy)
├── assets/
│   ├── charset.bin       ; binární data českého fontu
│   ├── maps/             ; data herních map (tile-based)
│   └── music/            ; POKEY hudební data
├── tools/
│   └── charset_editor/   ; pomocný nástroj pro editaci fontu
├── docs/
│   ├── memory_map.md     ; přehled paměťové mapy aplikace
│   ├── display_list.md   ; dokumentace display listů
│   └── hardware_notes.md ; poznámky k hardware registrům
└── README.md
```

---

## Sestavení

Projekt používá assembler **MADS** (Mad Assembler). Sestavení na PC:

```bash
mads main.asm -o build/prezentace.xex
```

Výstupní soubor `.xex` lze spustit přímo na Atari nebo nahrát přes FujiNet. Pro vývoj a testování je doporučen emulátor **Altirra**.

### Doporučené nástroje

| Nástroj | Účel |
|---|---|
| [MADS](http://mads.atari8.info) | Assembler pro 6502 |
| [Altirra](https://www.virtualdub.org/altirra.html) | Emulátor Atari (Windows) |
| [Atasm](https://atasm.sourceforge.net) | Alternativní assembler |
| [FujiNet](https://fujinet.online) | Síťový modul pro Atari |

---

## Klíčové hardwarové adresy

| Adresa | Registr | Popis |
|---|---|---|
| `$02F4` | `CHBAS` | Pointer na charset (shadow) |
| `$0230` | `SDLSTL/H` | Pointer na display list (shadow) |
| `$D000–$D00F` | GTIA | Kolize, barvy hráčů |
| `$D01A` | `COLBK` | Barva pozadí |
| `$D200–$D20F` | POKEY | Zvukové kanály |
| `$D400–$D40F` | ANTIC | Display list, scroll registry |
| `$DC00` | PIA port A | Joystick vstupy |
| `$FFFF` | `PORTB` | Přepínání paměťových bank (130XE) |

---

## Literatura

- Collins, J. (1984): *Atari Color Graphics — A Beginner's Workbook*
- Dočekal, P. (1987): *Adresy paměti počítačů ATARI 600XL/800XL*
- Hales, S. (1982): *SynAssembler Manual*
- Inman, D. & Inman, K. (1981): *The Atari Assembler*
- Moore, H., Lower, J., Albrecht, B. (1982): *Atari Sound and Graphics*
- Schreiber, L. (1983): *Advanced Programming Techniques for Your Atari*
- Stanton, J. & Pinal, D. (1983): *Atari Graphics and Arcade Game Design*

---

## Licence

Projekt vznikl jako diplomová práce na katedře informatiky UPOL (https://www.inf.upol.cz/). Zdrojové kódy jsou dostupné pro studijní účely.