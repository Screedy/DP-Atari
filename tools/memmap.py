#!/usr/bin/env python3
"""Print a memory map of an atasm build from the .xex, .lab (labels) and .lst (listing).

Usage: python3 tools/memmap.py [-v|-vv] [out/main.xex] > memmap.txt
.lab/.lst are looked up next to the .xex and are optional.
Exit code 1 on any overlap.
Colors only on a terminal (off when redirected or NO_COLOR is set).

Two overlap checks, because they catch different things:
- .lst: atasm assembles into ONE memory image, so code overwritten by a later `* =`
  never shows up in the .xex (only as "over-written" warnings). The listing still has
  both writes, with source file:line.
- .xex: separate segments loading over each other (e.g. atasm -a autobank, multiple builds).
"""

import argparse
import os
import re
import sys
from itertools import groupby, zip_longest
from pathlib import Path

# System memory per machine: (lo, hi, name). Loading or reserving over these is an error.
MACHINES = {
    "130xe": [  # loaded from DOS 2.5, BASIC off (normal for a game xex)
        (0x0000, 0x007F, "OS zero page"),
        (0x0100, 0x01FF, "stack"),
        (0x0200, 0x047F, "OS vars + buffers"),
        (
            0x0700,
            0x1FFF,
            "DOS 2.5",
        ),  # ponytail: real MEMLO ~$1D7C, rounded up to the usual $2000
        (0xBC20, 0xBFFF, "OS screen GR.0"),  # free once your own display list runs
        (0xC000, 0xCFFF, "OS ROM"),
        (0xD000, 0xD7FF, "I/O (GTIA POKEY PIA ANTIC)"),
        (0xD800, 0xFFFF, "FP + OS ROM"),
    ],
}
# emulator / FujiNet direct load, no DOS in memory
MACHINES["130xe-nodos"] = [r for r in MACHINES["130xe"] if r[2] != "DOS 2.5"]
VECTORS = {0x02E0: "RUNAD", 0x02E2: "INITAD"}
COLS = 64  # diagram width, 1 char = 256 / COLS bytes
LETTERS = "ABCDEFGHIJKLMNOPQSTUVWXYZabcdefghijklmnopqstuvwxyz0123456789"  # no r/R: 'r' = runtime
LST_LINE = re.compile(r"(\d+) ([0-9A-F]{4})  ((?:[0-9A-F]{2} )*[0-9A-F]{2})")

# ANSI SGR codes; red and yellow are reserved for overlap / runtime
COLOR = False  # set by main() when stdout is a terminal
PALETTE = ["36", "32", "35", "34", "96", "92", "95", "94"]
DIM, BOLD, RUNTIME, BAD, WARN, SYS = "2", "1", "33", "97;41", "1;31", "90"
ANSI = re.compile(r"\x1b\[[0-9;]*m")


def paint(text, code):
    return f"\x1b[{code}m{text}\x1b[0m" if COLOR and code and text else text


def visible_len(s):
    return len(ANSI.sub("", s))


def parse_xex(data):
    """Return list of (start, end, bytes) for every segment."""
    segs, i = [], 0

    while i + 4 <= len(data):
        if data[i : i + 2] == b"\xff\xff":
            i += 2
            continue

        start = data[i] | data[i + 1] << 8
        end = data[i + 2] | data[i + 3] << 8

        if end < start:
            raise ValueError(
                f"bad segment header at file offset {i}: ${start:04X}-${end:04X}"
            )

        i += 4
        segs.append((start, end, data[i : i + end - start + 1]))
        i += end - start + 1
    return segs


def parse_lab(text):
    """atasm .lab lines are 'hhhh NAME'. Returns sorted [(addr, name)]."""
    labels = []
    for line in text.splitlines():
        parts = line.split()
        # Ignore lines that don't have at least two parts
        if len(parts) == 2:
            try:
                labels.append((int(parts[0], 16), parts[1]))
            except ValueError:
                pass
    return sorted(labels)


