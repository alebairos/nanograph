#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
make -C tools -s bin/hello-fixture
export NANOGRAPH_ROOT="$ROOT"
exec tools/bin/hello-fixture "$@"
