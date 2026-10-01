from memmap import parse_xex, parse_lab, lst_overwrites, report


def seg(start, end):
    return bytes([start & 0xFF, start >> 8, end & 0xFF, end >> 8]) + bytes(end - start + 1)


xex = b"\xff\xff" + seg(0x2000, 0x20FF) + seg(0x2080, 0x217F) + bytes([0xE0, 0x02, 0xE1, 0x02, 0x00, 0x20])
segs = parse_xex(xex)
assert [(s, e) for s, e, _ in segs] == [(0x2000, 0x20FF), (0x2080, 0x217F), (0x02E0, 0x02E1)]

text, bad = report(segs, parse_lab("2000 START\n4000 SCREEN\n"))
assert bad and "!! SEGMENT OVERLAP $2000-$20FF with $2080-$217F" in text
assert "RUNAD: $2000" in text and "$4000  SCREEN" in text

_, bad = report(parse_xex(b"\xff\xff" + seg(0x2000, 0x20FF) + seg(0x2100, 0x21FF)), [])
assert not bad

lst = """Source: main.asm
15 2000  20 25 20  START     jsr setup_screen
16 2003  A9 50            lda #>charset

Source: gfx.asm
4 2002  00 00 00      .byte 0,0,0
134 02E0  00 20      .RUN start
135 02E0  00 20      .RUN start
"""
text, _ = report(parse_xex(b"\xff\xff" + seg(0x2000, 0x20FF)), parse_lab("2000 START\n2080 LOOP\n"), verbose=2)
assert "$2000 │" + "A" * 32 + "B" * 32 + "│ A START  B LOOP" in text
assert "├─ $2000-$20FF 256 B" in text and "⋮" in text

assert lst_overwrites(lst) == [(0x2002, 0x2004, "main.asm:15", "gfx.asm:4")]
print("ok")

import memmap
src = (parse_xex(b"\xff\xff" + seg(0x2000, 0x20FF)), parse_lab("2000 START\n2080 LOOP\n"))
assert "\x1b" not in report(*src, verbose=2)[0]
memmap.COLOR = True
text, _ = report(*src, verbose=2)
memmap.COLOR = False
assert "\x1b[36mAAAA" in text and "\x1b[36mA START\x1b[0m" in text     # letter and legend share color
assert "\x1b[32mBBBB" in text and "\x1b[32mB LOOP\x1b[0m" in text
print("color ok")

# NAME_LEN reservations
pmg = parse_xex(b"\xff\xff" + seg(0x6000, 0x601F))
text, bad = report(pmg, parse_lab("6000 PMGDATA\n0400 PMGDATA_LEN\n4000 SCREEN\n01E0 SCREEN_LEN\n"))
assert not bad                                                  # own segment inside own area is fine
assert "$6000-$63FF    1024 B  PMGDATA" in text and "$4000-$41DF     480 B  SCREEN" in text
assert "  $6400-$BC1F" in text and "$41E0-$5FFF" in text         # free RAM excludes reservations
assert "PMGDATA_LEN" not in text and "size unknown" not in text
text, bad = report(parse_xex(b"\xff\xff" + seg(0x4100, 0x41FF)), parse_lab("4000 SCREEN\n01E0 SCREEN_LEN\n"))
assert bad and "!! LOADED INTO SCREEN $4000-$41DF 480 B: segment $4100-$41FF" in text
print("reserve ok")

# machine profiles
low = parse_xex(b"\xff\xff" + seg(0x1000, 0x10FF))
text, bad = report(low, [])
assert bad and "!! LOADED INTO DOS 2.5 $0700-$1FFF 6400 B: segment $1000-$10FF" in text
assert "  $0080-$00FF     128 B" in text and "  $0480-$06FF     640 B" in text   # page 6 & co. free
text, bad = report(low, [], machine="130xe-nodos")
assert not bad and "  $0480-$0FFF" in text
_, bad = report(parse_xex(b"\xff\xff" + seg(0xC000, 0xC0FF)), [])
assert bad
text, bad = report(pmg, parse_lab("4000 SCREEN\n8000 SCREEN_LEN\n"))
assert bad and "!! RESERVED OVERLAP SCREEN $4000-$BFFF" in text
print("machine ok")

# -vvv: every page at true scale
import re
text, _ = report(pmg, parse_lab("6000 PMGDATA\n"), verbose=3)
assert len(re.findall(r"\$[0-9A-F]{2}00 │", text)) == 256 and "⋮" not in text
print("vvv ok")

# -d: diagram only, any verbosity
for v in (0, 1, 2, 3):
    text, _ = report(pmg, parse_lab("6000 PMGDATA\n"), verbose=v, diagram_only=True)
    assert text.startswith("      ┌") and "Segments" not in text and "Free RAM" not in text
    assert ("A PMGDATA" in text) == (v >= 2)
    assert (len(re.findall(r"\$[0-9A-F]{2}00 │", text)) == 256) == (v == 3)
print("diagram-only ok")
