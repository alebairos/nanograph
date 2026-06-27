#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Raw bech32/bech32m string probes for the differential relation against a
# general-purpose codec (no segwit semantics). Short valid strings carry correct
# checksums so target and reference concur. The overlong string carries a valid
# Bech32m checksum but exceeds the BIP173 90-character maximum: the BIP-canonical
# reference rejects it (length cap), a codec that omits the cap accepts it, so
# the two diverge in the defect direction (target accepts, reference rejects).

PYTHONPATH="$ROOT/fixtures/native/bech32-vendor" python3 - <<'PY'
import segwit_addr as s

out = []
out.append("a1qypqxpq9mqr2hj")
out.append(s.bech32_encode("bc", list(range(8)), s.Encoding.BECH32M))
out.append(s.bech32_encode("bc", list(range(8)), s.Encoding.BECH32))
out.append(s.bech32_encode("bc", [0] * 100, s.Encoding.BECH32M))

for a in out:
    if a:
        print(a)
PY
