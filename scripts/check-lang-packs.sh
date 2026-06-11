#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Lang-pack CI gate (ADR-021, G77). Committed-artifact leg only: parse (I1–I6)
# + honest accept. No Docker mint (network/toolchain) so safe inside check-all-proofs.

fail() { echo "LANG-PACKS FAIL: $1" >&2; exit 1; }

if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "LANG-PACKS SKIP (no Linux runner)"
  exit 0
fi

make -C tools -s bin/ngb-parse >/dev/null
VERIFY="./scripts/agent-eval/metamorphic-verify.sh"

check_pack() {
  local name="$1" ngb="$2" req="$3"
  [[ -f "$ngb" ]] || fail "$name missing committed $ngb"
  [[ -f "$req" ]] || fail "$name missing $req"
  tools/bin/ngb-parse "$ngb" >/dev/null || fail "$name ngb-parse rejected $ngb"
  local verdict
  verdict="$("$VERIFY" "$ngb" "$req" 2>/dev/null | tail -1)"
  grep -q '^verdict=accept' <<<"$verdict" || fail "$name behavior: $verdict"
  echo "LANG-PACK $name OK $verdict"
}

echo "== lang packs (committed gate) =="
check_pack C   fixtures/metamorphic/bswap32.ngb \
  fixtures/metamorphic/bswap32.req
check_pack Zig fixtures/backtest/zig-wyhash-native/zig_native_wyhash_rev1.ngb \
  fixtures/metamorphic/zig_wyhash.req
check_pack Rust fixtures/backtest/rust-bswap32-native/rust_native_bswap32_rev1.ngb \
  fixtures/metamorphic/bswap32.req
check_pack Go  fixtures/backtest/go-bswap32-native/go_native_bswap32_rev1.ngb \
  fixtures/metamorphic/bswap32.req

echo "== lang-pack native backtests =="
./scripts/check-backtest.sh fixtures/backtest/c-bswap32-native/timeline.manifest x=1 C-BSWAP32-NATIVE
./scripts/check-backtest.sh fixtures/backtest/rust-bswap32-native/timeline.manifest x=1 RUST-BSWAP32-NATIVE
./scripts/check-backtest.sh fixtures/backtest/go-bswap32-native/timeline.manifest x=1 GO-BSWAP32-NATIVE

echo "LANG-PACKS OK (4 packs + 3 native bswap32 backtests; Zig wyhash backtest in all-proofs)"
