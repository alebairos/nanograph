#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Structured Bech32m probe source for the differential relation. Emits real
# segwit addresses with valid checksums across witness versions, including
# versions 17 and 31 which carry a valid Bech32m checksum but are invalid per
# BIP350 (segwit versions are 0..16). A decoder missing the version<=16 check
# accepts those; the BIP-canonical reference rejects them, so the two diverge.
# Bad-checksum mutations are included so both sides concur on rejection.

PYTHONPATH="$ROOT/fixtures/native/bech32-vendor" python3 - <<'PY'
import segwit_addr as s

PROG20 = list(range(20))
PROG32 = list(range(32))


def addr(hrp, witver, prog, spec):
    data = [witver] + s.convertbits(prog, 8, 5)
    return s.bech32_encode(hrp, data, spec)


out = []
out.append(addr("bc", 0, PROG20, s.Encoding.BECH32))
out.append(addr("bc", 0, PROG32, s.Encoding.BECH32))
out.append(addr("bc", 1, PROG32, s.Encoding.BECH32M))
out.append(addr("bc", 1, PROG20, s.Encoding.BECH32M))
out.append(addr("bc", 16, PROG32, s.Encoding.BECH32M))
out.append(addr("tb", 1, PROG32, s.Encoding.BECH32M))

# spec-invalid witness versions with valid Bech32m checksums (the divergence probes)
out.append(addr("bc", 17, PROG32, s.Encoding.BECH32M))
out.append(addr("bc", 31, PROG20, s.Encoding.BECH32M))

# cross-spec confusion: valid checksum under the wrong spec for the witness
# version. BIP350 requires version 0 to use Bech32 and 1..16 to use Bech32m. A
# decoder that accepts either checksum regardless of version diverges here.
out.append(addr("bc", 1, PROG32, s.Encoding.BECH32))
out.append(addr("bc", 0, PROG20, s.Encoding.BECH32M))

# BIP350 official valid vectors
out.append("bc1pw508d6qejxtdg4y5r3zarvary0c5xw7kw508d6qejxtdg4y5r3zarvaryvaxxpcs")
out.append("bc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqzk5jj0")

# bad-checksum mutation (both sides must reject -> concur)
good = out[0]
out.append(good[:-1] + ("q" if good[-1] != "q" else "p"))

for a in out:
    if a:
        print(a)
PY
