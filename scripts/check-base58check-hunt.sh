#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Proves round_trip catches the Base58 leading-zero bug on seed-corpus probes.
# An honest codec preserves leading zero bytes (leading '1' chars) and clears
# round_trip. A bignum codec that decodes through an int drops leading zeros, so
# re-encoding a leading-'1' string loses those chars and the bijection breaks.

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/honest" <<'PY'
import sys

A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


def enc(b):
    n = int.from_bytes(b, "big")
    out = ""
    while n > 0:
        n, r = divmod(n, 58)
        out = A[r] + out
    return "1" * (len(b) - len(b.lstrip(b"\x00"))) + out


def dec(s):
    n = 0
    for c in s:
        n = n * 58 + A.index(c)
    body = n.to_bytes((n.bit_length() + 7) // 8, "big") if n else b""
    pad = len(s) - len(s.lstrip("1"))
    return b"\x00" * pad + body


mode, val = sys.argv[1], sys.argv[2]
if mode == "b58dec":
    try:
        print(dec(val).hex())
    except Exception:
        print("REJECT")
elif mode == "b58enc":
    print(enc(bytes.fromhex(val)))
else:
    print("REJECT")
PY

cat > "$WORK/buggy" <<'PY'
import sys

A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


def enc(b):
    n = int.from_bytes(b, "big")
    out = ""
    while n > 0:
        n, r = divmod(n, 58)
        out = A[r] + out
    return out


def dec(s):
    n = 0
    for c in s:
        n = n * 58 + A.index(c)
    return n.to_bytes((n.bit_length() + 7) // 8, "big") if n else b""


mode, val = sys.argv[1], sys.argv[2]
if mode == "b58dec":
    try:
        print(dec(val).hex())
    except Exception:
        print("REJECT")
elif mode == "b58enc":
    print(enc(bytes.fromhex(val)))
else:
    print("REJECT")
PY

cat > "$WORK/honest_t" <<PY
#!/usr/bin/env bash
exec python3 "$WORK/honest" "\$@"
PY
cat > "$WORK/buggy_t" <<PY
#!/usr/bin/env bash
exec python3 "$WORK/buggy" "\$@"
PY
chmod +x "$WORK/honest_t" "$WORK/buggy_t"

cat > "$WORK/base58check.req" <<'REQ'
relation=round_trip
domain=base58check
wire=ascii
encode=b58enc
decode=b58dec
reject=REJECT
canonical=enforced
probes_cmd=scripts/agent-eval/gen-base58check.sh
REQ

honest_out="$(./scripts/agent-eval/native-hunt.sh "$WORK/honest_t" "$WORK/base58check.req" 2>&1)" && honest_rc=0 || honest_rc=$?
buggy_out="$(./scripts/agent-eval/native-hunt.sh "$WORK/buggy_t" "$WORK/base58check.req" 2>&1)" && buggy_rc=0 || buggy_rc=$?

echo "honest: $honest_out"
echo "buggy:  $buggy_out"

fail=0
if [[ "$honest_rc" -ne 0 ]] || ! grep -q '^verdict=accept' <<<"$honest_out"; then
  echo "CHECK-BASE58CHECK-HUNT FAIL: honest leading-zero-preserving codec did not clear round_trip" >&2
  fail=1
fi
if [[ "$buggy_rc" -ne 1 ]] || ! grep -q '^verdict=reject' <<<"$buggy_out"; then
  echo "CHECK-BASE58CHECK-HUNT FAIL: bignum codec did not yield a leading-zero witness" >&2
  fail=1
fi
[[ "$fail" -eq 0 ]] || exit 1

echo "CHECK-BASE58CHECK-HUNT PASS round_trip catches Base58 leading-zero loss on seed-corpus probes"
