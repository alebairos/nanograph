# Conformance floor (G9)

The accountability floor for autonomous agent code. An auditor computes the expected consequence from a spec, runs the real bytes, and accepts only on a match. The name is **ground-truth conformance**: ground-truth because it runs the real ELF on the real machine with no model standing in for it, conformance because the claim is that the bytes do what the spec says.

Decision and scope: [`../adr/ADR-002-ground-truth-conformance.md`](../adr/ADR-002-ground-truth-conformance.md). Issue #31.

## The property under test

Compute-not-lookup. The expected consequence is **computed from the spec** by an evaluator that never reads the bytes. The existing two-agent auditor compares against a fixed `WANT_STDOUT` file, a looked-up oracle. This floor derives the oracle instead.

## Data shapes

`ConfSpec`, parsed from key=value lines:

| Field | Values | Meaning |
| --- | --- | --- |
| `op` | `add`, `sub`, `mul` | binary integer operation |
| `a` | integer | left operand |
| `b` | integer | right operand |
| `yield` | `exit` | how the result manifests (v0: process exit code) |

`conf-eval` output is the computed integer on stdout, exit 0. Malformed spec exits non-zero with no integer.

Verdict line: `verdict=accept expected=N observed=N` or `verdict=reject expected=N observed=M detail=<one line>`.

## Components

| Path | Role |
| --- | --- |
| `tools/bin/conf-eval` | Compute expected integer from a `ConfSpec`. Reads only the spec. |
| `fixtures/conformance/*.spec` | Declared specs. |
| `scripts/agent-eval/conformance-check.sh` | Run real ELF from a `.ngb`, compare to computed expected, emit verdict + JSONL. |
| `scripts/check-conformance-floor.sh` | CI gate: one accept, one reject. |

Log: `.harness-data/agent-eval/conformance/run.jsonl`.

## What is proven vs trusted

Proven, empirically, on the run inputs. The real bytes executed and produced a consequence equal to the independently computed expectation. Zero model gap, because the ELF runs on the real machine via `run-linux-elf-capture.sh`.

Trusted. The reference evaluator `conf-eval`, and the spec itself as the statement of intent. The floor is bounded by the evaluator. If `conf-eval` shares a bug with the byte producer, a wrong program passes. Keep it small and independently authored.

Not covered. Inputs not run. The exit code is a single sampled consequence, not a proof over all inputs.

## Demonstration

| Spec | Bytes | Computed | Observed | Verdict |
| --- | --- | --- | --- | --- |
| `add(1,1)` yield=exit | `add_two.ngb` | 2 | 2 | accept |
| `add(1,1)` yield=exit | `add_two_chain.ngb` | 2 | 4 | reject |

`add_two` computes `1+1` and exits 2. `add_two_chain` applies two patches and exits 4. Against the computed expectation 2, the first conforms and the second does not.

## Relation to the larger pipeline

This is the bottom tier of the layered verifier in [`ADR-002`](../adr/ADR-002-ground-truth-conformance.md). Higher tiers stay deferred.

- Symbolic equivalence lifts the claim from sampled inputs to all inputs, at the cost of a model and a solver.
- A zkVM proof makes the sampled run portable for an auditor who will not re-run.
- The zerolang handoff replaces the hand-authored `ConfSpec` with one derived from verified MIR. Deferred until the floor is proven in-house.

## Future work

- A patched-immediate miscompilation fixture (same intent, wrong bytes) to complement the divergent-program negative.
- `yield=stdout` for programs whose consequence is output, not exit code.
- A reference evaluator with operands fed at runtime, so the binary is a real function of inputs rather than a constant.