def lst_overwrites(text):
    """Addresses emitted twice in an atasm -g listing -> [(lo, hi, first_src, second_src)]."""
    seen = {}
    hits = []
    src = "?"

    for line in text.splitlines():
        if line.startswith("Source: "):
            src = line[8:]
            continue

        m = LST_LINE.match(line)

        if not m:
            continue

        where = f"{src}:{m[1]}"

        for k in range(len(m[3].split())):
            addr = int(m[2], 16) + k

            if 0x02E0 <= addr <= 0x02E3:  # RUNAD/INITAD are rewritten on purpose
                continue

            if addr in seen:
                if hits and hits[-1][1] == addr - 1:
                    hits[-1][1] = addr
                else:
                    hits.append([addr, addr, seen[addr], where])

            seen[addr] = where

    return [tuple(h) for h in hits]


def rt_title(lo, hi, name):
    return (
        f"{name} ${lo:04X}-${hi:04X} {hi - lo + 1} B" if hi > lo else f"{name} (size?)"
    )


def short_title(lo, hi, name):
    return f"{name} {hi - lo + 1} B" if hi > lo else f"{name} ?"


def diagram(data, spans, rt, system, bad, vv, seg_color, tags, tag_color, expand=False):
    """Vertical memory picture: 1 row = 256 B page, separator line at every block change.
    Areas that are fully free or fully system shrink to their separator line.
    rt = [(lo, hi, name)] reserved areas (NAME_LEN) and size-unknown runtime symbols (lo == hi).
    system = [(lo, hi, name)] machine areas (MACHINES).
    """
    step = 256 // COLS

    def cell(lo):
        """-> (char, color code)"""
        hi = lo + step - 1

        if any(s <= hi and e >= lo for s, e in bad):
            return "!", BAD

        if vv:
            # ponytail: one char = 4 B, so a label starting mid-cell wins and tiny neighbours can hide; legend still lists them
            hit = [n for s, _, n in spans if lo <= s <= hi] or [
                n for s, e, n in spans if s <= lo <= e
            ]
            if hit:
                return tags[hit[-1]], tag_color[hit[-1]]

        seg = [(s, e) for s, e in data if s <= hi and e >= lo]

        if seg:
            return "#", seg_color[seg[0]]
        if any(s <= hi and e >= lo for s, e, _ in rt):
            return "r", RUNTIME
        if any(s <= hi and e >= lo for s, e, _ in system):
            return "=", SYS
        return "·", DIM

    def row(lo):
        cells = [cell(lo + c * step) for c in range(COLS)]

        return "".join(
            paint("".join(ch for ch, _ in run), code)
            for code, run in groupby(cells, lambda c: c[1])
        )

    def page_row(page):
        lo = page << 8
        note = [
            paint(f"{tags[nm]} {nm}", tag_color[nm])
            for s, _, nm in spans
            if vv and lo <= s <= lo + 255
        ]
        return (
            paint(f"${lo:04X} │", DIM)
            + row(lo)
            + paint("│", DIM)
            + " "
            + "  ".join(note)
        )

    # blocks = what gets one separator: a segment plus reserved areas starting inside it
    # (CHARSET loaded 104 B of its 1 KB), or a reserved area / runtime symbol on its own
    blocks, owned = [], set()
    for s, e in data:
        own = [r for r in rt if s <= r[0] <= e]
        owned.update(own)
        title = [(f"${s:04X}-${e:04X} {e - s + 1} B", seg_color[(s, e)])]
        title += [(short_title(*r), RUNTIME) for r in own if r[1] > e]
        blocks.append((s, max([e] + [r[1] for r in own]), title))
    blocks += [(r[0], r[1], [(short_title(*r), RUNTIME)]) for r in rt if r not in owned]
    # system areas first so they lead the separator title
    blocks = [
        (lo, hi, [(short_title(lo, hi, n), SYS)]) for lo, hi, n in system
    ] + blocks
    nsys = len(system)  # blocks[:nsys] are system areas

    def key(page):
        lo, hi = page << 8, (page << 8) + 255
        return tuple(i for i, (s, e, _) in enumerate(blocks) if s <= hi and e >= lo)

    def full(page):
        """Page entirely inside one system area and nothing else touching it -> collapsible."""
        lo, hi = page << 8, (page << 8) + 255
        return all(i < nsys for i in key(page)) and any(
            s <= lo and hi <= e for s, e, _ in system
        )

    out = []
    for n, (k, pages) in enumerate(groupby(range(256), key)):
        pages = list(pages)
        runs = [(f, list(r)) for f, r in groupby(pages, full)] if k else [(True, pages)]
        if expand:  # -vvv: every page gets a row, true scale
            runs = [(False, pages)]
        parts = [p for i in k for p in blocks[i][2]] or [
            (f"free {len(pages) * 256} B", DIM)
        ]
        while len(parts) > 1 and len("  ".join(t for t, _ in parts)) > COLS - 5:
            parts = parts[:-1]  # title too long for the box: drop trailing names
            parts[-1] = (parts[-1][0] + " …", parts[-1][1])
        plain = "  ".join(t for t, _ in parts)
        left, right = ("├", "┤") if n else ("┌", "┐")
        # a group that starts collapsed is drawn as just its separator line
        one_line = runs[0][0]
        fill, code = (
            ("═", SYS) if one_line and k else ("┄", DIM) if one_line else ("─", DIM)
        )
        addr = f"${pages[0] << 8:04X} " if one_line else "      "
        out.append(
            paint(addr, DIM)
            + paint(f"{left}{fill} ", code)
            + "  ".join(paint(t, c) for t, c in parts)
            + paint(" " + fill * max(0, COLS - len(plain) - 3) + right, code)
        )
        for is_full, run in runs[one_line:]:
            if is_full:
                text = f"⋮ {len(run) * 256} B".center(COLS)
                out.append(paint(f"${run[0] << 8:04X} │" + text + "│", SYS))
            else:
                out += [page_row(page) for page in run]
    out.append(paint("      └" + "─" * COLS + "┘", DIM))
    out.append(
        f"      1 char = {step} B   "
        + paint("#", PALETTE[0])
        + " loaded  "
        + paint("r", RUNTIME)
        + " reserved/runtime  "
        + paint("=", SYS)
        + " system  "
        + paint("!", BAD)
        + " overlap"
        + ("  A-z labels" if vv else "")
    )
    return out


