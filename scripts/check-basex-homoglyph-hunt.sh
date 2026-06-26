#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p .harness-data/agent-eval/g84-pinned-repro

if [[ ! -d fixtures/native/base-x-vuln/node_modules/base-x ]]; then
  (cd fixtures/native/base-x-vuln && npm install --silent)
fi
if [[ ! -d fixtures/native/base-x-fixed/node_modules/base-x ]]; then
  (cd fixtures/native/base-x-fixed && npm install --silent)
fi

vuln_out="$(./scripts/agent-eval/native-hunt.sh fixtures/native/basex_vuln fixtures/native/basex_vuln.req 2>&1)" && vuln_rc=0 || vuln_rc=$?
fixed_out="$(./scripts/agent-eval/native-hunt.sh fixtures/native/basex_fixed fixtures/native/basex_fixed.req 2>&1)" && fixed_rc=0 || fixed_rc=$?

printf '%s\n' "$vuln_out" > .harness-data/agent-eval/g84-pinned-repro/basex-vuln.log
printf '%s\n' "$fixed_out" > .harness-data/agent-eval/g84-pinned-repro/basex-fixed.log

echo "vuln:  $vuln_out"
echo "fixed: $fixed_out"

fail=0
if [[ "$vuln_rc" -ne 1 ]] || ! grep -q '^verdict=reject' <<<"$vuln_out"; then
  echo "CHECK-BASEX-HOMOGLYPH FAIL: vulnerable target did not reject in defect direction" >&2
  fail=1
fi
if ! grep -q 'reason=target_accepts_reference_rejects' <<<"$vuln_out"; then
  echo "CHECK-BASEX-HOMOGLYPH FAIL: expected defect-direction asymmetry classification" >&2
  fail=1
fi
if ! grep -q 'input=ABCĀDEF' <<<"$vuln_out"; then
  echo "CHECK-BASEX-HOMOGLYPH FAIL: expected Unicode homoglyph witness ABCĀDEF" >&2
  fail=1
fi
if [[ "$fixed_rc" -ne 0 ]] || ! grep -q '^verdict=accept' <<<"$fixed_out"; then
  echo "CHECK-BASEX-HOMOGLYPH FAIL: fixed comparator did not accept/concur" >&2
  fail=1
fi

[[ "$fail" -eq 0 ]] || exit 1
echo "CHECK-BASEX-HOMOGLYPH PASS pinned base-x 5.0.0 reproduces CVE-2025-27611 witness; fixed 5.0.1 concurs with strict reference"
