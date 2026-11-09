#!/usr/bin/env python3
"""LEGACY (first version, kept for comparison in the thesis; not used by the build).

Writes the whole picture as one plain bitmap: every row 40 bytes, white rows included
(assets/legacy/logo.bin = 5440 bytes). Replaced by tools/img2bitmap.py, which gives
every line its own LMS, leaves out white rows and stores repeated rows only once.

Usage: python3 tools/legacy/img2bitmap.py assets/legacy/logo.png assets/legacy/logo.bin

Convert a PNG to an ANTIC mode E (GR.15) bitmap.

The PNG must be 160 px wide, non-interlaced, 8 bits per channel if not indexed.
Pixel value (0 = COLOR4 background, 1 = COLOR0, 2 = COLOR1, 3 = COLOR2):
  - indexed PNG: the palette index
  - RGB / RGBA PNG (e.g. from Affinity): the nearest colour in PALETTE below
Output: 40 bytes per row, 4 pixels per byte, left pixel in the 2 highest bits.
Standard library only.
"""

import struct
import sys
import zlib

WIDTH = 160

# RGB colours for pixel values 0-3 (the editor colours of assets/logo.png. The Atari
# colours themselves are set in src/attractor/logo.asm)
PALETTE = [(255, 255, 255), (29, 29, 27), (28, 100, 162), (190, 190, 190)]
#               white           black         UPOL blue       light gray


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
    open(sys.argv[2], "wb").write(pack(rows))
    print(f"{sys.argv[2]}: {h} lines, {h * WIDTH // 4} bytes")


if __name__ == "__main__":
    main()
