#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI required" >&2
  exit 1
fi

create_label() {
  local name="$1" color="$2" desc="$3"
  if gh label list --json name --jq '.[].name' | grep -qx "$name"; then
    echo "exists: $name"
  else
    gh label create "$name" --color "$color" --description "$desc"
    echo "created: $name"
  fi
}

for m in 5 6 7; do
  create_label "milestone:m${m}" "1D76DB" "NanoGraph milestone M${m}"
done

for p in $(seq -w 1 20); do
  n=$((10#$p))
  create_label "milestone:p${p}" "8250DF" "Product proof step P${n}"
done

create_label "type:product-proof" "FBCA04" "Product proof program (P01-P20)"
create_label "meta:product-program" "B60205" "NanoGraph product proof queue"

echo "OK: product proof labels ready"
