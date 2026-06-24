#!/usr/bin/env bash
set -euo pipefail

# CompactSize probe source for native-hunt round_trip. Emits hex wire tokens:
# canonical encodings that must round-trip, and non-minimal encodings that a
# consensus-correct decoder must reject. Lives outside the frozen blind generator
# (pinned by fixtures/holdout/preregistration.json) so new wire formats plug in
# without breaking the G83 holdout proof.

python3 - "${COMPACTSIZE_BUDGET:-256}" <<'PY'
import sys

budget = int(sys.argv[1])
seen, out = set(), []

def add(tok):
    if tok not in seen:
        seen.add(tok)
        out.append(tok)

# canonical 1-byte (round-trip)
for v in list(range(0, 33)) + [0xfc]:
    add(format(v, "02x"))

# canonical multi-byte at the minimal boundary for each prefix (round-trip)
for v in (0xfd, 0x100, 0x1234, 0xffff):
    add("fd" + v.to_bytes(2, "little").hex())
for v in (0x10000, 0xfedcba98, 0xffffffff):
    add("fe" + v.to_bytes(4, "little").hex())
for v in (0x100000000, 0xdeadbeefcafef00d):
    add("ff" + v.to_bytes(8, "little").hex())

# non-minimal: a small value padded into a wider prefix (must reject)
for v in (0, 1, 2, 0x7f, 0xfc):
    add("fd" + v.to_bytes(2, "little").hex())
    add("fe" + v.to_bytes(4, "little").hex())
    add("ff" + v.to_bytes(8, "little").hex())

# non-minimal: a u16-range value in a u32/u64 prefix (must reject)
for v in (0x100, 0xffff):
    add("fe" + v.to_bytes(4, "little").hex())
    add("ff" + v.to_bytes(8, "little").hex())

# non-minimal: a u32-range value in a u64 prefix (must reject)
for v in (0x10000, 0xffffffff):
    add("ff" + v.to_bytes(8, "little").hex())

for n, tok in enumerate(out):
    if n >= budget:
        break
    print(tok)
PY
