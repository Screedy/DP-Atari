#!/usr/bin/env python3
"""Convert a PNG to an ANTIC mode E (GR.15) picture: bitmap data + display list.

Usage: python3 tools/img2bitmap.py assets/logo.png assets/logo
       (writes assets/logo.bin and assets/logo_dlist.asm)

The PNG must be 160 px wide, non-interlaced, 8 bits per channel if not indexed.
Pixel value (0 = COLOR4 background, 1 = COLOR0, 2 = COLOR1, 3 = COLOR2):
  - indexed PNG: the palette index
  - RGB / RGBA PNG (e.g. from Affinity): the nearest colour in PALETTE below

Every line of the picture gets its own LMS in the display list, so the data only has
to hold what is not white, and each distinct row only once (see layout()):
  - white rows at the top and bottom are cropped (the screen centres the rest),
  - white rows inside become blank display-list lines (no data at all),
  - a row that already appears anywhere in the data (a repeated row, or bytes left by
    two overlapping rows) is not stored again: its LMS points there,
  - a new row starts inside the end of the previous one when the bytes match (e.g. the
    white right margin of one row = the white left margin of the next).
A row is 40 bytes, 4 pixels per byte, left pixel in the 2 highest bits.
Standard library only. The first version (one plain bitmap) is in tools/legacy/.
"""

import struct
import sys
import zlib

WIDTH = 160

# RGB colours for pixel values 0-3 (the editor colours of assets/logo.png; the Atari
# colours themselves are set in src/attractor/logo.asm)
PALETTE = [(255, 255, 255), (29, 29, 27), (28, 100, 162), (190, 190, 190)]
#               white           black         UPOL blue      light gray


def nearest(rgb):
    """Pixel value of the PALETTE colour closest to rgb."""
    return min(
        range(4), key=lambda i: sum((a - b) ** 2 for a, b in zip(rgb, PALETTE[i]))
    )


def read_png(data):
    """Return (width, height, [[pixel value, ...] per row], inexact pixel count)."""
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG file")

    pos, idat = 8, b""

    while pos < len(data):
        length, kind = struct.unpack(">I4s", data[pos : pos + 8])
        body = data[pos + 8 : pos + 8 + length]
        pos += 12 + length

        if kind == b"IHDR":
            w, h, depth, ctype, _, _, interlace = struct.unpack(">IIBBBBB", body)
        elif kind == b"IDAT":
            idat += body

    channels = {3: 1, 2: 3, 6: 4}.get(ctype)  # indexed, RGB, RGBA
    if channels is None:
        raise ValueError("PNG must be indexed, RGB or RGBA")
    if ctype != 3 and depth != 8:
        raise ValueError("RGB/RGBA PNG must have 8 bits per channel")
    if interlace:
        raise ValueError("interlaced PNG is not supported")

    raw = zlib.decompress(idat)
    stride = (w * channels * depth + 7) // 8
    bpp = max(
        1, channels * depth // 8
    )  # bytes per pixel, as the row filters count them
    prev, rows, p, inexact = bytearray(stride), [], 0, 0

    for _ in range(h):
        f, line = raw[p], bytearray(raw[p + 1 : p + 1 + stride])
        p += 1 + stride

        for i in range(stride):  # undo the row filter
            a = line[i - bpp] if i >= bpp else 0
            b, c = prev[i], prev[i - bpp] if i >= bpp else 0
            if f == 1:
                line[i] = (line[i] + a) & 255
            elif f == 2:
                line[i] = (line[i] + b) & 255
            elif f == 3:
                line[i] = (line[i] + (a + b) // 2) & 255
            elif f == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                line[i] = (
                    line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)
                ) & 255

        prev = line

        if ctype == 3:
            per, mask = 8 // depth, (1 << depth) - 1
            rows.append(
                [
                    (line[x // per] >> (8 - depth * (x % per + 1))) & mask
                    for x in range(w)
                ]
            )
        else:
            rgb = [tuple(line[x * channels : x * channels + 3]) for x in range(w)]
            inexact += sum(c not in PALETTE for c in rgb)
            rows.append([nearest(c) for c in rgb])
    return w, h, rows, inexact


def pack(rows):
    """4 pixels (2 bits each) per byte, left pixel in the high bits."""
    out = bytearray()
    for row in rows:
        for x in range(0, len(row), 4):
            a, b, c, d = row[x : x + 4]
            out.append(a << 6 | b << 4 | c << 2 | d)
    return bytes(out)


def layout(rows):
    """Lay out packed 40-byte rows. Returns (data, lines): lines is a list of
    data offsets (one per picture line) and None for a white line (a blank line)."""
    while rows and not any(rows[0]):
        rows = rows[1:]  # crop white rows at the top...
    while rows and not any(rows[-1]):
        rows = rows[:-1]  # ...and at the bottom

    data, lines = bytearray(), []

    for row in rows:
        if not any(row):
            lines.append(None)  # white: blank line, no data
            continue

        at = data.find(row)

        if at < 0:  # new row: overlap as much of its start as
            k = next(k for k in range(len(row), -1, -1) if data.endswith(row[:k]))
            at = len(data) - k  #   matches the end of the data so far
            data += row[k:]

        lines.append(at)

    return bytes(data), lines


def dlist_asm(lines, data_len, source):
    """Display-list body for src/attractor/logo.asm, as the macro LOGO_DLIST."""
    out = [
        f"; GENERATED by tools/img2bitmap.py from {source} - do not edit, run the tool again",
        f"logo_lines      = {len(lines)}           ; picture lines (white rows at the top/bottom cropped)",
        f"logo_data_len   = {data_len}          ; bytes of bitmap data",
        "",
        ".MACRO LOGO_DLIST",
    ]
    i = 0

    while i < len(lines):
        if lines[i] is None:  # a run of white lines: blank n = (n-1)*16, n <= 8
            n = 1

            while n < 8 and i + n < len(lines) and lines[i + n] is None:
                n += 1

            out.append(
                f"    .BYTE ${(n - 1) * 16:02X}                   ; {n} blank line(s)"
            )
            i += n
        else:  # mode E ($0E) + LMS ($40) + address
            out.append(
                f"    .BYTE $4E, <[logo_bitmap+{lines[i]}], >[logo_bitmap+{lines[i]}]"
            )
            i += 1
    out.append(".ENDM")
    return "\n".join(out) + "\n"


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)

    try:
        w, h, rows, inexact = read_png(open(sys.argv[1], "rb").read())
    except ValueError as e:
        sys.exit(f"{sys.argv[1]}: {e}")

    if w != WIDTH:
        sys.exit(f"{sys.argv[1]}: width {w}, must be {WIDTH}")

    if inexact:  # e.g. anti-aliased edges: snapped, but worth a look in the editor
        print(
            f"{sys.argv[1]}: warning: {inexact} pixels not exactly a PALETTE colour, "
            "used the nearest (turn off anti-aliasing?)"
        )

    bad = {i for row in rows for i in row if i > 3}
    if bad:
        sys.exit(f"{sys.argv[1]}: palette index {max(bad)} used, only 0-3 allowed")
    data, lines = layout([pack([row]) for row in rows])

    open(sys.argv[2] + ".bin", "wb").write(data)
    open(sys.argv[2] + "_dlist.asm", "w").write(
        dlist_asm(lines, len(data), sys.argv[1])
    )
    print(
        f"{sys.argv[2]}.bin: {len(lines)} lines ({lines.count(None)} blank), "
        f"{len(data)} bytes (plain bitmap: {h * WIDTH // 4})"
    )


if __name__ == "__main__":
    main()
