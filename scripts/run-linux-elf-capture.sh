#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

NGb="${1:?usage: run-linux-elf-capture.sh <file.ngb> [args...]}"
shift
ELF_ARGS=("$@")
ELF="/tmp/nanograph-elf-capture-$$"

# Untrusted or corrupted bytes may crash or loop. A corrupt ELF under qemu dumps
# core, and writing that core is pathologically slow, so disable it. timeout
# bounds a genuine loop. Do not exec the ELF as PID 1: a fatal signal to PID 1
# in the container stalls; keeping a shell parent lets the crash reap fast.
TLIMIT="${ELF_TIMEOUT:-10}"
ulimit -c 0 2>/dev/null || true

NGB_EXTRACT="${NGB_EXTRACT:-tools/bin/ngb-extract}"
if [[ "$NGB_EXTRACT" == tools/bin/ngb-extract ]]; then
  make -C tools -s bin/ngb-extract
fi
"$NGB_EXTRACT" "$NGb" "$ELF"
chmod +x "$ELF"

host_to() {
  if command -v timeout >/dev/null 2>&1; then timeout -s KILL "$TLIMIT" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout -s KILL "$TLIMIT" "$@"
  else "$@"; fi
}

run_native() {
  if ((${#ELF_ARGS[@]})); then host_to "$ELF" "${ELF_ARGS[@]}"; else host_to "$ELF"; fi
}

run_qemu() {
  if ((${#ELF_ARGS[@]})); then host_to qemu-x86_64 "$ELF" "${ELF_ARGS[@]}"; else host_to qemu-x86_64 "$ELF"; fi
}

run_docker() {
  if ((${#ELF_ARGS[@]})); then
    docker run --rm --platform linux/amd64 -i "ubuntu:24.04" \
      sh -c 'ulimit -c 0; cat > /tmp/e && chmod +x /tmp/e && timeout -s KILL '"$TLIMIT"' /tmp/e "$@"' _ "${ELF_ARGS[@]}" < "$ELF"
  else
    docker run --rm --platform linux/amd64 -i "ubuntu:24.04" \
      sh -c 'ulimit -c 0; cat > /tmp/e && chmod +x /tmp/e && timeout -s KILL '"$TLIMIT"' /tmp/e' < "$ELF"
  fi
}

# qemu/docker under load occasionally returns empty stdout for a specimen that
# deterministically prints; one bounded retry filters that backend fault.
# Byte-exact passthrough via a temp file (no newline normalization).
run_retry() {
  local attempts=$((${NGB_CAPTURE_RETRIES:-1} + 1)) i rc=0 tmp="/tmp/nanograph-cap-out-$$"
  for ((i = 1; i <= attempts; i++)); do
    set +e
    "$@" >"$tmp"
    rc=$?
    set -e
    [[ -s "$tmp" ]] && break
    [[ $i -lt $attempts ]] && sleep 1
  done
  cat "$tmp"
  rm -f "$tmp"
  return $rc
}

if [[ "$(uname -s)" == "Linux" ]]; then
  run_retry run_native
  exit $?
fi

if command -v qemu-x86_64 >/dev/null 2>&1; then
  run_retry run_qemu
  exit $?
fi

if command -v docker >/dev/null 2>&1; then
  run_retry run_docker
  exit $?
fi

echo "need one of: Linux, qemu-x86_64 (brew install qemu), or docker" >&2
exit 1
