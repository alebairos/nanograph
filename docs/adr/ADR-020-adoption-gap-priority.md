# ADR-020 — ICP adoption gap priority (probe generator first)

**Status:** Accepted
**Date:** 2026-06-11
**Goal:** G73 (#89)

## Context

The ICP pitch (`docs/ICP.md`) is evidence-backed for codec/parser maintainers, but adoption is a **pattern**, not an installable product. Four gaps were named in audit (2026-06-11):

1. **Probe generator** — who chooses inputs; detection vs confirmation.
2. **Extractor** — freestanding specimen transcription cost.
3. **Fit conditionality** — rubric excludes most software (scoping, not a build target).
4. **Platform narrowness** — x86_64 Linux ELF; APE extension rejected (ADR-014).

## Decision

**Invest in gap 1 (probe generator) first.** Do not productize the extractor until a paying candidate makes transcription cost the binding constraint. Do not reopen fit or platform as engineering work without a new ADR.

## Rationale

- Confirmation without discovery caps the value proposition. The ICP's second buyer question is "what probes do I run?"
- Gap 1 reuses G23 adversarial search and relation-native sweeps. Bounded experiment on the existing backtest corpus is cheap and falsifiable (`PROBE-GENERATOR-SPIKE.md`).
- Gap 2 is partially mitigated by agent transcription (G55 H3 tranches 2–3: four parallel delegates, minutes each). A deterministic extractor is high scope and high risk.
- Gaps 3–4 are intentional scope boundaries, not missing features.

## Witness production vs detection (terminology)

| Term | Meaning |
| --- | --- |
| **Witness production** | Given probe + oracle/relation, floor emits reject with bytes |
| **Detection** | Generator finds probe in trigger domain without fix-commit knowledge |

Backtests through G72 prove witness production. G73 tests detection.

## Consequences

- Open G73 (#89) before any extractor automation goal.
- ICP and NANO-GOALS must not claim "finds bugs" until G73 reports re-detection rate.
- Sidecar (ADR-015 skill-only) and probe generator are independent tracks.

## Kill trigger

If G73 is **REFUTED** at declared budget, keep the honest ICP line: "regression harness for properties you already named; detection is your fuzzer or our future generator work."

**Addendum 2026-06-11 (#89):** G73 **PROVEN (bounded)** at default budget. **6/12 true_found** (honest rev1 passes the same blind witness; value_oracle uses rev1 vs rev2 differential). 8/12 rev2 reject total; 2/12 **both_reject** (capnproto-base64, rust-base64 round_trip relation-declaration gaps on unpadded input). ICP may claim bounded blind detection on the committed corpus at exactly the 50% margin; misses (utf8 overlong, wabt 10-byte, parseip wrap) remain budget-limited, not wired into CI (~198s wall).

**Addendum 2026-06-11 (audit):** `blind-probe-search.sh` now reports `true_found` vs `both_reject` per case; verdict uses `true_found` rate only.

**Addendum 2026-06-11 (hardening, #96):** generator hints moved into `.req` declarations (no domain-keyed switches), corpus extended with `zig-wyhash-native` (blind **true_found** on a native non-C binary), rust-base64 converted to a true separator via `probe_block=4`. Rate **8/13 true_found (61%)**, above threshold with margin. Remaining both_reject (capnproto) is a documented relation-declaration gap, not generator error.
