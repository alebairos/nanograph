#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== all proofs =="

make -C tools -s all

./scripts/check-canonical-drift.sh
./scripts/check-hello-proof.sh
./scripts/check-add-two-proof.sh
./scripts/check-add-two-patched-proof.sh
./scripts/check-probe-diff.sh
./scripts/check-probe-disassemble.sh
./scripts/check-print-42-proof.sh
./scripts/check-ngb-patch-cli.sh
./scripts/check-ngb-parse-json.sh
./scripts/check-probe-trace.sh
./scripts/check-print-42-patched-proof.sh
./scripts/check-add-two-chain-proof.sh
./scripts/check-patch-reject.sh
./scripts/agent-eval/run-eval-sprint.sh
./scripts/check-two-agent-loop.sh
./scripts/check-conformance-floor.sh
./scripts/check-ca-oracle.sh
./scripts/check-ca-conformance.sh
./scripts/check-input-math-oracle.sh
./scripts/check-input-math-conformance.sh
./scripts/check-adversarial-verifier.sh
./scripts/check-metamorphic-involution.sh
./scripts/check-bswap-value-oracle.sh
./scripts/check-reverse32-real.sh
./scripts/check-utf8-roundtrip.sh
./scripts/check-case-fit-rubric.sh
./scripts/check-backtest-utf8.sh
./scripts/check-ca-author-sandbox.sh
./scripts/check-ca-live-scripted-loop.sh
./scripts/check-microop-floor.sh
./scripts/agent-eval/operational-error-matrix.sh
./scripts/check-author-sandbox.sh
./scripts/check-ngb-fuzz.sh 1000 1

echo "ALL-PROOFS OK"
