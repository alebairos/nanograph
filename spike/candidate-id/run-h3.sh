#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

TRANCHE="${1:-h3-nibbles}"
STEM="${2:-h3_nibbles}"
DEFINE="${DEFINE:--DODD_LEN_OK}"
export PROBES="${PROBES:-00 41 FF F}"

PROPOSE="$ROOT/spike/candidate-id/propose-req.py"
FROZEN="$ROOT/spike/candidate-id/FROZEN.sha256"
SRC="$ROOT/spike/candidate-id/$TRANCHE/$STEM.c"
HAND="$ROOT/spike/candidate-id/$TRANCHE/$STEM.req"
BUG_NGB="$ROOT/spike/candidate-id/$TRANCHE/${STEM}_buggy.ngb"
AUTO="$ROOT/spike/candidate-id/$TRANCHE/$STEM.req.auto"
VERIFY="$ROOT/spike/candidate-id/h3-roundtrip-verify.sh"

want="$(sed -n 's/^SHA256(propose-req.py)=//p' "$FROZEN" | head -1)"
got="$(shasum -a 256 "$PROPOSE" | awk '{print $1}')"
[[ "$want" == "$got" ]] || {
  echo "H3 ABORT: sidecar not frozen (want $want got $got)" >&2
  exit 2
}

# Pre-registration is only auditable if the freeze and the hand .req are in
# git history before the run, with no working-copy drift.
for f in "$PROPOSE" "$FROZEN" "$HAND" "$SRC"; do
  rel="${f#"$ROOT"/}"
  git ls-files --error-unmatch "$rel" >/dev/null 2>&1 || {
    echo "H3 ABORT: $rel not committed; commit freeze + hand .req before running" >&2
    exit 2
  }
  [[ -z "$(git status --porcelain -- "$rel")" ]] || {
    echo "H3 ABORT: $rel has uncommitted edits; re-freeze and commit first" >&2
    exit 2
  }
done

echo "== G55 H3 novel-codec follow-on (frozen sidecar $got) =="
echo "tranche=$TRANCHE stem=$STEM define=$DEFINE"
echo "pre_registered_hand_req=$HAND"
echo "hand_req_commit=$(git log -1 --format=%h -- "${HAND#"$ROOT"/}")"
echo "source_commit=$(git log -1 --format=%h -- "${SRC#"$ROOT"/}")"
echo "freeze_commit=$(git log -1 --format=%h -- "${FROZEN#"$ROOT"/}")"

./scripts/mint-one-elf.sh "$SRC" "$BUG_NGB" "$DEFINE"

hand_ms=0
sidecar_ms=0

hand_start=$(python3 - <<'PY'
import time; print(time.perf_counter())
PY
)
hand_out="$("$VERIFY" "$BUG_NGB" "$HAND" 2>&1 || true)"
hand_end=$(python3 - <<'PY'
import time; print(time.perf_counter())
PY
)
hand_ms=$(python3 - <<PY
print(int((${hand_end} - ${hand_start}) * 1000))
PY
)

propose_start=$(python3 - <<'PY'
import time; print(time.perf_counter())
PY
)
python3 "$PROPOSE" "$SRC" "$AUTO" >/dev/null
propose_end=$(python3 - <<'PY'
import time; print(time.perf_counter())
PY
)
propose_ms=$(python3 - <<PY
print(int((${propose_end} - ${propose_start}) * 1000))
PY
)
side_out="$("$VERIFY" "$BUG_NGB" "$AUTO" 2>&1 || true)"

echo "hand_verdict=$hand_out"
echo "sidecar_verdict=$side_out"
echo "hand_verify_wall_ms=$hand_ms"
echo "sidecar_authoring_ms=$propose_ms"

# End-to-end wall time is docker-startup-dominated and flips between runs, so
# it cannot gate. The reproducible claims are verdict equivalence and a
# bounded authoring cost.
if [[ "$hand_out" != "$side_out" ]]; then
  echo "H3: REFUTED (verdict mismatch)"
  exit 1
fi
if [[ "$hand_out" != verdict=reject* && "$hand_out" != *"verdict=reject"* ]]; then
  echo "H3: REFUTED (expected reject witness)"
  exit 1
fi
if [[ "$propose_ms" -le 1000 ]]; then
  echo "H3: PROVEN (verdict-equivalent reject; authoring ${propose_ms}ms <= 1000ms)"
else
  echo "H3: REFUTED (authoring too slow: ${propose_ms}ms)"
  exit 1
fi

echo "G55-H3-FOLLOWON OK"
