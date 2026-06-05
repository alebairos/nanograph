#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() { echo "LIVE-AGENT-LOOP FAIL: $1" >&2; exit 1; }

WITH_STATIC=0
MODEL="${LIVE_AGENT_MODEL:-composer-2.5}"
MAX_ROUNDS=5
GENESIS="fixtures/print_42.ngb"
ORACLE_SPEC="fixtures/conformance/print_43_stdout.spec"
STRING_OFF=151
PATCH_OFF=152
PATCH_ID=1
PATCH_TS=1700000000
PATCHED_HASH=2a8f5f4e1a9e8a3d294253229bea6526cb80e5cc21165e422d563563956dd9c1
LOG_DIR=".harness-data/agent-eval/live-agent"
LOG="$LOG_DIR/run.jsonl"
SKILL=".cursor/skills/live-ngb-author/SKILL.md"

usage() {
  echo "usage: run-live-agent-loop.sh [--with-static-gate|--no-static-gate] [--model NAME]" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --with-static-gate) WITH_STATIC=1; shift ;;
  --no-static-gate) WITH_STATIC=0; shift ;;
  --model) MODEL="$2"; shift 2 ;;
  -h | --help) usage ;;
  *) fail "unknown arg $1" ;;
  esac
done

./scripts/check-live-agent-prereqs.sh >/dev/null

mkdir -p "$LOG_DIR"
: >"$LOG"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

make -C tools -s all >/dev/null

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
emit() { printf '%s\n' "$1" >>"$LOG"; }
bundle_hash() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

rendered="$(tools/bin/conf-eval "$ORACLE_SPEC")"
idx=$((PATCH_OFF - STRING_OFF))
digit="${rendered:$idx:1}"
expect_new="$(printf '%02x' "'$digit")"

cp "$GENESIS" "$WORK/genesis.ngb"

SECONDS=0
emit "{\"ts\":\"$(now)\",\"event\":\"loop_start\",\"genesis\":\"$GENESIS\",\"with_static_gate\":$WITH_STATIC,\"model\":\"$MODEL\"}"

accepted=0
round=0
auditor_execs=0
prior_bundle=""
prior_verdict=""
prior_static=""

parse_patch_from_text() {
  local text="$1"
  local off pairs
  off="$(printf '%s\n' "$text" | sed -n 's/^patch_off=\([0-9][0-9]*\)$/\1/p' | tail -1)"
  pairs="$(printf '%s\n' "$text" | sed -n 's/^patch_pairs=\(.*\)$/\1/p' | tail -1)"
  if [[ -n "$off" && -n "$pairs" ]]; then
    printf '%s %s\n' "$off" "$pairs"
    return 0
  fi
  local cmd
  cmd="$(printf '%s\n' "$text" | grep -E 'ngb-patch.*--off[ =]' | tail -1 || true)"
  if [[ -z "$cmd" ]]; then
    return 1
  fi
  off="$(printf '%s\n' "$cmd" | sed -n 's/.*--off[ =]\{1,\}\([0-9][0-9]*\).*/\1/p')"
  pairs="$(printf '%s\n' "$cmd" | sed -n 's/.*--pair[ =]\{1,\}\([0-9a-fA-F]\{1,2\}:[0-9a-fA-F]\{1,2\}\).*/\1/p')"
  [[ -n "$off" && -n "$pairs" ]] || return 1
  printf '%s %s\n' "$off" "$pairs"
}

