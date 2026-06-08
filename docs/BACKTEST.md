# Backtesting NanoGraph against history

Run a critical function's revisions back in time and ask a counterfactual at each one. Would NanoGraph have rejected here. The output is a timeline. NanoGraph accepts the healthy revisions and rejects exactly the buggy window, with a byte-level witness. The customer is [`ICP.md`](ICP.md), the candidate test is [`CASE-FIT-RUBRIC.md`](CASE-FIT-RUBRIC.md).

## The controlled-history demo

A committed three-revision history of the UTF-8 codec, derived from `fixtures/metamorphic/utf8.c`. Revision one rejects overlong forms. Revision two drops the overlong checks, the classic bug. Revision three restores them, the fix.

`scripts/check-backtest-utf8.sh` (in `check-all-proofs.sh`) replays it and asserts the timeline.

| rev | what changed | verdict | witness |
| --- | --- | --- | --- |
| rev1 honest | overlong rejected | accept | |
| rev2 overlong | overlong checks removed | reject | C0 80 |
| rev3 fix | overlong rejected again | accept | |

The fix returns the binary to revision one's exact `graph_root_hash`, so the timeline closes where it opened. NanoGraph flags the buggy commit and nothing else.

## Data shape

A timeline manifest, `fixtures/backtest/utf8/timeline.manifest`. One `req=` line names the verification request. Each `rev=` line names a label, a committed `.ngb`, and the expected verdict. The per-revision `.ngb` are committed, so a proof run needs only a runner, not a compiler. Minting is dev-time, `scripts/mint-backtest-utf8.sh`, which derives the three sources and packs them through `scripts/mint-one-elf.sh`.

`scripts/backtest-relation.sh <manifest>` is the lever. It is relation-agnostic. It runs the relation over the ordered revisions, prints the timeline, and exits non-zero if any verdict misses its expectation. The same driver serves any codec, any relation, any history.

## From controlled to real

Phase one is this demo, a hand-written manifest over a synthetic history with a known answer. It proves the mechanism and guards it in CI.

Phase two points the same driver at a real upstream function. The only new piece is the manifest generator, `git rev-list <range> -- <file>` checked out into a worktree, each revision wrapped in the trusted driver and minted. The verdict logic, the timeline, the witness, all reused.

## The hard part

Build reproducibility of old real commits is the real cost, not the relation. A years-old commit may not compile with today's toolchain, and dependencies drift. The mitigation is the trusted-driver trick. Vendor only the function under test plus the `_start`, parse, and print harness, never the whole upstream project. This is why a small, dependency-light codec function is the right first real target and a framework is the wrong one.

## Scope honesty

A backtest validates the bug class NanoGraph can express as a relation, not all bugs. It is a counterfactual on real history, not a proof. Its credibility rests on pre-registering the function and the property before reading the timeline, and on reporting misses and false positives, not only the catches.
