#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

manifest="${1:-}"
[[ -n "$manifest" && -f "$manifest" ]] || { echo "usage: backtest-relation.sh <manifest>" >&2; exit 2; }

VERIFY="./scripts/agent-eval/metamorphic-verify.sh"
req="$(sed -n 's/^req=//p' "$manifest" | head -1)"
[[ -n "$req" ]] || { echo "backtest-relation: manifest has no req=" >&2; exit 2; }

fmt='%-17s %-9s %-9s %s\n'
printf "$fmt" rev verdict expect witness

fail=0
while IFS= read -r line; do
  case "$line" in
    rev=*) ;;
    *) continue ;;
  esac
  rev="$(printf '%s' "$line" | sed -n 's/.*rev=\([^ ]*\).*/\1/p')"
  ngb="$(printf '%s' "$line" | sed -n 's/.*ngb=\([^ ]*\).*/\1/p')"
  expect="$(printf '%s' "$line" | sed -n 's/.*expect=\([^ ]*\).*/\1/p')"

  # An empty verdict is a backend fault (qemu/docker under load), not a
  # relation outcome; retry those like the witness re-run policy. A parsed
  # accept/reject is never retried.
  verdict=""
  for attempt in 1 2 3; do
    out="$("$VERIFY" "$ngb" "$req" 2>/dev/null || true)"
    verdict="$(printf '%s' "$out" | sed -n 's/.*verdict=\([a-z]*\).*/\1/p')"
    [[ -n "$verdict" ]] && break
  done
  hex="$(printf '%s' "$out" | sed -n 's/.*hex=\([0-9A-Fa-f]*\).*/\1/p')"
  inv_x="$(printf '%s' "$out" | sed -n 's/.*witness x=\([^ ]*\).*/\1/p')"

  if [[ -n "$hex" ]]; then witness="hex=$hex"
  elif [[ -n "$inv_x" ]]; then witness="x=$inv_x"
  else witness="-"
  fi
  printf "$fmt" "$rev" "${verdict:--}" "$expect" "$witness"

  [[ "$verdict" == "$expect" ]] || fail=1
done < "$manifest"

[[ "$fail" -eq 0 ]]
