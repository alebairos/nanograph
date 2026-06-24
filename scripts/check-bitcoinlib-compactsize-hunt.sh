#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TARGET=fixtures/native/bitcoinlib_compactsize
REQ=fixtures/native/bitcoinlib_compactsize.req

out="$(./scripts/agent-eval/native-hunt.sh "$TARGET" "$REQ" 2>&1)" && rc=0 || rc=$?
echo "$out"

if [[ "$rc" -ne 1 ]] || ! grep -q '^verdict=reject' <<<"$out"; then
  echo "CHECK-BITCOINLIB-COMPACTSIZE-HUNT FAIL: expected reject on canonical-enforcing round_trip" >&2
  exit 1
fi
if ! grep -q 'witness bytes=fdffff' <<<"$out"; then
  echo "CHECK-BITCOINLIB-COMPACTSIZE-HUNT FAIL: expected witness fdffff (encoder boundary at 65535)" >&2
  exit 1
fi
if ! grep -q 'reencode=feffff0000' <<<"$out"; then
  echo "CHECK-BITCOINLIB-COMPACTSIZE-HUNT FAIL: expected non-minimal reencode feffff0000" >&2
  exit 1
fi

echo "CHECK-BITCOINLIB-COMPACTSIZE-HUNT PASS real bitcoinlib CompactSize fails round_trip (witness fdffff)"
