# ADR-021 — Language support as lang packs (contract, not plugin framework)

**Status:** Accepted
**Date:** 2026-06-11
**Goal:** G74 (#93)

## Context

The verify floor is language-blind by construction; it consumes `.ngb` + `.req` and never sees source (ADR-007, ADR-010). The claim "language-blind in practice" is **Proven (Zig)** at n=1 native non-C binary (G59). Language enters the system at exactly one point, the minter. `scripts/mint-one-elf.sh` (C, gcc:13) and `scripts/mint-one-zig.sh` (Zig 0.13.0) differ only in toolchain lines; both end at `tools/bin/ngb-pack`.

Adding languages (native Rust, Go) should be contributable by external agents or humans without touching the floor, the `.req` schema, or `NGB-V0`.

## Decision

**A language is a lang pack: one minter script honoring a documented contract, proven by an executable conformance gate.** No plugin framework.

A pack consists of:

1. `scripts/mint-one-<lang>.sh` honoring the minter CLI (`docs/specs/LANG-PACKS.md`).
2. At least one specimen + `.req` that the gate runs end to end.

`scripts/check-lang-pack.sh` is the acceptance bar: mint → `ngb-parse` (I1–I6) → honest accept under the declared `.req`. A pack that passes the gate is in; nothing else is negotiated.

## Alternatives rejected

- **Plugin framework** (registry, pack manifests, dynamic dispatch). There is no runtime extension point to dispatch through. The floor's public contract (`.ngb` + `.req`) is already the seam; a framework would be mechanism above an adjacent layer that suffices (01-system-design rule 1).
- **Status quo** (ad hoc per-language scripts). Gives a contributor no checkable target and lets the driver protocol drift; the implicit contract already had to be reverse-engineered from two scripts to write this ADR.

## Consequences

- Floor, `.req` schema, and `NGB-V0` are frozen with respect to language additions. A pack that needs a floor change is not a pack; it is a new ADR.
- Existing C and Zig minters must pass the gate unchanged (retrofit proof). If they cannot, the contract is wrong, not the minters.
- G75 (native Rust pack) and G76 (Go pack) are pre-registered conditionals in NANO-GOALS; each new pack that passes the gate upgrades the language-blind claim by one native language.
- Contribution surface for external agents: read `LANG-PACKS.md`, write one script + one specimen + one native backtest timeline, run `check-lang-pack.sh` (mint) and `check-lang-packs.sh` (CI).

## Addendum 2026-06-11 (G77, #106)

CI runs `check-lang-packs.sh` inside `check-all-proofs.sh`. It verifies committed honest `.ngb` per pack and **real-history** native backtests for Zig (`zig-wyhash-native`), Rust (`rust-base64-native`, G56), and Go (`go-base64-streaming-native`, G58). Docker mint stays manual at pack authoring time; CI never pulls toolchains.

## Addendum 2026-06-11 (G77 follow-on)

Removed synthetic `*-bswap32-native` CI timelines. Lang-pack gate honest specimens for Rust/Go now use the mined-case `.req`. `check-backtest.sh` witness match requires `(hex|x)=<value>` at field boundary. Go evil bswap uses build tags, not a duplicate source file.

## Addendum 2026-06-11 (G77c, docs + fidelity)

`NANO-GOALS.md` G75/G76 retro notes distinguish initial bswap32 contract proof from current CI gate. `LANG-PACKS.md` documents native port epistemology (C transcription port, not upstream repo mint), C backtest asymmetry, and Go artifact size. `check-native-port-fidelity.sh` asserts native rev2 witnesses match C-mined siblings on the same `.req`.

## Kill trigger

If two consecutive pack attempts (e.g. Rust then Go) require contract amendments to pass, the contract is mis-specified; reopen this ADR before a third attempt.
