# ADR-001 — NanoGraph product verdict

**Status:** Accepted (**Pivot**)  
**Date:** 2026-06-05 (revised after eval sprint #29)  
**Program:** P01–P20 product proof + measured Task A / ELF baseline

## Context

NanoGraph v3 tests whether agent-first `.ngb` graphs with post-hoc NanoProbe tooling beat raw ELF editing for bounded patch tasks. Infrastructure P01–P19 is shipped. Eval sprint #29 measured Task A (add_two → exit 4) on both surfaces without golden leakage.

## Decision

**Pivot** the product thesis before adding programs or syntax.

Keep the `.ngb` + NanoProbe stack as a **trust and audit substrate**. Do not claim agent-native editing beats ELF on iteration cost for simple exit-code patches until Task B (stdout / rodata) and improved offset discovery are measured.

## Evidence (measured)

| Falsification criterion | Result |
| --- | --- |
| Agent Task A ≤5 iterations | **Met** — 4 iterations (`task-a/run.jsonl`) |
| `.ngb` beats ELF baseline | **Not met** — ELF 3 iterations / 160 ms vs ngb 4 / 434 ms (`elf-a/run.jsonl`) |
| Proofs green through P19 | **Met** |
| Invalid patches rejected | **Met** |

## What worked

- Agent converged in budget using `disassemble` + `ngb-patch` only.
- Two-patch chain validated with audit preconditions.
- ELF baseline solved the same goal with fewer steps on identical byte offsets (image 120/127).

## What failed the product claim

- Iteration count and wall time favored raw ELF hex edit on Task A.
- Extra `.ngb` structure did not reduce agent effort on this task class.

## Pivot plan

1. **Do not** add a fourth canonical program yet.
2. Run Task B (print_42 → `43\n`) ngb vs ELF before revisiting this ADR.
3. Improve author surface: expose image-relative patch offsets from `nano-probe disassemble` (or JSON) so agents skip offset arithmetic.
4. Optional `nanograph-adversary` on eval PRs only.

## Kill triggers (unchanged)

- Task B shows same ELF advantage with no audit upside.
- Agents require fixture sources despite invariant JSON.
- Patch surface grows faster than proof coverage.

## Continue triggers (re-open)

- Task B ngb path wins on iterations or success where ELF rodata edit fails.
- Multi-patch audit catches an invalid chain that ELF editing would ship silently.
