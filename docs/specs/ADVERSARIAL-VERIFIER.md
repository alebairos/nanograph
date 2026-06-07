# Adversarial verifier vs static sampling (G23)

A competition supplies the independent oracle by construction. That removes the two open problems from the "author writes, QA verifies" case: intent provenance (who owns the spec) and the oracle ceiling (building a referee as hard as the program). In a competition the organizer owns both.

## Roles

- **Organizer.** Owns `gcd.spec` and `conf-eval` (the referee). The intent is independent of every author.
- **Authors.** Submit `.ngb` binaries. Honest ones (`gcd_v1`, `gcd_v2`) realize the spec; a buggy one (`gcd_evil`) does not.
- **Verifier.** Searches the input space for a pair where a submission's real bytes diverge from the oracle, and reports the witness.
- **NanoGraph.** Grounds the verdict in execution of the exact submitted bytes (`ngb-extract` then run), and records each submission's `graph_root_hash`.

## What this proves beyond G22

G22 verified against a fixed case list. A buggy author passes any fixed list that omits its trigger. `gcd_evil` returns `1` for equal operands, a plausible coprimality shortcut. The G21/G22 cases hold no equal pair, so the static suite accepts `gcd_evil`. An active searcher refereed by the oracle finds the diagonal and rejects with witness `(2,2)`.

The claim is not that the searcher is clever. A bounded enumeration of small inputs obviously dominates five fixed cases. The point is the structure. An independent oracle plus an active adversary plus byte-grounded execution turns "sampled, not proven" from a fixed blind spot into a moving one, and produces a concrete witness a human can read.

## Mechanism

- `gcd_evil` minted with `-DEVIL_GCD`. Correct Euclid except `a == b` returns `1`.
- `scripts/agent-eval/adversarial-verify.sh <candidate.ngb> <spec> [budget]`:
  - enumerates `(a,b)` by increasing sum within `budget` (default 64), deterministic and portable, no RNG.
  - runs the candidate over all probes in one backend session via `run-linux-elf-batch.sh`.
  - asks `conf-eval` for the truth per probe.
  - on a divergence, confirms it with an isolated clean run before declaring a separator, so a transient emulator fault cannot fabricate a reject.
  - exit 0 accept (no confirmed separator), exit 1 reject (witness printed).
- `scripts/run-linux-elf-batch.sh`: extract once, run all pairs in a single docker/qemu/native session, one crash-safe line per pair.

## Gate

`scripts/check-adversarial-verifier.sh`, in `check-all-proofs.sh`, guarded by `check-linux-runner.sh`:

1. Static arm. `gcd_evil` matches `conf-eval` on every `gcd.cases` line (the false negative the fixed suite would ship).
2. Adversarial arm. The searcher rejects `gcd_evil` with witness `a=2 b=2`.
3. Honest arm. The searcher accepts `gcd_v1` and `gcd_v2` with no separator in budget.

## Known limit

The searcher is still a bounded sample, just a far larger and adversarial one. It is not symbolic equivalence. A bug whose smallest trigger sits outside the budget box would pass. The budget is the dial. The oracle stays cheap.

## Not in scope

- No `.ngb` format change. I1–I6 hold.
- No live-LLM verifier in CI (nondeterministic; the deterministic enumerator is the lever). A live adversary is a later opt-in layer.
- No new floor tier; same stdout-diff verdict as G17/G21.
