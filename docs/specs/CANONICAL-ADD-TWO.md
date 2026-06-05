# Canonical add_two (1+1)

Second frozen program. Planned for **M4** after hello P1–P4 complete.

## Behavior

x86_64-linux ELF, static, no libc.

```text
mov eax, 1
add eax, 1
mov edi, eax
mov eax, 60
syscall          ; exit(2)
```

Auditors verify with `echo $?` → 2 after run. No stdout.

## Artifacts

| File | Role |
| --- | --- |
| `fixtures/add_two_elf.bin` | ELF image (137 bytes) |
| `fixtures/add_two.ngb` | Canonical `.ngb` v0 (345 bytes) |
| `fixtures/add_two.ngb.hex` | Review hex |
| `fixtures/add_two.audit-log.golden` | Expected `nano-probe audit-log` stdout |

Regenerate with `tools/bin/add-two-fixture` then `tools/bin/nano-probe audit-log fixtures/add_two.ngb` for audit golden.

## Proof ladder

Same IDs as [HELLO-CANONICAL.md](HELLO-CANONICAL.md) (P1–P4). `check-add-two-proof.sh` mirrors hello script.

## Node table (frozen)

Exactly **3** nodes, `node_id` 1..3:

| node_id | offset | length | instruction group |
| --- | --- | --- | --- |
| 1 | 0 | 5 | `mov eax, 1` |
| 2 | 5 | 3 | `add eax, 1` |
| 3 | 8 | 9 | `mov edi, eax` + `mov eax, 60` + `syscall` |

## Relation to hello

Independent genesis graph (`patch_count = 0`). `probe diff` between hello and add_two is a later teaching artifact (G6), not required for add_two acceptance.
