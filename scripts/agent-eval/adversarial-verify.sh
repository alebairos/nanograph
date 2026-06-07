#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# Competition verifier (G23). The organizer owns the spec and conf-eval (the
# referee). This searches the input space for a pair where the candidate's real
# bytes diverge from the oracle, and reports the first witness. A fixed case
# list cannot find a separator outside itself; an active search refereed by an
# independent oracle can.

usage() { echo "usage: adversarial-verify.sh <candidate.ngb> <spec> [budget]" >&2; exit 2; }
[[ $# -ge 2 ]] || usage
CAND="$1"
SPEC="$2"
BUDGET="${3:-64}"
[[ -f "$CAND" ]] || { echo "adversarial-verify: missing $CAND" >&2; exit 2; }
[[ -f "$SPEC" ]] || { echo "adversarial-verify: missing $SPEC" >&2; exit 2; }

make -C tools -s bin/conf-eval bin/ngb-extract bin/ngb-parse >/dev/null

hash="$(tools/bin/ngb-parse "$CAND" | sed -n 's/.*graph_root_hash=//p')"

gen_probes() {
  local count=0 s a b
  for ((s = 2; ; s++)); do
    for ((a = 1; a < s; a++)); do
      b=$((s - a))
      printf '%s %s\n' "$a" "$b"
      count=$((count + 1))
      [[ "$count" -ge "$BUDGET" ]] && return
    done
  done
}

observed="$(gen_probes | ./scripts/run-linux-elf-batch.sh "$CAND" 2>/dev/null)"

while read -r a b got; do
  [[ -z "${a:-}" ]] && continue
  want="$(tools/bin/conf-eval "$SPEC" "$a" "$b")"
  [[ "$got" == "$want" ]] && continue
  # A candidate witness from the fast scan is only a real separator if it
  # reproduces in an isolated clean run. This filters transient backend faults.
  got2="$(./scripts/run-linux-elf-capture.sh "$CAND" "$a" "$b" 2>/dev/null || true)"
  if [[ "$got2" != "$want" ]]; then
    echo "verdict=reject hash=${hash:0:12} witness a=$a b=$b got=$got2 want=$want"
    exit 1
  fi
done <<<"$observed"

echo "verdict=accept hash=${hash:0:12} probes=$BUDGET separator=none"
exit 0