def report(segs, labels, overwrites=(), verbose=0, machine="130xe", diagram_only=False):
    """-> (text, warnings). Warnings non-empty means an overlap/conflict."""
    system = MACHINES[machine]
    out, data = [], []

    for start, end, body in segs:
        if 0x02E0 <= start and end <= 0x02E3:  # vectors, not data
            for vec, name in VECTORS.items():
                o = vec - start

                if 0 <= o and o + 1 < len(body):
                    out.append(f"{name}: ${body[o] | body[o + 1] << 8:04X}")
            continue
        data.append((start, end))
    data.sort()
    seg_color = {d: PALETTE[i % len(PALETTE)] for i, d in enumerate(data)}

    # NAME_LEN equate => NAME occupies NAME .. NAME+NAME_LEN-1 (for buffers the xex never loads)
    addr_of = {n: a for a, n in labels}
    reserved = sorted(
        (a, a + addr_of[n + "_LEN"] - 1, n)
        for a, n in labels
        if addr_of.get(n + "_LEN", 0) > 0
    )
    labels = [(a, n) for a, n in labels if not n.endswith("_LEN")]

    spans = []  # (lo, hi, label) inside loaded segments
    for start, end in data:
        inside = [(a, n) for a, n in labels if start <= a <= end]
        for k, (a, n) in enumerate(inside):
            spans.append(
                (a, (inside[k + 1][0] if k + 1 < len(inside) else end + 1) - 1, n)
            )
    tags = {n: LETTERS[i % len(LETTERS)] for i, (_, _, n) in enumerate(spans)}
    tag_color = {n: PALETTE[i % len(PALETTE)] for i, (_, _, n) in enumerate(spans)}

    table = [paint("Segments", BOLD)]
    for start, end in data:
        table.append(
            paint(
                f"  ${start:04X}-${end:04X}  {end - start + 1:6} B",
                seg_color[(start, end)],
            )
        )
        for a, hi, n in spans:
            if start <= a <= end:
                table.append(
                    paint(f"      ${a:04X}", DIM)
                    + f"  {hi - a + 1:6} B  "
                    + paint(n, tag_color[n])
                )

    sized = {n for _, _, n in reserved}
    unknown = [
        (a, n)
        for a, n in labels
        if not any(s <= a <= e for s, e, _ in system)  # OS equates like COLOR0 drop out
        and n not in sized
        and not any(s <= a <= e for s, e in data)
        and not any(s <= a <= e for s, e, _ in reserved)  # e.g. PMG_P0 inside PMG
    ]
    rt = sorted(reserved + [(a, a, n) for a, n in unknown])

    bad, warn = [], []  # (lo, hi) ranges for the pictures
    for n, a in enumerate(data):
        for b in data[n + 1 :]:
            if a[0] <= b[1] and b[0] <= a[1]:
                bad.append((max(a[0], b[0]), min(a[1], b[1])))
                warn.append(
                    f"!! SEGMENT OVERLAP ${a[0]:04X}-${a[1]:04X} with ${b[0]:04X}-${b[1]:04X}"
                )
    for lo, hi, first, second in overwrites:
        bad.append((lo, hi))
        warn.append(
            f"!! OVERWRITE ${lo:04X}-${hi:04X} ({hi - lo + 1} B): {first} overwritten by {second}"
        )
    for i, (lo, hi, n) in enumerate(reserved):
        for lo2, hi2, n2 in reserved[i + 1 :]:
            if lo <= hi2 and lo2 <= hi:
                bad.append((max(lo, lo2), min(hi, hi2)))
                warn.append(
                    f"!! RESERVED OVERLAP {rt_title(lo, hi, n)} with {rt_title(lo2, hi2, n2)}"
                )
        # a segment loaded at NAME itself is NAME's content; anything else landing in it is a clash
        # ponytail: loading straight into screen RAM on purpose gets flagged too; add an opt-out if ever used
        for s, e in data:
            if s <= hi and lo <= e and not s <= lo <= e:
                bad.append((max(s, lo), min(e, hi)))
                warn.append(
                    f"!! LOADED INTO {rt_title(lo, hi, n)}: segment ${s:04X}-${e:04X}"
                )
    # system areas: no "own segment" exception
    for lo, hi, n in system:
        for s, e in data:
            if s <= hi and lo <= e:
                bad.append((max(s, lo), min(e, hi)))
                warn.append(
                    f"!! LOADED INTO {rt_title(lo, hi, n)}: segment ${s:04X}-${e:04X}"
                )
        for lo2, hi2, n2 in reserved:
            if lo <= hi2 and lo2 <= hi:
                bad.append((max(lo, lo2), min(hi, hi2)))
                warn.append(
                    f"!! RESERVED OVERLAP {rt_title(lo2, hi2, n2)} with {rt_title(lo, hi, n)}"
                )

    if verbose or diagram_only:
        pic = diagram(
            data,
            spans,
            rt,
            system,
            bad,
            verbose > 1,
            seg_color,
            tags,
            tag_color,
            expand=verbose > 2,
        )
    if diagram_only:
        return "\n".join(line.rstrip() for line in pic), warn

    out.append("")
    if verbose:
        w = max(map(visible_len, table)) + 4
        out += [
            (t + " " * (w - visible_len(t)) + d).rstrip()
            for t, d in zip_longest(table, pic, fillvalue="")
        ]
    else:
        out += table
    out += [paint(w, WARN) for w in warn]

    out.append("\n" + paint(f"System ({machine})", BOLD))
    out += [
        f"  ${lo:04X}-${hi:04X}  {hi - lo + 1:6} B  " + paint(n, SYS)
        for lo, hi, n in system
    ]

    out.append("\n" + paint("Free RAM", BOLD))
    pos = 0
    taken = data + [(lo, hi) for lo, hi, _ in reserved + system]
    for start, end in sorted(taken):
        if pos < start:
            out.append(f"  ${pos:04X}-${start - 1:04X}  {start - pos:6} B")
        pos = max(pos, end + 1)
    if pos <= 0xFFFF:
        out.append(f"  ${pos:04X}-$FFFF  {0x10000 - pos:6} B")

    if reserved:
        out.append("\n" + paint("Reserved areas (NAME_LEN)", BOLD))
        out += [
            f"  ${lo:04X}-${hi:04X}  {hi - lo + 1:6} B  " + paint(n, RUNTIME)
            for lo, hi, n in reserved
        ]
    if unknown:
        out.append(
            "\n"
            + paint("Runtime-only symbols, size unknown", BOLD)
            + " (define NAME_LEN to reserve them)"
        )
        out += [f"  ${a:04X}  " + paint(n, RUNTIME) for a, n in unknown]

    bar = []
    for kb in range(64):
        lo, hi = kb * 1024, kb * 1024 + 1023
        seg = [(s, e) for s, e in data if s <= hi and e >= lo]
        if any(s <= hi and e >= lo for s, e in bad):
            bar.append(("!", BAD))
        elif seg:
            bar.append(("#", seg_color[seg[0]]))
        elif any(s <= hi and e >= lo for s, e, _ in rt):
            bar.append(("r", RUNTIME))
        elif any(s <= lo and hi <= e for s, e, _ in system):  # whole KB system
            bar.append(("=", SYS))
        else:
            bar.append((".", DIM))
    out.append(
        "\n"
        + paint("1 char = 1 KB", BOLD)
        + "   # loaded  r reserved/runtime  = system  ! overlap"
    )
    out.append("  $0000           $4000           $8000           $C000")
    out.append("  " + "".join(paint(ch, code) for ch, code in bar))
    return "\n".join(out), warn


