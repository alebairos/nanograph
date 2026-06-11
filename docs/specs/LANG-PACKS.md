# Lang packs (modular language support)

How a new source language joins NanoGraph without touching the verify floor. Decision record: [`../adr/ADR-021-lang-pack-contract.md`](../adr/ADR-021-lang-pack-contract.md).

The floor consumes `.ngb` + `.req` and is language-blind (ADR-007, ADR-010). A **lang pack** is the language-aware layer above that seam: one minter script plus one specimen, proven by one gate. Contributors (human or agent) never modify `tools/**`, `NGB-V0.md`, or `metamorphic-verify.sh`.

## Pack inventory

| Pack | Minter | Toolchain (pinned) | Status |
| --- | --- | --- | --- |
| C | `scripts/mint-one-elf.sh` | `gcc:13` Docker image | **Gate green** (G74, `bswap32.req` involution) |
| Zig | `scripts/mint-one-zig.sh` | Zig 0.13.0, `ubuntu:24.04` Docker | **Gate green** (G74, `zig_wyhash.req` flow_composition) |
| Rust | `scripts/mint-one-rust.sh` | TBD (pin exact rustc) | Pre-registered (G75) |
| Go | `scripts/mint-one-go.sh` | TBD (TinyGo route) | Pre-registered (G76) |

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

```
scripts/check-lang-pack.sh <mint-cmd...> -- <specimen-out.ngb> <req>
```

Three legs, all required:

1. **Mint.** The minter exits 0 and produces the `.ngb`.
2. **Integrity.** `tools/bin/ngb-parse` accepts (invariants I1–I6).
3. **Behavior.** `metamorphic-verify.sh <ngb> <req>` returns `verdict=accept` on the honest specimen.

A reject leg (buggy revision rejected) is not part of the pack gate; it belongs to the backtest case the pack's specimens feed (see [`BACKTEST.md`](../BACKTEST.md)).

Retrofit proofs (2026-06-11, both unchanged minters):

```bash
./scripts/check-lang-pack.sh /tmp/lp_c.ngb fixtures/metamorphic/bswap32.req \
  -- ./scripts/mint-one-elf.sh fixtures/metamorphic/bswap32.c /tmp/lp_c.ngb
./scripts/check-lang-pack.sh /tmp/lp_zig.ngb fixtures/metamorphic/zig_wyhash.req \
  -- ./scripts/mint-one-zig.sh fixtures/backtest/zig-wyhash-native \
     fixtures/backtest/zig-wyhash-native/wyhash_fix.zig /tmp/lp_zig.ngb
```

The gate is not wired into `check-all-proofs.sh`; the Zig leg downloads its toolchain (~90s, network), which fails the CI determinism bar. Run it when adding or changing a pack.

## Contribution checklist (for an external agent)

1. Read this file and [`METAMORPHIC-RELATIONS.md`](METAMORPHIC-RELATIONS.md). Do not read or modify `tools/**`.
2. Write `scripts/mint-one-<lang>.sh` per the minter CLI.
3. Write one honest specimen in the new language implementing an existing relation's driver ABI, plus its `.req`.
4. Run `scripts/check-lang-pack.sh`. Green means in.
5. Open a PR referencing the pack's pre-registered goal (G75, G76, or a new conditional row in [`NANO-GOALS.md`](NANO-GOALS.md)).

## What a pack must not do

- Change `NGB-V0.md`, `tools/**`, the `.req` schema, or `metamorphic-verify.sh`. A pack needing any of those is a new ADR, not a pack.
- Vendor an unpinned toolchain.
- Embed source-language metadata in the `.ngb`. The artifact stays language-blind.
