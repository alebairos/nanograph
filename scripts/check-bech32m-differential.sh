#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Proves the differential relation catches a Bech32m acceptance bug that round_trip
# cannot see. The reference is the BIP-canonical sipa/bech32 decoder. An honest
# target that enforces segwit version <= 16 must concur. A target missing that one
# check accepts witness version 17/31 (valid Bech32m checksum, invalid per BIP350)
# where the reference rejects, so the differential diverges with a witness.

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
VENDOR="$ROOT/fixtures/native/bech32-vendor"

cat > "$WORK/honest" <<PY
#!/usr/bin/env python3
import sys
sys.path.insert(0, "$VENDOR")
import segwit_addr as s

def dec(addr):
    pos = addr.rfind("1")
    if pos < 1:
        return "REJECT"
    hrp = addr[:pos].lower()
    try:
        v, p = s.decode(hrp, addr)
    except Exception:
        return "REJECT"
    return "REJECT" if v is None else f"{v}:{bytes(p).hex()}"

print(dec(sys.argv[2]) if sys.argv[1] == "b32mdec" else "REJECT")
PY

cat > "$WORK/buggy" <<PY
#!/usr/bin/env python3
import sys
sys.path.insert(0, "$VENDOR")
import segwit_addr as s

def dec(addr):
    pos = addr.rfind("1")
    if pos < 1:
        return "REJECT"
    hrp = addr[:pos].lower()
    hrpgot, data, spec = s.bech32_decode(addr.lower())
    if hrpgot != hrp:
        return "REJECT"
    decoded = s.convertbits(data[1:], 5, 8, False)
    if decoded is None or len(decoded) < 2 or len(decoded) > 40:
        return "REJECT"
    return f"{data[0]}:{bytes(decoded).hex()}"

print(dec(sys.argv[2]) if sys.argv[1] == "b32mdec" else "REJECT")
PY

cat > "$WORK/stricter" <<PY
#!/usr/bin/env python3
import sys
sys.path.insert(0, "$VENDOR")
import segwit_addr as s

def dec(addr):
    pos = addr.rfind("1")
    if pos < 1:
        return "REJECT"
    hrp = addr[:pos].lower()
    try:
        v, p = s.decode(hrp, addr)
    except Exception:
        return "REJECT"
    if v is None or v != 0:
        return "REJECT"
    return f"{v}:{bytes(p).hex()}"

print(dec(sys.argv[2]) if sys.argv[1] == "b32mdec" else "REJECT")
PY
chmod +x "$WORK/honest" "$WORK/buggy" "$WORK/stricter"

cat > "$WORK/bech32m.req" <<REQ
relation=differential
domain=bech32m
wire=ascii
mode=b32mdec
reject=REJECT
reference=fixtures/native/bech32m_ref
probes_cmd=scripts/agent-eval/gen-bech32m.sh
REQ

honest_out="$(./scripts/agent-eval/native-hunt.sh "$WORK/honest" "$WORK/bech32m.req" 2>&1)" && honest_rc=0 || honest_rc=$?
buggy_out="$(./scripts/agent-eval/native-hunt.sh "$WORK/buggy" "$WORK/bech32m.req" 2>&1)" && buggy_rc=0 || buggy_rc=$?
stricter_out="$(./scripts/agent-eval/native-hunt.sh "$WORK/stricter" "$WORK/bech32m.req" 2>&1)" && stricter_rc=0 || stricter_rc=$?

echo "honest:   $honest_out"
echo "buggy:    $buggy_out"
echo "stricter: $stricter_out"

fail=0
if [[ "$honest_rc" -ne 0 ]] || ! grep -q '^verdict=accept' <<<"$honest_out"; then
  echo "CHECK-BECH32M-DIFFERENTIAL FAIL: honest target did not concur with reference" >&2
  fail=1
fi
if [[ "$buggy_rc" -ne 1 ]] || ! grep -q 'verdict=reject.*reason=target_accepts_reference_rejects' <<<"$buggy_out"; then
  echo "CHECK-BECH32M-DIFFERENTIAL FAIL: witver>16-lenient target did not classify as defect" >&2
  fail=1
fi
if ! grep -q 'target_out=17:' <<<"$buggy_out"; then
  echo "CHECK-BECH32M-DIFFERENTIAL FAIL: expected witness on witness version 17" >&2
  fail=1
fi
if [[ "$stricter_rc" -ne 3 ]] || ! grep -q 'verdict=capability_gap.*reason=target_rejects_reference_accepts' <<<"$stricter_out"; then
  echo "CHECK-BECH32M-DIFFERENTIAL FAIL: bech32-only target did not classify as capability_gap" >&2
  fail=1
fi
[[ "$fail" -eq 0 ]] || exit 1

echo "CHECK-BECH32M-DIFFERENTIAL PASS differential classifies witver>16 acceptance as defect and bech32-only as capability_gap"
