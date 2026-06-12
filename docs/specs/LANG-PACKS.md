# Lang packs (modular language support)

How a new source language joins NanoGraph without touching the verify floor. Decision record: [`../adr/ADR-021-lang-pack-contract.md`](../adr/ADR-021-lang-pack-contract.md).

The floor consumes `.ngb` + `.req` and is language-blind (ADR-007, ADR-010). A **lang pack** is the language-aware layer above that seam: one minter script plus one specimen, proven by one gate. Contributors (human or agent) never modify `tools/**`, `NGB-V0.md`, or `metamorphic-verify.sh`. CI enforces this via `fixtures/lang-packs/VERIFIER.sha256` and `scripts/check-verifier-frozen.sh` (G82). A deliberate verifier change requires updating the manifest in the same commit with justification; a lang-pack PR that drifts the verify surface without a manifest update fails the gate.

## Pack inventory

| Pack | Minter | Toolchain (pinned) | Gate (CI) | Native backtest (real-history) |
| --- | --- | --- | --- | --- |
| C | `scripts/mint-one-elf.sh` | `gcc:13` Docker image | `bswap32.ngb` + `bswap32.req` | General suite (15 C backtests in `check-all-proofs.sh`) |
| Zig | `scripts/mint-one-zig.sh` | Zig 0.13.0, `ubuntu:24.04` Docker | `zig_wyhash.req` honest rev | `zig-wyhash-native` (mined wyhash, G59) |
| Rust | `scripts/mint-one-rust.sh` | `rust:1.79` Docker image | `rust_base64.req` honest rev | `rust-base64-native` (mined InvalidLastSymbol, G56) |
| Go | `scripts/mint-one-go.sh` | `golang:1.22`, CGO_ENABLED=0 | `go_base64_streaming.req` honest rev | `go-base64-streaming-native` (mined tail fix, G58) |

## Minter CLI contract

```
scripts/mint-one-<lang>.sh <source...> <out.ngb> [extra flags...]
```

- Last positional argument before optional flags is the output `.ngb` path.
- Exit 0 and print `mint-one-<lang> OK <out.ngb>` on success; nonzero with a one-line reason on failure.
- Requires only `docker` and `tools/bin/ngb-pack` (built via `make -C tools`).
- Leaves no build intermediates behind in the source directory.

## Artifact contract (driver ABI)

The minted ELF must be:

1. **Static, freestanding, x86_64 Linux.** No dynamic linker, no libc requirement at runtime. Entry `_start` (a naked trampoline calling the real entry preserves C-ABI stack alignment; see G36).
2. **argv in, stdout out.** First argv token is the relation mode (e.g. `enc`, `dec`, `flow`, `cmp`, `draw` per [`METAMORPHIC-RELATIONS.md`](METAMORPHIC-RELATIONS.md)); operands follow as decimal, hex, or ascii tokens per the `.req` `wire=` field.
3. **Deterministic.** Same argv produces the same stdout bytes. No clock, no randomness outside seeded draws.
4. **Honest about rejection.** Invalid input prints the `.req` `reject=` token (or exits nonzero where the relation specifies).

## Reproducibility rules

- **Pinned toolchain.** Exact compiler version in a Docker image or versioned tarball. A pack that builds differently next year is broken.
- **Canonical source name.** Compile via a fixed filename (the C pack copies to `__one.c`) so the embedded `STT_FILE` symbol, and thus the graph hash, depends on content, not the incidental filename.
- **`--platform linux/amd64`** on Docker invocations so ARM64 hosts mint identical bytes.

## Conformance gate

Two legs. **CI** runs the committed-artifact leg only (no Docker mint). **Manual** adds the mint leg when authoring or refreshing a pack.

### CI leg (wired in `check-all-proofs.sh`)

```
./scripts/check-lang-packs.sh
```

For each pack: committed honest `.ngb` → `ngb-parse` (I1–I6) → `metamorphic-verify.sh` accept under the pack's `.req`, plus one **real-history** native backtest timeline per non-C pack (Zig, Rust, Go) in `check-lang-packs.sh`. The **C pack** has no separate lang-pack backtest directory. C real-history coverage lives in the general 15-case backtest suite (`check-all-proofs.sh`). C's lang-pack CI leg is honest involution gate only (`bswap32.ngb` + `bswap32.req`).

After backtest legs, `check-native-port-fidelity.sh` asserts native Rust/Go rev2 reject witnesses match the C-mined sibling case on the same `.req`.

### Manual mint leg (authoring)

```
./scripts/check-lang-pack.sh <out.ngb> <req> -- <mint command...>
```

Three steps, all required when minting fresh:

