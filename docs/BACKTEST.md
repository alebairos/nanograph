# Backtesting NanoGraph against history

Run a critical function's revisions back in time and ask a counterfactual at each one. Would NanoGraph have rejected here. The output is a timeline. NanoGraph accepts the healthy revisions and rejects exactly the buggy window, with a byte-level witness. The customer is [`ICP.md`](ICP.md), the candidate test is [`CASE-FIT-RUBRIC.md`](CASE-FIT-RUBRIC.md).

## The controlled-history demos

Two committed three-revision histories, each derived from its codec source. Both run the same generic driver and gate, which is the point. The backtest is codec-agnostic and relation-agnostic.

UTF-8, from `fixtures/metamorphic/utf8.c`. Revision one rejects overlong forms. Revision two drops the overlong checks, the classic security hole. Revision three restores them.

| rev | what changed | verdict | witness |
| --- | --- | --- | --- |
| rev1 honest | overlong rejected | accept | |
| rev2 overlong | overlong checks removed | reject | C0 80 |
| rev3 fix | overlong rejected again | accept | |

LEB128 unsigned varint, from `fixtures/metamorphic/leb128.c`. Revision one rejects non-minimal encodings. Revision two drops the minimality check, the classic varint hole where `80 00` decodes to zero. Revision three restores it.

| rev | what changed | verdict | witness |
| --- | --- | --- | --- |
| rev1 honest | non-minimal rejected | accept | |
| rev2 nonminimal | minimality check removed | reject | 80 00 |
| rev3 fix | non-minimal rejected again | accept | |

In both, the fix returns the binary to revision one's exact `graph_root_hash`, so the timeline closes where it opened. The same `round_trip` relation catches both bugs with no oracle. NanoGraph flags the buggy commit and nothing else.

`scripts/check-backtest.sh <manifest> <reject-hex> <label>` is the one gate for both, wired twice in `check-all-proofs.sh`.

## Data shape

A timeline manifest, one per case, for example `fixtures/backtest/leb128/timeline.manifest`. One `req=` line names the verification request. Each `rev=` line names a label, a committed `.ngb`, and the expected verdict. The per-revision `.ngb` are committed, so a proof run needs only a runner, not a compiler.

Minting is dev-time and generic. `scripts/mint-backtest.sh <source.c> <guard_macro> <outdir> <req_path> <bug_label>` derives the three sources by stripping the named guard block, packs them through `scripts/mint-one-elf.sh`, asserts the fix returns to revision one's hash, and writes the manifest. The two cases are minted by:

```
./scripts/mint-backtest.sh fixtures/metamorphic/utf8.c   OVERLONG_OK   fixtures/backtest/utf8   fixtures/metamorphic/utf8.req   overlong
./scripts/mint-backtest.sh fixtures/metamorphic/leb128.c NONMINIMAL_OK fixtures/backtest/leb128 fixtures/metamorphic/leb128.req nonminimal
```

`scripts/backtest-relation.sh <manifest>` is the lever. It is relation-agnostic. It runs the relation over the ordered revisions, prints the timeline, and exits non-zero if any verdict misses its expectation. The same driver serves any codec, any relation, any history.

## From controlled to real

Phase one is this demo, a hand-written manifest over a synthetic history with a known answer. It proves the mechanism and guards it in CI.

Phase two points the same driver at a real upstream function. The only new piece is the manifest generator, `git rev-list <range> -- <file>` checked out into a worktree, each revision wrapped in the trusted driver and minted. The verdict logic, the timeline, the witness, all reused.

## The hard part

Build reproducibility of old real commits is the real cost, not the relation. A years-old commit may not compile with today's toolchain, and dependencies drift. The mitigation is the trusted-driver trick. Vendor only the function under test plus the `_start`, parse, and print harness, never the whole upstream project. This is why a small, dependency-light codec function is the right first real target and a framework is the wrong one.

## Scope honesty

A backtest validates the bug class NanoGraph can express as a relation, not all bugs. It is a counterfactual on real history, not a proof. Its credibility rests on pre-registering the function and the property before reading the timeline, and on reporting misses and false positives, not only the catches.

## Formal mining (planned)

The two cases here are author-built histories with known answers. They prove the mechanism. The next step is mining real upstream histories where a relation-expressible bug was fixed, the counterfactual NanoGraph is built for. Proposed process, each stage filtering to the next.

1. Source. Permissive-license codecs, serializers, and parsers, the [`ICP.md`](ICP.md) shape. Start with standalone repos before functions buried in large projects.
2. Signal. A fix commit whose bug is non-canonical or non-minimal acceptance, a length or bounds error, or a broken involution or round-trip. The commit message and test diff name the property.
3. Score. Run each candidate through [`CASE-FIT-RUBRIC.md`](CASE-FIT-RUBRIC.md). Keep only a FIT, rank by priority.
4. Vendor. Extract the function and its types behind the trusted driver, never the whole project, so the buggy and fixed commits both build today.
5. Replay. Generate the manifest from `git rev-list` over the fix range and run `scripts/backtest-relation.sh`. Pre-register the property before reading the timeline.
6. Report. Publish catches, misses, and false positives. A miss is as informative as a catch.

G32 delivered the scored shortlist. G33 ran the synthetic track, G34 ran the first third-party real-history case (wabt), G35 ran the first real Knuth canon.

