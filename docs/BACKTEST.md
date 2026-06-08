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

The deliverable is a scored shortlist, then one vendored real-history backtest. The open decision is the lead source, a standalone permissive repo versus a varint or codec inside a named project like protobuf or DWARF tooling.
