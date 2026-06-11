#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

APE_DIR="$ROOT/spike/ape"
COSMOCC="$APE_DIR/bin/cosmocc"
OUT="$APE_DIR/out"
APE_LOADER="$OUT/ape-loader"
export PATH="$APE_DIR/bin:$PATH"

[[ -x "$COSMOCC" ]] || { echo "H1 rubric: cosmocc missing under spike/ape/bin" >&2; exit 2; }
mkdir -p "$OUT/shims"
[[ -x "$APE_LOADER" ]] || cc -O -o "$APE_LOADER" "$APE_DIR/bin/ape-m1.c"

echo "== G54 H1: input-math conformance gate consuming APE tools =="
echo "cosmocc=$("$COSMOCC" --version | head -1)"
echo "host=$(uname -sm)"

"$COSMOCC" -O2 -o "$OUT/conf-eval.ape" tools/bin/conf-eval.c
"$COSMOCC" -O2 -o "$OUT/ngb-extract.ape" tools/bin/ngb-extract.c
"$COSMOCC" -O2 -Itools/ngb -o "$OUT/ngb-parse.ape" tools/bin/ngb-parse.c tools/ngb/*.c

for tool in conf-eval ngb-extract ngb-parse; do
  cat > "$OUT/shims/$tool" <<SHIM
#!/usr/bin/env bash
exec "$APE_LOADER" "$OUT/$tool.ape" "\$@"
SHIM
  chmod +x "$OUT/shims/$tool"
done

run_timed() {
  local label="$1"; shift
  local t0 t1
  t0=$(python3 -c 'import time; print(time.perf_counter())')
  "$@" >"$OUT/$label.log" 2>&1
  local rc=$?
  t1=$(python3 -c 'import time; print(time.perf_counter())')
  echo "$label rc=$rc wall_ms=$(python3 -c "print(int(($t1-$t0)*1000))")"
  return $rc
}

run_timed native ./scripts/check-input-math-conformance.sh
run_timed ape env \
  CONF_EVAL="$OUT/shims/conf-eval" \
  NGB_PARSE="$OUT/shims/ngb-parse" \
  NGB_EXTRACT="$OUT/shims/ngb-extract" \
  ./scripts/check-input-math-conformance.sh

native_tail="$(tail -1 "$OUT/native.log")"
ape_tail="$(tail -1 "$OUT/ape.log")"
echo "native_last=$native_tail"
echo "ape_last=$ape_tail"

if [[ "$native_tail" == "INPUT-MATH-CONFORMANCE OK" && "$ape_tail" == "INPUT-MATH-CONFORMANCE OK" ]]; then
  echo "H1: PROVEN (gate green with conf-eval, ngb-parse, ngb-extract as APE on this host)"
else
  echo "H1: FAIL"
  exit 1
fi
echo "G54-H1-APE-RUBRIC OK"
