#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "VERIFIER-FROZEN FAIL: $1" >&2; exit 1; }

MANIFEST="fixtures/lang-packs/VERIFIER.sha256"
[[ -f "$MANIFEST" ]] || fail "missing $MANIFEST"
[[ -x scripts/agent-eval/metamorphic-verify.sh ]] || fail "metamorphic-verify.sh not executable"

while read -r expected path _rest; do
  [[ -n "${expected:-}" && -n "${path:-}" ]] || continue
  [[ "$expected" == \#* ]] && continue
  [[ -f "$path" ]] || fail "missing pinned file $path"
  if command -v shasum >/dev/null 2>&1; then
    got="$(shasum -a 256 "$path" | awk '{print $1}')"
  else
    got="$(sha256sum "$path" | awk '{print $1}')"
  fi
  [[ "$got" == "$expected" ]] || fail "$path hash drift (got $got want $expected); update $MANIFEST deliberately or revert"
done <"$MANIFEST"

if [[ "${1:-}" == --self-test-negative ]]; then
  tmp="$(mktemp)"
  cp scripts/agent-eval/metamorphic-verify.sh "$tmp"
  printf '\n' >>scripts/agent-eval/metamorphic-verify.sh
  set +e
  ./scripts/check-verifier-frozen.sh >/dev/null 2>&1
  rc=$?
  set -e
  mv "$tmp" scripts/agent-eval/metamorphic-verify.sh
  chmod +x scripts/agent-eval/metamorphic-verify.sh
  [[ "$rc" -ne 0 ]] || fail "negative self-test: gate should fail on verifier drift"
  echo "VERIFIER-FROZEN self-test-negative OK"
  exit 0
fi

echo "VERIFIER-FROZEN OK"