invoke_author() {
  local round_n="$1"
  local prompt="$WORK/author_prompt_r${round_n}.txt"
  local stream="$WORK/author_stream_r${round_n}.jsonl"
  local stderr="$WORK/author_stderr_r${round_n}.txt"
  local final="$WORK/author_final_r${round_n}.txt"

  {
    echo "Follow the live-ngb-author skill at $SKILL"
    echo
    cat "$prompt"
  } >"$WORK/author_invoke_r${round_n}.txt"

  local ph
  ph="$(bundle_hash "$WORK/author_invoke_r${round_n}.txt")"
  emit "{\"ts\":\"$(now)\",\"round\":$round_n,\"role\":\"harness\",\"msg_type\":\"author_invoke\",\"model\":\"$MODEL\",\"with_static_gate\":$WITH_STATIC,\"prompt_sha256\":\"$ph\"}"

  set +e
  agent -p --trust --workspace "$ROOT" \
    --output-format stream-json --stream-partial-output \
    --model "$MODEL" \
    "$(cat "$WORK/author_invoke_r${round_n}.txt")" \
    >"$stream" 2>"$stderr"
  agent_code=$?
  set -e
  [[ "$agent_code" -eq 0 ]] || fail "round $round_n: agent exit $agent_code ($(cat "$stderr"))"

  if command -v jq >/dev/null 2>&1; then
    jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' "$stream" 2>/dev/null \
      | tr -d '\r' >"$final" || true
  fi
  if [[ ! -s "$final" ]]; then
    grep '"type":"assistant"' "$stream" 2>/dev/null | sed 's/.*"text":"\([^"]*\)".*/\1/' >"$final" || true
  fi
  [[ -s "$final" ]] || cp "$stream" "$final"
}

apply_patch() {
  local round_n="$1"
  local off="$2"
  local pairs="$3"
  local in_ngb="$WORK/genesis.ngb"
  local out_ngb="$WORK/patched_r${round_n}.ngb"

  local pre
  pre="$(tools/bin/ngb-parse "$in_ngb" 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
  [[ -n "$pre" ]] || fail "round $round_n: missing precondition hash"

  emit "{\"ts\":\"$(now)\",\"round\":$round_n,\"role\":\"author\",\"msg_type\":\"patch_request\",\"precondition_hash\":\"$pre\",\"delta_off\":$off,\"delta_pairs\":\"$pairs\"}"

  set +e
  tools/bin/ngb-patch "$in_ngb" "$out_ngb" \
    --off "$off" --pair "$pairs" \
    --patch-id "$PATCH_ID" --timestamp "$PATCH_TS" >/dev/null 2>"$WORK/patch_err"
  patch_code=$?
  set -e
  [[ "$patch_code" -eq 0 ]] || fail "round $round_n: ngb-patch failed: $(cat "$WORK/patch_err")"

  local gh
  gh="$(tools/bin/ngb-parse "$out_ngb" 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
  emit "{\"ts\":\"$(now)\",\"round\":$round_n,\"role\":\"harness\",\"msg_type\":\"patched_ngb\",\"graph_root_hash\":\"$gh\"}"
  printf '%s\n' "$out_ngb"
}

static_gate() {
  local round_n="$1"
  local off="$2"
  local pairs="$3"
  local new_hex
  new_hex="$(printf '%s\n' "$pairs" | awk '{print $NF}' | awk -F: '{print $2}')"
  local microop="$WORK/r${round_n}.microop"
  cat >"$microop" <<EOF
kind=rodata_byte_write
image_off=$off
new=$new_hex
EOF

  set +e
  out="$(tools/bin/ngb-microop "$WORK/genesis.ngb" "$microop" /dev/null \
    --check-only --expect-new "$expect_new")"
  code=$?
  set -e
  echo "$out"
  if [[ "$code" -eq 0 ]]; then
    emit "{\"ts\":\"$(now)\",\"round\":$round_n,\"role\":\"harness\",\"msg_type\":\"static_gate\",\"decision\":\"accept\"}"
    return 0
  fi
  local inv detail
  inv="$(printf '%s\n' "$out" | sed -n 's/.*invariant=\([^ ]*\).*/\1/p')"
  detail="$(printf '%s\n' "$out" | sed -n 's/.*detail=\(.*\)/\1/p')"
  emit "{\"ts\":\"$(now)\",\"round\":$round_n,\"role\":\"harness\",\"msg_type\":\"static_gate\",\"decision\":\"reject\",\"invariant\":\"$inv\",\"detail\":\"$detail\"}"
  return 1
}

