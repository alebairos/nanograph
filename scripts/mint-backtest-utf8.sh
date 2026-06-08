#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SRC="fixtures/metamorphic/utf8.c"
DIR="fixtures/backtest/utf8"
mkdir -p "$DIR"

[[ -f "$SRC" ]] || { echo "mint-backtest-utf8: missing $SRC" >&2; exit 1; }

# Block strip over the #if !defined(OVERLONG_OK) ... #endif guards: rev1/rev3
# keep the guarded overlong checks (honest), rev2 drops them (the overlong bug).
python3 - "$SRC" "$DIR" <<'PY'
import os, sys
src, outdir = sys.argv[1], sys.argv[2]
with open(src) as f:
    lines = f.readlines()

def strip(keep_inside):
    out, in_block = [], False
    for ln in lines:
        s = ln.strip()
        if s == "#if !defined(OVERLONG_OK)":
            in_block = True
            continue
        if in_block and s == "#endif":
            in_block = False
            continue
        if in_block and not keep_inside:
            continue
        out.append(ln)
    return out

honest, bug = strip(True), strip(False)
for name, data in (("utf8_rev1.c", honest), ("utf8_rev2.c", bug), ("utf8_rev3.c", honest)):
    with open(os.path.join(outdir, name), "w") as f:
        f.writelines(data)
PY

scripts/mint-one-elf.sh "$DIR/utf8_rev1.c" "$DIR/utf8_rev1.ngb"
scripts/mint-one-elf.sh "$DIR/utf8_rev2.c" "$DIR/utf8_rev2.ngb"
scripts/mint-one-elf.sh "$DIR/utf8_rev3.c" "$DIR/utf8_rev3.ngb"

make -C tools -s bin/ngb-parse >/dev/null
h1="$(tools/bin/ngb-parse "$DIR/utf8_rev1.ngb" | sed -n 's/.*graph_root_hash=//p')"
h2="$(tools/bin/ngb-parse "$DIR/utf8_rev2.ngb" | sed -n 's/.*graph_root_hash=//p')"
h3="$(tools/bin/ngb-parse "$DIR/utf8_rev3.ngb" | sed -n 's/.*graph_root_hash=//p')"

[[ "$h1" == "$h3" ]] || { echo "mint-backtest-utf8: rev1 != rev3, the fix must restore the original bytes" >&2; exit 1; }
[[ "$h2" != "$h1" ]] || { echo "mint-backtest-utf8: rev2 == rev1, the overlong bug must change the bytes" >&2; exit 1; }

echo "rev1_honest=${h1:0:12} rev2_overlong=${h2:0:12} rev3_fix=${h3:0:12}"
echo "mint-backtest-utf8 OK"