1. **Mint.** The minter exits 0 and produces the `.ngb`.
2. **Integrity.** `tools/bin/ngb-parse` accepts (invariants I1–I6).
3. **Behavior.** `metamorphic-verify.sh <ngb> <req>` returns `verdict=accept` on the honest specimen.

Equivalent ICP facade commands:

```bash
./scripts/nanograph mint <c|rust|go|zig> ...
./scripts/nanograph verify --expect accept <ngb> <req>
```

Native mined backtests use `scripts/mint-lang-pack-native-backtest.sh <rust-base64|go-base64-streaming> <outdir>`. Zig uses `mint-one-zig.sh` on `fixtures/backtest/zig-wyhash-native/` (see CASE.md there). Optional synthetic involution smoke uses `mint-lang-pack-bswap32-backtest.sh` (not in CI).

A reject leg (buggy revision rejected) is not part of the pack gate; it belongs to the backtest case the pack's specimens feed (see [`BACKTEST.md`](../BACKTEST.md)).

Retrofit proofs (2026-06-11, both unchanged minters):

```bash
./scripts/check-lang-pack.sh /tmp/lp_c.ngb fixtures/metamorphic/bswap32.req \
  -- ./scripts/mint-one-elf.sh fixtures/metamorphic/bswap32.c /tmp/lp_c.ngb
./scripts/check-lang-pack.sh /tmp/lp_zig.ngb fixtures/metamorphic/zig_wyhash.req \
  -- ./scripts/mint-one-zig.sh fixtures/backtest/zig-wyhash-native \
     fixtures/backtest/zig-wyhash-native/wyhash_fix.zig /tmp/lp_zig.ngb
./scripts/check-lang-pack.sh /tmp/lp_rust.ngb fixtures/metamorphic/rust_base64.req \
  -- ./scripts/mint-one-rust.sh fixtures/metamorphic/rust_native_base64.rs /tmp/lp_rust.ngb
./scripts/check-lang-pack.sh /tmp/lp_go.ngb fixtures/metamorphic/go_base64_streaming.req \
  -- ./scripts/mint-one-go.sh fixtures/metamorphic/go_native_base64_streaming.go /tmp/lp_go.ngb
```

G77 (#106) wired `check-lang-packs.sh` into CI. **Follow-on (G77b):** replaced synthetic `*-bswap32-native` timelines with mined `rust-base64-native` (G56) and `go-base64-streaming-native` (G58); tightened `check-backtest.sh` witness regex; Go evil bswap uses build tags not a duplicate file. **G77c (docs+ fidelity):** G75/G76 narrative updated for current CI gate; native port fidelity check; epistemology note below.

## Native specimen epistemology

**Native** in a lang-pack backtest means the artifact was minted by `mint-one-<lang>.sh`, not that upstream Rust/Go sources were compiled verbatim. Specimens are faithful ports of the freestanding C transcription already used in the mined C backtest (same bug guard, same `.req`, same reject witness). The proof is that the lang-pack pipeline preserves real-history relation semantics at native scale. See sibling `fixtures/backtest/<case>/CASE.md` (C) and `fixtures/backtest/<case>-native/CASE.md` (native). `check-native-port-fidelity.sh` compares rev2 reject witnesses across the pair.

## Artifact size note

Go pack `.ngb` files carry the full Go runtime (~1.5MB per revision). That weight is expected and unchanged since G76. It is the stress test that pack/parse/verify stay language-blind at production scale.

## Contribution checklist (for an external agent)

1. Read this file and [`METAMORPHIC-RELATIONS.md`](METAMORPHIC-RELATIONS.md). Do not read or modify `tools/**`.
2. Write `scripts/mint-one-<lang>.sh` per the minter CLI.
3. Write one honest specimen in the new language implementing an existing relation's driver ABI, plus its `.req`.
4. Run `scripts/check-lang-pack.sh` (full mint leg) and `scripts/check-lang-packs.sh` after committing `.ngb` artifacts (CI leg).
5. Add or refresh a **real-history** native backtest timeline (`mint-lang-pack-native-backtest.sh` for Rust/Go mined cases, or a Zig-style mined directory). Synthetic involution smokes are optional and must not substitute for mined proof.
6. Open a PR referencing the pack's pre-registered goal (G75, G76, or a new conditional row in [`NANO-GOALS.md`](NANO-GOALS.md)).

## What a pack must not do

- Change `NGB-V0.md`, `tools/**`, or the `.req` schema. A pack needing any of those is a new ADR, not a pack.
- Change `metamorphic-verify.sh` except through a deliberate verifier-hash bump (see `fixtures/lang-packs/VERIFIER.sha256`). The generic maintainer domain `domain=bytes` is the supported path for new wire formats without new hard-coded domain names.
- Vendor an unpinned toolchain.
- Embed source-language metadata in the `.ngb`. The artifact stays language-blind.
