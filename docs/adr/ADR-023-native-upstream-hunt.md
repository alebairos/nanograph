# ADR-023 — Native-upstream hunt on third-party codecs

**Status:** Accepted
**Date:** 2026-06-24
**Goals:** G85 (vehicle, #126), G86 (first defect, #126)

## Context

G84/G85 established blind probe generation and `native-hunt.sh`, which runs metamorphic relations against real executables instead of transcribed `.ngb` specimens. A transcription reject is ambiguous between an upstream bug and a transcription error, which blocks a maintainer-facing report.

Bitcoin prep on `rust-bitcoin` `VarInt` yielded an honest null (`verdict=accept`). The next step is thinner third-party codecs where a native reject is a candidate defect.

## Decision

1. **Native CLI contract.** Targets expose `target <mode> <value>` on stdout or a reject sentinel, same as existing native fixtures (`cpython_base64`, `bitcoin_compactsize`).

2. **Canonical-enforcing only for defect claims.** A native `reject` on `canonical=enforced` is a candidate upstream defect. A `relation_gap` on `canonical=lenient` is a contract mismatch, not a bug report.

3. **Probe source seam.** Wire formats outside the holdout-frozen `blind-probe-generators.sh` use `probes_cmd` in the `.req` (e.g. `gen-compactsize.sh`). Do not edit the frozen generator.

4. **Upstream fidelity.** Prefer `pip install` / package import when the environment supports it. When install fails (e.g. `bitcoinlib` on Python 3.14 without `gmp`), vendor a verbatim extract of the codec functions at a pinned commit with provenance in `fixtures/native/<target>-vendor/` and `CASE.md`. The claim is upstream logic ran, not that the full package wheel installed.

5. **First mined defect.** `1200wd/bitcoinlib` CompactSize at `bec99a2` via `fixtures/native/bitcoinlib_compactsize`. Gated by `scripts/check-bitcoinlib-compactsize-hunt.sh`.

## Rationale

- Maintainer trust requires real code execution, not a freestanding reimplementation.
- CompactSize fits `round_trip` v1 without a checksummed seed corpus; blind probes already exist.
- The bitcoinlib finding is encoder boundary (`<` vs `<=`) plus missing decode minimality check, the same class Core enforces and rust-bitcoin fuzzing recently tightened (PR #5697 range check).

## Consequences

- Claims ledger may state "native hunt finds real upstream defect" only with a native target, enforced canonical contract, and confirmed witness against live or vendored-verbatim upstream code.
- Bech32m and Base58Check targets need a seed corpus or differential mode before they join the huntable-now set.
- Do not open maintainer issues from this repo until the human approves external contact; the CASE.md is the report draft.

## Kill trigger

If native wrappers routinely require full vendoring of entire packages because install is broken everywhere, revisit a containerized target runner rather than growing vendor trees.
