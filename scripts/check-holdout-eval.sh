#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PREREG="fixtures/holdout/preregistration.json"
RESULTS="fixtures/holdout/results-frozen.json"
fail() { echo "HOLDOUT-EVAL-CHECK FAIL: $1" >&2; exit 1; }

[[ -f "$PREREG" ]] || fail "missing $PREREG"
[[ -f "$RESULTS" ]] || fail "missing $RESULTS (run ./scripts/agent-eval/run-holdout-eval.sh on Linux runner)"

python3 - "$PREREG" "$RESULTS" <<'PY'
import json
import sys

prereg_path, results_path = sys.argv[1], sys.argv[2]
with open(prereg_path, encoding="utf-8") as f:
    prereg = json.load(f)
with open(results_path, encoding="utf-8") as f:
    results = json.load(f)

required = (
    "run_timestamp",
    "freeze_commit",
    "corpus",
    "case_lines",
    "summary",
    "verdict",
)
for key in required:
    if key not in results:
        raise SystemExit(f"results missing key {key}")

if results["freeze_commit"] != prereg["freeze_commit"]:
    raise SystemExit(
        f"freeze_commit mismatch: results={results['freeze_commit']!r} prereg={prereg['freeze_commit']!r}"
    )

if results["corpus"] != "holdout-rev1":
    raise SystemExit(f"corpus must be holdout-rev1 (got {results['corpus']!r})")

summary = results["summary"]
for key in ("true_found", "total", "found", "both_reject", "miss", "error", "true_rate_pct"):
    if key not in summary:
        raise SystemExit(f"summary missing {key}")

total = summary["total"]
if total != 5:
    raise SystemExit(f"expected total=5 (got {total})")

true_found = summary["true_found"]
true_rate = summary["true_rate_pct"]
if total > 0 and true_rate != (true_found * 100 // total):
    raise SystemExit(
        f"true_rate_pct mismatch: got {true_rate}, want {true_found * 100 // total}"
    )

gen_min = prereg["thresholds"]["generalizes_min_pct"]
over_max = prereg["thresholds"]["overfit_max_pct"]
verdict = results["verdict"]

if true_rate >= gen_min:
    expected = "generalizes_bounded"
elif true_rate < over_max:
    expected = "overfit"
else:
    expected = "inconclusive"

if verdict != expected:
    raise SystemExit(
        f"verdict {verdict!r} does not match thresholds (true_rate={true_rate}%, expected {expected!r})"
    )

if len(results["case_lines"]) != total:
    raise SystemExit(
        f"case_lines count {len(results['case_lines'])} != summary.total {total}"
    )
PY

echo "HOLDOUT-EVAL-CHECK OK verdict=$(python3 -c 'import json; print(json.load(open("fixtures/holdout/results-frozen.json"))["verdict"])')"
