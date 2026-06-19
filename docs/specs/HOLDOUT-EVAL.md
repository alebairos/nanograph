# G83 holdout eval (pre-registered generalization)

Pre-registered split for blind probe detection. The backtest corpus (`backtest-rev2`, 13 cases) was used to harden generators and hints; this holdout corpus (`holdout-rev1`, 5 cases) is drawn from backtests that never appear in `backtest-rev2`.

**Independence caveat.** The five cases were selected from backtests already in the repo, not newly mined in a separate session for G83. This satisfies "outside the train list" but is weaker than the #121 ideal of fresh out-of-session mining. Two cases (`rust-base64-native`, `go-base64-streaming-native`) share a `.req` and bug family with train siblings (`rust-base64`, `go-base64-streaming`), so they test native-binary portability of an already-tuned generator, not independent generalization. `conserve-popcount` is the clearest independent find (a relation the generator was never pointed at). Read `generalizes_bounded` as a bounded positive signal, not proof of generalization to unseen bug families. A `holdout-rev2` of freshly mined bugs would close this gap.

Parent goal: [`NANO-GOALS.md`](NANO-GOALS.md) G83 (#121). Detection spike context: [`PROBE-GENERATOR-SPIKE.md`](PROBE-GENERATOR-SPIKE.md). Decision record: [`../adr/ADR-020-adoption-gap-priority.md`](../adr/ADR-020-adoption-gap-priority.md).

## Protocol

1. **Freeze the lever.** `fixtures/holdout/preregistration.json` pins `freeze_commit`, generator SHA256 hashes, budgets, thresholds, and the five holdout cases before the single eval run.
2. **Hint legality.** Generators use only `.req` fields and interface-derived enumeration (see PROBE-GENERATOR-SPIKE Hint legality). No CASE.md witnesses, timeline reject lines, or fix-commit knowledge. One known exception. The `jemalloc-s2u` `size_monotone` find is driven by the `overflow_size` field in `jemalloc_s2u.req`, a value set during backtest authoring with witness knowledge. Powers-of-2 enumeration did not discover that defect on its own, so count jemalloc as relation-contract confirmation rather than pure blind discovery.
3. **Holdout corpus.** Five real-history bugs outside `backtest-rev2`:
   - jemalloc-s2u (`size_monotone`)
   - conserve-popcount (`conserve_popcount`)
   - knuth-sgb (`round_trip`, `domain=knuth_sgb`)
   - go-base64-streaming-native (`flow_composition`)
   - rust-base64-native (`round_trip`)
4. **Single frozen run.** `./scripts/agent-eval/run-holdout-eval.sh` runs once at default budgets and writes `fixtures/holdout/results-frozen.json`. No post-miss tuning on holdout.

## Data shapes

### HoldoutPreregistration (`fixtures/holdout/preregistration.json`)

| Field | Meaning |
| --- | --- |
| `freeze_commit` | Git commit hash pinning generator + hint grammar |
| `generator_sha256` | SHA256 of `blind-probe-generators.sh` and `blind-probe-search.sh` |
| `corpus` | `holdout-rev1` |
| `cases` | Five `{label, manifest, relation}` entries |
| `budgets` | Default blind budgets (byte/flow/u32/ascii/hex = 256/64/256/256/256) |
| `thresholds` | `generalizes_min_pct=50`, `overfit_max_pct=25` |

### HoldoutFrozenResults (`fixtures/holdout/results-frozen.json`)

| Field | Meaning |
| --- | --- |
| `run_timestamp` | UTC ISO8601 run time |
| `freeze_commit` | Must match preregistration |
| `case_lines` | Raw `case=…` lines from blind search |
| `summary` | `true_found`, `total`, rates, miss/error counts |
| `verdict` | `generalizes_bounded`, `overfit`, or `inconclusive` |

## Verdict thresholds (pre-registered)

| `true_found` rate | Verdict |
| --- | --- |
| ≥ 50% | `generalizes_bounded` |
| < 25% | `overfit` |
| 25–49% | `inconclusive` |

Verdict uses **true_found** only (rev1 replay control), same as G73.

## Interface-derived blind generators (holdout additions)

Added to `blind-probe-generators.sh` for relations not covered by the original G73 set:

| Relation / domain | Generator rule |
| --- | --- |
| `size_monotone` | Ascending powers of 2 from 1024 |
| `conserve_popcount` | `blind_gen_u32` (0..255) |
| `round_trip` + `domain=knuth_sgb` | Integers 1..`BLIND_BYTE_BUDGET` |

## Verification

Preregistration gate only in CI (no live re-run):

```bash
./scripts/check-holdout-prereg.sh
./scripts/check-holdout-eval.sh   # after frozen results exist
```

Live eval (Linux runner required):

```bash
./scripts/agent-eval/run-holdout-eval.sh
```

## Invariants

- Holdout cases must not appear in `backtest-rev2` corpus list in `blind-probe-search.sh`.
- `check-holdout-eval.sh` recomputes verdict from frozen summary + prereg thresholds; results cannot drift from declared logic.
- Misses on holdout are documented; holdout score is never retroactively improved.
