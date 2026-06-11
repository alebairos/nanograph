#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Mint accept → reject → accept native lang-pack backtest timelines (Rust/Go mined).
# Usage: mint-lang-pack-native-backtest.sh <rust-base64|go-base64-streaming> <outdir>

case_name="${1:-}"
dir="${2:-}"
[[ -n "$case_name" && -n "$dir" ]] || {
  echo "usage: mint-lang-pack-native-backtest.sh <rust-base64|go-base64-streaming> <outdir>" >&2
  exit 2
}

mkdir -p "$dir"

case "$case_name" in
  rust-base64)
    req="fixtures/metamorphic/rust_base64.req"
    src="fixtures/metamorphic/rust_native_base64.rs"
    stem="rust_native_base64"
    l2="rev2_invalidlast"
    ./scripts/mint-one-rust.sh "$src" "$dir/${stem}_rev1.ngb"
    ./scripts/mint-one-rust.sh "$src" "$dir/${stem}_rev2.ngb" --cfg disable_invalid_last_check
    ./scripts/mint-one-rust.sh "$src" "$dir/${stem}_rev3.ngb"
    ;;
  go-base64-streaming)
    req="fixtures/metamorphic/go_base64_streaming.req"
    src="fixtures/metamorphic/go_native_base64_streaming.go"
    stem="go_native_base64_streaming"
    l2="rev2_tailfix"
    ./scripts/mint-one-go.sh "$src" "$dir/${stem}_rev1.ngb"
    ./scripts/mint-one-go.sh "$src" "$dir/${stem}_rev2.ngb" --tags notail
    ./scripts/mint-one-go.sh "$src" "$dir/${stem}_rev3.ngb"
    ;;
  *)
    echo "mint-lang-pack-native-backtest: unknown case $case_name" >&2
    exit 2
    ;;
esac

ngb1="$dir/${stem}_rev1.ngb"
ngb2="$dir/${stem}_rev2.ngb"
ngb3="$dir/${stem}_rev3.ngb"

l1="rev1_honest"
l3="rev3_fix"
lw=0
for l in "$l1" "$l2" "$l3"; do [[ ${#l} -gt $lw ]] && lw=${#l}; done
pw=${#ngb1}

{
  printf 'req=%s\n' "$req"
  printf 'rev=%-*s ngb=%-*s   expect=%s\n' "$lw" "$l1" "$pw" "$ngb1" accept
  printf 'rev=%-*s ngb=%-*s   expect=%s\n' "$lw" "$l2" "$pw" "$ngb2" reject
  printf 'rev=%-*s ngb=%-*s   expect=%s\n' "$lw" "$l3" "$pw" "$ngb3" accept
} >"$dir/timeline.manifest"

make -C tools -s bin/ngb-parse >/dev/null
h1="$(tools/bin/ngb-parse "$ngb1" | sed -n 's/.*graph_root_hash=//p')"
h2="$(tools/bin/ngb-parse "$ngb2" | sed -n 's/.*graph_root_hash=//p')"
h3="$(tools/bin/ngb-parse "$ngb3" | sed -n 's/.*graph_root_hash=//p')"

[[ "$h1" == "$h3" ]] || {
  echo "mint-lang-pack-native-backtest: rev1 != rev3 hash" >&2
  exit 1
}
[[ "$h2" != "$h1" ]] || {
  echo "mint-lang-pack-native-backtest: rev2 == rev1, the bug must change the bytes" >&2
  exit 1
}

echo "rev1_honest=${h1:0:12} ${l2}=${h2:0:12} rev3_fix=${h3:0:12}"
echo "mint-lang-pack-native-backtest OK case=$case_name dir=$dir rev1==rev3 ${h1:0:12}"
