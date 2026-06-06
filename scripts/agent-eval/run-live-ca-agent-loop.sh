#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() { echo "LIVE-CA-AGENT-LOOP FAIL: $1" >&2; exit 1; }

MODEL="${LIVE_AGENT_MODEL:-composer-2.5}"
MAX_ROUNDS=5
GENESIS="fixtures/ca/ca_rule30_patched.ngb"
ORACLE_SPEC="fixtures/ca/rule30.spec"
PATCH_ID=3
PATCH_TS=1700000002
LOG_DIR=".harness-data/agent-eval/live-ca"
LOG="$LOG_DIR/run.jsonl"

usage() {
  echo "usage: run-live-ca-agent-loop.sh [--model NAME]" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --model) MODEL="$2"; shift 2 ;;
  -h | --help) usage ;;
  *) fail "unknown arg $1" ;;
  esac
done

./scripts/check-live-ca-agent-prereqs.sh >/dev/null
./scripts/check-linux-runner.sh --quiet || fail "need Linux runner for CA auditor"

mkdir -p "$LOG_DIR"
: >"$LOG"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

SANDBOX="$WORK/author-sandbox"
./scripts/agent-eval/prepare-author-sandbox-ca.sh "$SANDBOX"

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

cp "$GENESIS" "$WORK/genesis.ngb"

SECONDS=0
emit "{\"ts\":\"$(now)\",\"event\":\"loop_start\",\"genesis\":\"$GENESIS\",\"sandbox\":\"$SANDBOX\",\"model\":\"$MODEL\",\"task\":\"ca_rule30\"}"

accepted=0
prior_verdict=""

parse_patch_from_text() {
  local text="$1"
  local off pairs
  off="$(printf '%s\n' "$text" | sed -n 's/^patch_off=\([0-9][0-9]*\)$/\1/p' | tail -1)"
  pairs="$(printf '%s\n' "$text" | sed -n 's/^patch_pairs=\(.*\)$/\1/p' | tail -1)"
  if [[ -n "$off" && -n "$pairs" ]]; then
    printf '%s %s\n' "$off" "$pairs"
    return 0
  fi
  return 1
}

invoke_author() {
  local round_n="$1"
  local prompt="$WORK/author_prompt_r${round_n}.txt"
  local stream="$WORK/author_stream_r${round_n}.jsonl"
  local stream_log="$LOG_DIR/stream_r${round_n}.jsonl"
  local stderr="$WORK/author_stderr_r${round_n}.txt"
  local final="$WORK/author_final_r${round_n}.txt"

  {
    echo "Follow author/SKILL.md in this workspace."
    echo
    cat "$prompt"
  } >"$WORK/author_invoke_r${round_n}.txt"

  emit "{\"ts\":\"$(now)\",\"round\":$round_n,\"role\":\"harness\",\"msg_type\":\"author_invoke\",\"model\":\"$MODEL\",\"sandbox\":\"$SANDBOX\"}"

  set +e
  agent -p --trust --workspace "$SANDBOX" --sandbox enabled \
    --output-format stream-json --stream-partial-output \
    --model "$MODEL" \
    "$(cat "$WORK/author_invoke_r${round_n}.txt")" \
    >"$stream" 2>"$stderr"
  agent_code=$?
  set -e
  [[ "$agent_code" -eq 0 ]] || fail "round $round_n: agent exit $agent_code ($(cat "$stderr"))"

  cp "$stream" "$stream_log"
  ./scripts/agent-eval/audit-author-isolation.sh "$SANDBOX" "$stream"

  if command -v jq >/dev/null 2>&1; then
    jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' "$stream" 2>/dev/null \
      | tr -d '\r' >"$final" || true
  fi
  if [[ ! -s "$final" ]]; then
    grep '"type":"assistant"' "$stream" 2>/dev/null | sed 's/.*"text":"\([^"]*\)".*/\1/' >"$final" || true
  fi
  [[ -s "$final" ]] || cp "$stream" "$final"
}

