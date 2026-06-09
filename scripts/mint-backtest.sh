#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SRC="${1:-}"
GUARD="${2:-}"
DIR="${3:-}"
REQ="${4:-}"
BUG="${5:-}"
[[ -n "$SRC" && -n "$GUARD" && -n "$DIR" && -n "$REQ" && -n "$BUG" ]] || {
  echo "usage: mint-backtest.sh <source.c> <guard_macro> <outdir> <req_path> <bug_label>" >&2
  exit 1
}
[[ -f "$SRC" ]] || { echo "mint-backtest: missing $SRC" >&2; exit 1; }

STEM="$(basename "$SRC" .c)"
mkdir -p "$DIR"

# Block strip over the #if !defined(<guard>) ... #endif guards: rev1/rev3 keep
# the guarded checks (honest), rev2 drops them (the bug under test).
python3 - "$SRC" "$DIR" "$GUARD" "$STEM" <<'PY'
import os, sys
src, outdir, guard, stem = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(src) as f:
    lines = f.readlines()

marker = "#if !defined(%s)" % guard

def strip(keep_inside):
    out, in_block = [], False
    for ln in lines:
        s = ln.strip()
        if s == marker:
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
for name, data in ((stem + "_rev1.c", honest), (stem + "_rev2.c", bug), (stem + "_rev3.c", honest)):
    with open(os.path.join(outdir, name), "w") as f:
        f.writelines(data)
PY

scripts/mint-one-elf.sh "$DIR/${STEM}_rev1.c" "$DIR/${STEM}_rev1.ngb"
scripts/mint-one-elf.sh "$DIR/${STEM}_rev2.c" "$DIR/${STEM}_rev2.ngb" -D"${GUARD}"
scripts/mint-one-elf.sh "$DIR/${STEM}_rev3.c" "$DIR/${STEM}_rev3.ngb"

make -C tools -s bin/ngb-parse >/dev/null
h1="$(tools/bin/ngb-parse "$DIR/${STEM}_rev1.ngb" | sed -n 's/.*graph_root_hash=//p')"
h2="$(tools/bin/ngb-parse "$DIR/${STEM}_rev2.ngb" | sed -n 's/.*graph_root_hash=//p')"
h3="$(tools/bin/ngb-parse "$DIR/${STEM}_rev3.ngb" | sed -n 's/.*graph_root_hash=//p')"

[[ "$h1" == "$h3" ]] || { echo "mint-backtest: rev1 != rev3, the fix must restore the original bytes" >&2; exit 1; }
[[ "$h2" != "$h1" ]] || { echo "mint-backtest: rev2 == rev1, the bug must change the bytes" >&2; exit 1; }

l1="rev1_honest"
l2="rev2_${BUG}"
l3="rev3_fix"
ngb1="$DIR/${STEM}_rev1.ngb"
ngb2="$DIR/${STEM}_rev2.ngb"
ngb3="$DIR/${STEM}_rev3.ngb"

lw=0
for l in "$l1" "$l2" "$l3"; do [[ ${#l} -gt $lw ]] && lw=${#l}; done
pw=${#ngb1}

{
  printf 'req=%s\n' "$REQ"
  printf 'rev=%-*s ngb=%-*s   expect=%s\n' "$lw" "$l1" "$pw" "$ngb1" accept
  printf 'rev=%-*s ngb=%-*s   expect=%s\n' "$lw" "$l2" "$pw" "$ngb2" reject
  printf 'rev=%-*s ngb=%-*s   expect=%s\n' "$lw" "$l3" "$pw" "$ngb3" accept
} > "$DIR/timeline.manifest"

echo "rev1_honest=${h1:0:12} rev2_${BUG}=${h2:0:12} rev3_fix=${h3:0:12}"
echo "mint-backtest OK"
