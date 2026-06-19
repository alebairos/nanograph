#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PREREG="fixtures/holdout/preregistration.json"
fail() { echo "HOLDOUT-PREREG FAIL: $1" >&2; exit 1; }

[[ -f "$PREREG" ]] || fail "missing $PREREG"

python3 - "$PREREG" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    doc = json.load(f)

required_top = ("freeze_commit", "generator_sha256", "corpus", "cases", "budgets", "thresholds")
for key in required_top:
    if key not in doc:
        raise SystemExit(f"missing key {key}")

if not doc["freeze_commit"]:
    raise SystemExit("freeze_commit is empty")

if doc["corpus"] != "holdout-rev1":
    raise SystemExit(f"corpus must be holdout-rev1 (got {doc['corpus']!r})")

cases = doc["cases"]
if len(cases) != 5:
    raise SystemExit(f"expected 5 holdout cases (got {len(cases)})")

expected_labels = {
    "jemalloc-s2u",
    "conserve-popcount",
    "knuth-sgb",
    "go-base64-streaming-native",
    "rust-base64-native",
}
got_labels = {c["label"] for c in cases}
if got_labels != expected_labels:
    raise SystemExit(f"case label set mismatch: got {sorted(got_labels)}")

thresholds = doc["thresholds"]
if thresholds.get("generalizes_min_pct") != 50:
    raise SystemExit("generalizes_min_pct must be 50")
if thresholds.get("overfit_max_pct") != 25:
    raise SystemExit("overfit_max_pct must be 25")
PY

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

while IFS= read -r path expected; do
  [[ -n "${path:-}" && -n "${expected:-}" ]] || continue
  [[ -f "$path" ]] || fail "missing pinned generator $path"
  got="$(sha256_file "$path")"
  [[ "$got" == "$expected" ]] || fail "$path hash drift (got $got want $expected); update preregistration deliberately"
done < <(python3 - "$PREREG" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as f:
    doc = json.load(f)
for path, expected in doc["generator_sha256"].items():
    print(path, expected)
PY
)

while IFS= read -r manifest; do
  [[ -f "$manifest" ]] || fail "missing manifest $manifest"
  req="$(sed -n 's/^req=//p' "$manifest" | head -1)"
  rev1="$(sed -n 's/.*ngb=\([^ ]*\).*/\1/p' "$manifest" | head -1)"
  rev2="$(sed -n 's/.*ngb=\([^ ]*\).*/\1/p' "$manifest" | sed -n '2p')"
  [[ -f "$req" ]] || fail "missing req $req for $manifest"
  [[ -f "$rev1" ]] || fail "missing rev1 $rev1 for $manifest"
  [[ -f "$rev2" ]] || fail "missing rev2 $rev2 for $manifest"
done < <(python3 - "$PREREG" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as f:
    doc = json.load(f)
for case in doc["cases"]:
    print(case["manifest"])
PY
)

echo "HOLDOUT-PREREG OK freeze_commit=$(python3 -c 'import json; print(json.load(open("fixtures/holdout/preregistration.json"))["freeze_commit"])')"
