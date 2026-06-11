#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Mint accept → reject → accept bswap32 involution timelines for lang-pack backtests.
# Usage: mint-lang-pack-bswap32-backtest.sh <c|rust|go> <outdir>

lang="${1:-}"
dir="${2:-}"
[[ -n "$lang" && -n "$dir" ]] || {
  echo "usage: mint-lang-pack-bswap32-backtest.sh <c|rust|go> <outdir>" >&2
  exit 2
}

mkdir -p "$dir"
req="fixtures/metamorphic/bswap32.req"
honest_src="fixtures/metamorphic/rust_native_bswap32.rs"
go_honest="fixtures/metamorphic/go_native_bswap32.go"
go_evil="fixtures/metamorphic/go_native_bswap32_evil.go"

case "$lang" in
  c)
    stem="c_native_bswap32"
    cp fixtures/metamorphic/bswap32.ngb "$dir/${stem}_rev1.ngb"
    cp fixtures/metamorphic/bswap32_evil.ngb "$dir/${stem}_rev2.ngb"
    cp fixtures/metamorphic/bswap32.ngb "$dir/${stem}_rev3.ngb"
    ;;
  rust)
    stem="rust_native_bswap32"
    ./scripts/mint-one-rust.sh "$honest_src" "$dir/${stem}_rev1.ngb"
    ./scripts/mint-one-rust.sh "$honest_src" "$dir/${stem}_rev2.ngb" --cfg evil_bswap
    ./scripts/mint-one-rust.sh "$honest_src" "$dir/${stem}_rev3.ngb"
    ;;
  go)
    stem="go_native_bswap32"
    ./scripts/mint-one-go.sh "$go_honest" "$dir/${stem}_rev1.ngb"
    ./scripts/mint-one-go.sh "$go_evil" "$dir/${stem}_rev2.ngb"
    ./scripts/mint-one-go.sh "$go_honest" "$dir/${stem}_rev3.ngb"
    ;;
  *)
    echo "mint-lang-pack-bswap32-backtest: unknown lang $lang" >&2
    exit 2
    ;;
esac

cat >"$dir/timeline.manifest" <<EOF
req=$req
rev=rev1_honest ngb=$dir/${stem}_rev1.ngb expect=accept
rev=rev2_evil    ngb=$dir/${stem}_rev2.ngb expect=reject
rev=rev3_fix     ngb=$dir/${stem}_rev3.ngb expect=accept
EOF

make -C tools -s bin/ngb-parse >/dev/null
h1="$(tools/bin/ngb-parse "$dir/${stem}_rev1.ngb" | sed -n 's/.*graph_root_hash=//p')"
h3="$(tools/bin/ngb-parse "$dir/${stem}_rev3.ngb" | sed -n 's/.*graph_root_hash=//p')"
[[ "$h1" == "$h3" ]] || {
  echo "mint-lang-pack-bswap32-backtest: rev1 != rev3 hash" >&2
  exit 1
}

echo "mint-lang-pack-bswap32-backtest OK lang=$lang dir=$dir rev1==rev3 ${h1:0:12}"
