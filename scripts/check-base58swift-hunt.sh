#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p .harness-data/agent-eval/g90-pinned-repro

swift build -c release --package-path fixtures/native/base58swift-vuln -q
swift build -c release --package-path fixtures/native/base58swift-fixed -q

vuln_out="$(./scripts/agent-eval/native-hunt.sh fixtures/native/base58swift_vuln fixtures/native/base58swift_vuln.req 2>&1)" && vuln_rc=0 || vuln_rc=$?
fixed_out="$(./scripts/agent-eval/native-hunt.sh fixtures/native/base58swift_fixed fixtures/native/base58swift_fixed.req 2>&1)" && fixed_rc=0 || fixed_rc=$?

printf '%s\n' "$vuln_out" > .harness-data/agent-eval/g90-pinned-repro/base58swift-vuln.log
printf '%s\n' "$fixed_out" > .harness-data/agent-eval/g90-pinned-repro/base58swift-fixed.log

echo "vuln:  $vuln_out"
echo "fixed: $fixed_out"

fail=0
if [[ "$vuln_rc" -ne 3 ]] || ! grep -q 'verdict=capability_gap' <<<"$vuln_out"; then
  echo "CHECK-BASE58SWIFT-HUNT FAIL: vuln did not classify decode failure vs fixed reference" >&2
  fail=1
fi
if ! grep -q 'reason=target_rejects_reference_accepts' <<<"$vuln_out"; then
  echo "CHECK-BASE58SWIFT-HUNT FAIL: expected target_rejects_reference_accepts asymmetry" >&2
  fail=1
fi
if ! grep -q 'input=16L5yRNPTuciSgXGHqYwn9N6NeoKqopAu' <<<"$vuln_out"; then
  echo "CHECK-BASE58SWIFT-HUNT FAIL: expected leading-zero Base58Check witness" >&2
  fail=1
fi
if [[ "$fixed_rc" -ne 0 ]] || ! grep -q '^verdict=accept' <<<"$fixed_out"; then
  echo "CHECK-BASE58SWIFT-HUNT FAIL: PR #21 revision comparator did not accept round_trip" >&2
  fail=1
fi

[[ "$fail" -eq 0 ]] || exit 1
echo "CHECK-BASE58SWIFT-HUNT PASS Base58Swift #23 decode fail on leading-zero; PR #21 head reference accepts"
