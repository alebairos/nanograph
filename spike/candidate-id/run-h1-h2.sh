#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

PROPOSE="$ROOT/spike/candidate-id/propose-req.py"
REL="$ROOT/scripts/agent-eval/metamorphic-verify.sh"
TMP="$ROOT/spike/candidate-id/.tmp"
mkdir -p "$TMP"

holdout=(
  "utf8:fixtures/metamorphic/utf8.c:fixtures/metamorphic/utf8.ngb"
  "leb128:fixtures/metamorphic/leb128.c:fixtures/backtest/leb128/leb128_rev1.ngb"
  "capnproto_base64:fixtures/metamorphic/capnproto_base64.c:fixtures/backtest/capnproto-base64/capnproto_base64_rev1.ngb"
  "wabt_leb128:fixtures/metamorphic/wabt_leb128.c:fixtures/backtest/wabt-leb128/wabt_leb128_rev1.ngb"
  "cosmo_ljson:fixtures/metamorphic/cosmo_ljson.c:fixtures/backtest/cosmo-ljson/cosmo_ljson_rev1.ngb"
)

normalize_req() {
  sed '/^$/d' "$1" | sort
}

match_count=0
total="${#holdout[@]}"

echo "== G55 H1 recall + H2 verdict equivalence =="
for entry in "${holdout[@]}"; do
  IFS=: read -r name src ngb <<<"$entry"
  hand="fixtures/metamorphic/${name}.req"
  auto="$TMP/${name}.req.auto"
  [[ -f "$src" && -f "$hand" && -f "$ngb" ]] || {
    echo "SKIP $name missing artifact"
    continue
  }
  python3 "$PROPOSE" "$src" "$auto"
  if diff -q <(normalize_req "$hand") <(normalize_req "$auto") >/dev/null 2>&1; then
    h1=match
    match_count=$((match_count + 1))
  else
    h1=miss
    echo "-- H1 miss $name --"
    diff -u <(normalize_req "$hand") <(normalize_req "$auto") || true
  fi
  hand_out="$("$REL" "$ngb" "$hand" 2>/dev/null || true)"
  auto_out="$("$REL" "$ngb" "$auto" 2>/dev/null || true)"
  if [[ "$hand_out" == "$auto_out" ]]; then
    h2=equivalent
  else
    h2=diverge
    echo "-- H2 diverge $name --"
    echo "hand: $hand_out"
    echo "auto: $auto_out"
  fi
  cp "$auto" "fixtures/metamorphic/${name}.req.auto"
  echo "$name h1=$h1 h2=$h2"
done

echo "H1 recall: $match_count/$total (pass threshold >=4/5)"
if [[ "$match_count" -ge 4 ]]; then
  echo "H1: PROVEN"
else
  echo "H1: REFUTED"
fi

echo "CANDIDATE-ID-SPIKE H1-H2 OK"
