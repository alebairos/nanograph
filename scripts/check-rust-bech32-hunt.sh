#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p .harness-data/agent-eval/g89-pinned-repro

cargo build --release --manifest-path fixtures/native/rust-bech32-hunt/Cargo.toml -q

vuln_out="$(./scripts/agent-eval/native-hunt.sh fixtures/native/rust_bech32_vuln fixtures/native/rust_bech32_vuln.req 2>&1)" && vuln_rc=0 || vuln_rc=$?
fixed_out="$(./scripts/agent-eval/native-hunt.sh fixtures/native/rust_bech32_fixed fixtures/native/rust_bech32_fixed.req 2>&1)" && fixed_rc=0 || fixed_rc=$?

printf '%s\n' "$vuln_out" > .harness-data/agent-eval/g89-pinned-repro/rust-bech32-vuln.log
printf '%s\n' "$fixed_out" > .harness-data/agent-eval/g89-pinned-repro/rust-bech32-fixed.log

echo "vuln:  $vuln_out"
echo "fixed: $fixed_out"

fail=0
if [[ "$vuln_rc" -ne 1 ]] || ! grep -q '^verdict=reject' <<<"$vuln_out"; then
  echo "CHECK-RUST-BECH32-HUNT FAIL: validate_segwit path did not reject in defect direction" >&2
  fail=1
fi
if ! grep -q 'reason=target_accepts_reference_rejects' <<<"$vuln_out"; then
  echo "CHECK-RUST-BECH32-HUNT FAIL: expected defect-direction asymmetry" >&2
  fail=1
fi
if ! grep -q 'target_out=17:' <<<"$vuln_out"; then
  echo "CHECK-RUST-BECH32-HUNT FAIL: expected witness on witness version 17" >&2
  fail=1
fi
if [[ "$fixed_rc" -ne 0 ]] || ! grep -q '^verdict=accept' <<<"$fixed_out"; then
  echo "CHECK-RUST-BECH32-HUNT FAIL: SegwitHrpstring::new comparator did not accept/concur" >&2
  fail=1
fi

[[ "$fail" -eq 0 ]] || exit 1
echo "CHECK-RUST-BECH32-HUNT PASS bech32 0.12.0 validate_segwit reproduces rust-bech32 #274; SegwitHrpstring::new concurs with reference"
