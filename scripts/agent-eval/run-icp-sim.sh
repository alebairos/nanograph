#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() { echo "ICP-SIM FAIL: $1" >&2; exit 1; }

if [[ -f "$ROOT/.env" ]]; then
  set -a
  if grep -q '^=CURSOR_API_KEY=' "$ROOT/.env" 2>/dev/null; then
    echo "ICP-SIM WARN: .env line starts with '='; sourcing sanitized copy" >&2
    tmp_env="$(mktemp)"
    sed 's/^=CURSOR_API_KEY=/CURSOR_API_KEY=/' "$ROOT/.env" >"$tmp_env"
    # shellcheck disable=SC1090
    source "$tmp_env"
    rm -f "$tmp_env"
  else
    # shellcheck disable=SC1091
    source "$ROOT/.env"
  fi
  set +a
fi

MODEL="${ICP_SIM_MODEL:-composer-2.5}"
KEEP_SANDBOX=0
BASELINE="fixtures/icp-sim/baseline.json"
SKIP_BASELINE=0
UPDATE_BASELINE=0

usage() {
  echo "usage: run-icp-sim.sh [--model NAME] [--baseline PATH] [--skip-baseline] [--update-baseline] [--keep-sandbox]" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --model) MODEL="$2"; shift 2 ;;
  --baseline) BASELINE="$2"; shift 2 ;;
  --skip-baseline) SKIP_BASELINE=1; shift ;;
  --update-baseline) UPDATE_BASELINE=1; shift ;;
  --keep-sandbox) KEEP_SANDBOX=1; shift ;;
  -h | --help) usage ;;
  *) fail "unknown arg $1" ;;
  esac
done

command -v agent >/dev/null 2>&1 || fail "cursor agent CLI not found"
if [[ -z "${CURSOR_API_KEY:-}" ]]; then
  agent status >/dev/null 2>&1 || fail "set CURSOR_API_KEY or run agent login"
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR=".harness-data/agent-eval/icp-sim/run-$TS"
mkdir -p "$OUT_DIR"

WORK="$(mktemp -d)"
if [[ "$KEEP_SANDBOX" -eq 0 ]]; then
  trap 'rm -rf "$WORK"' EXIT
fi

SANDBOX="$WORK/icp-sim-sandbox"
./scripts/agent-eval/prepare-icp-sim-sandbox.sh "$SANDBOX"

PROMPT="Read PERSONA.md in this workspace and follow it exactly. You are the maintainer it describes. Produce STALL-REPORT.md as specified before you finish."

SECONDS=0
set +e
agent -p --trust --workspace "$SANDBOX" --sandbox disabled \
  --output-format stream-json --stream-partial-output \
  --model "$MODEL" \
  "$PROMPT" \
  >"$OUT_DIR/stream.jsonl" 2>"$OUT_DIR/stderr.txt"
agent_code=$?
set -e
wall_s=$SECONDS

[[ "$agent_code" -eq 0 ]] || fail "agent exit $agent_code ($(tail -3 "$OUT_DIR/stderr.txt" 2>/dev/null))"

[[ -f "$SANDBOX/STALL-REPORT.md" ]] || fail "agent finished without STALL-REPORT.md"
cp "$SANDBOX/STALL-REPORT.md" "$OUT_DIR/STALL-REPORT.md"

RESULT_LINE="$(grep -E '^ICP-SIM RESULT completed=(yes|no) first_stall=(none|[0-9]+) friction=[0-9]+$' "$OUT_DIR/STALL-REPORT.md" | tail -1 || true)"
[[ -n "$RESULT_LINE" ]] || fail "STALL-REPORT.md missing parseable result line"

if [[ "$UPDATE_BASELINE" -eq 1 ]]; then
  if command -v jq >/dev/null 2>&1; then
    completed="$(sed -n 's/^ICP-SIM RESULT completed=\([^ ]*\).*/\1/p' <<<"$RESULT_LINE")"
    first_stall="$(sed -n 's/^ICP-SIM RESULT completed=[^ ]* first_stall=\([^ ]*\).*/\1/p' <<<"$RESULT_LINE")"
    friction="$(sed -n 's/^ICP-SIM RESULT .* friction=\([0-9]*\)$/\1/p' <<<"$RESULT_LINE")"
    jq --arg c "$completed" --arg f "$first_stall" --argjson fr "$friction" \
      '.expect.completed = $c | .expect.first_stall = $f | .expect.friction_max = $fr | del(.expect.first_stall_not_before)' \
      "$BASELINE" >"${BASELINE}.tmp" && mv "${BASELINE}.tmp" "$BASELINE"
  else
    fail "--update-baseline requires jq"
  fi
fi

if [[ "$SKIP_BASELINE" -eq 0 ]]; then
  ./scripts/check-icp-sim-eval.sh "$OUT_DIR/STALL-REPORT.md" "$BASELINE"
fi

echo "ICP-SIM OK model=$MODEL wall_s=$wall_s out=$OUT_DIR"
echo "$RESULT_LINE"
if [[ "$KEEP_SANDBOX" -eq 1 ]]; then
  echo "sandbox kept at $SANDBOX"
fi
