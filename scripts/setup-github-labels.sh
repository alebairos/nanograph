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

for m in 0 1 2 3 4; do
  create_label "milestone:m${m}" "1D76DB" "NanoGraph milestone M${m}"
done

create_label "type:feature" "0E8A16" "New behavior or tool"
create_label "type:bug" "D73A4A" "Defect fix"
create_label "type:chore" "FEF2C0" "Maintenance"
create_label "type:docs" "0075CA" "Documentation"
create_label "type:harness" "5319E7" "Agent harness / process"

create_label "area:ngb" "BFD4F2" ".ngb format and pack/parse"
create_label "area:probe" "C5DEF5" "NanoProbe tools"
create_label "area:harness" "D4C5F9" "Cursor harness and loop"
create_label "area:docs" "E99695" "Canonical docs"

create_label "meta:umbrella" "F9D0C4" "Parent tracking issue"

echo "OK: labels ready"
