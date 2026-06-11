# Probe generator spike (G73)

Pre-registered eval for the top ICP adoption gap. Answers whether the existing floor can **find** defects without curated witness probes, or only **confirm** them once pointed.

Decision record: [`../adr/ADR-020-adoption-gap-priority.md`](../adr/ADR-020-adoption-gap-priority.md).

## What the backtests proved (confirmation)

Given a probe inside the defect's trigger domain and a correct expected value (or a relation that is its own oracle), the verify floor returns a byte-precise reject witness. Honest builds accept the same probe set. Fifteen real-history timelines replay accept → reject → accept.

That is witness **production**, not defect **discovery**. Probe selection for every backtest used fix-commit knowledge or domain-specific construction (5553-byte adler32 vector, 5414-byte LZW overflow stream, etc.).

## Empirical counterexample (off-domain accept)

Same buggy mint, two probe sets:

| Probe | `zig_adler32_buggy.ngb` verdict |
| --- | --- |
| 5553-byte gradient (curated) | reject |
| `616263` only | accept |

The defect remains in the binary. The pipeline is blind outside the trigger domain.

## Hypothesis under test

A blind probe generator, given only `.req` + relation-native enumeration rules, re-finds a useful fraction of known buggy rev2 witnesses within a fixed budget.

## Non-hypothesis

- Sidecar `.req` recall (G55, separate track, skill-only).
- Freestanding extraction from arbitrary repos (agent-prompt pattern until cost binds).
- Fit scoring or platform expansion (scoping, not engineering).

## Generator inputs (allowed)

From the committed `.req` only:

