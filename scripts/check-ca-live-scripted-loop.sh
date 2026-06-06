#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "CHECK-CA-LIVE-SCRIPTED-LOOP FAIL: $1" >&2; exit 1; }

echo "== ca live scripted loop (deterministic, no LLM) =="

./scripts/check-linux-runner.sh --quiet || {
  echo "CHECK-CA-LIVE-SCRIPTED-LOOP SKIP (no Linux runner)"
  exit 0
}

make -C tools -s bin/ngb-patch bin/ngb-parse bin/conf-eval >/dev/null

GENESIS="fixtures/ca/ca_rule30_patched.ngb"
SPEC="fixtures/ca/rule30.spec"
PATCH_OFF=4424

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

want="$WORK/want_stdout"
bundle="$WORK/bundle.txt"
verdict="$WORK/verdict.txt"
patched="$WORK/fixed.ngb"

tools/bin/conf-eval "$SPEC" >"$want"

tools/bin/ngb-patch "$GENESIS" "$patched" \
  --off "$PATCH_OFF" --pair 5a:1e \
  --patch-id 3 --timestamp 1700000002 >/dev/null

./scripts/agent-eval/two-agent-auditor.sh "$GENESIS" "$patched" "$want" "$bundle" "$verdict"
grep -q '^verdict=accept ' "$verdict" || fail "scripted fix should accept ($(cat "$verdict"))"

v1_out="$(mktemp)"
patched_out="$(mktemp)"
./scripts/run-linux-elf-capture.sh fixtures/ca/ca_rule30_v1.ngb >"$v1_out" 2>/dev/null
./scripts/run-linux-elf-capture.sh "$patched" >"$patched_out" 2>/dev/null
diff "$v1_out" "$patched_out" >/dev/null || fail "fixed stdout differs from ca_rule30_v1"

echo "CHECK-CA-LIVE-SCRIPTED-LOOP OK (patched genesis + 5a:1e -> accept, stdout matches v1)"
