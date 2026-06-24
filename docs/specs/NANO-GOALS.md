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
| `size_monotone` catches a real allocator sizing bug | **Proven** | G49 jemalloc backtest gated `JEMALLOC-S2U` (#68) |
| `conserve_popcount` names scalar conservation for permutations | **Proven** | G50 reverse32 backtest gated `CONSERVE-POPCOUNT` (#69); G68 rule 184 bridge |
| Language-diversity mining yields FIT candidates (Rust, Zig, Go) | **Proven** | G51–G53 (#70); scorecards + [`MINING-G51-G53.md`](MINING-G51-G53.md) |
| Verification floor is language-blind in practice (not only in docs) | **Proven (Zig+Rust+Go)** | G77 `check-lang-packs.sh` on mined native backtests (`zig-wyhash-native`, `rust-base64-native`, `go-base64-streaming-native`); G75/G76 first proved minter+verifier via bswap32 smoke, then G77b moved CI gate to mined cases; blind search re-detects native Zig (true_found, #96); n=3 native non-C |
| Rust real-history backtests execute on language-diversity lane | **Proven** | G56 `RUST-BASE64-INVALID-LAST` + G71 `RUST-CRC32FAST-COMBINE-LEN0` |
| `flow_composition` catches real-history incremental bugs | **Proven (Rust+Zig+Go)** | G57/G59 Wyhash + G58 Go streaming + G71 crc32fast; witness `hex=5` all three; [`FLOW-COMPOSITION-TRI-LANGUAGE.md`](FLOW-COMPOSITION-TRI-LANGUAGE.md) |
| `linear_xor` catches real-history bugs on current x86 floor | **Parked** | Zero FIT across Rust/Zig/Go mining (#70); BE-only and -race cases |
| Cross-loader / APE target extension adds product value | **Refuted (G54)** | ADR-014 **reject**; H4 kill, H1/H2 blocked on cosmocc; [`APE-TARGET-SPIKE.md`](APE-TARGET-SPIKE.md) |
| Candidate-ID sidecar at `.req` seam helps agent build-verify loops | **Partial (G55)** | ADR-015 **skill-only**; H1 4/5 + H2 proven; H3 **PROVEN** under frozen sidecar on novel + 5/5 mined house-style specimens (#85–#87); recall is convention-lint (prose dependency); G63–G64 parked; [`CANDIDATE-ID-SPIKE-FOLLOWON.md`](CANDIDATE-ID-SPIKE-FOLLOWON.md) |
| Verification floor discovers defects without curated probes | **Proven (bounded, G73)** | Frozen default tier **8/13 true_found (61%)** (#96); format-aware hint tier **12/13 true_found (92%)** (#102–#105, separate row); one documented relation gap (capnproto); [`PROBE-GENERATOR-SPIKE.md`](PROBE-GENERATOR-SPIKE.md) |
| Blind generator reaches a wire format it was never tuned on | **Proven (planted, G73 fresh-wire)** | base32 (RFC 4648) honest accepts, buggy reject witness `AAAAAAB=` on first blind pass; only alphabet/block mirror added; planted-bug caveat stands (not real-upstream discovery, that is G84); [`PROBE-GENERATOR-SPIKE.md`](PROBE-GENERATOR-SPIKE.md) |
| Relation runs against live upstream code, not a transcription | **Proven (G85, vehicle)** | `native-hunt.sh` reuses the blind generator and `canonical` classification, runs `round_trip` on real executables; live CPython base64 reproduces the tranche-1 `relation_gap` (witness `AAB=`) with no transcription; honest null for defects, vehicle proven; [`PROBE-GENERATOR-SPIKE.md`](PROBE-GENERATOR-SPIKE.md) |
| Vehicle runs `round_trip` on real Bitcoin consensus code, canonical-enforcing | **Proven (G85, bitcoin prep)** | real `rust-bitcoin` `VarInt` (CompactSize) wired through the native CLI; `verdict=accept` 43/64 (non-minimal rejected, none accepted); negative control `check-compactsize-hunt.sh` flags a lenient codec with witness `fd0000`; new `probes_cmd` seam + `gen-compactsize.sh` leave the frozen blind generator untouched (holdout prereg green); honest null for a Bitcoin defect at HEAD; [`PROBE-GENERATOR-SPIKE.md`](PROBE-GENERATOR-SPIKE.md) |
| Differential relation makes acceptance-class codec bugs huntable | **Proven (G87, vehicle)** | `native-hunt.sh` gains `relation=differential` (target vs trusted reference, divergence is the witness); BIP-canonical `sipa/bech32` reference vendored; `gen-bech32m.sh` mints valid-checksum witness-version 0..31 probes; `check-bech32m-differential.sh` catches the witver>16 acceptance class (rust-bech32 #274 shape), `check-base58check-hunt.sh` catches Base58 leading-zero loss via seed-corpus `round_trip`; both hermetic honest-vs-buggy; real third-party target is follow-on; ADR-023; [`PROBE-GENERATOR-SPIKE.md`](PROBE-GENERATOR-SPIKE.md) |
| Native hunt finds real upstream defect without transcription | **Proven (G86, bitcoinlib, #127)** | `1200wd/bitcoinlib` CompactSize at `bec99a2` via `native-hunt.sh`; `verdict=reject` witness `fdffff` (decode `65535`, reencode `feffff0000`, canonical wire input); encoder uses `< 0xffff` not `<=`; decoder lacks minimality check; severity low (triggers only 65535/4294967295); gated `check-bitcoinlib-compactsize-hunt.sh`; ADR-023; [`fixtures/backtest/bitcoinlib-compactsize/CASE.md`](../fixtures/backtest/bitcoinlib-compactsize/CASE.md) |
| Relation taxonomy guides mining before new MR branches | **Proven** | G66 RELATION-TAXONOMY + BACKTEST checklist; gated `check-relation-taxonomy.sh` |
| Homomorphism family (`linear_xor`) catches non-linear CA rule | **Proven** | G67 rule 90 vs rule 30 imposter; gated `check-linear-xor.sh` |
| Scalar conservation applies to Wolfram particle rule 184 | **Proven** | G68 `conserve_popcount` on rule 184 step; gated `check-rule184-conserve.sh` |
| Flow composition catches skipped-generation drift | **Proven** | G69 `flow_composition` + EVIL_SKIP; gated `check-flow-composition.sh`; matrix `measure-relation-impact.sh` |
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
| G35 | Real Knuth canon backtest: rand_len off-by-one (range-coverage relation) | #55 | Done |
| G36 | Fix CI red: align ca_eca.c _start so O2 SSE stores don't fault on native | #56 | Done |
| G37 | Strengthen range_coverage with endpoint witnesses (re-mint G35 proof) | #57 | Done |
| G38 | Split range_coverage into reachability and containment phases | #59 | Done |
| G39 | capnproto decodeBase64 real-history backtest (ICP follow-through) | #60 | Done |
| G40 | Mine llamafile-stack subcases + scorecards (Justine/Cosmopolitan) | — | Done (shortlist) |
| G41 | cosmo ParseIp real-history backtest (Justine ICP follow-through) | #61 | Done |
| G44 | Strengthen cosmo ParseIp value_oracle witness set (u32 wrap probe) | #62 | Done |
| G42 | cosmo ljson overlong UTF-8 real-history backtest (reselected, value_oracle) | #66 | Done |
| G48 | LLVM BOLT cmp_order real-history backtest (comparator contract) | #67 | Done |
| G49 | jemalloc size_monotone real-history backtest | #68 | Done |
| G50 | conserve_popcount modeled backtest (reverse32) | #69 | Done |
| G51 | Mine Rust backtest candidates (language diversity) | #70 | Done |
| G52 | Mine Zig backtest candidates (language diversity) | #70 | Done |
| G53 | Mine Go backtest candidates (language diversity) | #70 | Done |
| G66 | Relation taxonomy for mining + catalog | #73 | Done |
| G67 | linear_xor homomorphism (rule 90 step) | #74 | Done |
| G68 | Rule 184 conserve_popcount bridge | #75 | Done |
| G69 | flow_composition on iterated CA | #76 | Done |
| G57 | Zig Wyhash flow_composition real-history backtest | #80 | Done |
| G58 | Go base64 streaming flow_composition backtest | #81 | Done |
| G59 | Native Zig specimen through existing gate | G57 | Done |
| G56 | Rust base64 round_trip real-history backtest | #79 | Done |
| G71 | Rust crc32fast flow_composition real-history backtest | #82 | Done |
| G72 | Tri-language flow_composition witness equivalence doc | G57+G58+G71 | Done |

G49 spec: [`METAMORPHIC-RELATIONS.md`](METAMORPHIC-RELATIONS.md), decision [`../adr/ADR-012-size-monotone-relation.md`](../adr/ADR-012-size-monotone-relation.md). **Done** (#68); see Next goals.

G50 spec: [`METAMORPHIC-RELATIONS.md`](METAMORPHIC-RELATIONS.md), decision [`../adr/ADR-013-conserve-popcount-relation.md`](../adr/ADR-013-conserve-popcount-relation.md). **Done** (#69); see Next goals.

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

G35: the first real-Knuth-canon backtest. It runs Knuth's actual GB_FLIP generator and `rand_len` draw, native, no simulation, unlike G33 (modeled) and G34 (third-party wabt). The documented "embarrassing off-by-one" in `gb_rand.w`: buggy `min_len+gb_unif_rand(max_len-min_len)` yields `[min,max-1]` and never reaches `max`; the fix adds `+1`. Mirror `ascherer/sgb` `fd99287` (buggy) to `65433e2` (fixed). `fixtures/metamorphic/knuth_rand_len.c` vendors `gb_flip` and the `rand_len` draw, validated against Knuth's `test_flip` constants. The new relation `range_coverage`; strengthened in G37. Timeline accept/reject/accept; gated `KNUTH-RAND-LEN`. `fixtures/backtest/knuth-rand-len/CASE.md`, root `THIRD-PARTY.md`.

G37: strengthens `range_coverage` so the proof is deterministic, not sweep-shaped. Optional `lo_seed` and `hi_seed` in `.req`; when both are set, `metamorphic-verify.sh` checks isolated `draw(lo_seed)==lo` and `draw(hi_seed)==hi` before the 256-seed sweep. The sweep remains a robustness bound check. G35 `knuth_rand_len.req` sets `lo_seed=22`, `hi_seed=2` (honest `22→1`, `2→10`). **Catch** on buggy rev: `draw(22)` yields 2 not 1, witness `hex=02`, `endpoint=lo`; `rev2_offbyone` is the structural span-minus-one mutant. Timeline accept/reject/accept unchanged; gate witness updated from sweep-only `09` to endpoint `02`. Documented in `docs/specs/METAMORPHIC-RELATIONS.md`, `fixtures/backtest/knuth-rand-len/CASE.md`, `docs/BACKTEST.md`. No `.ngb` remint (relation change is verifier-only).

G38: splits `range_coverage` into named phases. `.req` keys `reachability=on|off` and `containment=sweep|off` (defaults: reachability on when both seeds set, containment sweep). Rejects name `phase=reachability` or `phase=containment`; accept reports `reachability=pass|skip containment=pass|skip`. G35 `knuth_rand_len.req` sets `reachability=on containment=sweep`. Under-reach bugs fail reachability first; over-reach would fail containment. Verifier-only; no `.ngb` remint. Gated `KNUTH-RAND-LEN` unchanged.

G39: second ICP follow-through from G32 (`capnproto-base64.fit` 8/8). capnproto/kj libb64-derived `decodeBase64` (parent `9306bc0` to fix `f3e0ed2` / PR #595). Pre-fix decode skipped invalid and padding bytes and never failed; fix adds `hadErrors` per WHATWG atob rules. `fixtures/metamorphic/capnproto_base64.c` transcribes encode/decode into freestanding C; strict checks strippable via `INVALID_OK`, rev2 compiled with `-DINVALID_OK`. New `wire=ascii` for base64 string probes; witness hex is the ASCII byte encoding. **Catch** on `Zm9v@` (`hex=5a6d397640`): buggy skips `@`, decodes to `foo`, re-encodes `Zm9v`; honest rejects. Timeline accept/reject/accept; gated `CAPNPROTO-BASE64`. `fixtures/backtest/capnproto-base64/CASE.md`, root `THIRD-PARTY.md`.

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
| 184 | Particle-like | `conserve_popcount` on one-step rule 184 (G68); bridges scalar MR to ruliad | **Done** (G68) |
| 73 | Replicator | Miscompilation locality in grid output | Parked |
| 126 | Complex transient | `gens` parameter stress | Parked |

Shared machinery (`op=eca`, `conf-eval`, `ca_eca.c`, `mint-ca-fixtures.sh`, conformance gates). A new rule is a `.spec` + golden + mint, not a new floor.

## Next goals

Status buckets: **Done** (gated or shortlist complete), **In progress** (issue open, implementation started), **Open** (exploration spike, no product commit yet), **Conditional** (pre-registered follow-on; opens only when a parent spike or mining track passes its verdict).

G40 scores the llamafile-stack subcases mined from [Justine Tunney](https://github.com/jart) code (Cosmopolitan libc inside [llamafile](https://builders.mozilla.org/project/llamafile/), not the inference runtime). The whole product is NOT-A-FIT (`llamafile-inference.fit`, `observable=0`). FIT survivors are ranked by `priority = fit_score * criticality` from committed scorecards in `fixtures/fit-cases/`.

| ID | Goal | Scorecard / issue | Priority | Status |
| --- | --- | --- | --- | --- |
| G40 | Mine llamafile-stack subcases + scorecards | six `.fit` files | n/a | **Done** (shortlist) |
| G41 | cosmo `ParseIp` real-history backtest | `cosmo-parseip.fit` 8/8 | **16** | **Done** |
| G42 | cosmo `ljson` overlong UTF-8 real-history backtest | `cosmo-ljson-overlong.fit` 7/8 | **7** | **Done** |
| G43 | cosmo `uleb64`/`unuleb64` synthetic `round_trip` backtest | `cosmo-uleb64.fit` 7/8 | **7** | Cancelled |
| G44 | Strengthen G41 ParseIp `value_oracle` witness set | `cosmo-parseip.fit` (same) | n/a | **Done** |
| G48 | LLVM BOLT `cmp_order` real-history backtest | `llvm-bolt-cmp-order.fit` 8/8 | **8** | **Done** |
| G49 | jemalloc `size_monotone` real-history backtest | `jemalloc-s2u-monotone.fit` | TBD | **Done** (#68) |
| G50 | `conserve_popcount` modeled backtest (reverse32) | TBD | n/a | **Done** (#69) |
| G51 | Mine Rust backtest candidates (language diversity) | `rust-base64-invalid-last.fit` 8/8 | **8** | **Done** (#70) |
| G52 | Mine Zig backtest candidates (language diversity) | `zig-std-wyhash-iterative.fit` 8/8 | **8** | **Done** (#70) |
| G53 | Mine Go backtest candidates (language diversity) | `go-base64-streaming.fit` 7/8 | **7** | **Done** (#70) |
| G54 | Falsify Cosmopolitan APE as target extension | `ape-target-extension.fit` parked | n/a | **Done** (#71, reject) |
| G55 | Falsify candidate-ID sidecar at `.req` seam | H1 4/5 + H2 | n/a | **Done** (#72, skill-only) |
| G66 | Relation taxonomy for mining + catalog | n/a | n/a | **Done** |
| G67 | `linear_xor` homomorphism (rule 90 step) | n/a | n/a | **Done** |
| G68 | Rule 184 `conserve_popcount` bridge | n/a | n/a | **Done** |
| G69 | `flow_composition` on iterated CA | n/a | n/a | **Done** |
| G73 | Blind probe generation on backtest corpus | #89 | n/a | **Done** (8/13 true_found, PROVEN bounded) |
| G74 | Lang-pack contract + conformance gate (ADR-021) | #93 | n/a | **Done** (C + Zig retrofit green) |
| G75 | Native Rust lang pack | #98 | n/a | **Done** (gate green, zero contract amendments) |
| G76 | Native Go lang pack | #100 | n/a | **Done** (gate green, full Go runtime artifact) |
| G77 | Lang-pack CI + native backtest per pack | #106 | n/a | **Done** (`check-lang-packs.sh` in all-proofs) |
| G78 | ICP CLI facade + callsite refactor | #110 | n/a | **Done** |
| G79 | Root README for product, ICP, and adoption path | #112 | n/a | **Done** |
| G80 | Complete CLI surface (`./nanograph` entrypoint + adoption guide) | #113 | n/a | **Done** |
| G81 | ICP maintainer simulation (cold-start adoption eval) | #115, #122 | n/a | **Done** (ref run completed=yes; n=2 stall=16; CI adoption gate) |
| G82 | Verifier-hash gate (language-blind floor as machine invariant) | #120 | n/a | **Done** |
| G83 | Pre-registered holdout eval (blind detection generalization) | #121 | n/a | **Done** (4/5 true_found 80%; `generalizes_bounded`) |
| G84 | Blind discovery on real upstream (reject nobody flagged) | #126 | n/a | **Active** (tranche-1: real base-N decoders are trailing-bits-lenient by design; blind round_trip rejects are relation gaps, not bugs; Go base32 + CPython base64 confirmed) |
| G85 | Native-upstream hunt vehicle (relation on live code, not transcription) | #126 | n/a | **Done** (vehicle + self-tests; CPython `relation_gap`; rust-bitcoin honest null; first defect moved to G86) |
| G86 | First native upstream defect (1200wd/bitcoinlib CompactSize) | #127 | n/a | **Done** (`verdict=reject` witness `fdffff`; gated `check-bitcoinlib-compactsize-hunt.sh`; CASE + ADR-023; severity low; pending install-side repro + human approval before upstream report) |
| G87 | Differential relation + Bech32m/Base58Check huntability | #126 | n/a | **Done** (`relation=differential` in `native-hunt.sh`; `sipa/bech32` reference vendored; `gen-bech32m.sh`/`gen-base58check.sh`; `check-bech32m-differential.sh` catches witver>16, `check-base58check-hunt.sh` catches leading-zero; real third-party target is follow-on) |

### ICP adoption gaps (priority order, ADR-020)

| Gap | Status | Next action |
| --- | --- | --- |
| Probe generator (detection) | **Done bounded (G73 + #96)** | 8/13 true_found (61%) incl. native Zig; one documented relation gap (capnproto); see [`PROBE-GENERATOR-SPIKE.md`](PROBE-GENERATOR-SPIKE.md) |
| Extractor (freestanding specimen) | **Mitigated by agents** | Delegate transcription pattern (H3 tranches 2–3); productize only if paying candidate binds cost |
| Fit conditionality | **Scoping** | `score-case-fit.sh`; say no to NOT-A-FIT |
| Platform (x86_64 Linux ELF) | **Intentional** | APE rejected ADR-014; no reopen without new evidence |

### Conditional follow-ons (pre-registered)

These earn issues only when the parent goal's verdict or mining output satisfies the trigger. Do not start without the trigger.

| ID | Goal | Trigger | Parent |
| --- | --- | --- | --- |
| G56 | First Rust real-history backtest | G51 delivers ≥1 FIT scorecard with verified SHAs + extraction note | G51 / #70 |
| G57 | First Zig real-history backtest | G52 delivers ≥1 FIT scorecard with verified SHAs + extraction note | G52 / #70 |
| G58 | First Go real-history backtest | G53 delivers ≥1 FIT scorecard with verified SHAs + extraction note | G53 / #70 |
| G59 | Non-C freestanding specimen through existing gate unchanged | G51–G53 stretch passes on one Rust, Zig, or Go binary | G51–G53 / #70 |
| G60 | APE harness tooling (native macOS proof subset) | G54 H1 **PROVEN** | G54 / #71 |
| G61 | APE specimen runner + witness cross-loader gate | G54 H2 **PROVEN** (verification extension, not tooling-only) | G54 / #71 |
| G62 | Real portability bug via APE (G33 bridge) | G54 H4 **PROVEN** with FIT candidate | G54 / #71 |
| G63 | Candidate-ID sidecar contract + `*.req.auto` gate | G55 H1+H2 **PROVEN** | G55 / #72 |
| G64 | Agent build→sidecar→verify loop harness | G55 verdict **adopt sidecar** + G63 done | G55 / #72 |
| G65 | `size_monotone` second mined bug (broader power claim) | Real-history candidate beyond jemalloc overflow boundary | G49 done + mining |
| G71 | Rust crc32fast `flow_composition` real-history backtest | G56 extraction spike passes + G69 done | G51 / #70 |
| G72 | Tri-language `flow_composition` witness equivalence doc | G57 + G58 + G71 backtests done | G57/G58/G71 |
| ~~G75~~ | ~~Native Rust lang pack~~ | Triggered and **done** (#98) | G74 / #93 |
| ~~G76~~ | ~~Native Go lang pack~~ | Triggered and **done** (#100, standard Go not TinyGo) | G74 / #93 |

**G51** (done, #70). Rust mining shortlist in [`MINING-G51-G53.md`](MINING-G51-G53.md). Top FIT `rust-base64-invalid-last` (G56 survivor). Wolfram runner-up `rust-crc32fast-combine-len0` (G71). `linear_xor` PARKED on BE-only baseline.

**G52** (done, #70). Zig mining shortlist. Top FIT `zig-std-wyhash-iterative` (`flow_composition`, G57 survivor). `linear_xor` family kill (no verified fix).

**G53** (done, #70). Go mining shortlist. Top FIT `go-base64-streaming` (`flow_composition`, G58 survivor). `linear_xor` NOT-A-FIT (AVX512+race). `conserve_popcount` PARKED modeled only.

**G49** (done, #68). jemalloc `sz_s2u_compute_using_delta`. Gated `BACKTEST-JEMALLOC-S2U` in `check-all-proofs.sh`. Witness `hex=7000000000000101`.

**G50** (done, #69). Modeled `conserve_popcount` on reverse32. Gated `BACKTEST-CONSERVE-POPCOUNT`. Witness `hex=3`. G68 extends same relation to rule 184 step.

**G69** (done, #76). `flow_composition` relation on `fixtures/metamorphic/ca_flow.c` (rule 90). `-DEVIL_SKIP` omits one middle generation when `steps >= 2`. Gate `scripts/check-flow-composition.sh`. Impact matrix `scripts/measure-relation-impact.sh`. ADR-019. No `.ngb` format change.

**G68** (done). Rule 184 one-step specimen reuses G50 `conserve_popcount` without a new branch. `-DEVIL_DROP` on `ca_step.c`. Ruliad rule 184 marked Done in ledger. Gate `scripts/check-rule184-conserve.sh`. ADR-018.

**G67** (done). `linear_xor` relation on rule 90 CA step; `-DEVIL_RULE` compiles rule 30 imposter. Gate `scripts/check-linear-xor.sh`. ADR-017. Mining note: CRC/checksum combine histories are the real-history follow-on (scorecard TBD).

**G66** (done). [`RELATION-TAXONOMY.md`](RELATION-TAXONOMY.md), family column in METAMORPHIC-RELATIONS, BACKTEST stage-2 checklist. ADR-016. Gate `scripts/check-relation-taxonomy.sh`. Docs only.

**G55** (done, #72; follow-on #85–#87). Candidate-ID sidecar spike. Verdict **skill-only** per ADR-015. H1 **PROVEN** (4/5 holdout `.req` recall), H2 **PROVEN** (verdict equivalence), H3 **PROVEN** under frozen sidecar (novel nibbles + 5/5 mined house-style; variant A fail-closed without relation prose), H4 **PROVEN** (boundary). Sidecar is a convention lint, not an authoring oracle. G63–G64 stay parked.

**G76** (done, #100). Native Go lang pack. `scripts/mint-one-go.sh` (pinned `golang:1.22`, CGO_ENABLED=0, `-trimpath`, `-buildid=`) first proved the contract via `go_native_bswap32.go` + `bswap32.req` (full Go runtime in `.ngb`, ~1.5MB vs 9.4KB C). Zero contract amendments; language-blind claim **Proven (Zig+Rust+Go)**, n=3. **G77b:** CI gate and native backtest now use mined `go_base64_streaming.req` + `go-base64-streaming-native` (G58); bswap32 remains optional manual smoke only.

**G75** (done, #98). Native Rust lang pack. `scripts/mint-one-rust.sh` (pinned `rust:1.79`) + `rust_native_bswap32.rs` (no_std, no_main, raw syscalls, G36 trampoline) first proved the contract via `bswap32.req`. Zero contract amendments; language-blind claim upgraded to **Proven (Zig+Rust)**, n=2 native non-C. **G77b:** CI gate and native backtest now use mined `rust_base64.req` + `rust-base64-native` (G56); bswap32 remains optional manual smoke only.

**G74** (done, #93). Lang-pack contract per ADR-021: language support is a modular pack (one `mint-one-<lang>.sh` + one specimen) proven by `check-lang-pack.sh` (mint → I1–I6 parse → honest accept), not a plugin framework. C and Zig minters retrofit green with zero minter changes (`bswap32.req` involution, `zig_wyhash.req` flow_composition). **G77** (#106) wired `check-lang-packs.sh` into CI on committed `.ngb` plus real-history native backtest per non-C pack (C covered by the general 15-case C backtest suite). Spec [`LANG-PACKS.md`](LANG-PACKS.md).

**G77** (done, #106). Lang-pack CI and native backtest per pack. `check-lang-packs.sh` in `check-all-proofs.sh`. **Follow-on:** mined native backtests `rust-base64-native` (G56 InvalidLastSymbol) and `go-base64-streaming-native` (G58 tail fix) replace synthetic bswap32 timelines; `check-backtest.sh` witness regex tightened; Go build tags for evil bswap.

**G78** (done, #110). ICP-facing CLI facade (`scripts/nanograph`) that routes `doctor`, `demo`, `fit`, `verify`, and `mint` to existing floor scripts without changing floor semantics. Follow-on refactors migrated onboarding-facing callsites to the CLI and added dedicated CLI regression gating (`check-icp-cli.sh`).

**G81** (done, #115, #122). ICP maintainer simulation. Reference live run `run-20260613T023339Z`: `completed=yes first_stall=none friction=3`. n=2 check `run-20260614T011931Z`: `completed=no first_stall=16 friction=4` (persona wants hosted `hex.c` proof, not template-only). Deterministic adoption gate is CI truth; live sim is stochastic telemetry.

**G82** (done, #120). Verifier-hash gate. `fixtures/lang-packs/VERIFIER.sha256` pins `metamorphic-verify.sh`; `check-verifier-frozen.sh` wired into lang-pack CI.

**G83** (done, #121). Pre-registered holdout eval for blind detection generalization. Five cases outside `backtest-rev2`; generators pinned at `fixtures/holdout/preregistration.json`. Frozen run **4/5 true_found (80%)**, verdict **`generalizes_bounded`**. Bounded signal, not full proof. Cases selected from existing backtests (not freshly mined), two are native-binary ports of train siblings, jemalloc rode a `.req` overflow field; `conserve-popcount` is the clearest independent find. knuth-sgb miss is budget/domain-size (integers 1..256). `holdout-rev2` fresh mining is the follow-up. Spec [`HOLDOUT-EVAL.md`](HOLDOUT-EVAL.md); spike row in [`PROBE-GENERATOR-SPIKE.md`](PROBE-GENERATOR-SPIKE.md).

**G73 follow-on** (done, #102–#105). Four frozen-tier blind misses closed under legal format-aware hints. Full corpus with hints: 12/13 true_found; curated backtests unchanged. Separate spike row preserves the original 8/13 headline.

**G73** (done, #89; hardened #96). Blind probe generation eval. `blind-probe-search.sh` + `blind-probe-generators.sh`; after hardening, **8/13 true_found (61%)** with rev1 replay control (`METAMORPHIC_PROBES`), `.req`-declared generator hints, native Zig corpus case (blind true_found), and capture-level fault retry. One documented relation gap (capnproto WHATWG leniency). Misses documented (utf8/leb128/wabt/parseip budget). No CI gate (~207s wall). Spec [`PROBE-GENERATOR-SPIKE.md`](PROBE-GENERATOR-SPIKE.md).

**G54** (done, #71; tooling revisit #85). APE target extension spike. Verdict **reject** per ADR-014 for verification extension; H1 tooling tier **PROVEN** (#85). G60–G62 stay parked.

**G56** (done, #79). First Rust real-history backtest on `marshallpierce/rust-base64` `decode_helper` (`rust-base64-invalid-last.fit`, parent `95edf364` → fix `f6915a3`). `round_trip` relation. Gated `RUST-BASE64-INVALID-LAST`. Witness `hex=6959563d` (`iYV=`).

**G57** (done, #80). Zig Wyhash iterative tail backtest gated `ZIG-WYHASH`. `flow_composition` on mined history; witness `hex=5` (seed 5, triple 48+10). Validates G69 beyond modeled CA.

**G58** (done, #81). Go base64 streaming backtest gated `GO-BASE64-STREAMING`. `flow_composition` on mined history; witness `hex=5` (seed 5, probe `AAAAAA`).

**G59** (done). Native Zig Wyhash via `mint-one-zig.sh`; gated `ZIG-WYHASH-NATIVE`. Same witness as G57; proves language-blind floor for one non-C language.

**G71** (done, #82). Rust crc32fast `flow_composition` on `combine(len2=0)` (parent `cdbd51f` → fix `724ceb6`). Gated `RUST-CRC32FAST-COMBINE-LEN0`. Witness `hex=5` (triple `0 0 5`). Completes tri-language `flow_composition` mined lane.

**G72** (done). Tri-language witness equivalence doc [`FLOW-COMPOSITION-TRI-LANGUAGE.md`](FLOW-COMPOSITION-TRI-LANGUAGE.md). Verdict **PROVEN (bounded)**. Shared primary witness seed `hex=5` across Zig, Go, Rust.

**G40** (shortlist). Follow-through from G32 mining on the Justine/llamafile ICP thread ([`docs/icps/justine-tunney.md`](../icps/justine-tunney.md)). Six scorecards, anti-fabrication SHAs verified via `gh api`. Active FIT survivor executed as G41. `parked=1` scorecards (`cosmo-decodebase64`, `cosmo-isutf8`, `cosmo-uleb64`) score `gate=PARKED` and are excluded from the queue. NOT-A-FIT: `llamafile-inference` (`observable=0`). Score with `scripts/score-case-fit.sh fixtures/fit-cases/<name>.fit`. No floor or format change.

**G41** (done). `jart/cosmopolitan` `ParseIp` (`net/http/parseip.c`). Integer overflow on `b *= 10; b += digit` before fix `c995838`; parent `539bddc`. New `value_oracle` relation; `fixtures/metamorphic/cosmo_parseip.c` behind trusted driver. **Catch** on `255.255.255.256` (`hex=3235352e3235352e3235352e323536`): buggy returns `4294967040`, honest returns `REJECT`. Timeline accept/reject/accept; gated `COSMO-PARSEIP`. `fixtures/backtest/cosmo-parseip/CASE.md`, root `THIRD-PARTY.md`.

**G44** (done, #62). Verifier-only strengthen of G41 `value_oracle` probe set. Added undotted wrap witness `4294967296` (`hex=34323934393637323936`): buggy returns `0`, honest `REJECT`. This isolates the u32 overflow path because `dotted==0` disables the range guard. No `.ngb` remint; backtest timeline witness stays `255.255.255.256`.

**G42** (done, #66). `jart/cosmopolitan` `ljson` string UTF-8 (`tool/net/ljson.c`). Reselected after punycode (CVE-2022-3602) proved a memory-safety OOB `round_trip` cannot see, and pg-semver (`4d79dcc`, 64-bit no-op) and utf8proc (`6249e6b`, refactor not a defect) failed the clean-fit bar. The pre-fix string loop copied bytes above `0x1F` verbatim with no UTF-8 check; fix `baf51a4` (parent `ccd057a`) adds the `kJsonStr` classifier and rejects overlong, surrogate, and malformed sequences. `fixtures/metamorphic/cosmo_ljson.c` transcribes the classifier and raw-byte validation behind a trusted driver; strippable honest decoder, rev2 compiled with `-DLJSON_NOUTF8` for the verbatim parent path. Relation corrected from the scorecard's `round_trip` to `value_oracle`: the buggy decoder is a verbatim pass-through, so `round_trip` is the identity and misses it; the acceptance gap needs `value_oracle`. **Catch** on `c080` (overlong U+0000): buggy echoes `c080`, honest `REJECT`. Timeline accept/reject/accept; gated `COSMO-LJSON`. `fixtures/backtest/cosmo-ljson/CASE.md`, root `THIRD-PARTY.md`.

**G43** (cancelled). `cosmo-uleb64` synthetic lane duplicates G31 leb128 with no verified fix SHA. Scorecard kept with `parked=1` for reference only.

**G48** (done, #67). `llvm/llvm-project` BOLT `getCodeSections` `compareSections` lambda. Mined round 2 after Linux ORC `0210d25` parked on GPL. Parent `e8606ab` omits identity guard; fix `5fe235b` adds `if (A == B) return false`. New `cmp_order` relation (irreflexivity + antisymmetry on bool comparator). `fixtures/metamorphic/llvm_bolt_cmp.c` transcribes string ordering logic; strippable guard, rev2 `-DCMP_IDENTITY_OK`. **Catch** on pair `(0,0)` mover self (`hex=00`): buggy `got_ij=1`, honest `0`. Timeline accept/reject/accept; gated `LLVM-BOLT-CMP`. ADR-011. `fixtures/backtest/llvm-bolt-cmp/CASE.md`, root `THIRD-PARTY.md`.

The retry-reduction line is closed (G14). G16 closes the repo-leakage gap for live eval. The proven claim is integrity plus execution-grounded conformance, and it stands on the deterministic suite without a live-agent number.

Parked ideas, each needing a concrete reason before it earns a slot. Do not build speculatively.

| Parked | Trigger to revive |
| --- | --- |
| G45 differential-backend conformance, same `.ngb` across runners (#63) | A second backend-drift defect surfaces that one runner misses (G36 was the first and is already fixed structurally), or a new vectorization/alignment surface needs cross-runner regression insurance |
| G46 disjoint-patch commutativity at observable level (#64) | An agent produces an order-sensitive disjoint-patch sequence observed in practice, not by analogy to confluence theory |
| G47 superposition-style search for the G23 verifier (#65) | G23 sum-ordered enumeration provably misses a known bug within budget, and a portable deterministic superposition variant exists with no HVM4-in-CI dependency; leans reject (synthesis vs verification mismatch) |
| dna-reverse-complement involution specimen | Extend involution lane beyond bswap/reverse32 |
| Second generator case (over-reach or finite domain only) | Cited real-history candidate with different failure mode than G35 |
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
| #55 | G35 real Knuth-canon backtest, rand_len off-by-one |
| #56 | G36 fix CI red, ca_eca.c _start stack alignment |
| #57 | G37 strengthen range_coverage with endpoint witnesses |
| #58 | Post-G37 backlog (umbrella, parked next goals) |
| #59 | G38 split range_coverage reachability/containment phases |
| #60 | G39 capnproto decodeBase64 real-history backtest |
| #61 | G41 cosmo ParseIp real-history backtest |
| #62 | G44 strengthen G41 ParseIp value_oracle witness set (u32 wrap) |
| #63–#65 | G45/G46/G47 exploration triage (parked, closed not-planned) |
| #66 | G42 cosmo ljson overlong UTF-8 real-history backtest (reselected) |
| #67 | G48 LLVM BOLT cmp_order real-history backtest |
| #68 | G49 jemalloc size_monotone real-history backtest |
| #69 | G50 conserve_popcount modeled backtest (reverse32) |
| #70 | G51–G53 Rust, Zig, Go backtest mining (language diversity) |
| #79 | G56 Rust base64 real-history backtest |
| #80 | G57 Zig Wyhash flow_composition backtest |
| #81 | G58 Go base64 streaming flow_composition backtest |
| #82 | G71 Rust crc32fast flow_composition backtest |
| #71 | G54 falsify Cosmopolitan APE target extension (prove or refute) |
| #72 | G55 falsify candidate-ID sidecar at VerificationRequest seam |
| #73 | G66 relation taxonomy (docs) |
| #74 | G67 linear_xor homomorphism relation |
| #75 | G68 rule 184 conserve_popcount bridge |
| #76 | G69 flow_composition relation |
| #85 | G55 H3 tranche 2 adversarial mined codec + G54 APE H1 tooling revisit |
| #87 | G55 H3 tranche 3 four remaining mined specimens |
| #89 | G73 blind probe generation eval (ADR-020) |
| #93 | G74 lang-pack contract + conformance gate |
| #96 | G73 hardening follow-on (hints, native case, replay control) |
| #98 | G75 native Rust lang pack |
| #100 | G76 native Go lang pack |
| #102–#105 | G73 blind misses follow-up strategies (utf8, leb128, wabt, parseip) |
| #106 | G77 lang-pack CI gate + native backtest per pack |
| #110 | G78 ICP CLI facade + callsite refactor |
| #112 | G79 root README for product, ICP, adoption |
| #113 | G80 CLI surface completion (`./nanograph` + adoption guide) |
| #115 | G81 ICP maintainer simulation (cold-start adoption eval) |
| #116–#119 | G81 first-run findings (doctor probe, fail-fast, transcription docs, generic domain) |
| #120 | G82 verifier-hash gate (language-blind machine invariant) |
| #121 | G83 pre-registered holdout eval (blind detection generalization) |
| — | G56–G65 conditional follow-ons (pre-registered in Next goals; no issue until trigger) |
| — | G40 llamafile-stack subcase mining + scorecards (shortlist) |
