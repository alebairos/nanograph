# Two-agent probe protocol (P14)

Lightweight author/auditor loop folded into product proof step P14. This is the first **real use case** under test: one agent patches at metal speed, another verifies through deterministic probes. Humans are not in the hot path.

## Roles

| Role | May write | May read | Emits |
| --- | --- | --- | --- |
| **Author** | Patch deltas, patched `.ngb` | Auditor `probe_bundle` only | `patch_request`, `patched.ngb` |
| **Auditor** | Nothing on disk | Genesis + author artifacts | `probe_bundle`, `accept` or `reject` |

The auditor never patches. The author never runs behavioral proofs without auditor accept.

## Message shapes

### `patch_request` (author → auditor)

```text
precondition_hash=<64 hex>
delta_off=<u32>
delta_pairs=<old new pairs, space-separated hex bytes>
```

### `probe_bundle` (auditor → author)

Deterministic NanoProbe stdout concatenated in fixed order:

```text
--- parse ---
{ngb-parse --json output}
--- disassemble ---
{nano-probe disassemble output}
--- diff ---
{nano-probe diff genesis.ngb patched.ngb output}
--- audit-log ---
{nano-probe audit-log patched.ngb output}
```

No natural-language summary. The bundle is the message.

### `verdict` (auditor → author)

```text
verdict=accept graph_root_hash=<64 hex>
```

or

```text
verdict=reject invariant=<I1-I6|behavior|stdout> detail=<one line>
```

## P14 task (print_42 → 43)

| Field | Value |
| --- | --- |
| Genesis | `fixtures/print_42.ngb` |
| Goal | stdout `43\n`, exit 0 |
| Author tools | `ngb-patch`, read `probe_bundle` |
| Auditor tools | `ngb-parse --json`, `nano-probe disassemble`, `diff`, `audit-log`, `run-linux-elf-capture.sh` |
| Forbidden | Author reads `fixtures/print_42_patched*` or hand-authored patch goldens |

## Success rubric (P14)

1. Author completes in ≤5 patch rounds (auditor reject → author retry counts as one round).
2. Final `patched.ngb` passes `ngb-parse` and P3 stdout check.
3. Auditor `diff` shows only intended byte changes (data or code).
4. Eval log records rounds, wall time, and probe_bundle hashes per round.

## Kill signal for two-agent mode

Auditor rejects are unactionable (author cannot fix from bundle alone), or two-agent needs more rounds than single-agent Task B with the same tools. Then the split is overhead, not leverage.

## Depends on

- P04 `ngb-patch` CLI
- P05 `ngb-parse --json`
- P06 `nano-probe trace` (optional in bundle for patched chains)
- P08 print_42 patched fixture exists as **harness oracle only** (not author-readable during eval)