def main():
    global COLOR
    ap = argparse.ArgumentParser(description="Memory map of an atasm build.")
    ap.add_argument("xex", nargs="?", default="out/main.xex")
    ap.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="-v diagram, -vv + labels, -vvv full 64 KB at scale (no collapsing)",
    )
    ap.add_argument(
        "-d",
        "--diagram-only",
        action="store_true",
        help="print only the diagram (implies -v; combine with -vv/-vvv)",
    )
    ap.add_argument(
        "-m",
        "--machine",
        choices=MACHINES,
        default="130xe",
        help="system memory profile (default: 130xe = loaded from DOS 2.5)",
    )

    args = ap.parse_args()
    COLOR = sys.stdout.isatty() and not os.environ.get("NO_COLOR")
    xex = Path(args.xex)
    lab, lst = xex.with_suffix(".lab"), xex.with_suffix(".lst")
    labels = parse_lab(lab.read_text()) if lab.exists() else []
    overwrites = lst_overwrites(lst.read_text(errors="replace")) if lst.exists() else []
    missing = [p.name for p in (lab, lst) if not p.exists()]
    text, bad = report(
        parse_xex(xex.read_bytes()),
        labels,
        overwrites,
        args.verbose,
        args.machine,
        args.diagram_only,
    )

    if args.diagram_only:
        # keep stdout diagram-only; problems still visible on stderr and in the exit code
        for w in bad:
            print(w, file=sys.stderr)
    else:
        print(
            xex,
            f"[{args.machine}]",
            f"(missing {', '.join(missing)})" if missing else "",
        )
    print(text)

    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
