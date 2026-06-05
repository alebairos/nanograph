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

## Fuzzed integrity gap (1000 random image mutations)

`tools/bin/ngb-fuzz` flips a random image byte in both a valid `.ngb` and the raw ELF, then runs each surface's author-time validator.

| Seed | ngb caught | ELF structural check caught |
| --- | --- | --- |
| 1 | 1000/1000 | 271/1000 |
| 2 | 1000/1000 | 269/1000 |

NanoGraph catches every image mutation because every image byte is in the root hash. The structural ELF check catches only header and phdr mutations (~27%); it cannot detect code or data tampering, because ELF stores no expectation of its contents. Log: `.harness-data/agent-eval/fuzz/run.jsonl`.

## Infrastructure evidence (automated)

| Check | Status |
| --- | --- |
| `check-all-proofs.sh` | green |
| `check-patch-reject.sh` | green |
| `check-add-two-chain-proof.sh` | green (I6 chain) |
| `run-eval-sprint.sh` | green (control + integrity) |

## Two-agent loop (G8, issue #30)

Measured via `./scripts/check-two-agent-loop.sh`. Deterministic scripted author; auditor verdict from bytes only.

| Metric | Value |
| --- | --- |
| Task | print_42 → stdout `43\n`, exit 0 |
| Rounds to accept | 2 (1 reject + 1 accept) |
| Max rounds rubric | ≤5 |
| Negative case | Round 1 wrong patch (`32:34`) → `verdict=reject invariant=stdout` |
| Positive case | Round 2 correct patch (`32:33`) → `verdict=accept` |
| Final hash | Matches `print-42-patch-fixture` oracle |

Log: `.harness-data/agent-eval/two-agent/run.jsonl`.

The auditor never trusts author claims. It reads genesis + `patched.ngb`, builds `probe_bundle`, and runs `run-linux-elf-capture.sh` for behavioral proof.

## Live-agent eval (G13, issue #35)

Measured 2026-06-05 via `./scripts/agent-eval/run-live-agent-loop.sh`. Cursor CLI `agent` as author; auditor scripted. Model `composer-2.5`. Opt-in only.

| Condition | Rounds | Wall time | Patch | Verdict |
| --- | --- | --- | --- | --- |
| stacked (`--with-static-gate`) | 1 | 34s | off 152, `32:33` | accept |
| auditor-only (`--no-static-gate`) | 1 | 42s | off 152, `32:33` | accept |

Logs: `.harness-data/agent-eval/live-agent/run-{stacked,auditor-only}.jsonl`.

The live author computed `21+22=43`, found rodata offset 152, and proposed the correct digit on round 1. Both modes succeeded immediately. The G13 skill leaked the offset and digit, so the author did not have to discover them.

## Live-agent falsification (G14, issue #35)

Measured 2026-06-05. Skill leak removed; author discovers the offset via `disassemble`. Static gate runs on the author's offset. Both arms blind, model `composer-2.5`.

| Condition | Rounds | Auditor execs | Wall time | Patch |
| --- | --- | --- | --- | --- |
| stacked (`--with-static-gate`) | 1 | 1 | 43s | off 152, `32:33` |
| auditor-only (`--no-static-gate`) | 1 | 1 | 53s | off 152, `32:33` |

Logs: `.harness-data/agent-eval/live-agent/run-g14-{stacked,auditor-only}.jsonl`.

The author made zero errors in both arms even when blind. The static gate had nothing to cut. **ADR-001 re-open trigger NOT MET.** Retry-reduction positioning dropped. The question is closed, not retried on a tuned task.

## Interpretation

NanoGraph's value is verifiable editing, not edit speed and not live retry reduction. The integrity test is the fair, deterministic comparison (1000/1000 versus ~270/1000). The conformance floor (G9) grounds intent in real execution. The live harness works end-to-end (G13), and G14 falsified the retry-reduction claim for a capable model on a single-byte task. Both speed and retry positioning are dropped. The claim is integrity and execution-grounded conformance.
