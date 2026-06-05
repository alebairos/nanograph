# Agent eval metrics (P16)

Measured 2026-06-05 via `./scripts/agent-eval/run-eval-sprint.sh` (issue #29).

## Falsification targets (from PRODUCT-PROOF.md)

| Criterion | Target | Result |
| --- | --- | --- |
| Task A iterations | ≤5 without golden leakage | **Met** (4 iterations) |
| ngb vs ELF | `.ngb` wins on success rate or iteration count | **Not met** (ELF 3 vs ngb 4) |
| Proofs | `check-all-proofs.sh` green | **Met** |
| Invalid patches | Structured rejection | **Met** |

## Results table

| Task | Surface | Success | Iterations | Wall ms | Tool calls | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| A exit 4 | ngb-patch | yes | 4 | 434 | 4 | disassemble → 2× ngb-patch → audit; log: `.harness-data/agent-eval/task-a/run.jsonl` |
| A exit 4 | ELF hex | yes | 3 | 160 | 3 | scan → 2 byte patches → docker run; log: `.harness-data/agent-eval/elf-a/run.jsonl` |
| B stdout 43 | ngb two-agent | pending | — | — | — | Run before next program |
| B stdout 43 | ELF hex | pending | — | — | — | Run before next program |

## Infrastructure evidence (automated)

| Check | Status |
| --- | --- |
| `check-all-proofs.sh` | green |
| `check-patch-reject.sh` | green |
| `check-add-two-chain-proof.sh` | green (I6 chain) |
| `ngb-patch` CLI | shipped |

## Interpretation

Both surfaces solved exit 4. ELF used fewer tool rounds and less wall time on this micro-task. The `.ngb` path still adds precondition-gated patch chain and probe audit, but that did not buy iteration efficiency here.