copy_feedback_to_sandbox() {
  cp "$1" "$SANDBOX/feedback/probe_bundle.txt"
  printf '%s\n' "$2" >"$SANDBOX/feedback/verdict.txt"
}

apply_patch() {
  local round_n="$1"
  local off="$2"
  local pairs="$3"
  local out_ngb="$WORK/patched_r${round_n}.ngb"

  emit "{\"ts\":\"$(now)\",\"round\":$round_n,\"role\":\"author\",\"msg_type\":\"patch_request\",\"delta_off\":$off,\"delta_pairs\":\"$pairs\"}"

  set +e
  tools/bin/ngb-patch "$WORK/genesis.ngb" "$out_ngb" \
    --off "$off" --pair "$pairs" \
    --patch-id "$PATCH_ID" --timestamp "$PATCH_TS" >/dev/null 2>"$WORK/patch_err"
  patch_code=$?
  set -e
  [[ "$patch_code" -eq 0 ]] || fail "round $round_n: ngb-patch failed: $(cat "$WORK/patch_err")"

  printf '%s\n' "$out_ngb"
}

auditor_round() {
  local round_n="$1"
  local patched="$2"
  local bundle="$WORK/bundle_r${round_n}.txt"
  local verdict="$WORK/verdict_r${round_n}.txt"
  local want="$WORK/want_stdout"
  tools/bin/conf-eval "$ORACLE_SPEC" >"$want"

  ./scripts/agent-eval/two-agent-auditor.sh "$GENESIS" "$patched" "$want" "$bundle" "$verdict"

  vline="$(tr -d '\n' <"$verdict")"
  if grep -q '^verdict=accept ' "$verdict"; then
    emit "{\"ts\":\"$(now)\",\"round\":$round_n,\"role\":\"auditor\",\"msg_type\":\"verdict\",\"decision\":\"accept\",\"line\":\"$vline\"}"
    accepted=1
    return 0
  fi

  emit "{\"ts\":\"$(now)\",\"round\":$round_n,\"role\":\"auditor\",\"msg_type\":\"verdict\",\"decision\":\"reject\",\"line\":\"$vline\"}"
  prior_verdict="$vline"
  copy_feedback_to_sandbox "$bundle" "$vline"
  return 1
}

echo "-- live-ca loop: patched rule30 specimen -> computed grid stdout --"

for round in $(seq 1 "$MAX_ROUNDS"); do
  prompt="$WORK/author_prompt_r${round}.txt"
  {
    echo "Round $round of $MAX_ROUNDS."
    echo "Genesis: genesis.ngb (miscompiled rule byte; fix from intent.spec)."
    echo "Intent: intent.spec (op=eca parameters and yield=stdout)."
    if [[ -n "$prior_verdict" ]]; then
      echo "Prior verdict is in feedback/verdict.txt"
      echo "Prior probe bundle is in feedback/probe_bundle.txt"
    fi
    echo "Emit patch_off= and patch_pairs= when done."
  } >"$prompt"

  invoke_author "$round"
  parsed="$(parse_patch_from_text "$(cat "$WORK/author_final_r${round}.txt")" || true)"
  [[ -n "$parsed" ]] || fail "round $round: could not parse patch from author output"

  read -r patch_off patch_pairs <<<"$parsed"
  patched="$(apply_patch "$round" "$patch_off" "$patch_pairs")"
  if auditor_round "$round" "$patched"; then
    echo "round $round OK: auditor accepted"
    break
  fi
  echo "round $round: auditor rejected ($prior_verdict)"
done

[[ "$accepted" -eq 1 ]] || fail "loop ended without accept in $MAX_ROUNDS rounds"

got_hash="$(tools/bin/ngb-parse "$patched" 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"

wall_ms=$((SECONDS * 1000))
emit "{\"ts\":\"$(now)\",\"event\":\"loop_end\",\"success\":true,\"rounds\":$round,\"wall_ms\":$wall_ms,\"final_graph_root_hash\":\"$got_hash\"}"

echo "LIVE-CA-AGENT-LOOP OK rounds=$round wall_ms=$wall_ms log=$LOG"
