#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Guards the CompactSize hunt prep: the gen-compactsize.sh probe source and the
# native-hunt probes_cmd seam. An honest minimal-enforcing codec must clear
# round_trip; a codec that accepts non-minimal CompactSize must yield a reject
# witness on the same probes. Hermetic python codecs, no rust/cargo, so an accept
# on the real rust-bitcoin target cannot be a blind harness passing everything.

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/honest.py" <<'PY'
import sys

def dec(h):
    try:
        b = bytes.fromhex(h)
    except ValueError:
        return None
    if not b:
        return None
    n = b[0]
    if n < 0xfd:
        return n if len(b) == 1 else None
    if n == 0xfd:
        if len(b) != 3:
            return None
        v = int.from_bytes(b[1:3], "little")
        return v if v >= 0xfd else None
    if n == 0xfe:
        if len(b) != 5:
            return None
        v = int.from_bytes(b[1:5], "little")
        return v if v >= 0x10000 else None
    if len(b) != 9:
        return None
    v = int.from_bytes(b[1:9], "little")
    return v if v >= 0x100000000 else None

def enc(v):
    if v < 0xfd:
        return bytes([v]).hex()
    if v <= 0xffff:
        return "fd" + v.to_bytes(2, "little").hex()
    if v <= 0xffffffff:
        return "fe" + v.to_bytes(4, "little").hex()
    return "ff" + v.to_bytes(8, "little").hex()

mode, val = sys.argv[1], sys.argv[2]
if mode == "csdec":
    v = dec(val)
    print("REJECT" if v is None else v)
elif mode == "csenc":
    print(enc(int(val)))
else:
    print("REJECT")
PY

cat > "$WORK/buggy.py" <<'PY'
import sys

def dec(h):
    try:
        b = bytes.fromhex(h)
    except ValueError:
        return None
    if not b:
        return None
    n = b[0]
    if n < 0xfd:
        return n if len(b) == 1 else None
    if n == 0xfd:
        return int.from_bytes(b[1:3], "little") if len(b) == 3 else None
    if n == 0xfe:
        return int.from_bytes(b[1:5], "little") if len(b) == 5 else None
    return int.from_bytes(b[1:9], "little") if len(b) == 9 else None

def enc(v):
    if v < 0xfd:
        return bytes([v]).hex()
    if v <= 0xffff:
        return "fd" + v.to_bytes(2, "little").hex()
    if v <= 0xffffffff:
        return "fe" + v.to_bytes(4, "little").hex()
    return "ff" + v.to_bytes(8, "little").hex()

mode, val = sys.argv[1], sys.argv[2]
if mode == "csdec":
    v = dec(val)
    print("REJECT" if v is None else v)
elif mode == "csenc":
    print(enc(int(val)))
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

cat > "$WORK/compactsize.req" <<'REQ'
relation=round_trip
domain=compactsize
wire=hex
encode=csenc
decode=csdec
reject=REJECT
canonical=enforced
probes_cmd=scripts/agent-eval/gen-compactsize.sh
REQ

honest_out="$(./scripts/agent-eval/native-hunt.sh "$WORK/honest" "$WORK/compactsize.req" 2>&1)" && honest_rc=0 || honest_rc=$?
buggy_out="$(./scripts/agent-eval/native-hunt.sh "$WORK/buggy" "$WORK/compactsize.req" 2>&1)" && buggy_rc=0 || buggy_rc=$?

echo "honest: $honest_out"
echo "buggy:  $buggy_out"

fail=0
if [[ "$honest_rc" -ne 0 ]] || ! grep -q '^verdict=accept' <<<"$honest_out"; then
  echo "CHECK-COMPACTSIZE-HUNT FAIL: honest minimal codec did not clear round_trip" >&2
  fail=1
fi
if [[ "$buggy_rc" -ne 1 ]] || ! grep -q '^verdict=reject' <<<"$buggy_out"; then
  echo "CHECK-COMPACTSIZE-HUNT FAIL: lenient codec did not yield a reject witness" >&2
  fail=1
fi
[[ "$fail" -eq 0 ]] || exit 1

echo "CHECK-COMPACTSIZE-HUNT PASS generator + probes_cmd seam separate minimal-enforcing from non-minimal-lenient CompactSize"
