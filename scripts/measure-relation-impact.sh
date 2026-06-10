#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Separation matrix: which relation accepts/rejects which mutant. Impact report for G66–G69.
# Exit 0 always; prints table to stdout.

if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "MEASURE-RELATION-IMPACT SKIP (no Linux runner)"
  exit 0
fi

REL="./scripts/agent-eval/metamorphic-verify.sh"

probe() {
  local ngb="$1" req="$2"
  if out="$("$REL" "$ngb" "$req" 2>/dev/null)"; then
    if [[ "$out" == *"verdict=accept"* ]]; then echo accept; else echo "?"; fi
  else
    if [[ "$out" == *"verdict=reject"* ]]; then echo reject; else echo error; fi
  fi
}

echo "== relation separation matrix (impact) =="
printf "%-28s %-14s %-14s %-14s %-14s\n" "specimen" "linear_xor" "conserve_pc" "flow_comp" "round_trip"
printf "%-28s %-14s %-14s %-14s %-14s\n" "--------" "----------" "-----------" "---------" "----------"

rows=(
  "ca_step90.ngb|fixtures/metamorphic/ca_step90.req|fixtures/metamorphic/ca_step184.req|fixtures/metamorphic/ca_flow90.req|fixtures/metamorphic/utf8.req"
  "ca_step90_evil.ngb|fixtures/metamorphic/ca_step90.req|fixtures/metamorphic/ca_step184.req|fixtures/metamorphic/ca_flow90.req|fixtures/metamorphic/utf8.req"
  "ca_step184.ngb|fixtures/metamorphic/ca_step90.req|fixtures/metamorphic/ca_step184.req|fixtures/metamorphic/ca_flow90.req|fixtures/metamorphic/utf8.req"
  "ca_step184_evil.ngb|fixtures/metamorphic/ca_step90.req|fixtures/metamorphic/ca_step184.req|fixtures/metamorphic/ca_flow90.req|fixtures/metamorphic/utf8.req"
  "ca_flow90_evil.ngb|fixtures/metamorphic/ca_step90.req|fixtures/metamorphic/ca_step184.req|fixtures/metamorphic/ca_flow90.req|fixtures/metamorphic/utf8.req"
)

for row in "${rows[@]}"; do
  IFS='|' read -r spec lx cp fc rt <<<"$row"
  ngb="fixtures/metamorphic/$spec"
  [[ -f "$ngb" ]] || { echo "missing $ngb"; continue; }
  printf "%-28s %-14s %-14s %-14s %-14s\n" "$spec" \
    "$(probe "$ngb" "$lx")" \
    "$(probe "$ngb" "$cp")" \
    "$(probe "$ngb" "$fc")" \
    "$(probe "$ngb" "$rt")"
done

echo ""
echo "Expected impact:"
echo "  ca_step90.ngb: linear_xor=accept; conserve_pc=reject (rule 90 is not particle-conserving)"
echo "  ca_step184.ngb: conserve_pc=accept"
echo "  ca_step90_evil: linear_xor=reject"
echo "  ca_step184_evil: conserve_pc=reject"
echo "  ca_flow90_evil: flow_comp=reject"
echo "MEASURE-RELATION-IMPACT OK"
