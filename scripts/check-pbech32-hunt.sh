#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p .harness-data/agent-eval/g91-novel-pbech32

cargo build --release --manifest-path fixtures/native/pbech32-hunt/Cargo.toml -q

out="$(./scripts/agent-eval/native-hunt.sh fixtures/native/pbech32_target fixtures/native/pbech32_target.req 2>&1)" && rc=0 || rc=$?

printf '%s\n' "$out" > .harness-data/agent-eval/g91-novel-pbech32/pbech32.log
echo "pbech32: $out"

fail=0
if [[ "$rc" -ne 1 ]] || ! grep -q '^verdict=reject' <<<"$out"; then
  echo "CHECK-PBECH32-HUNT FAIL: differential did not reject in defect direction" >&2
  fail=1
fi
if ! grep -q 'reason=target_accepts_reference_rejects' <<<"$out"; then
  echo "CHECK-PBECH32-HUNT FAIL: expected defect-direction asymmetry" >&2
  fail=1
fi
if ! grep -q 'reference_out=REJECT' <<<"$out"; then
  echo "CHECK-PBECH32-HUNT FAIL: expected reference to reject the overlong witness" >&2
  fail=1
fi

[[ "$fail" -eq 0 ]] || exit 1
echo "CHECK-PBECH32-HUNT PASS pbech32 0.2.0 accepts a >90-char valid-checksum bech32m string the BIP173 reference rejects (missing length cap)"
