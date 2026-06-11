#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DIR="${1:-}"
REQ="${2:-}"
[[ -n "$DIR" && -n "$REQ" ]] || {
  echo "usage: mint-backtest-zig-native.sh <outdir> <req_path>" >&2
  exit 1
}
[[ -f "$DIR/main.zig" ]] || { echo "mint-backtest-zig-native: missing $DIR/main.zig" >&2; exit 1; }
[[ -f "$DIR/wyhash_fix.zig" && -f "$DIR/wyhash_bug.zig" ]] || {
  echo "mint-backtest-zig-native: missing wyhash_fix.zig / wyhash_bug.zig" >&2
  exit 1
}

mkdir -p "$DIR"

STEM="zig_native_wyhash"
scripts/mint-one-zig.sh "$DIR" "$DIR/wyhash_fix.zig" "$DIR/${STEM}_rev1.ngb"
scripts/mint-one-zig.sh "$DIR" "$DIR/wyhash_bug.zig" "$DIR/${STEM}_rev2.ngb"
scripts/mint-one-zig.sh "$DIR" "$DIR/wyhash_fix.zig" "$DIR/${STEM}_rev3.ngb"

make -C tools -s bin/ngb-parse >/dev/null
h1="$(tools/bin/ngb-parse "$DIR/${STEM}_rev1.ngb" | sed -n 's/.*graph_root_hash=//p')"
h2="$(tools/bin/ngb-parse "$DIR/${STEM}_rev2.ngb" | sed -n 's/.*graph_root_hash=//p')"
h3="$(tools/bin/ngb-parse "$DIR/${STEM}_rev3.ngb" | sed -n 's/.*graph_root_hash=//p')"

[[ "$h1" == "$h3" ]] || { echo "mint-backtest-zig-native: rev1 != rev3" >&2; exit 1; }
[[ "$h2" != "$h1" ]] || { echo "mint-backtest-zig-native: rev2 == rev1" >&2; exit 1; }

l1="rev1_honest"
l2="rev2_parent"
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

echo "rev1_honest=${h1:0:12} rev2_parent=${h2:0:12} rev3_fix=${h3:0:12}"
echo "mint-backtest-zig-native OK"
