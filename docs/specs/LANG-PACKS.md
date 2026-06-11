# Lang packs (modular language support)

How a new source language joins NanoGraph without touching the verify floor. Decision record: [`../adr/ADR-021-lang-pack-contract.md`](../adr/ADR-021-lang-pack-contract.md).

The floor consumes `.ngb` + `.req` and is language-blind (ADR-007, ADR-010). A **lang pack** is the language-aware layer above that seam: one minter script plus one specimen, proven by one gate. Contributors (human or agent) never modify `tools/**`, `NGB-V0.md`, or `metamorphic-verify.sh`.

## Pack inventory

| Pack | Minter | Toolchain (pinned) | Gate | Native backtest |
| --- | --- | --- | --- | --- |
| C | `scripts/mint-one-elf.sh` | `gcc:13` Docker image | **CI green** (`bswap32.req`) | `c-bswap32-native` (committed G24 mints) |
| Zig | `scripts/mint-one-zig.sh` | Zig 0.13.0, `ubuntu:24.04` Docker | **CI green** (`zig_wyhash.req`) | `zig-wyhash-native` (mined wyhash) |
| Rust | `scripts/mint-one-rust.sh` | `rust:1.79` Docker image | **CI green** (`bswap32.req`) | `rust-bswap32-native` (G77) |
| Go | `scripts/mint-one-go.sh` | `golang:1.22` Docker image, CGO_ENABLED=0 | **CI green** (`bswap32.req`) | `go-bswap32-native` (G77) |

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

For each pack: committed honest `.ngb` → `ngb-parse` (I1–I6) → `metamorphic-verify.sh` accept under the pack's `.req`, plus one native backtest timeline per pack (accept → reject → accept).

### Manual mint leg (authoring)

```
./scripts/check-lang-pack.sh <out.ngb> <req> -- <mint command...>
```

Three steps, all required when minting fresh:

1. **Mint.** The minter exits 0 and produces the `.ngb`.
2. **Integrity.** `tools/bin/ngb-parse` accepts (invariants I1–I6).
3. **Behavior.** `metamorphic-verify.sh <ngb> <req>` returns `verdict=accept` on the honest specimen.

Native backtest timelines for involution packs use `scripts/mint-lang-pack-bswap32-backtest.sh <c|rust|go> <outdir>`. Zig uses `mint-one-zig.sh` on `fixtures/backtest/zig-wyhash-native/` (see CASE.md there).

A reject leg (buggy revision rejected) is not part of the pack gate; it belongs to the backtest case the pack's specimens feed (see [`BACKTEST.md`](../BACKTEST.md)).

Retrofit proofs (2026-06-11, both unchanged minters):

```bash
./scripts/check-lang-pack.sh /tmp/lp_c.ngb fixtures/metamorphic/bswap32.req \
  -- ./scripts/mint-one-elf.sh fixtures/metamorphic/bswap32.c /tmp/lp_c.ngb
./scripts/check-lang-pack.sh /tmp/lp_zig.ngb fixtures/metamorphic/zig_wyhash.req \
  -- ./scripts/mint-one-zig.sh fixtures/backtest/zig-wyhash-native \
     fixtures/backtest/zig-wyhash-native/wyhash_fix.zig /tmp/lp_zig.ngb
./scripts/check-lang-pack.sh /tmp/lp_rust.ngb fixtures/metamorphic/bswap32.req \
  -- ./scripts/mint-one-rust.sh fixtures/metamorphic/rust_native_bswap32.rs /tmp/lp_rust.ngb
./scripts/check-lang-pack.sh /tmp/lp_go.ngb fixtures/metamorphic/bswap32.req \
  -- ./scripts/mint-one-go.sh fixtures/metamorphic/go_native_bswap32.go /tmp/lp_go.ngb
```

The Rust pack (G75) and Go pack (G76) both passed with zero contract amendments, two data points against the ADR-021 kill trigger. Go is the heaviest contract test so far: the artifact carries the full Go runtime (`.ngb` 1.5MB vs 9.4KB for the C pack), and pack/parse/verify handled it unchanged. The only Go-specific fact lives inside the minter (the go tool ignores `_`-prefixed files, so the canonical source name is `one.go`).

G77 (#106) wired `check-lang-packs.sh` into CI (`check-all-proofs.sh`). Mint remains manual; CI checks committed `.ngb` only. Each pack now has a native backtest timeline (C/Rust/Go bswap32 involution; Zig wyhash-native unchanged).

## Contribution checklist (for an external agent)

1. Read this file and [`METAMORPHIC-RELATIONS.md`](METAMORPHIC-RELATIONS.md). Do not read or modify `tools/**`.
2. Write `scripts/mint-one-<lang>.sh` per the minter CLI.
3. Write one honest specimen in the new language implementing an existing relation's driver ABI, plus its `.req`.
4. Run `scripts/check-lang-pack.sh` (full mint leg) and `scripts/check-lang-packs.sh` after committing `.ngb` artifacts (CI leg).
5. Add or refresh a native backtest timeline (`mint-lang-pack-bswap32-backtest.sh` for involution packs, or a mined case like Zig wyhash-native).
6. Open a PR referencing the pack's pre-registered goal (G75, G76, or a new conditional row in [`NANO-GOALS.md`](NANO-GOALS.md)).

## What a pack must not do

- Change `NGB-V0.md`, `tools/**`, the `.req` schema, or `metamorphic-verify.sh`. A pack needing any of those is a new ADR, not a pack.
- Vendor an unpinned toolchain.
- Embed source-language metadata in the `.ngb`. The artifact stays language-blind.