- `relation`, `entry`, `encode`/`decode`/`mode`, `domain`, `wire`, `reject`
- Declared generator hints (2026-06-11 hardening, #96): `flow_nm`, `seed_start`, `cmp_max`, `probe_style`, `probe_block`. These move driver-protocol facts (e.g. the flow partial length the driver supports, the token block size of the wire format) into the declaration; `blind-probe-generators.sh` carries no domain-keyed switches.
- Relation-native generators already in tree:
  - `round_trip` / `value_oracle` with `wire=hex`: bounded byte/hex enumeration
  - `involution` / `u32` domain: full or stepped sweep (G24)
  - `flow_composition`: `(n,m,seed)` triple schedule (G57–G71 gen scripts as templates)
  - `range_coverage`: seed sweep + optional endpoints from `.req`
  - `value_oracle` with external spec: G23 sum-ordered argv enumeration when `.spec` + `conf-eval` exist

## Generator inputs (forbidden)

- Witness hex from `fixtures/backtest/*/CASE.md`
- `timeline.manifest` reject lines
- Fix-commit SHAs or scorecard notes
- Hand `PROBES=` strings from spike H3 runs

## Corpus

Committed backtest **rev2 (buggy)** `.ngb` files with known witnesses in CASE.md (held out from the generator). Start with relation-diverse subset ≥10:

- utf8, leb128 (round_trip)
- wabt-leb128, capnproto-base64, cosmo-ljson, cosmo-parseip
- knuth-rand-len, llvm-bolt-cmp
- rust-base64, zig-wyhash, go-base64-streaming, rust-crc32fast

## Budget (declare before run)

| Relation family | Initial budget |
| --- | --- |
| round_trip byte domain | first N byte sequences by length then lex order (N=256 default) |
| involution u32 | full u32 sweep (existing) |
| flow_composition | seeds 0..B-1 with fixed (n,m) from gen script defaults (B=64) |
| value_oracle argv | G23 sum-ordered pairs up to sum S (S=32 default) |
| range_coverage | 256 seed sweep (existing) |

Document wall time per case. Raise budget only in a labeled follow-on tranche.

## Pass / fail criteria

| Outcome | Meaning |
| --- | --- |
| **PROVEN (bounded)** | ≥50% of corpus cases get a **true_found** reject within budget (rev1 passes the same witness; value_oracle uses rev1 vs rev2 differential); misses documented with reason |
| **PARTIAL** | 20–49% true_found; generator useful only with relation-specific tuning |
| **REFUTED** | <20% true_found without cheating; floor remains confirmation-only for ICP pitch |

**Specificity control (2026-06-11 follow-on).** A blind `found` on rev2 alone is insufficient. The driver re-checks honest rev1 on the same witness. `both_reject` means both builds fail the declared relation for the same probe (relation-declaration gap, not mined-defect separation). Verdict uses `true_found` rate only.

Either outcome is publishable. Do not tune budget post hoc to pass.

## Deliverables

1. Spike script under `scripts/agent-eval/` (name TBD at implementation).
2. Results markdown table in this file (Results section below).
3. NANO-GOALS claims ledger row for detection.
4. Optional gate only if PROVEN and script is deterministic + fast enough for CI.

## Results

Run: 2026-06-11 (hardened, #96), `./scripts/agent-eval/blind-probe-search.sh --corpus backtest-rev2 --budget default`, wall ~207s (Docker runner). Corpus extended to 13 with `zig-wyhash-native`.

Budget: byte/hex/ascii/u32=256, flow seeds=64. Generator hints declared in `.req` (`flow_nm`, `seed_start`, `cmp_max`, `probe_style`, `probe_block`); empty-output backend faults retried inside `run-linux-elf-capture.sh`.

| Case | Relation | Result | Specificity | wall ms | Notes |
| --- | --- | --- | --- | ---: | --- |
| utf8 | round_trip | miss | — | 4939 | overlong `C080` not in 256-probe decimal budget |
| leb128 | round_trip | miss | — | 5330 | non-minimal `8000` not in first 256 decimal probes |
| wabt-leb128 | round_trip | miss | — | 5229 | 10-byte witness `…ff02` not in first 256 hex strings |
| capnproto-base64 | round_trip | found | **both_reject** | 6501 | witness `AAB=`; honest (WHATWG atob) tolerates nonzero trailing bits, decode `0000` reencode `AAA=`; relation gap stands for this decoder |
| cosmo-ljson | value_oracle | found | true_found | 52586 | differential vs rev1; witness `80` (not curated `c080`) |
| cosmo-parseip | value_oracle | miss | — | 94991 | `255.255.255.256` not in ascii budget |
| knuth-rand-len | range_coverage | found | true_found | 233 | endpoint lo seed=22 hex=02 (matches curated) |
| llvm-bolt-cmp | cmp_order | found | true_found | 389 | pair 0,0 hex=00 (matches curated) |
| rust-base64 | round_trip | found | **true_found** | 6144 | witness `AAB=` (nonzero trailing bits); strict honest rejects, buggy accepts; `probe_block=4` converted the prior false positive |
| zig-wyhash | flow_composition | found | true_found | 562 | seed=0 hex=0 (curated witness uses seed=5) |
| **zig-wyhash-native** | flow_composition | found | **true_found** | 614 | **first blind detection on a native non-C binary**; same witness as the C transcription |
| go-base64-streaming | flow_composition | found | true_found | 17420 | seed=5 hex=5 (`seed_start=1` now declared in `.req`) |
| rust-crc32fast | flow_composition | found | true_found | 3593 | seed=5 hex=5 (matches curated) |

**Summary:** 9/13 rev2 reject (`found`), **8/13 true defect separators (61%)**, 1/13 `both_reject`, 4 miss, 0 error. **Verdict: PROVEN (bounded)** per pre-registered ≥50% **true_found** threshold, now with margin.

**Remaining precision gap.** capnproto's WHATWG-style decoder legitimately tolerates nonzero trailing bits, so `encode∘decode == id` over `probe_block=4` tokens still over-rejects the honest build. The honest relation for that decoder needs a canonical-form domain (zero trailing bits) or a `decode∘encode∘decode == decode` form; the latter would also blind the relation to the mined skip-invalid bug, so the case stays documented as a relation gap rather than silently weakened.

Misses are honest budget/domain-size failures, not confirmation-only on those relations. utf8/leb128/wabt need longer hex/decimal enumeration or structured fuzz, not fix-commit hints.

## Verification

```bash
./scripts/check-canonical-drift.sh
./scripts/agent-eval/blind-probe-search.sh --corpus backtest-rev2 --budget default
```
