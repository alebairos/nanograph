# Fixtures (canonical hello)

See [`docs/specs/HELLO-CANONICAL.md`](../docs/specs/HELLO-CANONICAL.md).

| File | Notes |
| --- | --- |
| `hello_elf.bin` | Minimal x86_64-linux ELF, exit(0) |
| `hello.ngb` / `hello.ngb.hex` | Canonical `.ngb` v0 (regenerate with `tools/bin/hello-fixture`) |

**graph_root_hash (sha256):** `8444570de269709c92670e0eb2a1b26d87200b00b9be01a83061627fd0aa0411`

**image_len:** 130  
**node_count:** 1 (`node_id=1`, offset 0, length 130)

**P1 budgets** (enforced by `scripts/check-hello-proof.sh`):

| Artifact | Bytes |
| --- | --- |
| `hello_elf.bin` | 130 |
| `hello.ngb` | 242 |

`hello-fixture --no-write --print-ms` must report ≤ 50ms (expected sub-ms; ceiling catches hangs).
