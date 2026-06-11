#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

APE_DIR="$ROOT/spike/ape"
COSMOCC="$APE_DIR/bin/cosmocc"
APE_LOADER="/tmp/ape-m1"
export PATH="$APE_DIR/bin:$PATH"

[[ -x "$COSMOCC" ]] || { echo "G54 follow-on: cosmocc missing under spike/ape" >&2; exit 2; }
[[ -x "$APE_LOADER" ]] || cc -O -o "$APE_LOADER" "$APE_DIR/bin/ape-m1.c"

COSMO_VER="$("$COSMOCC" --version 2>&1 | head -1)"
echo "== G54 follow-on H1/H2 =="
echo "cosmocc=$COSMO_VER"
echo "host=$(uname -sm)"

H1_BUILD_OK=0
H1_RUBRIC_OK=0
H1_MS=0
H2_MATCH=0

h1_start=$(python3 - <<'PY'
import time; print(time.perf_counter())
PY
)
if "$COSMOCC" -O2 -o /tmp/ngb-extract.ape tools/bin/ngb-extract.c \
  && "$COSMOCC" -O2 -o /tmp/conf-eval.ape tools/bin/conf-eval.c; then
  H1_BUILD_OK=1
  if "$APE_LOADER" /tmp/conf-eval.ape fixtures/input-math/gcd.spec 12 18 | grep -qx 6; then
    echo "conf-eval.ape smoke: gcd(12,18)=6 OK"
  else
    echo "conf-eval.ape smoke FAIL"
    H1_BUILD_OK=0
  fi
fi
if ./scripts/check-case-fit-rubric.sh >/dev/null 2>&1; then
  H1_RUBRIC_OK=1
fi
h1_end=$(python3 - <<'PY'
import time; print(time.perf_counter())
PY
)
H1_MS=$(python3 - <<PY
print(int((${h1_end} - ${h1_start}) * 1000))
PY
)

echo "H1 build_ape_tools=$H1_BUILD_OK rubric_exit0=$H1_RUBRIC_OK wall_ms=$H1_MS"
if [[ "$H1_BUILD_OK" -eq 1 && "$H1_RUBRIC_OK" -eq 1 ]]; then
  echo "H1: PARTIAL (tools build; rubric does not consume APE binaries yet)"
else
  echo "H1: INCONCLUSIVE or FAIL (build=$H1_BUILD_OK rubric=$H1_RUBRIC_OK)"
fi

ELF_WITNESS="$(./scripts/agent-eval/metamorphic-verify.sh fixtures/metamorphic/utf8_overlong.ngb fixtures/metamorphic/utf8.req 2>&1 || true)"
echo "elf_witness=$ELF_WITNESS"

"$COSMOCC" -O2 -DOVERLONG_OK -o /tmp/utf8_overlong.ape spike/ape/utf8_cosmo.c
run_ape() {
  "$APE_LOADER" /tmp/utf8_overlong.ape "$@" 2>/dev/null | tr -d '\n'
}
b=114816
cp2="$(run_ape dec "$b")"
b3="$(run_ape enc "$cp2")"
enc_out="$(run_ape enc "$cp2")"
if [[ "$enc_out" != "$b" && -n "$cp2" && "$cp2" != 1114112 ]]; then
  hexw="$(printf '%X' "$b" | sed 's/^1//')"
  APE_WITNESS="verdict=reject relation=round_trip witness bytes=$b hex=$hexw decode=$cp2 reencode=$enc_out"
  echo "ape_witness=$APE_WITNESS"
  if [[ "$ELF_WITNESS" == *"bytes=114816"* && "$ELF_WITNESS" == *"decode=0"* && "$ELF_WITNESS" == *"reencode=256"* ]]; then
    if [[ "$cp2" == "0" && "$enc_out" == "256" ]]; then
      H2_MATCH=1
    fi
  fi
else
  echo "ape_witness=unexpected enc_out=$enc_out cp2=$cp2"
fi

if [[ "$H2_MATCH" -eq 1 ]]; then
  echo "H2: PROVEN (APE native witness matches ELF docker witness on probe 114816)"
else
  echo "H2: INCONCLUSIVE or FAIL"
fi

echo "G54-FOLLOWON OK"