**G33 (synthetic, done).** A Knuth-shaped portability backtest that does not run Knuth's bytes. It models the Stanford GraphBase `save_graph` erratum (page 414, December 2025), where `fopen(f,"w")` let Windows text mode write `\r\n` for internal `\n` and broke cross-platform `restore_graph`; the fix is `"wb"`. The trusted driver `fixtures/metamorphic/knuth_sgb.c` reconstructs the erratum with a `BUGGY_TEXTMODE` macro because the defect is Windows-only and the Linux runner cannot observe the real bug. The SGB SHAs `c0943fd` and `88fac2f` are provenance, not proof inputs. What it proves is that the pipeline generalizes to a third `round_trip` domain. **Catch** on probe `266` (`0x01 0x0A`), witness hex `0A`. Timeline accept, reject, accept; fix hash matches rev1. See `fixtures/backtest/knuth-sgb/CASE.md`. The real-Knuth proof is G35.

**G35 (real Knuth canon, done).** The first backtest on Knuth's actual canon. The documented `rand_len` off-by-one in `gb_rand.w`: buggy `min_len+gb_unif_rand(max_len-min_len)` never reaches `max`; the fix adds `+1`. Mirror `ascherer/sgb` `fd99287` (buggy) to `65433e2` (fixed). `fixtures/metamorphic/knuth_rand_len.c` vendors Knuth's `gb_flip` + `rand_len`, transcribed at `fd99287`, validated against his `test_flip` constants (`gb_init_rand(-314159)` then `gb_next_rand()==119318998`). Runs his actual arithmetic, no simulation. The new `range_coverage` relation; strengthened in G37 with endpoint witnesses. See `fixtures/backtest/knuth-rand-len/CASE.md`.

**G37 (range_coverage strengthen, done).** `range_coverage` gains optional `lo_seed` and `hi_seed` in `.req`. Isolated draws verify `draw(lo_seed)==lo` and `draw(hi_seed)==hi` before the 256-seed sweep. The primary proof is deterministic endpoint reachability; the sweep is a robustness bound check. G35 re-minted req sets `lo_seed=22`, `hi_seed=2` (honest `22→1`, `2→10`). **Catch** on buggy rev: `draw(22)` yields 2 not 1, witness `hex=02`, `endpoint=lo`. Timeline accept, reject, accept; gated `KNUTH-RAND-LEN`. See `docs/specs/METAMORPHIC-RELATIONS.md`.

**G38 (range_coverage phase split, done).** Reachability and containment are named phases in `.req` (`reachability=on|off`, `containment=sweep|off`). Rejects emit `phase=reachability` or `phase=containment`. Accept reports `reachability=pass|skip containment=pass|skip`. G35 req sets `reachability=on containment=sweep`. No `.ngb` remint.

**G34 (wabt ICP, done).** The first true real-history backtest. wabt `ReadU64Leb128`, parent `89582f5` to fix `f1f3d6d` (PR #2256). The 10th-byte overflow check used `p[9] & 0xf0`, copied from the u32 path, missing bits 1..3, so a 10-byte LEB128 above u64 max was silently accepted and truncated; the fix is `0xfe`. `fixtures/metamorphic/wabt_leb128.c` transcribes wabt's decode and the real mask faithfully into freestanding C behind a trusted driver, not a verbatim build of wabt's non-freestanding C++. The fix is a strippable block (`0xf0` base, honest adds `0x0e`); a new `wire=hex` carries the 10-byte input. **Catch** on witness `ffffffffffffffffff02`: the buggy revision decodes it to the truncated `9223372036854775807`, the honest revision rejects it, both accept u64 max. Timeline accept, reject, accept; gated `WABT-LEB128`. See `fixtures/backtest/wabt-leb128/CASE.md`. Scored in `fixtures/fit-cases/wabt-leb128-u64.fit`.

**G41 (cosmo ParseIp, done).** First Justine-stack follow-through from G40. cosmopolitan `ParseIp`, parent `539bddc` to fix `c995838`. Pre-fix octet digit accumulation had no overflow guard; `255.255.255.256` silently becomes `4294967040`. New `value_oracle` relation. **Catch** on witness `3235352e3235352e3235352e323536`. Timeline accept, reject, accept; gated `COSMO-PARSEIP`. See `fixtures/backtest/cosmo-parseip/CASE.md`.

**G39 (capnproto ICP, done).** Second ICP follow-through from G32. capnproto/kj libb64-derived `decodeBase64`, parent `9306bc0` to fix `f3e0ed2` (PR #595). Pre-fix decode skipped invalid and padding bytes and never failed; fix adds `hadErrors`. `fixtures/metamorphic/capnproto_base64.c` transcribes encode/decode into freestanding C; strict checks strippable via `INVALID_OK`, rev2 compiled with `-DINVALID_OK`. New `wire=ascii` for base64 string probes. **Catch** on witness `5a6d397640` (`Zm9v@`): buggy skips `@`, decodes to `foo`, re-encodes `Zm9v`; honest rejects. Timeline accept, reject, accept; gated `CAPNPROTO-BASE64`. See `fixtures/backtest/capnproto-base64/CASE.md`. Scored in `fixtures/fit-cases/capnproto-base64.fit`.
