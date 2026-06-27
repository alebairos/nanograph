#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

./scripts/check-basex-homoglyph-hunt.sh
./scripts/check-rust-bech32-hunt.sh
./scripts/check-base58swift-hunt.sh

echo "CHECK-PINNED-HISTORICAL-REPROS PASS all wired pinned historical repro gates"
