# ADR-006 — Adversarial verifier vs static sampling

**Status:** Accepted (**Competition oracle; active searcher beats a fixed case list**)
**Date:** 2026-06-07
**Goal:** G23 (issue #43)

## Context

Two earlier cases were evaluated and set aside. "Author writes a program, QA agent verifies it" left intent provenance unsolved (the author can own the spec) and ran into the oracle ceiling (a referee as hard to build as the program). A competition resolves both by construction: the organizer owns the spec and the referee, independent of every author.

The conformance floor through G22 verifies against a fixed case list. That is a fixed blind spot. A buggy submission that avoids the listed inputs ships green.

## Decision

Build a competition verifier. The organizer's `conf-eval` is the referee. A deterministic searcher enumerates inputs, runs each submission's real bytes, and reports the first confirmed input where the submission diverges from the oracle. Add `gcd_evil` (equal-operands returns 1) as a buggy author that the G21/G22 static suite accepts and the searcher rejects.

## Why deterministic, not a live agent

The novelty is the structure, not an LLM. A bounded enumeration refereed by an independent oracle is the smallest thing that demonstrates it and the only thing that belongs in CI (live agents are nondeterministic, out of scope per the ledger). The enumerator is the lever a reviewer reruns. A live adversarial verifier is a later opt-in layer on the same gate.

## Why the adjacent lower layer is insufficient

The G21/G22 gate compares against a fixed list and cannot find a separator outside it. The smallest mechanism that closes this is an input enumerator plus a batched runner plus a witness reporter, all on top of the existing `conf-eval` and runner contracts. No new floor tier, no format change.

## Robustness

Running an emulated x86_64 ELF per probe under docker on Apple Silicon throws transient segfaults on known-correct binaries. Two guards keep the verdict honest. The batch runner emits exactly one crash-safe line per probe so a fault cannot shift the stream. The verifier confirms any candidate witness with an isolated clean run, so a reject requires a reproducible divergence. That is also the honest definition of a separator.

## What we are not building

- No `.ngb` format change. I1–I6 hold.
- No live-LLM verifier in CI.
- No symbolic or all-inputs proof. The searcher is a larger, adversarial sample.
- No new program. Reuses the G21 gcd spec, oracle, and runner.

## Design

- `gcd_evil.ngb` minted by `mint-input-math-fixtures.sh` (`-DEVIL_GCD`).
- `scripts/agent-eval/adversarial-verify.sh`: enumerate by increasing sum to a budget, batch-run, referee per probe, confirm witnesses.
- `scripts/run-linux-elf-batch.sh`: extract once, one backend session, crash-safe per-probe line.
- `scripts/check-adversarial-verifier.sh`: static arm accepts gcd_evil, adversarial arm rejects with witness (2,2), honest arm accepts v1/v2.

## Known limit

The searcher samples a bounded box. A bug whose smallest trigger sits past the budget would pass. The budget is the dial; symbolic equivalence is still out of reach.

## Kill trigger

If beating static sampling needs a general solver or a live agent in CI to separate cases, stop extending the searcher and revisit the floor's ambition.
