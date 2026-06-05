# Agent eval metrics (P16)

Evidence for P20 verdict. Update rows after P13–P15 runs.

## Falsification targets (from PRODUCT-PROOF.md)

| Criterion | Target |
| --- | --- |
| Task A iterations | ≤5 tool rounds without golden leakage |
| ngb vs ELF | `.ngb` path wins on success rate or iterations |
| Proofs | `check-all-proofs.sh` green through P19 |
| Invalid patches | Structured I1–I6 rejection |

## Results table

| Task | Surface | Success | Iterations | Wall ms | Tool calls | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| A exit 4 | ngb-patch | pending | — | — | — | Spec: `task-add-two-exit4.md` |
| A exit 4 | ELF hex | pending | — | — | — | Spec: `task-elf-baseline-exit4.md` |
| B stdout 43 | ngb two-agent | pending | — | — | — | Protocol: `TWO-AGENT-PROBE-PROTOCOL.md` |
| B stdout 43 | ELF hex | pending | — | — | — | Spec: `task-elf-baseline-43.md` |

## Infrastructure evidence (automated)

| Check | Status |
| --- | --- |
| `check-all-proofs.sh` | green at P11 |
| `check-patch-reject.sh` | green |
| `check-add-two-chain-proof.sh` | green (I6 chain) |
| `ngb-patch` CLI | shipped P04 |

Agent iteration metrics stay **pending** until live eval logs land under `.harness-data/agent-eval/`.
