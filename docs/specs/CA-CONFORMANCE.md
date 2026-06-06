# Cellular-automata conformance (G17)

Extends the conformance floor from a scalar consequence to an **emergent byte stream**. A single local rule, iterated, produces complex global output. The independent oracle computes the full evolution from a compact spec; the compiled program must realize the same bytes.

Decision and scope: [`../adr/ADR-004-ca-conformance.md`](../adr/ADR-004-ca-conformance.md). Issue #37.

## Why this and not more arithmetic

The scalar floor (G9) accepts on a one-byte exit code. That hides two questions. Does conformance hold on a rich observable, not a single sampled byte. And can two binaries with different bytes both be accepted because they realize the same intent. An elementary cellular automaton answers both with the smallest possible rule. The rule is one byte; the output is a grid.

## Data shapes

`ConfSpec` gains `op=eca`:

| Field | Values | Meaning |
| --- | --- | --- |
| `op` | `eca` | elementary cellular automaton (Wolfram code) |
| `rule` | 0–255 | the local transition rule |
| `width` | 1–512 | cells per row |
| `gens` | 1–512 | rows to render, generation 0 first |
| `init` | `center`, `right` | single 1 at `width/2` (`center`) or `width-1` (`right`), rest 0 |
| `yield` | `stdout` | the observable is the rendered grid |

Boundary is fixed-zero. Cells past the edges are 0. Generation 0 is the seed row. New cell value is `rule >> (left<<2 | center<<1 | right) & 1`.

Render: `gens` lines, each `width` chars from `{., #}` (`.`=0, `#`=1), each line `\n`-terminated. `conf-eval` reads only the spec, never the bytes. Output is exactly the byte stream a conforming program must print.

## The observable is stdout, not exit code

A grid does not fit in one exit byte, so CA conformance compares the full captured stdout to the oracle stdout, byte for byte. The scalar exit-code path (`conformance-check.sh`) is unchanged. CA gets its own check so the proven path keeps its narrow contract.

## Components

| Path | Role |
| --- | --- |
| `tools/bin/conf-eval` | `op=eca` renders the evolution to stdout. Reads only the spec. |
| `fixtures/ca/*.spec` | Declared CA specs. |
| `fixtures/ca/rule30.golden` | Independently minted Rule 30 grid. |
| `fixtures/ca/*.ngb` | Route B compiled-C specimens (two variants). |
| `scripts/check-ca-oracle.sh` | Phase 1 gate: popcount invariant + golden diff. No toolchain. |
| `scripts/check-ca-conformance.sh` | Phase 2 gate: ELF stdout vs oracle, two-variant accept, wrong-rule + patch-level reject. |
| `tools/bin/ca-rule30-patch-fixture` | One-byte rule flip on v1 (`0x1e`→`0x5a`); `ca_rule30_patched.ngb`. |
| `scripts/check-linux-runner.sh` | Prereq for phase 2; skips gracefully without docker/qemu/native Linux. |
| `scripts/agent-eval/run-live-ca-agent-loop.sh` | Opt-in live CA author (sandbox + `op=eca` intent). |

Log: `.harness-data/agent-eval/conformance/run.jsonl`.

## What is proven vs trusted

Phase 1 proves the oracle two independent ways. Rule 90 from a center seed has row `k` population equal to `2^popcount(k)` (Pascal's triangle mod 2). That invariant is closed-form, derived from outside `conf-eval`, so it catches an oracle that renders a plausible-but-wrong grid. Rule 30 has no closed form and is diffed against a golden minted by an independent computation, not by `conf-eval`.

Phase 2 proves conformance on the real bytes. A Route B program, compiled freestanding C, prints the grid via `write(1,...)`. Its `.ngb` is run via `run-linux-elf-capture.sh` and its stdout is diffed against the oracle. Two variants compiled from the same source at different optimization have different `graph_root_hash` and identical stdout. Both are accepted. That is **behavioral-not-structural** conformance, stated and demonstrated, not assumed. A mutated `.ngb` prints a different grid and is rejected.

Trusted. The spec as the statement of intent, and `conf-eval` as the reference. The floor is bounded by the evaluator. The popcount invariant exists so the evaluator is not the only witness to its own correctness.

## Behavioral-not-structural, precisely

The conformance verdict is a function of `(spec, observed stdout)`. It does not read `graph_root_hash`. Two specimens with distinct hashes and identical stdout therefore receive the same accept. The hashes are recorded in the demonstration so the distinctness is auditable, but they are not an input to the verdict. This is the property the scalar floor could assert but never exhibited, because it shipped a single binary per spec.

## Provenance

Route B binaries are compiler output, not hand-assembled bytes. They are minted once, in a pinned container, and committed as golden `.ngb`. CI packs and runs the committed bytes; it does not recompile. The compiler is a fixture mint, the same role C already plays for the hand-built specimens. NanoGraph stays language-agnostic. It verifies emitted bytes against intent and never reads source.

## Relation to the larger pipeline

Same bottom tier as G9. The lift to all-inputs (symbolic equivalence) and portable proof (zkVM) stay deferred. The CA only widens the observable and exhibits the behavioral-not-structural property; it does not change the trust model.
