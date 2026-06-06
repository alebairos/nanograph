#!/usr/bin/env bash
set -euo pipefail

fail() { echo "AUDIT-AUTHOR-ISOLATION FAIL: $1" >&2; exit 1; }

[[ $# -eq 2 ]] || fail "usage: audit-author-isolation.sh <sandbox_dir> <stream.jsonl>"

SANDBOX="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
STREAM="$2"

[[ -d "$SANDBOX" ]] || fail "missing sandbox $SANDBOX"
[[ -f "$STREAM" ]] || fail "missing stream $STREAM"

violations=0
note_violation() {
  echo "ISOLATION VIOLATION: $1" >&2
  violations=$((violations + 1))
}

path_under_sandbox() {
  local p="$1"
  [[ -z "$p" ]] && return 1
  case "$p" in
  /*)
    [[ "$p" == "$SANDBOX"/* || "$p" == "$SANDBOX" ]]
    ;;
  *)
    return 0
    ;;
  esac
}

LEAK_RE='fixtures/|docs/|\.cursor/|harness-data/|print_42_patched|patch-fixture|check-all-proofs|NANO-GOALS|MICROOP-FLOOR'

if command -v jq >/dev/null 2>&1; then
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    if ! path_under_sandbox "$path"; then
      note_violation "tool read outside sandbox: $path"
    fi
    if printf '%s' "$path" | grep -qE "$LEAK_RE"; then
      note_violation "forbidden path token: $path"
    fi
  done < <(jq -r '
    .tool_call.readToolCall.args.path?,
    .tool_call.writeToolCall.args.path?,
    .tool_call.grepToolCall.args.path?,
    .tool_call.globToolCall.args.path?
  ' "$STREAM" 2>/dev/null | sort -u)
fi

while IFS= read -r line; do
  if printf '%s' "$line" | grep -qE "$LEAK_RE"; then
    note_violation "stream mentions forbidden token: $(printf '%.120s' "$line")"
  fi
  if printf '%s' "$line" | grep -Eo '/[^ "]+' | while read -r p; do
    case "$p" in
    "$SANDBOX"/* | "$SANDBOX") ;;
    /Users/* | /home/* | /var/* | /tmp/*)
      if [[ "$p" != "$SANDBOX"* ]]; then
        note_violation "absolute path outside sandbox: $p"
      fi
      ;;
    esac
  done; then
    :
  fi
done <"$STREAM"

[[ "$violations" -eq 0 ]] || fail "$violations isolation violation(s); see stderr"

echo "AUDIT-AUTHOR-ISOLATION OK sandbox=$SANDBOX"
