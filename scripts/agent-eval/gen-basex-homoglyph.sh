#!/usr/bin/env bash
set -euo pipefail

# Probe source for CVE-2025-27611 (base-x homograph acceptance). Most probes are
# valid Base58 strings that should decode identically across implementations.
# The final probe injects U+0100, which strict decoders reject. Vulnerable
# base-x (<3.0.11, 4.0.0, 5.0.0) accepts it due to BASE_MAP overflow.

./scripts/agent-eval/gen-base58check.sh
printf 'ABCDEF\n'
printf '1112\n'
python3 - <<'PY'
print("ABC\u0100DEF")
PY
