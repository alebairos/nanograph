#!/usr/bin/env bash
set -euo pipefail

# Base58Check probe source for native-hunt round_trip. Emits valid Base58
# strings (version byte + payload + double-SHA256 checksum) generated from the
# spec, independent of any target. Includes leading zero-byte payloads, which
# encode to leading '1' characters: the case bignum-based decoders drop, breaking
# the encode(decode(b))==b bijection.

python3 - <<'PY'
import hashlib

ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


def b58encode(b):
    n = int.from_bytes(b, "big")
    out = ""
    while n > 0:
        n, r = divmod(n, 58)
        out = ALPHABET[r] + out
    pad = len(b) - len(b.lstrip(b"\x00"))
    return "1" * pad + out


def check(version, payload):
    data = bytes([version]) + payload
    chk = hashlib.sha256(hashlib.sha256(data).digest()).digest()[:4]
    return b58encode(data + chk)


payloads = [
    (0x00, bytes(range(1, 21))),
    (0x00, b"\x00" + bytes(range(1, 20))),
    (0x00, b"\x00\x00" + bytes(range(1, 19))),
    (0x05, bytes(range(1, 21))),
    (0x80, bytes(range(32))),
    (0x00, bytes(20)),
]

for v, p in payloads:
    print(check(v, p))
PY
