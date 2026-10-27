#!/bin/sh
# ci.sh - build check: assemble, no warnings, no memory conflicts, tool tests pass.
# Used by .forgejo/workflows/build.yml and .github/workflows/build.yml; runs locally too:
#   sh tools/ci.sh
# Needs: cc + make + zlib headers (only if atasm isn't installed), curl, python3.
set -eu
cd "$(dirname "$0")/.."

ATASM_VERSION=1.30
ATASM_SHA256=c3ae8ea1f824e0ee65e123b33982572277207d1749bcd04da3af8f06af977db5  # same tarball as Homebrew

# --- atasm: use the installed one, otherwise build the pinned version into .atasm/ ---
if command -v atasm >/dev/null 2>&1; then
    ATASM=atasm
else
    ATASM=.atasm/atasm
    if [ ! -x "$ATASM" ]; then
        echo "== building atasm $ATASM_VERSION"
        mkdir -p .atasm
        curl -fsSL -o .atasm/atasm.tar.gz "https://github.com/CycoPH/atasm/archive/refs/tags/V$ATASM_VERSION.tar.gz"
        echo "$ATASM_SHA256  .atasm/atasm.tar.gz" | sha256sum -c -
        tar -xzf .atasm/atasm.tar.gz -C .atasm
        make -C ".atasm/atasm-$ATASM_VERSION/src" >/dev/null
        cp ".atasm/atasm-$ATASM_VERSION/src/atasm" "$ATASM"
    fi
fi
"$ATASM" 2>&1 | head -1 || true

# --- assemble (same include dirs as atasm-build.json) ---
echo "== assembling src/main.asm"
mkdir -p out
log=out/build.log
if ! "$ATASM" -Isrc/charset -Isrc -oout/main.xex -lout/main.lab -gout/main.lst src/main.asm >"$log" 2>&1; then
    cat "$log"
    echo "FAILED: assembly error"
    exit 1
fi
if grep -q "Warning:" "$log"; then
    grep "Warning:" "$log"
    echo "FAILED: assembly warnings"
    exit 1
fi
grep -E "Block:|successful" "$log"

# --- memory map: exits 1 on overlaps / conflicts ---
echo "== memory map"
python3 tools/memmap.py out/main.xex

# --- tool tests ---
echo "== tool tests"
python3 tools/test_memmap.py
python3 tools/test_mapview.py

echo "== all checks passed"
