#!/usr/bin/env bash
set -euo pipefail

quiet=0
[[ "${1:-}" == "--quiet" ]] && quiet=1

have=0
if [[ "$(uname -s)" == "Linux" ]]; then
  have=1
elif command -v qemu-x86_64 >/dev/null 2>&1; then
  have=1
elif command -v docker >/dev/null 2>&1; then
  have=1
fi

if [[ "$have" -eq 1 ]]; then
  [[ "$quiet" -eq 1 ]] || echo "LINUX-RUNNER OK"
  exit 0
fi

[[ "$quiet" -eq 1 ]] || echo "LINUX-RUNNER: need Linux, qemu-x86_64, or docker" >&2
exit 1
