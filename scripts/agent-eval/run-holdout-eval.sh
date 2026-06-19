#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

PREREG="fixtures/holdout/preregistration.json"
RESULTS="fixtures/holdout/results-frozen.json"

fail() { echo "HOLDOUT-EVAL FAIL: $1" >&2; exit 1; }

[[ -f "$PREREG" ]] || fail "missing $PREREG"

./scripts/check-holdout-prereg.sh || fail "preregistration check failed"

if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "HOLDOUT-EVAL SKIP (no Linux runner)"
  exit 0
fi

run_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
freeze_commit="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["freeze_commit"])' "$PREREG")"

out="$(./scripts/agent-eval/blind-probe-search.sh \
  --corpus holdout-rev1 \
  --budget default \
  --verdict holdout 2>&1)" || true

echo "$out"

verdict="$(sed -n 's/^BLIND-PROBE-SEARCH VERDICT //p' <<<"$out" | tail -1)"
summary="$(sed -n 's/^BLIND-PROBE-SEARCH SUMMARY //p' <<<"$out" | tail -1)"
[[ -n "$verdict" ]] || fail "missing verdict line in search output"
[[ -n "$summary" ]] || fail "missing summary line in search output"

true_found="$(sed -n 's/.*true_found=\([0-9]*\).*/\1/p' <<<"$summary" | head -1)"
total="$(sed -n 's/.*total=\([0-9]*\).*/\1/p' <<<"$summary" | head -1)"
found="$(sed -n 's/.*found=\([0-9]*\).*/\1/p' <<<"$summary" | head -1)"
both_reject="$(sed -n 's/.*both_reject=\([0-9]*\).*/\1/p' <<<"$summary" | head -1)"
miss="$(sed -n 's/.*miss=\([0-9]*\).*/\1/p' <<<"$summary" | head -1)"
err="$(sed -n 's/.*error=\([0-9]*\).*/\1/p' <<<"$summary" | head -1)"
true_rate="$(sed -n 's/.*true_rate=\([0-9]*\)%/\1/p' <<<"$summary" | head -1)"

case_lines=()
while IFS= read -r line; do
  [[ "$line" == case=* ]] || continue
  case_lines+=("$line")
done < <(grep '^case=' <<<"$out" || true)

python3 - "$RESULTS" "$run_ts" "$freeze_commit" "$verdict" \
  "$true_found" "$total" "$found" "$both_reject" "$miss" "$err" "$true_rate" \
  "${case_lines[@]}" <<'PY'
import json
import sys

path = sys.argv[1]
run_ts = sys.argv[2]
freeze_commit = sys.argv[3]
verdict = sys.argv[4]
true_found = int(sys.argv[5])
total = int(sys.argv[6])
found = int(sys.argv[7])
both_reject = int(sys.argv[8])
miss = int(sys.argv[9])
err = int(sys.argv[10])
true_rate = int(sys.argv[11])
case_lines = sys.argv[12:]

doc = {
    "run_timestamp": run_ts,
    "freeze_commit": freeze_commit,
    "corpus": "holdout-rev1",
    "case_lines": case_lines,
    "summary": {
        "true_found": true_found,
        "total": total,
        "found": found,
        "both_reject": both_reject,
        "miss": miss,
        "error": err,
        "true_rate_pct": true_rate,
    },
    "verdict": verdict,
}

with open(path, "w", encoding="utf-8") as f:
    json.dump(doc, f, indent=2)
    f.write("\n")
PY

echo "HOLDOUT-EVAL wrote $RESULTS verdict=$verdict true_found=$true_found/$total (${true_rate}%)"
echo "HOLDOUT-EVAL VERDICT $verdict"
