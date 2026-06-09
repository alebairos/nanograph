# Nano goals (decided)

Ordered goals for NanoGraph v3. Each canonical program gets the same proof ladder (static → structural → behavioral → audit).

## Claims ledger (2026-06-05)

What the program has settled versus what still needs a goal.

| Claim | Status | Evidence |
| --- | --- | --- |
| Integrity gating beats raw ELF at author time | **Proven** | 3/3 hand-picked bad edits; 1000/1000 fuzz (ADR-001) |
| Two-agent message interchange works | **Proven** | G8 scripted loop, 2 rounds, CI-gated |
| Oracle is computed, not looked up | **Proven** | G9 `conf-eval`, G11 `yield=stdout` in loop |
| Static micro-op rejects structural mistakes | **Proven** | G10 `not_rodata`, G12 `value_mismatch`, CI-gated |
| Miscompilation caught by conformance floor | **Proven** | G9 `add_two_patched` negative (exit 3 vs spec 2) |
| Live Cursor CLI author completes the loop | **Proven** | G13 first run, 1 round, `composer-2.5` |
| Static gate rejects operational errors pre-execution | **Proven** | Operational-error matrix: 4/4 bad classes rejected at 0 executions (`--expect-off` + `--expect-new`); gated in `check-all-proofs.sh` |
| Conformance generalizes to emergent output, behavioral-not-structural | **Proven** | G17 CA: `conf-eval op=eca` renders the grid; two Route B variants accept on one spec with distinct `graph_root_hash`, wrong-rule specimen rejects; Rule 90 popcount invariant guards the oracle |
| CA patch-level miscompilation caught by conformance floor | **Proven** | G18 `ca_rule30_patched.ngb` one-byte rule flip; still runs; stdout diverges; rejected in `check-ca-conformance.sh` |
| CA conformance generalizes across rule bytes | **Proven** | G19 rules 50 (regular/nested) and 110; golden oracle + two-variant accept + wrong-rule reject; same `op=eca` machinery |
| Conformance holds on a richer observable at scale | **Proven** | G20 re-mints rule 110 at width 96 / gens 96 / `init=right` so the grid fills with glider structure (9.3 KB stdout, beyond eyeball check); `init=right` added to `conf-eval`, `ca_eca.c` parameterized; not an oracle-ceiling claim, the oracle stays cheap |
| Input-bound conformance (runtime argv operands) | **Proven** | G21 `op=gcd input=argv`: `conf-eval` takes runtime `(a,b)`; five-case oracle; two Route B variants accept on all vectors with distinct `graph_root_hash` |
| Multi-case sampling catches near-misses | **Proven** | G22 near-miss `gcd_nearmiss.ngb` (Euclid loop degraded to one `if`, right only when `b` divides `a`); gate asserts it accepts >=1 case and rejects >=1; a single sample would not separate it |
| Active search beats a fixed case list, refereed by an independent oracle | **Proven** | G23 competition: organizer owns `gcd.spec` + `conf-eval`; `gcd_evil` (equal operands return 1) passes the G21/G22 static suite but the searcher finds witness `(2,2)` and rejects; honest v1/v2 accept; witnesses confirmed by isolated re-run |
| A metamorphic relation verifies a binary with no external oracle, with an explicit ceiling | **Proven** | G24 involution: `bswap32.req` declares `relation=involution`; `metamorphic-verify` composes `f(f(x))` over a u32 sweep, no expected value computed; honest `bswap32` accepts, `rotl8` rejects with witness `x=1`, an involution-but-wrong outer-swap imposter accepts (the ceiling, asserted); complements the value-oracle floor |
| The relation floor and the value-oracle floor compose (cheap pre-filter, expensive backstop) | **Proven** | G25 handoff: `conf-eval op=bswap` gives the value oracle an expected byte swap; on the same `bswap32_imposter` the involution relation accepts and the value oracle rejects with witness `x=256` (`got=256 want=65536`); turns G24's asserted complementarity into a tested fact on one artifact |
| The floors verify real, vendored, third-party code we did not author | **Proven** | G26: `reverse32.c` ships the public-domain "Reverse bits in parallel" routine (Bit Twiddling Hacks) verbatim behind a trusted driver; `conf-eval op=bitrev` is an independent loop reference; relation accepts the real bit reversal and rejects an `EVIL_REVERSE` mask typo with witness `x=1`; value oracle accepts the real bytes and rejects `bswap32` (an involution that is not bit reversal) with witness `x=1` |
| A passing unit test hides a bug a metamorphic relation catches | **Proven** | G27 demo: `utf8.c` codec, honest decoder rejects overlong/surrogate/range, `OVERLONG_OK` accepts the classic overlong hole (`C0 80` decodes to U+0000); the fixed canonical unit test `decode(encode(cp))==cp` stays green on the buggy binary, the `round_trip` relation (`encode(decode(b))==b` over a byte domain incl. overlong) rejects it with witness `bytes=C0 80 decode=0 reencode=00` |
| Stacked gates reduce live-agent retries | **Not the claim** | G14 blind A/B was inconclusive (answer leaked across ~18 repo files, no tool-call trace); reframed to pre-execution rejection above |
| Live eval generalizes beyond print_42 | **Parked** | Single program only; no reason to expand until a workload needs it |
| Human-auditable verdict trail | **Parked** | `probe_bundle` is text concatenation; revisit if an external auditor needs it |

