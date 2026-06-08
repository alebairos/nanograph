#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Gate rule: a case is a FIT only when all four fit factors (oracle_hardness,
# property_checkable, observable, silent_survival) are >= 1 at once. A single
# zero in any factor means there is no usable oracle/property/observation/decay
# path, so high scores elsewhere cannot rescue it. criticality scales priority
# but never grants the gate.

die() { echo "score-case-fit: $1" >&2; exit 2; }

FILE="${1:-}"
[[ -n "$FILE" && -f "$FILE" ]] || { echo "usage: score-case-fit.sh <file.fit>" >&2; exit 2; }

getval() {
  sed -n "s/^$1=//p" "$FILE" | head -n1 \
    | sed 's/[[:space:]]*#.*$//' \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

numeric_keys="oracle_hardness property_checkable observable silent_survival criticality"
for key in $numeric_keys; do
  val="$(getval "$key")"
  [[ -n "$val" ]] || die "missing $key"
  [[ "$val" =~ ^-?[0-9]+$ ]] || die "$key not an integer: $val"
  [[ "$val" -ge 0 && "$val" -le 2 ]] || die "$key out of range 0..2: $val"
  eval "$key=$val"
done

name="$(getval name)"
relation="$(getval relation)"

fit_score=$(( oracle_hardness + property_checkable + observable + silent_survival ))
priority=$(( fit_score * criticality ))

zero_factors=""
for f in oracle_hardness property_checkable observable silent_survival; do
  if [[ "${!f}" -eq 0 ]]; then
    zero_factors="${zero_factors:+$zero_factors,}$f"
  fi
done

printf 'case=%s relation=%s\n' "$name" "$relation"
printf '  %-18s  %d\n' oracle_hardness "$oracle_hardness"
printf '  %-18s  %d\n' property_checkable "$property_checkable"
printf '  %-18s  %d\n' observable "$observable"
printf '  %-18s  %d\n' silent_survival "$silent_survival"
printf '  --------------------------------\n'

if [[ -z "$zero_factors" ]]; then
  printf '  gate=FIT fit_score=%d/8 criticality=%d priority=%d\n' "$fit_score" "$criticality" "$priority"
  exit 0
else
  printf '  gate=NOT-A-FIT fit_score=%d/8 zero_factors=%s\n' "$fit_score" "$zero_factors"
  exit 1
fi
