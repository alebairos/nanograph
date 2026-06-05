# ADR-001 — NanoGraph product verdict

**Status:** Accepted (**Continue, scoped to verifiable editing**)  
**Date:** 2026-06-05 (revised after eval sprint #29 and integrity reframe)  
**Program:** P01–P20 product proof + measured integrity test

## Context

NanoGraph v3 asks whether agent-first `.ngb` graphs with NanoProbe tooling beat raw ELF editing. The first eval framed this as a speed race on a single exit-code task and concluded Pivot. That framing was wrong on two counts, corrected here.

## What the prior eval got wrong

1. **The speed race was unmeasurable by a script.** Iteration count and wall time depend on how a live agent searches, errs, and retries. The sprint hardcoded the correct offsets, so "4 iterations" was a ceiling for the happy path, not a measurement of agent behavior. No live LLM agent was run.
2. **It counted NanoGraph's value-add as a cost.** The extra step was the audit-log call, which ELF has no equivalent for. On a task nobody asked to be audited, the surface with no audit looked leaner. That is not a fair comparison.

## What is fairly measurable by a script

Integrity gating is **deterministic tool behavior**, not agent behavior. A script can settle it. The same bad edit is issued to both surfaces; the question is who rejects it at author time versus who writes the bytes and defers failure to runtime.

## Decision

**Continue**, scoped to **verifiable editing**. The product is "edits that cannot silently corrupt," not "fewer keystrokes than `dd`." Drop the speed positioning entirely.

## Evidence (measured 2026-06-05, `scripts/agent-eval/run-eval-sprint.sh`)

### Control: both surfaces reach exit 4

| Surface | Result | Proof |
| --- | --- | --- |
| ngb | exit 4 | graph hash equals docker-proven `add_two_chain` fixture |
| ELF | exit 4 | byte patch at off 121/127; behavioral run proven prior |

Parity, not a differentiator. Neither surface wins on simple exit-code edits.

### Integrity test: same bad edit, who catches it

| Bad edit | NanoGraph | Raw ELF |
| --- | --- | --- |
| Out-of-bounds offset | **caught** `I3:node_range` | shipped (`dd` wrote past code) |
| Corrupt header | **caught** `I1:magic` | shipped (loader fails only at runtime) |
| Silent code tamper | **caught** `root_hash` | shipped (no integrity check) |

**NanoGraph caught 3/3 at author time. Raw ELF caught 0/3.**

Logs: `.harness-data/agent-eval/{task-a,elf-a,integrity}/run.jsonl`.

### Fuzzed integrity gap (1000 random mutations, `tools/bin/ngb-fuzz`)

The hand-picked N=3 was widened to 1000 random image-byte mutations per seed, each issued to both surfaces.

| Seed | NanoGraph caught | Structural ELF check caught |
| --- | --- | --- |
| 1 | 1000/1000 | 271/1000 |
| 2 | 1000/1000 | 269/1000 |

NanoGraph catches 100% because every image byte is in the root hash. The structural ELF check (every invariant `readelf` enforces) catches only ~27%, the header and phdr region; it cannot detect the ~73% that are code or data tampering, because ELF stores no expectation of its contents. The gap is a property of the formats, confirmed across seeds.

## Honest caveats

- No live LLM agent was run. The integrity result is a property of the formats and tools, so a deterministic fuzzer is legitimate evidence for it. The speed claim was not, and stays **unmeasured**.
- The ELF baseline is a structural validator, not a strawman. It enforces magic, class, type, machine, and phdr bounds. It legitimately cannot check code bytes because the format records no expectation of them.
- The corrupt-header ELF case fails at load, not silently. It still escapes author-time review, which is the point, but "silent" applies most strongly to the ~73% of code and data mutations.

## What this changes for the consumer

An agent or human editing a graph gets a typed rejection the moment an edit is malformed, before it ships. Editing a raw ELF gives no such signal; the same mistake surfaces at runtime or not at all.

## What the next maintainer inherits

`run-eval-sprint.sh` is bash plus the C tools, no Python. It runs the control and the integrity test deterministically without Docker. `run-two-agent-loop.sh` (G8, issue #30) runs the author/auditor message interchange with a scripted author: round 1 wrong stdout patch rejected, round 2 correct patch accepted in 2 rounds total. Extend with a live LLM author rather than re-running the speed race.

## Two-agent loop evidence (G8, 2026-06-05)

| Metric | Value |
| --- | --- |
| Harness | `scripts/check-two-agent-loop.sh` |
| Rounds | 2 (1 reject + 1 accept) |
| Auditor negative | Wrong rodata patch (`32:34`) → `verdict=reject invariant=stdout` |
| Auditor positive | Correct patch (`32:33`) → `verdict=accept`, hash matches oracle |

Log: `.harness-data/agent-eval/two-agent/run.jsonl`. The interchange works at tool speed.

## Live-agent evidence (G13, 2026-06-05)

| Condition | Rounds | Wall time | Patch |
| --- | --- | --- |
| stacked (`--with-static-gate`) | 1 | 34s | `32:33` at off 152 |
| auditor-only | 1 | 42s | `32:33` at off 152 |

Harness: `scripts/agent-eval/run-live-agent-loop.sh`. Model `composer-2.5`. Logs: `.harness-data/agent-eval/live-agent/run-{stacked,auditor-only}.jsonl`.

The live loop works. The G13 runs used a skill that leaked the answer (`patch_off=152 patch_pairs=32:33`), so the author did not have to discover anything. The retry-reduction trigger stayed unsettled.

## Live-agent falsification (G14, 2026-06-05)

The skill leak was removed. The author is told nothing about the offset and must discover the rodata byte with `nano-probe disassemble`, then compute the digit from the conf spec. The static gate runs on the author's own offset. Same A/B, both arms blind.

| Condition | Rounds | Auditor execs | Wall time | Patch |
| --- | --- | --- | --- |
| stacked (`--with-static-gate`) | 1 | 1 | 43s | `32:33` at off 152 |
| auditor-only | 1 | 1 | 53s | `32:33` at off 152 |

Logs: `.harness-data/agent-eval/live-agent/run-g14-{stacked,auditor-only}.jsonl`.

**Re-open trigger result: NOT MET.** `composer-2.5` discovered offset 152, computed `0x33`, and emitted the correct patch on round 1 in both arms. With zero author errors there were zero retries for typed errors to cut. The static gate accepted (correct digit), saving nothing. The trigger as worded requires errors the model did not make on a single-byte patch.

This is a falsification run, not a demo, so the null result is the answer and the question is closed. Forcing a wrong round (weaker model, or a task tuned until the author fails) would manufacture the result rather than measure it. The retry-reduction positioning is dropped, the same way the speed positioning was dropped. The product claim stands on deterministic integrity (1000/1000 fuzz) and execution-grounded conformance (G9), neither of which needs a live retry count.

Caveats on G14. The harness logs the author's emitted patch, not its internal tool calls, so this run does not independently prove the author discovered the offset versus inferring it. Worse, the answer (`152`, `32:33`) is written in roughly eighteen repo files the author could read with `--workspace $ROOT`, so the run was not truly blind. The blinding was incomplete and the live retry question is best treated as inconclusive, not cleanly settled. Either way the gate had nothing to cut because there were no errors, and the retry-count framing is the wrong claim to chase.

## The claim that survives, measured (operational-error matrix, 2026-06-05)

Rather than chase a model-dependent retry count, the right test is deterministic. `scripts/agent-eval/operational-error-matrix.sh` enumerates every operational error class for a `rodata_byte_write` and records where each is caught, static gate versus auditor-only.

| Error class | Static gate | Auditor-only | Execution saved |
| --- | --- | --- | --- |
| wrong value | reject `value_mismatch` (0 exec) | reject `stdout` (1 exec) | yes |
| wrong target, instruction byte | reject `not_rodata` (0 exec) | reject `behavior` (1 exec) | yes |
| out of bounds | reject `bounds` (0 exec) | `ngb-patch` reject (0 exec) | no |
| correct value, wrong position | reject `position_mismatch` (0 exec) | reject `stdout` (1 exec) | yes |

Four of four bad classes are rejected before any ELF runs when intent binding includes both position (`--expect-off`) and value (`--expect-new`) derived from the conf spec. The value-only gate had a blind spot. Position binding closed it. This is the honest, gated, model-free claim. The product value is **pre-execution rejection of operational errors**, not fewer agent retries. Detail in [`../specs/MICROOP-FLOOR.md`](../specs/MICROOP-FLOOR.md). Gated in `check-all-proofs.sh`.

## Kill triggers

- A fuzzed bad-edit set shows NanoGraph misses a class raw ELF would also miss, with no compensating benefit. **Tested 2026-06-05: NanoGraph 1000/1000, no miss. Not triggered.**
- The patch surface grows faster than invariant coverage.

## Re-open / expand triggers

- ~~A live-agent eval shows NanoGraph's typed errors cut real retry counts.~~ **Tested 2026-06-05 (G14): not met. `composer-2.5` made zero errors on the blind single-byte task, so there were no retries to cut. Retry-reduction positioning dropped.** Re-open only if a real workload (not a tuned demo) shows agents erring at author time often enough that pre-execution typed rejects measurably reduce cost.
- Task B (stdout / rodata) shows the structured graph prevents a corruption ELF rodata edits ship.