ADR-001 re-open trigger *"A live-agent eval shows NanoGraph's typed errors cut real retry counts"* was tested by G14 and **not met**. `composer-2.5` made no errors on the blind single-byte task, so there were no retries to cut. Retry-reduction positioning is dropped. The product claim rests on integrity (1000/1000 fuzz) and execution-grounded conformance (G9).

## Completed (M0–M7)

| ID | Goal | Milestone | Status |
| --- | --- | --- | --- |
| G1 | Hello pack/parse + run | M2 | Done (#3) |
| G2 | Hello audit-log | M3 | Done (#4) |
| G3 | add_two genesis | M4 | Done (#5) |
| G4 | probe disassemble | M6 | Done (#7) |
| G5 | Signed graph patch | M5 | Done (#6) |
| G6 | probe diff | M5 | Done (#6) |
| G7 | print_42 stdout | M7 | Done (#8) |

## Completed (post-P20 ladder)

| ID | Goal | Issue | Status |
| --- | --- | --- | --- |
| G8 | Deterministic two-agent author/auditor loop | #30 | Done |
| G9 | Ground-truth conformance floor (compute expected from spec) | #31 | Done |
| G10 | Micro-op static floor (`RODATA_BYTE_WRITE`) | #32 | Done |
| G11 | Computed oracle for the two-agent loop (`yield=stdout`) | #33 | Done |
| G12 | Value-bound micro-op (`--expect-new` derived digit) | #34 | Done |
| G13 | Live-agent harness + first run (Cursor CLI author) | #35 | Done |
| G14 | Blind live falsification of retry-reduction claim | #35 | Done (inconclusive; claim reframed) |
| G15 | Operational-error matrix (deterministic gate coverage) | #35 | Done (4/4 pre-exec) |
| G16 | Isolated author sandbox for live-agent eval | #36 | Done |
| G17 | Cellular-automata conformance (emergent stdout, behavioral-not-structural) | #37 | Done |
| G18 | CA hardening (patch negative, live harness, runner guard) | #38 | Done |
| G19 | CA rules 50 and 110 specimens | #39 | Done |
| G20 | Honest CA ledger + rule 110 at scale (`init=right`) | #40 | Done |
| G21 | Input-bound math conformance (`op=gcd input=argv`) | #41 | Done |
| G22 | Near-miss negative for input-bound conformance | #42 | Done |
| G23 | Adversarial verifier vs static sampling (competition oracle) | #43 | Done |
| G24 | Metamorphic involution verification (oracle-free relation, VerificationRequest seam) | #44 | Done |
| G25 | Close the involution ceiling (value oracle rejects the imposter the relation accepts) | #45 | Done |
| G26 | Verify real vendored upstream code (bit reversal) behind a trusted driver | #47 | Done |
| G27 | round_trip on a real UTF-8 codec (demo: unit test passes, relation rejects overlong) | #46 | Done |
| G28 | UTF-8 demo script + the emerging ICP | #48 | Done |
| G29 | Case-fit rubric as a runnable target score | #49 | Done |
| G30 | Backtest harness on controlled history (promote the spike) | #50 | Done |
| G31 | Second backtest case (LEB128 varint) + generalize backtest scripts | #51 | Done |
| G32 | Mine real-history backtest candidates (standalone permissive codecs) | #52 | Done |
| G33 | Synthetic Knuth-shaped portability backtest (models save_graph erratum, no SGB bytes) | #53 | Done |
| G34 | wabt ReadU64Leb128 real-history backtest (ICP follow-through) | #54 | Done |
| G35 | Real Knuth canon backtest: rand_len off-by-one (range-coverage relation) | #55 | Parked |
| G36 | Fix CI red: align ca_eca.c _start so O2 SSE stores don't fault on native | #56 | Done |

G8 spec: [`TWO-AGENT-PROBE-PROTOCOL.md`](TWO-AGENT-PROBE-PROTOCOL.md). Harness `scripts/agent-eval/run-two-agent-loop.sh`, gated by `scripts/check-two-agent-loop.sh`.

G9 spec: [`CONFORMANCE-FLOOR.md`](CONFORMANCE-FLOOR.md), decision [`../adr/ADR-002-ground-truth-conformance.md`](../adr/ADR-002-ground-truth-conformance.md). Harness `scripts/agent-eval/conformance-check.sh`, gated by `scripts/check-conformance-floor.sh`.

G10 spec: [`MICROOP-FLOOR.md`](MICROOP-FLOOR.md). Harness `tools/bin/ngb-microop`, gated by `scripts/check-microop-floor.sh`.

G13/G14 spec: [`LIVE-AGENT-EVAL.md`](LIVE-AGENT-EVAL.md). Harness `scripts/agent-eval/run-live-agent-loop.sh`, opt-in. Skill `.cursor/skills/live-ngb-author/SKILL.md`. G13 leaked the answer in the skill; G14 removed the leak and ran blind A/B. Both arms 1 round / 1 exec, retry-reduction trigger not met. Logs: `.harness-data/agent-eval/live-agent/run-g14-{stacked,auditor-only}.jsonl`.

G16 spec: [`AUTHOR-SANDBOX.md`](AUTHOR-SANDBOX.md), decision [`../adr/ADR-003-author-sandbox.md`](../adr/ADR-003-author-sandbox.md). Harness `prepare-author-sandbox.sh`, `audit-author-isolation.sh`, gated by `scripts/check-author-sandbox.sh`. Live loop uses `--workspace $SANDBOX` only; streams persisted under `.harness-data/agent-eval/live-agent/`.

G17 spec: [`CA-CONFORMANCE.md`](CA-CONFORMANCE.md), decision [`../adr/ADR-004-ca-conformance.md`](../adr/ADR-004-ca-conformance.md). `conf-eval op=eca` renders an elementary cellular automaton to stdout. Phase 1 `scripts/check-ca-oracle.sh` (Rule 90 popcount invariant + Rule 30 golden, no toolchain). Phase 2 `scripts/check-ca-conformance.sh` (two Route B variants accept on the same spec with distinct `graph_root_hash`, wrong-rule specimen rejects). Specimens minted by `scripts/mint-ca-fixtures.sh` (pinned `gcc:13`, committed `.ngb`, no recompile in CI). Both gated in `check-all-proofs.sh`.

G18 spec: extends G17. `ca-rule30-patch-fixture` mints `ca_rule30_patched.ngb` (one-byte rule flip, `add_two_patched` shape). `check-linux-runner.sh` guards phase-2 conformance. CA live harness: `prepare-author-sandbox-ca.sh`, `run-live-ca-agent-loop.sh` (opt-in), deterministic `check-ca-author-sandbox.sh` + `check-ca-live-scripted-loop.sh` in `check-all-proofs.sh`.

G19 spec: extends G17/G18. Shared `fixtures/ca/ca_eca.c` compiled with `-DRULE=n`. Rules 50 and 110 added to `mint-ca-fixtures.sh`, `check-ca-oracle.sh` (golden diff), `check-ca-conformance.sh` (two-variant accept + wrong-rule reject). No new floor machinery.

G20 spec: extends G19. `conf-eval op=eca` gains `init=right` (seed at `width-1`); `ca_eca.c` parameterized with `-DWIDTH`/`-DGENS`/`-DINIT_RIGHT`. `rule110.spec` re-minted at width 96 / gens 96 / `init=right` so the left-propagating pattern fills the grid (9.3 KB golden, no eyeball check). Rule 50's "periodic" and rule 110's "universal-class oracle-stress" labels were dropped as overclaims; the gates and ledger now state only what specimens show. No new floor machinery.

G21 spec: [`INPUT-MATH-CONFORMANCE.md`](INPUT-MATH-CONFORMANCE.md), decision [`../adr/ADR-005-input-math-conformance.md`](../adr/ADR-005-input-math-conformance.md). `conf-eval op=gcd input=argv` takes runtime operands via CLI args; freestanding `fixtures/input-math/gcd.c` reads argv at `_start`. Phase 1 `scripts/check-input-math-oracle.sh` (cases file vs conf-eval). Phase 2 `scripts/check-input-math-conformance.sh` (v1/v2 accept all cases, distinct hash). Specimens minted by `scripts/mint-input-math-fixtures.sh` (pinned `gcc:13`, committed `.ngb`). `run-linux-elf-capture.sh` forwards extra args to the ELF. Both gated in `check-all-proofs.sh`.

G22 spec: extends G21. The `a+b` far-miss is replaced by `gcd_nearmiss.ngb`, Euclid's loop degraded to a single `if` (right only when `b` divides `a`). `check-input-math-conformance.sh` asserts the near-miss accepts >=1 case and rejects >=1, so the suite proves multi-case sampling separates a near-miss a single sample would pass. With committed cases it accepts `(100,25)` and `(30,5)`, rejects the rest. No new floor machinery.

G23 spec: [`ADVERSARIAL-VERIFIER.md`](ADVERSARIAL-VERIFIER.md), decision [`../adr/ADR-006-adversarial-verifier.md`](../adr/ADR-006-adversarial-verifier.md). Competition with an independent oracle: organizer owns `gcd.spec` + `conf-eval`, authors submit `.ngb`, a deterministic searcher (`scripts/agent-eval/adversarial-verify.sh`) enumerates inputs by increasing sum, runs the submission via `scripts/run-linux-elf-batch.sh` (extract once, one backend session, crash-safe per probe), referees per probe, and confirms any witness with an isolated re-run. `gcd_evil` (`-DEVIL_GCD`, equal operands return 1) passes the G21/G22 static suite but the searcher rejects it with witness `(2,2)`; v1/v2 accept. Gated by `scripts/check-adversarial-verifier.sh` in `check-all-proofs.sh`. No new floor machinery.

G24 spec: [`METAMORPHIC-RELATIONS.md`](METAMORPHIC-RELATIONS.md), decision [`../adr/ADR-007-metamorphic-relations.md`](../adr/ADR-007-metamorphic-relations.md). Oracle-free verification: a metamorphic relation is the oracle, no expected value is computed. A language-neutral `VerificationRequest` (`fixtures/metamorphic/bswap32.req`: `relation entry domain eq`) is the seam; NanoGraph stays language-blind. `scripts/agent-eval/metamorphic-verify.sh` parses the request, sweeps the `u32` domain, composes `f(f(x))` in two batched passes (reusing G23's batch + capture runners), and rejects with a readable witness. Specimen `fixtures/metamorphic/bswap32.c` minted by `scripts/mint-metamorphic-fixtures.sh` (pinned `gcc:13`) into honest / `EVIL_BSWAP` (rotl8) / `IMPOSTER_BSWAP` (outer-swap). Gate `scripts/check-metamorphic-involution.sh`: honest accepts, rotl8 rejects with witness `x=1`, the involution-but-wrong imposter accepts. That third arm is the asserted ceiling: involution is necessary, not sufficient, and complements the G9-G23 value-oracle floor. No `.ngb` format change.

G25 spec: extends G24 in [`METAMORPHIC-RELATIONS.md`](METAMORPHIC-RELATIONS.md), decision [`../adr/ADR-008-floor-handoff.md`](../adr/ADR-008-floor-handoff.md). Closes the involution ceiling by demonstration. `conf-eval` gains `op=bswap` (single argv operand, u32 decimal); `fixtures/metamorphic/bswap32.spec` + `bswap32.cases` hand table feed the value oracle. `scripts/check-bswap-value-oracle.sh` runs both floors on the same `bswap32_imposter`: the involution relation accepts (the G24 ceiling), the value oracle rejects with witness `x=256` (`got=256 want=65536`). Cheap-then-expensive handoff: the relation needs no spec and rejects non-involutions for free, the value oracle costs a computed expected value and separates the imposter. Gated in `check-all-proofs.sh`. No new floor machinery, no `.ngb` format change.

G26 spec: extends G24/G25 in [`METAMORPHIC-RELATIONS.md`](METAMORPHIC-RELATIONS.md), decision [`../adr/ADR-009-real-vendored-code.md`](../adr/ADR-009-real-vendored-code.md). De-toys the line: both floors run on real, vendored, attributed upstream code. `fixtures/metamorphic/reverse32.c` ships the public-domain "Reverse bits in parallel" routine (Bit Twiddling Hacks) verbatim behind a trusted `_start`/parse/print driver. `conf-eval` gains `op=bitrev` (independent loop reference). `scripts/check-reverse32-real.sh` asserts the attribution, the involution relation accepts the real bit reversal and rejects an `EVIL_REVERSE` mask typo (non-involution) with witness `x=1`, the value oracle accepts the real bytes, and the handoff shows `bswap32` is an involution the relation accepts but the value oracle rejects as bit reversal with witness `x=1`. The driver calls the function via the C ABI; instruction-level isolation stays parked. Gated in `check-all-proofs.sh`. No `.ngb` format change.

G32: executes stages 1-3 of the formal-mining plan for the standalone-codec lead source. A research pass produced a cited, anti-fabrication shortlist of five verified candidates with real fix-commit and buggy-parent SHAs, top three scored as `fixtures/fit-cases/*.fit` (`wabt-leb128-u64` 8/8, `capnproto-base64` 8/8, `openssl-punycode` 6/8 priority 12). The wabt target is deferred to G34. Shortlist-only, no floor or format change.

G33: a synthetic, Knuth-shaped portability backtest. **It does not run Knuth's bytes.** It models the `save_graph` erratum (Stanford GraphBase page 414, December 2025), where `fopen(f,"w")` let Windows text mode expand internal `\n` to `\r\n` so a graph saved on Windows could not `restore_graph` on Linux; Knuth changed it to `fopen(f,"wb")`. The trusted driver `fixtures/metamorphic/knuth_sgb.c` is code we wrote that reconstructs the erratum with a `BUGGY_TEXTMODE` macro, because the bug is Windows-only and the Linux runner cannot observe the real defect. The SGB SHAs `c0943fd` (buggy) and `88fac2f` (fix) are provenance for the story, not inputs to the proof. What G33 actually proves is that the G30/G31 backtest pipeline generalizes to a third `round_trip` domain (`knuth_sgb`) with one driver and one `gen_` line. **Catch** on probe `266` (`0x01 0x0A`), witness hex `0A`; timeline accept, reject, accept; fix hash matches rev1. `fixtures/backtest/knuth-sgb/CASE.md`, root `THIRD-PARTY.md`, gated in `check-all-proofs.sh`. No floor or format change. The credibility claim that G33 verified canon was withdrawn; the real-Knuth proof is G35.

G34: the first true real-history backtest, follow-through from G32. wabt `ReadU64Leb128` (parent `89582f5` to fix `f1f3d6d` / PR #2256). The 10th byte of a u64 LEB128 may set only bit 0; the overflow check used `p[9] & 0xf0` (copied from the u32 path), which misses bits 1..3, so a 10-byte LEB128 above u64 max was silently accepted and truncated. Fix changes the mask to `0xfe`. `fixtures/metamorphic/wabt_leb128.c` transcribes wabt's decode arithmetic and the real mask faithfully into freestanding C behind a trusted driver (the G26 standard); it is not a verbatim build of wabt's C++, which is not freestanding. The fix is a strippable block (base `0xf0`, honest adds `0x0e`), so `mint-backtest.sh` derives the buggy revision. A new `wire=hex` carries the 10-byte input as a hex argv token. **Catch** on witness `ffffffffffffffffff02`; the buggy revision decodes it to the truncated `9223372036854775807`, the honest revision rejects it, both accept u64 max `ffffffffffffffffff01`. Timeline accept, reject, accept; fix hash matches rev1; gated `WABT-LEB128` in `check-all-proofs`. `fixtures/backtest/wabt-leb128/CASE.md`, root `THIRD-PARTY.md`.

G36: fixed `hello-proof` CI, red since G30 on `CA-CONFORMANCE FAIL: rule 110 v2`. `fixtures/ca/ca_eca.c` used a bare `_start`; at O2 gcc vectorized the WIDTH=96 buffer loops with `movaps` stores requiring 16-byte stack alignment. The kernel leaves rsp 16-aligned at entry, but the C-ABI prologue assumes the 8-byte skew a `call` leaves, so the stores faulted on native x86_64 (rule110 v2 only, big enough to vectorize), died with empty output, and read as reject; qemu does not enforce the alignment, which hid it off-CI. Proven by disassembly (`movaps %xmm5,-0x78(%rsp,%rax)`). Fix is the naked `_start` trampoline `leb128.c` and `wabt_leb128.c` already use; its `call real_start` restores the ABI alignment. Re-minted all CA fixtures, updated the stale rule30 v1 hash in the sandbox leak guard. CI green on native; `BACKTEST-WABT-LEB128` and `ALL-PROOFS OK` now run upstream.

G35: the real Knuth-canon backtest, parked. Target is the documented "embarrassing off-by-one" in `gb_rand.w` (`rand_len`, errata page 388, fixed 1999). Buggy `min_len+gb_unif_rand(max_len-min_len)` yields a length in `[min,max-1]` and never reaches `max`; the fix adds `+1`. Mirror `ascherer/sgb` `fd99287` (1992 initial, buggy) to `65433e2` (2002-01-30, fixed), both verified to differ only by the `+1`. Unlike G33 this runs Knuth's actual integer arithmetic with no simulation: `gb_flip` plus `rand_len` is pure computation, no libc, no platform dependency, vendorable freestanding. The bug is silent (graphs still look valid, the max length is just never drawn) and deterministic under a fixed `gb_flip` seed. The cost is a new relation: it is not `round_trip` or `involution` but a range-coverage property (the empirical maximum over a seed sweep must equal `max`). That new relation in `metamorphic-verify`, plus vendoring `gb_flip`, is why G35 is its own goal, not a relabel.

G31: a second worked backtest case proves the G30 driver generalizes. `fixtures/metamorphic/leb128.c` is an unsigned LEB128 varint codec whose non-minimal-acceptance bug (`NONMINIMAL_OK`) is caught by the unchanged `round_trip` relation (`80 00` decodes to 0, re-encodes to `00`, witness hex `8000`); the only new verifier code is `gen_leb128`. With two cases, the G30 mint and gate were generalized to `scripts/mint-backtest.sh` and `scripts/check-backtest.sh` (parameterized by source, guard macro, manifest, reject hex), the utf8-specific scripts deleted, and `check-all-proofs.sh` calls the one gate twice (utf8 C080, leb128 8000). `docs/BACKTEST.md` adds the second case and a formal-mining plan for real upstream histories. No floor or format change.

G30: promotes the throwaway backtest spike into a committed harness. [`../BACKTEST.md`](../BACKTEST.md) explains replaying a function's revisions and flagging the buggy window. `scripts/mint-backtest-utf8.sh` derives three revisions of the UTF-8 codec (honest, overlong bug, fix) from `fixtures/metamorphic/utf8.c` and mints committed `.ngb` via the factored `scripts/mint-one-elf.sh`. `scripts/backtest-relation.sh` is a relation-agnostic driver that replays a `timeline.manifest` (ordered committed `.ngb` plus expected verdict) and asserts the sequence. `scripts/check-backtest-utf8.sh` asserts the timeline reads accept, reject with witness C0 80, accept, and that the fix returns to revision one's hash; runner-guarded, gated in `check-all-proofs.sh`. The driver is reused by the future real-git-history backtest. No floor or format change.

G29: makes "a case is a fit when four things are true at once" runnable. [`../CASE-FIT-RUBRIC.md`](../CASE-FIT-RUBRIC.md) scores a candidate on four fit factors (oracle hardness, property checkability, observability, silent-bug survival), each 0-2; `scripts/score-case-fit.sh` reads a `fixtures/fit-cases/*.fit` scorecard, gates on all four nonzero at once, sums `fit_score`, and reports `priority = fit_score * criticality` (criticality a separate axis, price not fit). `scripts/check-case-fit-rubric.sh` asserts the worked examples (payment conservation FIT priority 16, the robotics control loop NOT-A-FIT because observability is 0, proving criticality alone does not qualify) and the malformed-input poka-yoke; gated in `check-all-proofs.sh`. Positioning and selection tooling, no floor or format change.

G28: packages G27 for an audience and records positioning. `scripts/demo-utf8.sh` narrates the contrast end to end (the overlong slip in source, the canonical unit test green on the buggy binary, the `round_trip` relation rejecting it with witness `C0 80`, the honest binary accepting), reusing committed fixtures with no recompile. [`../ICP.md`](../ICP.md) names the one ideal customer (codec, serializer, and parser maintainers), the reasoning chain, the non-customers, the evidence (G24-G27), and the signal that would confirm or kill the bet. Positioning only, no floor or format change.

G27 spec: the demo case in [`METAMORPHIC-RELATIONS.md`](METAMORPHIC-RELATIONS.md), decision [`../adr/ADR-010-utf8-roundtrip-demo.md`](../adr/ADR-010-utf8-roundtrip-demo.md). Adds the `round_trip` relation and proves it on a UTF-8 codec. `fixtures/metamorphic/utf8.c` has `enc`/`dec` modes over a single integer (`0x01 ++ utf8 bytes`); the honest decoder rejects overlong, surrogate, and out-of-range forms; `OVERLONG_OK` drops only the overlong lower-bound checks, the classic security hole where `C0 80` decodes to U+0000. `metamorphic-verify` gains a `round_trip` branch: for each byte sequence `b` in the domain, `decode` then `encode`, skip what the decoder rejects, require `encode(decode(b))==b`. `utf8.req` declares `relation=round_trip` with `encode`/`decode` mode tokens and a `reject` sentinel. `scripts/check-utf8-roundtrip.sh` shows the contrast: the fixed canonical unit test `decode(encode(cp))==cp` stays green on the buggy binary, while the relation sweep (domain includes overlong `C0 80`) rejects it with witness `bytes=114816 hex=C080 decode=0 reencode=256`. Gated in `check-all-proofs.sh`. Scope note in ADR-010: the floor is execution-grounded plus byte-integrity, not C-specific; any artifact with a runnable observable fits. No `.ngb` format change.

## Ruliad rule exploration

| Rule | Character | What it tests | Status |
| --- | --- | --- | --- |
| 90 | Sierpinski / fractal | Closed-form oracle witness (`2^popcount(k)` per row) | **Done** (G17 phase 1 invariant) |
| 30 | Chaotic | Rich stdout; golden + patch negative | **Done** (G17/G18 primary specimen) |
| 50 | Regular / nested | Second rule byte; golden-only oracle; behavioral-not-structural | **Done** (G19) |
| 110 | Left-propagating; glider structure at scale | Richer observable (9.3 KB, `init=right` fills grid); golden-only, no closed-form witness; not an oracle-ceiling claim | **Done** (G19 toy, G20 scaled) |
| 184 | Particle-like | Longer runs; byte-for-byte diff scale | Parked |
| 73 | Replicator | Miscompilation locality in grid output | Parked |
| 126 | Complex transient | `gens` parameter stress | Parked |

Shared machinery (`op=eca`, `conf-eval`, `ca_eca.c`, `mint-ca-fixtures.sh`, conformance gates). A new rule is a `.spec` + golden + mint, not a new floor.

## Next goals

**G35 (parked).** Real Knuth-canon backtest on the `rand_len` off-by-one. Runs Knuth's actual arithmetic, needs a new range-coverage relation.

The retry-reduction line is closed (G14). G16 closes the repo-leakage gap for live eval. The proven claim is integrity plus execution-grounded conformance, and it stands on the deterministic suite without a live-agent number.

Parked ideas, each needing a concrete reason before it earns a slot. Do not build speculatively.

| Parked | Trigger to revive |
| --- | --- |
| G35 rand_len off-by-one (real Knuth canon) | A range-coverage relation earns its place; pick up next |
| Second program live eval (`add_two` exit-code) | A real task needs a non-print_42 patch verified live |
| Multi-op micro-op set | A real edit shape beyond single-byte rodata appears |
| Differential conformance (one binary, two specs) | A spec-collision risk shows up in practice |
| Portable verdict bundle (JSON) | An external auditor needs to verify without re-running probes |
| Zerolang MIR seam (spike) | An external intent source wants to feed the conformance floor |

## Completed product proof

**Product proof P01–P20** decided Continue scoped to verifiable editing (ADR-001).

Spec: [`PRODUCT-PROOF.md`](PRODUCT-PROOF.md)

## Explicitly not in scope

- NanoLang syntax or compiler
- Cycle-accurate `probe verify` / gem5
- Multi-arch
- v2 JSON audit manifest inside `.ngb`
- Live eval in CI (requires `CURSOR_API_KEY`, nondeterministic)

## Issue mapping

| Range | Binds |
| --- | --- |
| #3–#8 | G1–G7 technical milestones |
| #9–#28 | P01–P20 product proof |
| #30 | G8 two-agent loop |
| #31 | G9 conformance floor |
| #32 | G10 micro-op floor |
| #33 | G11 computed oracle |
| #34 | G12 value-bound micro-op |
| #35 | G13 live harness, G14 blind falsification, G15 operational-error matrix |
| #36 | G16 isolated author sandbox |
| #37 | G17 cellular-automata conformance |
| #38 | G18 CA hardening |
| #39 | G19 CA rules 50 and 110 |
| #40 | G20 honest CA ledger + rule 110 at scale |
| #41 | G21 input-bound math conformance |
| #42 | G22 near-miss negative for input-bound conformance |
| #43 | G23 adversarial verifier vs static sampling |
| #44 | G24 metamorphic involution verification |
| #45 | G25 close the involution ceiling (floor handoff) |
| #46 | G27 round_trip on a real UTF-8 codec (demo) |
| #47 | G26 verify real vendored upstream code (bit reversal) |
| #48 | G28 UTF-8 demo script + ICP |
| #49 | G29 case-fit rubric (target score) |
| #50 | G30 backtest harness (controlled history) |
| #51 | G31 second backtest case (LEB128) + generic scripts |
| #52 | G32 mine real-history backtest candidates (shortlist) |
| #53 | G33 synthetic Knuth-shaped portability backtest (models save_graph erratum) |
| #54 | G34 wabt ReadU64Leb128 real-history backtest (parked) |
| #55 | G35 real Knuth-canon backtest, rand_len off-by-one (parked) |
| #56 | G36 fix CI red, ca_eca.c _start stack alignment |
