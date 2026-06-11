#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# G73 blind probe search. Finds reject witnesses on rev2 mints using only .req
# fields and relation-native enumeration (no CASE.md, no timeline reject hex).

usage() {
  echo "usage: blind-probe-search.sh [--corpus backtest-rev2] [--budget default]" >&2
  exit 2
}

CORPUS=backtest-rev2
BUDGET=default

while [[ $# -gt 0 ]]; do
  case "$1" in
    --corpus) CORPUS="${2:-}"; shift 2 ;;
    --budget) BUDGET="${2:-}"; shift 2 ;;
    -h | --help) usage ;;
    *) echo "unknown arg: $1" >&2; usage ;;
  esac
done

if [[ "$BUDGET" == default ]]; then
  export METAMORPHIC_BLIND_BYTE=256
  export METAMORPHIC_BLIND_FLOW=64
  export METAMORPHIC_BLIND_U32=256
  export METAMORPHIC_BLIND_ASCII=256
  export METAMORPHIC_BLIND_HEX=256
fi

# shellcheck source=blind-probe-generators.sh
source "$(dirname "$0")/blind-probe-generators.sh"

witness_field() {
  sed -n "s/.* ${2}=\([^ ]*\).*/\1/p" <<<"$1" | head -1
}

# True defect separator check: replay the witness probe through the one
# relation implementation in metamorphic-verify.sh against honest rev1.
# range_coverage witnesses are endpoint checks, not probes; rerun the full
# (cheap) blind check instead.
rev1_passes_witness() {
  local rev1="$1" req="$2" relation="$3" witness_line="$4" probe=""
  case "$relation" in
    round_trip) probe="$(witness_field "$witness_line" bytes)" ;;
    involution | conserve_popcount) probe="$(witness_field "$witness_line" x)" ;;
    flow_composition)
      probe="$(witness_field "$witness_line" n) $(witness_field "$witness_line" m) $(witness_field "$witness_line" seed)"
      ;;
    cmp_order) probe="$(witness_field "$witness_line" pair | tr ',' ' ')" ;;
    range_coverage)
      METAMORPHIC_BLIND=1 ./scripts/agent-eval/metamorphic-verify.sh "$rev1" "$req" 2>/dev/null \
        | grep -q '^verdict=accept'
      return $?
      ;;
    *) return 1 ;;
  esac
  [[ -n "${probe// /}" ]] || return 1
  METAMORPHIC_PROBES="$probe" ./scripts/agent-eval/metamorphic-verify.sh "$rev1" "$req" 2>/dev/null \
    | grep -q '^verdict=accept'
}

search_self_oracle() {
  local cand="$1" req="$2"
  METAMORPHIC_BLIND=1 ./scripts/agent-eval/metamorphic-verify.sh "$cand" "$req" 2>&1 || true
}

search_value_oracle_diff() {
  local ref="$1" cand="$2" req="$3"
  export RELATION=value_oracle
  export DOMAIN="$(sed -n 's/^domain=//p' "$req" | head -1)"
  export WIRE="$(sed -n 's/^wire=//p' "$req" | head -1)"
  local mode reject
  mode="$(sed -n 's/^mode=//p' "$req" | head -1)"
  reject="$(sed -n 's/^reject=//p' "$req" | head -1)"

  make -C tools -s bin/ngb-parse >/dev/null
  hash="$(tools/bin/ngb-parse "$cand" | sed -n 's/.*graph_root_hash=//p')"

  while read -r probe; do
    [[ -z "$probe" ]] && continue
    got_ref="$(./scripts/run-linux-elf-capture.sh "$ref" "$mode" "$probe" 2>/dev/null | tr -d '\n\r' || true)"
    got_cand="$(./scripts/run-linux-elf-capture.sh "$cand" "$mode" "$probe" 2>/dev/null | tr -d '\n\r' || true)"
    [[ -n "$got_ref" && -n "$got_cand" && "$got_ref" != "$got_cand" ]] || continue
    got_ref2="$(./scripts/run-linux-elf-capture.sh "$ref" "$mode" "$probe" 2>/dev/null | tr -d '\n\r' || true)"
    got_cand2="$(./scripts/run-linux-elf-capture.sh "$cand" "$mode" "$probe" 2>/dev/null | tr -d '\n\r' || true)"
    [[ "$got_ref2" == "$got_cand2" ]] && continue
    local hexw
    if [[ "$WIRE" == hex ]]; then
      hexw="$probe"
    elif [[ "$WIRE" == ascii ]]; then
      hexw="$(printf '%s' "$probe" | hexdump -ve '1/1 "%02x"')"
    else
      hexw="$(printf '%X' "$probe")"
    fi
    echo "verdict=reject hash=${hash:0:12} relation=value_oracle witness bytes=$probe hex=$hexw ref=$got_ref2 got=$got_cand2"
    return 0
  done < <(blind_gen_probes)

  echo "verdict=accept hash=${hash:0:12} relation=value_oracle separator=none"
  return 1
}

