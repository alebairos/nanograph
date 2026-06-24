#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# Proves the native-upstream hunt vehicle on real executables (no .ngb, no ELF
# transcription). An honest strict base32 codec must clear round_trip; a buggy
# trailing-bits-lenient codec must yield a reject witness. Both targets are real
# python processes invoked through the same CLI contract a real upstream wrapper
# would expose, so a pass here means the relation ran against live code.

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/honest.py" <<'PY'
import sys
ALPHA = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
IDX = {c: i for i, c in enumerate(ALPHA)}

def decode(tok):
    if len(tok) % 8 != 0:
        return None
    s = tok.rstrip("=")
    bits = ""
    for c in s:
        if c not in IDX:
            return None
        bits += format(IDX[c], "05b")
    nbytes = len(bits) // 8
    if any(ch != "0" for ch in bits[nbytes * 8:]):
        return None
    return bytes(int(bits[i * 8:(i + 1) * 8], 2) for i in range(nbytes))

def encode(data):
    bits = "".join(format(b, "08b") for b in data)
    while len(bits) % 5 != 0:
        bits += "0"
    out = "".join(ALPHA[int(bits[i * 5:(i + 1) * 5], 2)] for i in range(len(bits) // 5))
    while len(out) % 8 != 0:
        out += "="
    return out

mode, val = sys.argv[1], sys.argv[2]
if mode == "b32dec":
    d = decode(val)
    print("REJECT" if d is None else d.hex())
elif mode == "b32enc":
    print(encode(bytes.fromhex(val)))
else:
    print("REJECT")
PY

cat > "$WORK/buggy.py" <<'PY'
import sys
ALPHA = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
IDX = {c: i for i, c in enumerate(ALPHA)}

def decode(tok):
    if len(tok) % 8 != 0:
        return None
    s = tok.rstrip("=")
    bits = ""
    for c in s:
        if c not in IDX:
            return None
        bits += format(IDX[c], "05b")
    nbytes = len(bits) // 8
    return bytes(int(bits[i * 8:(i + 1) * 8], 2) for i in range(nbytes))

def encode(data):
    bits = "".join(format(b, "08b") for b in data)
    while len(bits) % 5 != 0:
        bits += "0"
    out = "".join(ALPHA[int(bits[i * 5:(i + 1) * 5], 2)] for i in range(len(bits) // 5))
    while len(out) % 8 != 0:
        out += "="
    return out

mode, val = sys.argv[1], sys.argv[2]
if mode == "b32dec":
    d = decode(val)
    print("REJECT" if d is None else d.hex())
elif mode == "b32enc":
    print(encode(bytes.fromhex(val)))
else:
    print("REJECT")
PY

cat > "$WORK/honest" <<PY
#!/usr/bin/env bash
exec python3 "$WORK/honest.py" "\$@"
PY
cat > "$WORK/buggy" <<PY
#!/usr/bin/env bash
exec python3 "$WORK/buggy.py" "\$@"
PY
chmod +x "$WORK/honest" "$WORK/buggy"

cat > "$WORK/base32.req" <<'REQ'
relation=round_trip
domain=base32
wire=ascii
encode=b32enc
decode=b32dec
reject=REJECT
canonical=enforced
probe_block=8
REQ

export METAMORPHIC_BLIND_ASCII=128

honest_out="$(./scripts/agent-eval/native-hunt.sh "$WORK/honest" "$WORK/base32.req" 2>&1)" && honest_rc=0 || honest_rc=$?
buggy_out="$(./scripts/agent-eval/native-hunt.sh "$WORK/buggy" "$WORK/base32.req" 2>&1)" && buggy_rc=0 || buggy_rc=$?

echo "honest: $honest_out"
echo "buggy:  $buggy_out"

fail=0
if [[ "$honest_rc" -ne 0 ]] || ! grep -q '^verdict=accept' <<<"$honest_out"; then
  echo "CHECK-NATIVE-HUNT FAIL: honest target did not clear round_trip" >&2
  fail=1
fi
if [[ "$buggy_rc" -ne 1 ]] || ! grep -q '^verdict=reject' <<<"$buggy_out"; then
  echo "CHECK-NATIVE-HUNT FAIL: buggy target did not yield a reject witness" >&2
  fail=1
fi
[[ "$fail" -eq 0 ]] || exit 1

echo "CHECK-NATIVE-HUNT PASS native vehicle separates honest vs lenient codec on live processes"
