#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "CA-CONFORMANCE FAIL: $1" >&2; exit 1; }

echo "== ca conformance (G17 phase 2) =="
if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "CA-CONFORMANCE SKIP (no Linux runner: need Linux, qemu-x86_64, or docker)"
  exit 0
fi

make -C tools -s bin/conf-eval bin/ngb-extract bin/ngb-parse bin/ca-rule30-patch-fixture >/dev/null

SPEC="fixtures/ca/rule30.spec"
V1="fixtures/ca/ca_rule30_v1.ngb"
V2="fixtures/ca/ca_rule30_v2.ngb"
WRONG="fixtures/ca/ca_rule30_wrongrule.ngb"
PATCHED="fixtures/ca/ca_rule30_patched.ngb"
for f in "$SPEC" "$V1" "$V2" "$WRONG" "$PATCHED"; do
  [[ -f "$f" ]] || fail "missing $f (run scripts/mint-ca-fixtures.sh && make -C tools bin/ca-rule30-patch-fixture)"
done

hash_of() { tools/bin/ngb-parse "$1" | sed -n 's/.*graph_root_hash=//p'; }

BUILT_PATCHED_HASH="$(NANOGRAPH_ROOT="$ROOT" tools/bin/ca-rule30-patch-fixture --no-write --print-hash)"
FILE_PATCHED_HASH="$(hash_of "$PATCHED")"
[[ "$BUILT_PATCHED_HASH" == "$FILE_PATCHED_HASH" ]] || fail "ca_rule30_patched.ngb drift (rebuild fixture)"

expected="$(tools/bin/conf-eval "$SPEC")"

LOG_DIR=".harness-data/agent-eval/conformance"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/run.jsonl"

# verdict reads only (spec, observed stdout); it never reads graph_root_hash.
verdict() {
  local ngb="$1" observed ts
  observed="$(./scripts/run-linux-elf-capture.sh "$ngb" 2>/dev/null)" || true
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ "$observed" == "$expected" ]]; then
    printf '{"ts":"%s","msg_type":"verdict","spec":"%s","ngb":"%s","yield":"stdout","decision":"accept"}\n' \
      "$ts" "$SPEC" "$ngb" >>"$LOG"
    echo accept
  else
    printf '{"ts":"%s","msg_type":"verdict","spec":"%s","ngb":"%s","yield":"stdout","decision":"reject"}\n' \
      "$ts" "$SPEC" "$ngb" >>"$LOG"
    echo reject
  fi
}

h1="$(hash_of "$V1")"
h2="$(hash_of "$V2")"
[[ "$h1" != "$h2" ]] || fail "variants share graph_root_hash; not structurally distinct"

echo "-- accept: variant 1 (O0) realizes rule30 stdout --"
[[ "$(verdict "$V1")" == "accept" ]] || fail "variant 1 should accept"

echo "-- accept: variant 2 (O2) distinct bytes, same stdout --"
[[ "$(verdict "$V2")" == "accept" ]] || fail "variant 2 should accept"

echo "-- reject: wrong-rule specimen claims rule30, computes a different grid --"
[[ "$(verdict "$WRONG")" == "reject" ]] || fail "wrong-rule specimen should reject"

echo "-- reject: one-byte patch flips rule immediate 0x1e->0x5a (add_two_patched shape) --"
[[ "$(verdict "$PATCHED")" == "reject" ]] || fail "ca_rule30_patched should reject"

echo "behavioral-not-structural: v1=${h1:0:12} v2=${h2:0:12} accept on same spec; wrong-rule + patched reject"
echo "CA-CONFORMANCE OK (two-variant accept, wrong-rule reject, patch-level reject)"