run_case() {
  local label="$1" manifest="$2"
  local req rev1 rev2 relation
  req="$(sed -n 's/^req=//p' "$manifest" | head -1)"
  _ngbs=()
  while read -r _n; do [[ -n "$_n" ]] && _ngbs+=("$_n"); done < <(sed -n 's/.*ngb=\([^ ]*\).*/\1/p' "$manifest")
  rev1="${_ngbs[0]:-}"
  rev2="${_ngbs[1]:-}"

  [[ -f "$req" && -f "$rev1" && -f "$rev2" ]] || {
    echo "case=$label result=skip reason=missing-artifacts"
    return 0
  }

  relation="$(sed -n 's/^relation=//p' "$req" | head -1)"
  export DOMAIN="$(sed -n 's/^domain=//p' "$req" | head -1)"
  export WIRE="$(sed -n 's/^wire=//p' "$req" | head -1)"
  export RELATION="$relation"
  export REQ="$req"

  t0=$(python3 -c 'import time; print(int(time.time()*1000))')
  if [[ "$relation" == value_oracle ]]; then
    out="$(search_value_oracle_diff "$rev1" "$rev2" "$req" 2>&1 || true)"
  else
    out="$(search_self_oracle "$rev2" "$req")"
  fi
  t1=$(python3 -c 'import time; print(int(time.time()*1000))')
  wall=$((t1 - t0))

  if grep -q '^verdict=reject' <<<"$out"; then
    witness="$(grep '^verdict=reject' <<<"$out" | head -1)"
    if [[ "$relation" == value_oracle ]]; then
      spec=true_found
    elif rev1_passes_witness "$rev1" "$req" "$relation" "$witness"; then
      spec=true_found
    else
      spec=both_reject
    fi
    echo "case=$label relation=$relation result=found specificity=$spec wall_ms=$wall $witness"
  elif grep -q '^verdict=accept' <<<"$out"; then
    echo "case=$label relation=$relation result=miss wall_ms=$wall reason=budget-exhausted"
  else
    echo "case=$label relation=$relation result=error wall_ms=$wall detail=$(tr '\n' ' ' <<<"$out" | head -c 120)"
  fi
}

if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "BLIND-PROBE-SEARCH SKIP (no Linux runner)"
  exit 0
fi

declare -a CASES
if [[ "$CORPUS" == backtest-rev2 ]]; then
  CASES=(
    "utf8:fixtures/backtest/utf8/timeline.manifest"
    "leb128:fixtures/backtest/leb128/timeline.manifest"
    "wabt-leb128:fixtures/backtest/wabt-leb128/timeline.manifest"
    "capnproto-base64:fixtures/backtest/capnproto-base64/timeline.manifest"
    "cosmo-ljson:fixtures/backtest/cosmo-ljson/timeline.manifest"
    "cosmo-parseip:fixtures/backtest/cosmo-parseip/timeline.manifest"
    "knuth-rand-len:fixtures/backtest/knuth-rand-len/timeline.manifest"
    "llvm-bolt-cmp:fixtures/backtest/llvm-bolt-cmp/timeline.manifest"
    "rust-base64:fixtures/backtest/rust-base64/timeline.manifest"
    "zig-wyhash:fixtures/backtest/zig-wyhash/timeline.manifest"
    "zig-wyhash-native:fixtures/backtest/zig-wyhash-native/timeline.manifest"
    "go-base64-streaming:fixtures/backtest/go-base64-streaming/timeline.manifest"
    "rust-crc32fast:fixtures/backtest/rust-crc32fast-combine/timeline.manifest"
  )
else
  echo "unknown corpus: $CORPUS" >&2
  exit 2
fi

found=0
true_found=0
both_reject=0
miss=0
err=0
total=${#CASES[@]}

echo "BLIND-PROBE-SEARCH corpus=$CORPUS budget=default cases=$total"
for entry in "${CASES[@]}"; do
  label="${entry%%:*}"
  manifest="${entry#*:}"
  line="$(run_case "$label" "$manifest")"
  echo "$line"
  if grep -q 'result=found' <<<"$line"; then found=$((found + 1)); fi
  if grep -q 'specificity=true_found' <<<"$line"; then true_found=$((true_found + 1)); fi
  if grep -q 'specificity=both_reject' <<<"$line"; then both_reject=$((both_reject + 1)); fi
  if grep -q 'result=miss' <<<"$line"; then miss=$((miss + 1)); fi
  if grep -q 'result=error' <<<"$line"; then err=$((err + 1)); fi
done

found_pct=$((found * 100 / total))
true_pct=$((true_found * 100 / total))
echo "BLIND-PROBE-SEARCH SUMMARY found=$found true_found=$true_found both_reject=$both_reject miss=$miss error=$err total=$total found_rate=${found_pct}% true_rate=${true_pct}%"
if [[ "$true_pct" -ge 50 ]]; then
  echo "BLIND-PROBE-SEARCH VERDICT PROVEN_bounded"
elif [[ "$true_pct" -ge 20 ]]; then
  echo "BLIND-PROBE-SEARCH VERDICT PARTIAL"
else
  echo "BLIND-PROBE-SEARCH VERDICT REFUTED"
fi
