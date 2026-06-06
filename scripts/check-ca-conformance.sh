#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "CA-CONFORMANCE FAIL: $1" >&2; exit 1; }

echo "== ca conformance (G17/G19) =="
if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "CA-CONFORMANCE SKIP (no Linux runner: need Linux, qemu-x86_64, or docker)"
  exit 0
fi

make -C tools -s bin/conf-eval bin/ngb-extract bin/ngb-parse bin/ca-rule30-patch-fixture >/dev/null

LOG_DIR=".harness-data/agent-eval/conformance"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/run.jsonl"

hash_of() { tools/bin/ngb-parse "$1" | sed -n 's/.*graph_root_hash=//p'; }

check_ca_rule() {
  local label="$1" spec="$2" v1="$3" v2="$4" wrong="$5" patched="${6:-}"
  for f in "$spec" "$v1" "$v2" "$wrong"; do
    [[ -f "$f" ]] || fail "missing $f (run scripts/mint-ca-fixtures.sh)"
  done
  if [[ -n "$patched" ]]; then
    [[ -f "$patched" ]] || fail "missing $patched"
    local built patched_hash
    built="$(NANOGRAPH_ROOT="$ROOT" tools/bin/ca-rule30-patch-fixture --no-write --print-hash)"
    patched_hash="$(hash_of "$patched")"
    [[ "$built" == "$patched_hash" ]] || fail "$patched drift (rebuild fixture)"
  fi

  local expected h1 h2
  expected="$(tools/bin/conf-eval "$spec")"
  h1="$(hash_of "$v1")"
  h2="$(hash_of "$v2")"
  [[ "$h1" != "$h2" ]] || fail "rule $label variants share graph_root_hash"

  verdict() {
    local ngb="$1" observed ts
    observed="$(./scripts/run-linux-elf-capture.sh "$ngb" 2>/dev/null)" || true
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    if [[ "$observed" == "$expected" ]]; then
      printf '{"ts":"%s","msg_type":"verdict","spec":"%s","ngb":"%s","yield":"stdout","decision":"accept"}\n' \
        "$ts" "$spec" "$ngb" >>"$LOG"
      echo accept
    else
      printf '{"ts":"%s","msg_type":"verdict","spec":"%s","ngb":"%s","yield":"stdout","decision":"reject"}\n' \
        "$ts" "$spec" "$ngb" >>"$LOG"
      echo reject
    fi
  }

  echo "-- rule $label: accept variant 1 (O0) --"
  [[ "$(verdict "$v1")" == "accept" ]] || fail "rule $label v1 should accept"
  echo "-- rule $label: accept variant 2 (O2), distinct bytes --"
  [[ "$(verdict "$v2")" == "accept" ]] || fail "rule $label v2 should accept"
  echo "-- rule $label: reject wrong-rule specimen --"
  [[ "$(verdict "$wrong")" == "reject" ]] || fail "rule $label wrong-rule should reject"
  if [[ -n "$patched" ]]; then
    echo "-- rule $label: reject one-byte patch (add_two_patched shape) --"
    [[ "$(verdict "$patched")" == "reject" ]] || fail "rule $label patched should reject"
  fi
  echo "rule $label OK v1=${h1:0:12} v2=${h2:0:12}"
}

check_ca_rule 30 fixtures/ca/rule30.spec \
  fixtures/ca/ca_rule30_v1.ngb fixtures/ca/ca_rule30_v2.ngb \
  fixtures/ca/ca_rule30_wrongrule.ngb fixtures/ca/ca_rule30_patched.ngb

check_ca_rule 50 fixtures/ca/rule50.spec \
  fixtures/ca/ca_rule50_v1.ngb fixtures/ca/ca_rule50_v2.ngb \
  fixtures/ca/ca_rule50_wrongrule.ngb

check_ca_rule 110 fixtures/ca/rule110.spec \
  fixtures/ca/ca_rule110_v1.ngb fixtures/ca/ca_rule110_v2.ngb \
  fixtures/ca/ca_rule110_wrongrule.ngb

echo "CA-CONFORMANCE OK (rules 30/50/110 two-variant accept + wrong-rule reject; rule30 patch reject)"
