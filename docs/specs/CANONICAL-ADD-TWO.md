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

## Artifacts (when implemented)

| File | Role |
| --- | --- |
| `fixtures/add_two_elf.bin` | ELF image |
| `fixtures/add_two.ngb` | Canonical `.ngb` v0 |
| `fixtures/add_two.ngb.hex` | Review hex |

## Proof ladder

Same IDs as [HELLO-CANONICAL.md](HELLO-CANONICAL.md) (P1–P4). `check-add-two-proof.sh` mirrors hello script.

## Node table expectation

At least **3** nodes (one per instruction boundary). `node_id` 1..3 or stable ids from objdump ranges.

## Relation to hello

Independent genesis graph (`patch_count = 0`). `probe diff` between hello and add_two is a later teaching artifact (G6), not required for add_two acceptance.
