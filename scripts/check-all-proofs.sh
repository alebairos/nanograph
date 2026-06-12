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
./scripts/check-relation-taxonomy.sh
./scripts/check-linear-xor.sh
./scripts/check-rule184-conserve.sh
./scripts/check-flow-composition.sh
./scripts/measure-relation-impact.sh
./scripts/check-bswap-value-oracle.sh
./scripts/check-reverse32-real.sh
./scripts/check-utf8-roundtrip.sh
./scripts/check-icp-cli.sh
./scripts/check-icp-sim-sandbox.sh
./scripts/check-icp-adoption-sandbox.sh
./scripts/check-icp-stall-report.sh fixtures/icp-sim/stall-report-minimal.md
./scripts/check-verifier-frozen.sh --self-test-negative
./scripts/check-verifier-frozen.sh
./scripts/check-case-fit-rubric.sh
./scripts/check-backtest.sh fixtures/backtest/utf8/timeline.manifest C080 UTF8
./scripts/check-backtest.sh fixtures/backtest/leb128/timeline.manifest 8000 LEB128
./scripts/check-backtest.sh fixtures/backtest/knuth-sgb/timeline.manifest 0A KNUTH-SGB
./scripts/check-backtest.sh fixtures/backtest/wabt-leb128/timeline.manifest ffffffffffffffffff02 WABT-LEB128
./scripts/check-backtest.sh fixtures/backtest/knuth-rand-len/timeline.manifest 02 KNUTH-RAND-LEN
./scripts/check-backtest.sh fixtures/backtest/capnproto-base64/timeline.manifest 5a6d397640 CAPNPROTO-BASE64
./scripts/check-backtest.sh fixtures/backtest/rust-base64/timeline.manifest 6959563d RUST-BASE64-INVALID-LAST
./scripts/check-backtest.sh fixtures/backtest/cosmo-parseip/timeline.manifest 3235352e3235352e3235352e323536 COSMO-PARSEIP
./scripts/check-backtest.sh fixtures/backtest/cosmo-ljson/timeline.manifest c080 COSMO-LJSON
./scripts/check-backtest.sh fixtures/backtest/llvm-bolt-cmp/timeline.manifest 00 LLVM-BOLT-CMP
./scripts/check-backtest.sh fixtures/backtest/jemalloc-s2u/timeline.manifest 7000000000000101 JEMALLOC-S2U
./scripts/check-backtest.sh fixtures/backtest/conserve-popcount/timeline.manifest 3 CONSERVE-POPCOUNT
./scripts/check-backtest.sh fixtures/backtest/zig-wyhash/timeline.manifest 5 ZIG-WYHASH
./scripts/check-backtest.sh fixtures/backtest/zig-wyhash-native/timeline.manifest 5 ZIG-WYHASH-NATIVE
./scripts/check-backtest.sh fixtures/backtest/go-base64-streaming/timeline.manifest 5 GO-BASE64-STREAMING
./scripts/check-backtest.sh fixtures/backtest/rust-crc32fast-combine/timeline.manifest 5 RUST-CRC32FAST-COMBINE-LEN0
./scripts/check-lang-packs.sh
./scripts/check-ca-author-sandbox.sh
./scripts/check-ca-live-scripted-loop.sh
./scripts/check-microop-floor.sh
./scripts/agent-eval/operational-error-matrix.sh
./scripts/check-author-sandbox.sh
./scripts/check-ngb-fuzz.sh 1000 1

echo "ALL-PROOFS OK"
