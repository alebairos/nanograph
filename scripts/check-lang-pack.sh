#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Lang-pack conformance gate (ADR-021). Three legs: mint, parse (I1-I6),
# honest accept under the declared .req. Usage:
#   check-lang-pack.sh <out.ngb> <req> -- <mint command...>

usage() {
  echo "usage: check-lang-pack.sh <out.ngb> <req> -- <mint command...>" >&2
  exit 2
}

OUT="${1:-}"
REQ="${2:-}"
[[ -n "$OUT" && -n "$REQ" && "${3:-}" == "--" ]] || usage
shift 3
[[ $# -ge 1 ]] || usage
[[ -f "$REQ" ]] || { echo "check-lang-pack: missing req $REQ" >&2; exit 2; }

if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "LANG-PACK SKIP (no Linux runner)"
  exit 0
fi

rm -f "$OUT"
"$@"
[[ -f "$OUT" ]] || {
  echo "LANG-PACK FAIL leg=mint: $* did not produce $OUT" >&2
  exit 1
}

make -C tools -s bin/ngb-parse >/dev/null
tools/bin/ngb-parse "$OUT" >/dev/null || {
  echo "LANG-PACK FAIL leg=integrity: ngb-parse rejected $OUT" >&2
  exit 1
}

verdict="$(./scripts/nanograph verify --expect accept "$OUT" "$REQ" | tail -1)"
grep -q '^verdict=accept' <<<"$verdict" || {
  echo "LANG-PACK FAIL leg=behavior: $verdict" >&2
  exit 1
}

echo "LANG-PACK OK ngb=$OUT req=$REQ $verdict"
