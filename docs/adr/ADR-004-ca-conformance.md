# ADR-004 — Cellular-automata conformance

**Status:** Accepted (**Widen the observable to stdout; exhibit behavioral-not-structural acceptance**)
**Date:** 2026-06-06
**Goal:** G17 (issue #37)

## Context

The conformance floor (G9, ADR-002) accepts a binary when its real exit code equals an expectation computed from a spec. Two limits were never tested. The observable was one byte, so conformance on a rich output was unproven. And every spec shipped with one binary, so the claim that conformance is behavioral and not structural was asserted but never exhibited.

An elementary cellular automaton is the smallest specimen that stresses both. The transition rule is a single byte. Iterated from one live cell, it generates a non-trivial grid. Rule 90 is fractal with a closed-form population per row. Rule 30 is chaotic with no closed form.

## Decision

Add `op=eca` to `conf-eval`, rendering the full evolution to stdout. Verify CA conformance by comparing the program's captured stdout to the oracle's stdout, byte for byte. Ship two Route B specimens per spec, compiled from one source at different optimization, to exhibit behavioral-not-structural acceptance directly.

## Why the adjacent lower layer is insufficient

`conf-eval` computed a scalar and the harness compared it to an exit code. A grid exceeds a single exit byte, so the scalar path cannot carry the observable. The smallest mechanism that closes the gap is a renderer in `conf-eval` plus a stdout-diff check. The existing exit-code check is left untouched; widening it would couple the proven scalar path to the new byte-stream path for no benefit.

## What we are not building

- No `.ngb` format change. Pack, parse, and probe are untouched; invariants I1–I6 hold unchanged. The `.ngb` embeds a different ELF image with the same structure.
- No general CA. `init=center`, fixed-zero boundary, elementary (radius-1, two-state) rules only.
- No recompilation in CI. Binaries are minted once in a pinned container and committed.
- No new trust model. Same bottom tier as ADR-002.

## Design

- `ConfSpec` `op=eca` = `{ rule:0-255, width, gens, init=center, yield=stdout }`.
- Render `gens` rows of `width` chars from `{., #}`, newline-terminated. New cell = `rule >> (l<<2 | c<<1 | r) & 1`, zero boundary.
- Phase 1 oracle gate, no toolchain. Rule 90 row `k` population must equal `2^popcount(k)`. Rule 30 must match an independently minted golden.
- Phase 2 conformance gate. Route B C reproduces the grid via `write(1,...)`; `.ngb` runs via `run-linux-elf-capture.sh`; stdout is diffed against the oracle. Two variants accept; a mutated `.ngb` rejects.

## Behavioral-not-structural

The verdict is a function of `(spec, observed stdout)` and never reads `graph_root_hash`. Two specimens with distinct hashes and identical stdout both accept. The hashes are recorded for audit but are not verdict inputs.

## Known limit

The floor is only as strong as `conf-eval`. The Rule 90 popcount invariant is the guard against the evaluator being the sole witness to its own correctness, because it is derived outside the evaluator. Inputs not run are not covered; a CA spec fixes one seed and one generation count, so it is still a sampled consequence, only a much richer sample than one byte.

## Kill trigger

If rendering even an elementary CA from the spec needs a general interpreter, the compute-not-lookup property stops being cheap and the floor's claim to run at agent speed weakens. That cost signal stops further investment in richer oracles.
