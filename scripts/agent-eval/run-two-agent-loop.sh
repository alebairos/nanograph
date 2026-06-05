#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() { echo "TWO-AGENT-LOOP FAIL: $1" >&2; exit 1; }

GENESIS="fixtures/print_42.ngb"
GENESIS_HASH=2429c3ed702dbfa62e4ab9eb2547b509f188b63f14742befa49dcee71f8cf016
PATCHED_HASH=2a8f5f4e1a9e8a3d294253229bea6526cb80e5cc21165e422d563563956dd9c1
PATCH_OFF=152
PATCH_ID=1
PATCH_TS=1700000000
WANT_STDOUT=$'43\n'
MAX_ROUNDS=5

LOG_DIR=".harness-data/agent-eval/two-agent"
LOG="$LOG_DIR/run.jsonl"
mkdir -p "$LOG_DIR"
: >"$LOG"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

make -C tools -s all

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
emit() { printf '%s\n' "$1" >>"$LOG"; }
bundle_hash() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

SECONDS=0

emit "{\"ts\":\"$(now)\",\"event\":\"loop_start\",\"genesis\":\"$GENESIS\",\"goal\":\"stdout 43\\\\n exit 0\"}"

round=0
accepted=0

author_patch() {
  local round_n="$1"
  local pair="$2"
  local in_ngb="$3"
  local out_ngb="$4"

  local pre
  pre="$(tools/bin/ngb-parse "$in_ngb" 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
  [[ -n "$pre" ]] || fail "round $round_n: missing precondition hash"

  emit "{\"ts\":\"$(now)\",\"round\":$round_n,\"role\":\"author\",\"msg_type\":\"patch_request\",\"precondition_hash\":\"$pre\",\"delta_off\":$PATCH_OFF,\"delta_pairs\":\"$pair\"}"

  set +e
  tools/bin/ngb-patch "$in_ngb" "$out_ngb" \
    --off "$PATCH_OFF" --pair "$pair" \
    --patch-id "$PATCH_ID" --timestamp "$PATCH_TS" >/dev/null 2>"$WORK/patch_err"
  patch_code=$?
  set -e
  [[ "$patch_code" -eq 0 ]] || fail "round $round_n: ngb-patch failed: $(cat "$WORK/patch_err")"

  local gh
  gh="$(tools/bin/ngb-parse "$out_ngb" 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
  emit "{\"ts\":\"$(now)\",\"round\":$round_n,\"role\":\"author\",\"msg_type\":\"patched_ngb\",\"graph_root_hash\":\"$gh\"}"
}

auditor_round() {
  local round_n="$1"
  local patched="$2"

  local bundle="$WORK/bundle_r${round_n}.txt"
  local verdict="$WORK/verdict_r${round_n}.txt"
  local want="$WORK/want_stdout"
  printf '%s' "$WANT_STDOUT" >"$want"

  ./scripts/agent-eval/two-agent-auditor.sh "$GENESIS" "$patched" "$want" "$bundle" "$verdict"

  local bh
  bh="$(bundle_hash "$bundle")"
  emit "{\"ts\":\"$(now)\",\"round\":$round_n,\"role\":\"auditor\",\"msg_type\":\"probe_bundle\",\"bundle_sha256\":\"$bh\"}"

  local vline
  vline="$(tr -d '\n' <"$verdict")"
  if grep -q '^verdict=accept ' "$verdict"; then
    local gh
    gh="$(sed -n 's/.*graph_root_hash=//p' "$verdict")"
    emit "{\"ts\":\"$(now)\",\"round\":$round_n,\"role\":\"auditor\",\"msg_type\":\"verdict\",\"decision\":\"accept\",\"graph_root_hash\":\"$gh\",\"line\":\"$vline\"}"
    accepted=1
    return 0
  fi

  local inv detail
  inv="$(sed -n 's/.*invariant=\([^ ]*\).*/\1/p' "$verdict")"
  detail="$(sed -n 's/.*detail=\(.*\)/\1/p' "$verdict")"
  emit "{\"ts\":\"$(now)\",\"round\":$round_n,\"role\":\"auditor\",\"msg_type\":\"verdict\",\"decision\":\"reject\",\"invariant\":\"$inv\",\"detail\":\"$detail\",\"line\":\"$vline\"}"
  return 1
}

echo "-- two-agent loop: print_42 -> 43 --"

round=1
author_patch "$round" "32:34" "$GENESIS" "$WORK/r1.ngb"
if auditor_round "$round" "$WORK/r1.ngb"; then
  fail "round 1: auditor accepted wrong patch (want reject)"
fi
echo "round 1 OK: auditor rejected wrong stdout patch"

round=2
author_patch "$round" "32:33" "$GENESIS" "$WORK/r2.ngb"
if ! auditor_round "$round" "$WORK/r2.ngb"; then
  fail "round 2: auditor rejected correct patch"
fi
echo "round 2 OK: auditor accepted correct patch"

[[ "$accepted" -eq 1 ]] || fail "loop ended without accept"
[[ "$round" -le "$MAX_ROUNDS" ]] || fail "exceeded $MAX_ROUNDS rounds"

got_hash="$(tools/bin/ngb-parse "$WORK/r2.ngb" 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
[[ "$got_hash" == "$PATCHED_HASH" ]] || fail "final hash $got_hash != oracle $PATCHED_HASH"

wall_ms=$((SECONDS * 1000))

emit "{\"ts\":\"$(now)\",\"event\":\"loop_end\",\"success\":true,\"rounds\":$round,\"wall_ms\":$wall_ms,\"final_graph_root_hash\":\"$got_hash\"}"

echo "TWO-AGENT-LOOP OK rounds=$round wall_ms=$wall_ms log=$LOG"
