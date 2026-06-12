#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Lang-pack CI gate (ADR-021, G77). Committed-artifact leg only: parse (I1–I6)
# + honest accept + real-history native backtest per non-C pack. No Docker mint.

fail() { echo "LANG-PACKS FAIL: $1" >&2; exit 1; }

if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "LANG-PACKS SKIP (no Linux runner)"
  exit 0
fi

make -C tools -s bin/ngb-parse >/dev/null

./scripts/check-verifier-frozen.sh >/dev/null || {
  echo "LANG-PACKS FAIL: language-blind verify surface drift (see fixtures/lang-packs/VERIFIER.sha256)" >&2
  exit 1
}

check_pack() {
  local name="$1" ngb="$2" req="$3"
  [[ -f "$ngb" ]] || fail "$name missing committed $ngb"
  [[ -f "$req" ]] || fail "$name missing $req"
  tools/bin/ngb-parse "$ngb" >/dev/null || fail "$name ngb-parse rejected $ngb"
  local verdict
  verdict="$(./scripts/nanograph verify --expect accept "$ngb" "$req" 2>/dev/null | tail -1)"
  grep -q '^verdict=accept' <<<"$verdict" || fail "$name behavior: $verdict"
  echo "LANG-PACK $name OK $verdict"
}

echo "== lang packs (committed gate) =="
check_pack C   fixtures/metamorphic/bswap32.ngb \
  fixtures/metamorphic/bswap32.req
check_pack Zig fixtures/backtest/zig-wyhash-native/zig_native_wyhash_rev1.ngb \
  fixtures/metamorphic/zig_wyhash.req
check_pack Rust fixtures/backtest/rust-base64-native/rust_native_base64_rev1.ngb \
  fixtures/metamorphic/rust_base64.req
check_pack Go  fixtures/backtest/go-base64-streaming-native/go_native_base64_streaming_rev1.ngb \
  fixtures/metamorphic/go_base64_streaming.req

echo "== lang-pack native backtests (real-history) =="
./scripts/check-backtest.sh fixtures/backtest/zig-wyhash-native/timeline.manifest 5 ZIG-WYHASH-NATIVE
./scripts/check-backtest.sh fixtures/backtest/rust-base64-native/timeline.manifest 6959563d RUST-BASE64-NATIVE
./scripts/check-backtest.sh fixtures/backtest/go-base64-streaming-native/timeline.manifest 5 GO-BASE64-STREAMING-NATIVE
./scripts/check-native-port-fidelity.sh

echo "LANG-PACKS OK (4 packs + 3 mined native backtests + port fidelity)"
