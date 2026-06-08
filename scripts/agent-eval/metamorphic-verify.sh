#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# Metamorphic verifier (G24). Checks a binary against a relation that is its own
# oracle, so no expected output is computed. The VerificationRequest (.req)
# declares relation, entry, domain, eq. The only relation implemented is
# involution: f(f(x)) == x. A candidate witness from the fast batched scan is
# confirmed by an isolated clean re-run, which filters transient backend faults.

usage() { echo "usage: metamorphic-verify.sh <candidate.ngb> <request.req>" >&2; exit 2; }
[[ $# -ge 2 ]] || usage
CAND="$1"
REQ="$2"
[[ -f "$CAND" ]] || { echo "metamorphic-verify: missing $CAND" >&2; exit 2; }
[[ -f "$REQ" ]] || { echo "metamorphic-verify: missing $REQ" >&2; exit 2; }

reqval() { sed -n "s/^$1=//p" "$REQ" | head -1; }
RELATION="$(reqval relation)"
DOMAIN="$(reqval domain)"

make -C tools -s bin/ngb-extract bin/ngb-parse >/dev/null
hash="$(tools/bin/ngb-parse "$CAND" | sed -n 's/.*graph_root_hash=//p')"

gen_u32() {
  local k
  for ((k = 0; k < 32; k++)); do printf '%s\n' "$((1 << k))"; done
  printf '%s\n' 0 305419896 3735928559 16909060 4294967295
}

gen_probes() {
  case "$DOMAIN" in
    u32) gen_u32 ;;
    *) echo "metamorphic-verify: unsupported domain=$DOMAIN" >&2; exit 2 ;;
  esac
}

apply_once() {
  while read -r p; do [[ -z "$p" ]] && continue; printf '%s %s\n' "$p" "$p"; done \
    | ./scripts/run-linux-elf-batch.sh "$CAND" 2>/dev/null | awk '{print $3}'
}

if [[ "$RELATION" != involution ]]; then
  echo "metamorphic-verify: unsupported relation=$RELATION (only involution)" >&2
  exit 2
fi

probes=()
while read -r p; do probes+=("$p"); done < <(gen_probes)

ys=()
while read -r y; do ys+=("$y"); done < <(printf '%s\n' "${probes[@]}" | apply_once)

ys_filled=()
for y in "${ys[@]}"; do ys_filled+=("${y:-0}"); done

zs=()
while read -r z; do zs+=("$z"); done < <(printf '%s\n' "${ys_filled[@]}" | apply_once)

for i in "${!probes[@]}"; do
  x="${probes[$i]}"
  y="${ys[$i]:-}"
  z="${zs[$i]:-}"
  [[ -n "$y" && "$z" == "$x" ]] && continue
  y2="$(./scripts/run-linux-elf-capture.sh "$CAND" "$x" 2>/dev/null || true)"
  z2="$(./scripts/run-linux-elf-capture.sh "$CAND" "$y2" 2>/dev/null || true)"
  if [[ "$z2" != "$x" ]]; then
    echo "verdict=reject hash=${hash:0:12} relation=involution witness x=$x fx=$y2 ffx=$z2"
    exit 1
  fi
done

echo "verdict=accept hash=${hash:0:12} relation=involution probes=${#probes[@]} separator=none"
exit 0
