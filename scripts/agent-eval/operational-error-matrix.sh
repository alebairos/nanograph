#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() { echo "OPERATIONAL-ERROR-MATRIX FAIL: $1" >&2; exit 1; }

GENESIS="fixtures/print_42.ngb"
ORACLE_SPEC="fixtures/conformance/print_43_stdout.spec"
STRING_OFF=151
TARGET_OFF=152
PATCH_ID=1
PATCH_TS=1700000000
LOG_DIR=".harness-data/agent-eval/operational-errors"
LOG="$LOG_DIR/run.jsonl"

make -C tools -s all >/dev/null
mkdir -p "$LOG_DIR"
: >"$LOG"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
emit() { printf '%s\n' "$1" >>"$LOG"; }

rendered="$(tools/bin/conf-eval "$ORACLE_SPEC")"
idx=$((TARGET_OFF - STRING_OFF))
digit="${rendered:$idx:1}"
EXPECT_NEW="$(printf '%02x' "'$digit")"

want="$WORK/want_stdout"
tools/bin/conf-eval "$ORACLE_SPEC" >"$want"

static_gate() {
  local off="$1" new="$2"
  local spec="$WORK/op.microop"
  printf 'kind=rodata_byte_write\nimage_off=%s\nnew=%s\n' "$off" "$new" >"$spec"
  set +e
  local out
  out="$(tools/bin/ngb-microop "$GENESIS" "$spec" /dev/null --check-only --expect-new "$EXPECT_NEW" 2>&1)"
  local code=$?
  set -e
  printf '%s\t%s' "$code" "$out"
}

auditor_only() {
  local off="$1" old="$2" new="$3"
  local patched="$WORK/ao.ngb"
  set +e
  tools/bin/ngb-patch "$GENESIS" "$patched" --off "$off" --pair "$old:$new" \
    --patch-id "$PATCH_ID" --timestamp "$PATCH_TS" >/dev/null 2>"$WORK/patch_err"
  local pc=$?
  set -e
  if [[ "$pc" -ne 0 ]]; then
    printf 'ngb-patch-reject\t0\t%s' "$(tr -d '\n' <"$WORK/patch_err")"
    return
  fi
  local bundle="$WORK/ao_bundle.txt" verdict="$WORK/ao_verdict.txt"
  ./scripts/agent-eval/two-agent-auditor.sh "$GENESIS" "$patched" "$want" "$bundle" "$verdict" >/dev/null
  printf 'auditor\t1\t%s' "$(tr -d '\n' <"$verdict")"
}

printf '%-26s | %-22s | %-7s | %-34s | %-5s\n' "error class" "static gate" "s.exec" "auditor-only (no gate)" "a.exec"
printf -- '---------------------------+------------------------+---------+------------------------------------+------\n'

caught_pre_exec=0
gate_misses=0
total_bad=0

run_class() {
  local label="$1" off="$2" old="$3" new="$4" kind="$5"

  local sres scode sout
  sres="$(static_gate "$off" "$new")"
  scode="${sres%%	*}"
  sout="${sres#*	}"
  local sdecision sexec
  if [[ "$scode" -eq 0 ]]; then
    sdecision="accept"
    sexec=1
  else
    sdecision="reject $(printf '%s' "$sout" | sed -n 's/.*invariant=\([^ ]*\).*/\1/p')"
    sexec=0
  fi

  local ares acaught aexec averd
  ares="$(auditor_only "$off" "$old" "$new")"
  acaught="${ares%%	*}"
  local rest="${ares#*	}"
  aexec="${rest%%	*}"
  averd="${rest#*	}"
  local adecision
  case "$acaught" in
  ngb-patch-reject) adecision="ngb-patch reject" ;;
  auditor)
    if printf '%s' "$averd" | grep -q '^verdict=accept'; then
      adecision="auditor accept"
    else
      adecision="auditor reject $(printf '%s' "$averd" | sed -n 's/.*invariant=\([^ ]*\).*/\1/p')"
    fi
    ;;
  esac

  printf '%-26s | %-22s | %-7s | %-34s | %-5s\n' "$label" "$sdecision" "$sexec" "$adecision" "$aexec"

  emit "{\"ts\":\"$(now)\",\"class\":\"$label\",\"kind\":\"$kind\",\"off\":$off,\"new\":\"$new\",\"static\":\"$sdecision\",\"static_exec\":$sexec,\"auditor_only\":\"$adecision\",\"auditor_exec\":$aexec}"

  if [[ "$kind" == "bad" ]]; then
    total_bad=$((total_bad + 1))
    if [[ "$sexec" -eq 0 ]]; then
      caught_pre_exec=$((caught_pre_exec + 1))
    else
      gate_misses=$((gate_misses + 1))
    fi
  fi

  case "$label" in
  correct)
    [[ "$sdecision" == "accept" ]] || fail "correct: expected static accept, got $sdecision"
    [[ "$adecision" == "auditor accept" ]] || fail "correct: expected auditor accept, got $adecision"
    ;;
  wrong_value)
    [[ "$sdecision" == "reject value_mismatch" ]] || fail "wrong_value: expected static reject value_mismatch, got $sdecision"
    ;;
  wrong_target_instruction)
    [[ "$sdecision" == "reject not_rodata" ]] || fail "wrong_target: expected static reject not_rodata, got $sdecision"
    ;;
  out_of_bounds)
    [[ "$sdecision" == "reject bounds" ]] || fail "out_of_bounds: expected static reject bounds, got $sdecision"
    ;;
  correct_value_wrong_position)
    [[ "$sdecision" == "accept" ]] || fail "wrong_position: expected static accept (blind spot), got $sdecision"
    printf '%s' "$adecision" | grep -q '^auditor reject' || fail "wrong_position: expected auditor reject, got $adecision"
    ;;
  esac
}

run_class "correct"                      152    32 33 good
run_class "wrong_value"                  152    32 34 bad
run_class "wrong_target_instruction"     135    ba 33 bad
run_class "out_of_bounds"                999999 00 33 bad
run_class "correct_value_wrong_position" 151    34 33 bad

echo
echo "bad-edit classes: $total_bad"
echo "rejected before execution by static gate: $caught_pre_exec"
echo "gate blind spots (needed execution to catch): $gate_misses"

emit "{\"ts\":\"$(now)\",\"event\":\"summary\",\"bad_classes\":$total_bad,\"caught_pre_exec\":$caught_pre_exec,\"gate_misses\":$gate_misses}"

[[ "$caught_pre_exec" -eq 3 ]] || fail "expected 3 bad classes caught pre-execution, got $caught_pre_exec"
[[ "$gate_misses" -eq 1 ]] || fail "expected 1 documented blind spot, got $gate_misses"

echo "OPERATIONAL-ERROR-MATRIX OK (3/4 bad edits caught pre-execution; 1 documented blind spot) log=$LOG"
