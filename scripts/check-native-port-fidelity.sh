#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "NATIVE-PORT-FIDELITY FAIL: $1" >&2; exit 1; }

if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "NATIVE-PORT-FIDELITY SKIP (no Linux runner)"
  exit 0
fi

reject_witness_hex() {
  local ngb="$1" req="$2"
  local line hex
  line="$(./scripts/nanograph verify --expect reject "$ngb" "$req" 2>/dev/null | tail -1)" || true
  grep -q '^verdict=reject' <<<"$line" || fail "$ngb expected reject: $line"
  hex="$(grep -Eo 'hex=[0-9a-f]+' <<<"$line" | head -1 | cut -d= -f2)"
  [[ -n "$hex" ]] || fail "$ngb reject line missing hex=: $line"
  printf '%s' "$hex"
}

check_pair() {
  local label="$1" c_ngb="$2" nat_ngb="$3" req="$4" expect_hex="$5"
  [[ -f "$c_ngb" && -f "$nat_ngb" ]] || fail "$label missing ngb"
  local c_hex nat_hex
  c_hex="$(reject_witness_hex "$c_ngb" "$req")"
  nat_hex="$(reject_witness_hex "$nat_ngb" "$req")"
  [[ "$c_hex" == "$expect_hex" ]] || fail "$label C witness hex=$c_hex want $expect_hex"
  [[ "$nat_hex" == "$expect_hex" ]] || fail "$label native witness hex=$nat_hex want $expect_hex"
  echo "NATIVE-PORT-FIDELITY $label OK hex=$nat_hex"
}

check_pair RUST-BASE64 \
  fixtures/backtest/rust-base64/rust_base64_rev2.ngb \
  fixtures/backtest/rust-base64-native/rust_native_base64_rev2.ngb \
  fixtures/metamorphic/rust_base64.req 6959563d

check_pair GO-BASE64-STREAMING \
  fixtures/backtest/go-base64-streaming/go_base64_streaming_rev2.ngb \
  fixtures/backtest/go-base64-streaming-native/go_native_base64_streaming_rev2.ngb \
  fixtures/metamorphic/go_base64_streaming.req 5

echo "NATIVE-PORT-FIDELITY OK"
