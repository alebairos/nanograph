# Fixtures (canonical programs)

Hello: [`docs/specs/HELLO-CANONICAL.md`](../docs/specs/HELLO-CANONICAL.md)  
add_two: [`docs/specs/CANONICAL-ADD-TWO.md`](../docs/specs/CANONICAL-ADD-TWO.md)

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

## add_two (M4)

| File | Notes |
| --- | --- |
| `add_two_elf.bin` | x86_64-linux ELF, `1+1` via `add`, exit(2) |
| `add_two.ngb` / `add_two.ngb.hex` | Regenerate with `tools/bin/add-two-fixture` |
| `add_two.audit-log.golden` | `nano-probe audit-log` stdout |

**graph_root_hash:** `5a74198abb4229f2a85dd2320f4e3d6fbc359c9c99da20556d7fa815a65a6cf2`

**P1 budgets** (`scripts/check-add-two-proof.sh`): ELF 137 B, `.ngb` 345 B, exit code 2.
