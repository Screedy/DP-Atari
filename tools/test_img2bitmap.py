#!/usr/bin/env python3
"""Self-check for img2bitmap.py: write tiny PNGs (indexed and RGB), read them back, pack,
lay out the rows and rebuild the picture from the layout (and from the real logo)."""

import re
import struct
import zlib

from img2bitmap import PALETTE, dlist_asm, layout, pack, read_png


def chunk(kind, body):
    return (
        struct.pack(">I", len(body))
        + kind
        + body
        + struct.pack(">I", zlib.crc32(kind + body))
    )


def png(w, h, ctype, depth, raw_rows):
    """Minimal PNG writer (only for this test); raw_rows already carry their filter byte."""
    ihdr = struct.pack(">IIBBBBB", w, h, depth, ctype, 0, 0, 0)
    plte = chunk(b"PLTE", bytes(12)) if ctype == 3 else b""

    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + plte
        + chunk(b"IDAT", zlib.compress(b"".join(raw_rows)))
        + chunk(b"IEND", b"")
    )


def indexed(rows, depth):
    """Row 0 unfiltered, row 1 with the "up" filter (difference to the row above)."""
    per, out, prev = 8 // depth, [], None

    for row in rows:
        line = bytearray((len(row) * depth + 7) // 8)

        for x, v in enumerate(row):
            line[x // per] |= v << (8 - depth * (x % per + 1))
        if prev is None:
            out.append(b"\0" + bytes(line))
        else:
            out.append(b"\2" + bytes((v - prev[i]) & 255 for i, v in enumerate(line)))
        prev = line
    return out


def rgb(rows, channels):
    """Every row with the "sub" filter (difference to the pixel on the left: bpp = channels)."""
    out = []

    for row in rows:
        line = b"".join(bytes(PALETTE[v] + (255,) * (channels - 3)) for v in row)

        out.append(
            b"\1"
            + bytes(
                (v - (line[i - channels] if i >= channels else 0)) & 255
                for i, v in enumerate(line)
            )
        )

    return out


def rebuild(data, asm, width):
    """Read the generated display list like ANTIC: LMS lines read `width` bytes, blank
    lines read nothing. Returns the rows it would show (None = blank)."""
    shown = []

    for line in asm.splitlines():
        if m := re.search(r"logo_bitmap\+(\d+)\]", line):
            shown.append(data[int(m.group(1)) : int(m.group(1)) + width])
        elif m := re.match(r"\s+\.BYTE \$([0-7])0\s", line):
            shown += [None] * (int(m.group(1)) + 1)

    return shown


# PNG reading and packing
rows = [[0, 1, 2, 3, 3, 2, 1, 0], [1, 1, 1, 1, 0, 0, 0, 3]]

for depth in (2, 8):
    assert read_png(png(8, 2, 3, depth, indexed(rows, depth))) == (8, 2, rows, 0), depth

for ctype, channels in ((2, 3), (6, 4)):
    assert read_png(png(8, 2, ctype, 8, rgb(rows, channels))) == (8, 2, rows, 0), ctype

assert pack(rows) == bytes([0b00011011, 0b11100100, 0b01010101, 0b00000011])


# layout: white top/bottom cropped, white inside = blank, repeat = same offset, overlap
z, a, b = bytes(4), bytes([0, 0, 1, 2]), bytes([2, 0, 0, 0])
data, lines = layout([z, a, z, a, b, z])

assert lines == [0, None, 0, 3] and data == bytes([0, 0, 1, 2, 0, 0, 0]), (lines, data)

assert rebuild(data, dlist_asm(lines, len(data), "test"), 4) == [a, None, a, b]

# the real logo: the generated files must show exactly the picture
_, _, logo, _ = read_png(open("assets/logo.png", "rb").read())
packed = [pack([row]) for row in logo]

while not any(packed[0]):
    packed.pop(0)
while not any(packed[-1]):
    packed.pop()

shown = rebuild(
    open("assets/logo.bin", "rb").read(), open("assets/logo_dlist.asm").read(), 40
)

assert shown == [
    row if any(row) else None for row in packed
], "logo.bin/logo_dlist.asm out of date"

print("ok")
