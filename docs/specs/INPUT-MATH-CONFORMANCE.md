# Input-bound math conformance (G21)

The scalar floor (G9) and CA floor (G17) both fix operands in the spec. `add(1,1)` bakes `a=1 b=1`. `op=eca rule=110 width=96` bakes every parameter. The program is a constant, not a function. G21 closes the gap the claims ledger parked as "Runtime operands in ConfSpec."

Decision: [`../adr/ADR-005-input-math-conformance.md`](../adr/ADR-005-input-math-conformance.md). Issue #41.

## The property under test

Input-bound conformance. The spec declares the operation and where operands come from. The harness feeds runtime inputs at execution time. The oracle computes the expected consequence from `(spec, runtime inputs)` without reading the bytes. Multiple input vectors exercise the same binary as a function, not a single sampled constant.

## Data shapes

`ConfSpec` gains `input=argv` and `op=gcd`:

| Field | Values | Meaning |
| --- | --- | --- |
| `op` | `gcd` | greatest common divisor (Euclidean algorithm) |
| `input` | `argv` | two integer operands from command-line args at runtime |
| `yield` | `stdout` | observable is the rendered integer plus newline |

No `a` or `b` in the spec. Operands are runtime-bound.

`conf-eval` invocation: `conf-eval <spec> <a> <b>`. The evaluator reads the spec for `op` and `input`, takes `a` and `b` from its own argv, computes the expected integer, prints `%ld\n` on stdout.

Cases file (`fixtures/input-math/gcd.cases`), one vector per line:

```
<a> <b> <expected>
```

Comments (`#` prefix) and blank lines are ignored. The oracle gate checks `conf-eval` against each expected value. The conformance gate runs the ELF with each `(a,b)` pair and diffs stdout against `conf-eval`.

Verdict is a function of `(spec, runtime inputs, observed stdout)`. `graph_root_hash` is not an input.

## Components

| Path | Role |
| --- | --- |
| `tools/bin/conf-eval` | `op=gcd input=argv`; runtime operands via extra CLI args |
| `fixtures/input-math/gcd.spec` | Declared intent (no fixed operands) |
| `fixtures/input-math/gcd.cases` | Independent test vectors |
| `fixtures/input-math/gcd.c` | Freestanding Route B specimen source |
| `fixtures/input-math/gcd_v1.ngb`, `gcd_v2.ngb` | Two optimization variants (behavioral-not-structural) |
| `fixtures/input-math/gcd_wrong.ngb` | Wrong-algorithm negative |
| `scripts/mint-input-math-fixtures.sh` | Mint specimens (pinned `gcc:13`, committed `.ngb`) |
| `scripts/run-linux-elf-capture.sh` | Forwards extra args to the extracted ELF |
| `scripts/check-input-math-oracle.sh` | Phase 1: conf-eval matches cases |
| `scripts/check-input-math-conformance.sh` | Phase 2: ELF stdout matches oracle per case |

## What is proven vs trusted

Proven on the run inputs. The same binary, fed multiple `(a,b)` pairs at runtime, produces stdout equal to the independently computed expectation for each pair. Two variants with distinct `graph_root_hash` both accept on all cases.

Trusted. `conf-eval` Euclidean gcd, and the cases file as the independent witness for the oracle gate.

Not covered. All integers, symbolic proof, or stdin-based input (v0 is argv only).

## Relation to prior floors

G9 scalar floor: constant operands, exit code. G17 CA floor: constant parameters, rich stdout. G21: runtime operands, stdout. Same bottom tier (ADR-002). No format change. Invariants I1–I6 hold.
