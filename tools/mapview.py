#!/usr/bin/env python3
"""Print an overview picture of a tile map.

Usage: python3 tools/mapview.py src/maps/university_outside.asm

Map rows are the tiles under each indented "    ; row N" comment of the map file
(a row may span several .BYTE lines). Every tile is shown as one character, see SYMBOLS.
"""
import re
import sys
from pathlib import Path

# One character per tile name; add new tiles here (see src/tiles.asm)
SYMBOLS = {
    "EMP": ".",
    "BRA": "A", "BRB": "B", "BRC": "C",
    "WNL": "[", "WNR": "]",
    "LWL": "(", "LWR": ")",
    "FLW": "_",
}
ROW = re.compile(r"^\s+;\s*row \d+")        # indented row comment, e.g. "    ; row 4: building"
BYTES = re.compile(r"^\s*\.BYTE\s+(.*)", re.I)


def parse_rows(text):
    """Return [[tile name, ...] per map row]."""
    rows = []
    for line in text.splitlines():
        if ROW.match(line):
            rows.append([])
            continue
        m = BYTES.match(line.split(";")[0])
        if m and rows:
            rows[-1] += [t.strip() for t in m.group(1).split(",") if t.strip()]
    return rows


def picture(rows):
    """Column ruler + one line per map row."""
    width = max(map(len, rows))
    out = ["          " + "".join(str(c // 10) if c % 10 == 0 else " " for c in range(width)).rstrip(),
           "          " + "".join(str(c % 10) for c in range(width))]
    out += [f"row {i:2}    " + "".join(SYMBOLS.get(t, "?") for t in row) for i, row in enumerate(rows)]
    return out


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    path = Path(sys.argv[1])
    rows = parse_rows(path.read_text())
    if not rows:
        sys.exit(f"{path}: no '    ; row N' rows found")
    unknown = sorted({t for row in rows for t in row} - SYMBOLS.keys())
    if unknown:
        print(f"warning: no symbol for {', '.join(unknown)} (shown as ?); add them to SYMBOLS", file=sys.stderr)
    if len({len(r) for r in rows}) > 1:
        print(f"warning: rows have different lengths: {[len(r) for r in rows]}", file=sys.stderr)
    print(f"{path.name}: {len(rows)} rows x {max(map(len, rows))} tiles")
    print("legend: " + "  ".join(f"{s} {n}" for n, s in SYMBOLS.items()) + "  ? unknown")
    print("\n".join(picture(rows)))


if __name__ == "__main__":
    main()
