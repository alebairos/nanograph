#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# Native-upstream hunt mode. Runs a metamorphic relation against a real
# executable instead of a transcribed .ngb specimen, reusing the blind probe
# generator (the IP) and the witness format. A target is any executable honoring
# the ELF CLI contract: `target <mode> <value>` prints the result on stdout, or
# the reject sentinel. A round_trip reject on a canonical-enforcing target is a
# candidate upstream defect, not a transcription artifact, because real code ran.

usage() { echo "usage: native-hunt.sh <target-exec> <request.req>" >&2; exit 2; }
[[ $# -ge 2 ]] || usage
TARGET="$1"
REQ="$2"
[[ -x "$TARGET" || -f "$TARGET" ]] || { echo "native-hunt: missing target $TARGET" >&2; exit 2; }
[[ -f "$REQ" ]] || { echo "native-hunt: missing req $REQ" >&2; exit 2; }

reqval() { sed -n "s/^$1=//p" "$REQ" | head -1; }
RELATION="$(reqval relation)"
export RELATION
export DOMAIN="$(reqval domain)"
export WIRE="$(reqval wire)"
export REQ

TLIMIT="${NATIVE_TIMEOUT:-10}"
run_target() {
  local mode="$1" val="$2"
  if command -v timeout >/dev/null 2>&1; then
    timeout -s KILL "$TLIMIT" "$TARGET" "$mode" "$val" 2>/dev/null | tr -d '\r\n' || true
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout -s KILL "$TLIMIT" "$TARGET" "$mode" "$val" 2>/dev/null | tr -d '\r\n' || true
  else
    "$TARGET" "$mode" "$val" 2>/dev/null | tr -d '\r\n' || true
  fi
}

# shellcheck source=blind-probe-generators.sh
source "$(dirname "$0")/blind-probe-generators.sh"

# Probe source seam. A target may declare probes_cmd in its .req to supply a wire
# format the frozen blind generator does not cover (pinned by the holdout prereg).
# Default stays blind_gen_probes so existing targets are unchanged.
PROBES_CMD="$(reqval probes_cmd)"
probe_source() {
  if [[ -n "$PROBES_CMD" ]]; then
    [[ -x "$ROOT/$PROBES_CMD" ]] || { echo "native-hunt: probes_cmd not executable: $PROBES_CMD" >&2; exit 2; }
    "$ROOT/$PROBES_CMD"
  else
    blind_gen_probes
  fi
}

if [[ "$RELATION" != round_trip ]]; then
  echo "native-hunt: unsupported relation=$RELATION (v1 covers round_trip)" >&2
  exit 2
fi

ENCODE="$(reqval encode)"
DECODE="$(reqval decode)"
REJECT="$(reqval reject)"
CANONICAL="$(reqval canonical)"
CANONICAL="${CANONICAL:-enforced}"
[[ -n "$ENCODE" && -n "$DECODE" && -n "$REJECT" ]] || {
  echo "native-hunt: round_trip needs encode, decode, reject in $REQ" >&2
  exit 2
}

hexify() {
  if [[ "$WIRE" == ascii ]]; then
    printf '%s' "$1" | hexdump -ve '1/1 "%02x"'
  else
    printf '%s' "$1"
  fi
}

label="$(basename "$TARGET")"
accepted=0
while read -r b; do
  [[ -z "$b" ]] && continue
  cp="$(run_target "$DECODE" "$b")"
  [[ -z "$cp" || "$cp" == "$REJECT" ]] && continue
  b3="$(run_target "$ENCODE" "$cp")"
  if [[ "$b3" != "$b" ]]; then
    hexw="$(hexify "$b")"
    if [[ "$CANONICAL" == lenient ]]; then
      echo "verdict=relation_gap target=$label relation=round_trip reason=lenient_contract witness bytes=$b hex=$hexw decode=$cp reencode=$b3"
      exit 3
    fi
    echo "verdict=reject target=$label relation=round_trip witness bytes=$b hex=$hexw decode=$cp reencode=$b3"
    exit 1
  fi
  accepted=$((accepted + 1))
done < <(probe_source)

[[ "$accepted" -ge 1 ]] || {
  echo "native-hunt: round_trip accepted 0 inputs (domain has no canonical sample)" >&2
  exit 2
}
echo "verdict=accept target=$label relation=round_trip accepted=$accepted separator=none"
exit 0
