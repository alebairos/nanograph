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

`run-eval-sprint.sh` is bash plus the C tools, no Python. It runs the control and the integrity test deterministically without Docker. Extend it with more bad-edit classes or a live-agent harness rather than re-running the speed race.

## Kill triggers

- A fuzzed bad-edit set shows NanoGraph misses a class raw ELF would also miss, with no compensating benefit. **Tested 2026-06-05: NanoGraph 1000/1000, no miss. Not triggered.**
- The patch surface grows faster than invariant coverage.

## Re-open / expand triggers

- A live-agent eval shows NanoGraph's typed errors cut real retry counts.
- Task B (stdout / rodata) shows the structured graph prevents a corruption ELF rodata edits ship.