auditor_round() {
  local round_n="$1"
  local patched="$2"
  local bundle="$WORK/bundle_r${round_n}.txt"
  local verdict="$WORK/verdict_r${round_n}.txt"
  local want="$WORK/want_stdout"
  tools/bin/conf-eval "$ORACLE_SPEC" >"$want"

  ./scripts/agent-eval/two-agent-auditor.sh "$GENESIS" "$patched" "$want" "$bundle" "$verdict"

  local bh vline
  bh="$(bundle_hash "$bundle")"
  emit "{\"ts\":\"$(now)\",\"round\":$round_n,\"role\":\"auditor\",\"msg_type\":\"probe_bundle\",\"bundle_sha256\":\"$bh\"}"

  vline="$(tr -d '\n' <"$verdict")"
  if grep -q '^verdict=accept ' "$verdict"; then
    local gh
    gh="$(sed -n 's/.*graph_root_hash=//p' "$verdict")"
    emit "{\"ts\":\"$(now)\",\"round\":$round_n,\"role\":\"auditor\",\"msg_type\":\"verdict\",\"decision\":\"accept\",\"graph_root_hash\":\"$gh\",\"line\":\"$vline\"}"
    prior_bundle=""
    prior_verdict=""
    accepted=1
    return 0
  fi

  local inv detail
  inv="$(sed -n 's/.*invariant=\([^ ]*\).*/\1/p' "$verdict")"
  detail="$(sed -n 's/.*detail=\(.*\)/\1/p' "$verdict")"
  emit "{\"ts\":\"$(now)\",\"round\":$round_n,\"role\":\"auditor\",\"msg_type\":\"verdict\",\"decision\":\"reject\",\"invariant\":\"$inv\",\"detail\":\"$detail\",\"line\":\"$vline\"}"
  prior_bundle="$bundle"
  prior_verdict="$vline"
  return 1
}

echo "-- live-agent loop: print_42 -> computed stdout (static=$WITH_STATIC) --"

for round in $(seq 1 "$MAX_ROUNDS"); do
  prompt="$WORK/author_prompt_r${round}.txt"
  {
    echo "Round $round of $MAX_ROUNDS."
    echo "Genesis copy: $WORK/genesis.ngb"
    echo "Conf spec: $ORACLE_SPEC"
    echo "You are not told the offset. Discover the rodata byte with nano-probe disassemble on the genesis, then compute the new byte from the conf spec sum."
    if [[ -n "$prior_static" ]]; then
      echo "Prior static-gate rejection: $prior_static"
    fi
    if [[ -n "$prior_verdict" ]]; then
      echo "Prior verdict: $prior_verdict"
      echo "Prior probe_bundle: $prior_bundle"
    fi
    echo "Emit patch_off= and patch_pairs= when done."
  } >"$prompt"

  invoke_author "$round"
  parsed="$(parse_patch_from_text "$(cat "$WORK/author_final_r${round}.txt")" || true)"
  [[ -n "$parsed" ]] || fail "round $round: could not parse patch from author output"

  read -r patch_off patch_pairs <<<"$parsed"

  if [[ "$WITH_STATIC" -eq 1 ]]; then
    if ! static_gate "$round" "$patch_off" "$patch_pairs"; then
      prior_static="off=$patch_off pairs=$patch_pairs rejected before execution"
      echo "round $round: static gate rejected patch (no auditor execution)"
      continue
    fi
  fi
  prior_static=""

  patched="$(apply_patch "$round" "$patch_off" "$patch_pairs")"
  auditor_execs=$((auditor_execs + 1))
  if auditor_round "$round" "$patched"; then
    echo "round $round OK: auditor accepted"
    break
  fi
  echo "round $round: auditor rejected ($prior_verdict)"
done

[[ "$accepted" -eq 1 ]] || fail "loop ended without accept in $MAX_ROUNDS rounds"

got_hash="$(tools/bin/ngb-parse "$patched" 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
[[ "$got_hash" == "$PATCHED_HASH" ]] || fail "final hash $got_hash != oracle $PATCHED_HASH"

wall_ms=$((SECONDS * 1000))
emit "{\"ts\":\"$(now)\",\"event\":\"loop_end\",\"success\":true,\"rounds\":$round,\"auditor_execs\":$auditor_execs,\"wall_ms\":$wall_ms,\"with_static_gate\":$WITH_STATIC,\"final_graph_root_hash\":\"$got_hash\"}"

echo "LIVE-AGENT-LOOP OK rounds=$round auditor_execs=$auditor_execs wall_ms=$wall_ms static=$WITH_STATIC log=$LOG"
