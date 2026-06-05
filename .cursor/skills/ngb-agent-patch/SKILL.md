---
name: ngb-agent-patch
description: Agent loop for patching .ngb graphs with ngb-patch and probe verification.
---

# Agent patch loop

Use when an agent must edit a NanoGraph without reading golden patch fixtures.

## Tools

| Tool | Role |
| --- | --- |
| `tools/bin/ngb-patch` | Apply `--off` + `--pair old:new` to genesis `.ngb` |
| `tools/bin/ngb-parse --json` | Validate patched file; read `invariant` on failure |
| `tools/bin/nano-probe diff` | Compare genesis vs patched |
| `tools/bin/nano-probe disassemble` | Instruction overlay for author feedback |
| `tools/bin/nano-probe trace` | Patch chain steps |

## Loop

1. Read goal and genesis `fixtures/<program>.ngb`.
2. Propose `ngb-patch` command with delta pairs only.
3. Run `ngb-parse --json` on output.
4. On failure, fix delta from `invariant` field only.
5. Run behavioral proof script or `run-linux-elf-capture.sh` when stdout matters.
6. Run `nano-probe diff` genesis patched for audit.

## Example (add_two exit 3)

```bash
tools/bin/ngb-patch fixtures/add_two.ngb /tmp/patched.ngb \
  --off 127 --pair 01:02 --patch-id 1 --timestamp 1700000000
tools/bin/ngb-parse --json /tmp/patched.ngb
./scripts/run-linux-elf.sh /tmp/patched.ngb
```

## Forbidden during eval tasks

- `fixtures/*_patched*`
- `*-patch-fixture.c` sources
