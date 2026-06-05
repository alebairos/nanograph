# NanoGraph tools (C)

M2 executable spec. C + bash only.

## Build

```bash
make -C tools
```

## Binaries

| Binary | Role |
| --- | --- |
| `bin/hello-fixture` | Canonical hello ELF + `.ngb` fixtures |
| `bin/ngb-pack` | Pack ELF → `.ngb` v0 (single genesis node) |
| `bin/ngb-parse` | Validate I1–I6 + print `graph_root_hash` |
| `bin/ngb-extract` | Extract ELF image from `.ngb` |

## macOS P3 (run linux ELF)

`./scripts/run-linux-elf.sh` tries native Linux, then `qemu-x86_64`, then Docker (`ubuntu:24.04`, stdin pipe, no bind mount).

On Apple Silicon, Homebrew QEMU no longer ships user-mode `qemu-x86_64`. Use Colima or Docker Desktop:

```bash
brew install colima docker
colima start
./scripts/check-hello-proof.sh
```

CI uses native x86_64 Linux on `ubuntu-latest`.
