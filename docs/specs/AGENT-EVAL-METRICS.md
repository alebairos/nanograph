# Agent eval metrics (P16)

Measured 2026-06-05 via `./scripts/agent-eval/run-eval-sprint.sh` (issue #29). Bash plus C tools, no Python, no Docker.

## What each claim can and cannot prove

| Claim | Settled by script? | Why |
| --- | --- | --- |
| Speed / iteration count | No | Depends on live agent search and retries; needs a real LLM run |
| Integrity gating | Yes | Deterministic tool behavior; same bad edit, both surfaces |

## Control: exit-4 parity

| Surface | Success | Behavioral proof |
| --- | --- | --- |
| ngb-patch chain | yes | graph hash equals docker-proven `add_two_chain` fixture |
| ELF byte patch | yes | offsets 121/127 set to 0x02; run proven prior |

Both reach exit 4. Not a differentiator.

## Integrity test: bad edits caught at author time

| Bad edit | NanoGraph | Raw ELF |
| --- | --- | --- |
| Out-of-bounds offset | caught `I3:node_range` | shipped |
| Corrupt header | caught `I1:magic` | shipped |
| Silent code tamper | caught `root_hash` | shipped |
| **Total** | **3/3 caught** | **0/3 caught** |

Logs: `.harness-data/agent-eval/integrity/run.jsonl`.

## Infrastructure evidence (automated)

| Check | Status |
| --- | --- |
| `check-all-proofs.sh` | green |
| `check-patch-reject.sh` | green |
| `check-add-two-chain-proof.sh` | green (I6 chain) |
| `run-eval-sprint.sh` | green (control + integrity) |

## Interpretation

NanoGraph's value is verifiable editing, not edit speed. The integrity test is the fair, deterministic comparison. The speed comparison is left unmeasured until a live-agent harness exists; it must not be claimed from a scripted run.
