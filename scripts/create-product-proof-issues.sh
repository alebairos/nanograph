#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

./scripts/setup-product-proof-labels.sh

create_issue() {
  local pstep="$1"
  local title="$2"
  local body="$3"
  local area="${4:-harness}"
  gh issue create \
    --title "P${pstep}: ${title}" \
    --label "milestone:p$(printf '%02d' "$pstep"),type:product-proof,meta:product-program,area:${area}" \
    --body "$body"
}

create_issue 1 "Docs and harness sync (M5–M7 truth)" "$(cat <<'EOF'
## Problem

NANO-GOALS, MILESTONES, milestone-gate, and ISSUE-LABELS lag M5–M7 shipped work.

## Acceptance

- [ ] `NANO-GOALS.md` reflects G1–G7 complete; points to PRODUCT-PROOF.md
- [ ] `MILESTONES.md` includes M5–M7 verification commands
- [ ] `milestone-gate` skill lists all current `check-*-proof.sh` scripts
- [ ] `ISSUE-LABELS.md` includes m5–m7 and product-proof labels
- [ ] `./scripts/check-canonical-drift.sh` passes

## Product proof

Bound step: P01

## Verification

- [ ] `./scripts/check-canonical-drift.sh`
- [ ] `./scripts/check-all-proofs.sh` (after P03) or individual proofs until then
EOF
)" docs

create_issue 2 "Link PRODUCT-PROOF spec in canonical map" "$(cat <<'EOF'
## Problem

Product proof program exists but is not in the canonical read order.

## Acceptance

- [ ] `docs/CANONICAL.md` links `docs/specs/PRODUCT-PROOF.md`
- [ ] `AGENTS.md` mentions P01–P20 queue when present

## Product proof

Bound step: P02

## Verification

- [ ] `./scripts/check-canonical-drift.sh`
EOF
)" docs

create_issue 3 "Unified proof runner check-all-proofs.sh" "$(cat <<'EOF'
## Problem

Proof scripts exist but no single local command mirrors CI.

## Acceptance

- [ ] `scripts/check-all-proofs.sh` runs hello, add_two, patched, diff, disassemble, print_42 proofs
- [ ] CI workflow calls `check-all-proofs.sh` instead of listing each script (or wraps it)

## Product proof

Bound step: P03

## Verification

- [ ] `./scripts/check-all-proofs.sh`
EOF
)" harness

create_issue 4 "ngb-patch CLI for agent apply path" "$(cat <<'EOF'
## Problem

`ngb_apply_patch()` exists in C but agents have no CLI to apply deltas with validation.

## Acceptance

- [ ] `tools/bin/ngb-patch` reads genesis `.ngb`, delta spec, emits patched `.ngb`
- [ ] Validates I1–I6 before write; non-zero exit on failure
- [ ] Prints `graph_root_hash=` on success
- [ ] `scripts/check-ngb-patch-cli.sh` with add_two canonical patch case

## Product proof

Bound step: P04

## Verification

- [ ] `./scripts/check-ngb-patch-cli.sh`
- [ ] `./scripts/check-all-proofs.sh`
EOF
)" ngb

create_issue 5 "ngb-parse --json structured errors" "$(cat <<'EOF'
## Problem

Agents need machine-readable invariant failures, not stderr prose.

## Acceptance

- [ ] `ngb-parse --json <file>` emits `{ok, invariant, message, graph_root_hash?}` 
- [ ] Golden JSON for one failure per I1–I6 where feasible
- [ ] `scripts/check-ngb-parse-json.sh`

## Product proof

Bound step: P05

## Verification

- [ ] `./scripts/check-ngb-parse-json.sh`
EOF
)" ngb

create_issue 6 "nano-probe trace patch chain replay" "$(cat <<'EOF'
## Problem

audit-log lists patches; trace should replay genesis→current for humans and agents.

## Acceptance

- [ ] `nano-probe trace <file.ngb>` deterministic stdout format v0
- [ ] Golden for add_two_patched.ngb
- [ ] `scripts/check-probe-trace.sh` + CI step

## Product proof

Bound step: P06

## Verification

- [ ] `./scripts/check-probe-trace.sh`
EOF
)" probe

create_issue 7 "Agent patch skill and workflow doc" "$(cat <<'EOF'
## Problem

No documented agent workflow tying parse feedback, patch CLI, and probes.

## Acceptance

- [ ] `.cursor/skills/ngb-agent-patch/SKILL.md` with step-by-step patch loop
- [ ] References P04 CLI and P05 JSON errors
- [ ] Example task: add_two immediate 1→2 without hand-editing fixtures

## Product proof

Bound step: P07

## Verification

- [ ] Skill file present; example command block runs manually
EOF
)" harness

create_issue 8 "print_42 patched to 43" "$(cat <<'EOF'
## Problem

Only exit-code programs were patched; stdout mutation unproven.

## Acceptance

- [ ] Patch `42\n` → `43\n` via data or code delta
- [ ] `fixtures/print_42_patched.ngb` + audit/disassemble goldens
- [ ] `scripts/check-print-42-patched-proof.sh` P1–P4

## Product proof

Bound step: P08

## Verification

- [ ] `./scripts/check-print-42-patched-proof.sh`
EOF
)" ngb

create_issue 9 "add_two two-patch chain exit 4" "$(cat <<'EOF'
## Problem

Single-patch I6 proven; multi-patch agent edits need a frozen chain.

## Acceptance

- [ ] Genesis → exit 3 → exit 4 via two patches
- [ ] I6 validates full chain
- [ ] probe trace golden shows 2 patches
- [ ] `scripts/check-add-two-chain-proof.sh`

## Product proof

Bound step: P09

## Verification

- [ ] `./scripts/check-add-two-chain-proof.sh`
EOF
)" ngb

create_issue 10 "Invalid patch rejection suite" "$(cat <<'EOF'
## Problem

Trust requires loud failure on illegal patches.

## Acceptance

- [ ] `scripts/check-patch-reject.sh` cases: OOB delta, odd delta_len, corrupt magic
- [ ] Each case expects specific invariant or error exit
- [ ] CI step

## Product proof

Bound step: P10

## Verification

- [ ] `./scripts/check-patch-reject.sh`
EOF
)" ngb

create_issue 11 "Wrong precondition hash rejection" "$(cat <<'EOF'
## Problem

I6 must block patches that lie about graph history.

## Acceptance

- [ ] Cases in reject suite for bad precondition_hash
- [ ] Document expected `I6:patch_chain` JSON when --json lands

## Product proof

Bound step: P11

## Verification

- [ ] `./scripts/check-patch-reject.sh` (extended)
EOF
)" ngb

create_issue 12 "Agent eval harness skeleton" "$(cat <<'EOF'
## Problem

Need reproducible agent task runner before real evals.

## Acceptance

- [ ] `scripts/agent-eval/README.md` defines rubric
- [ ] `scripts/agent-eval/run-task.sh` logs iterations, success, artifacts dir
- [ ] Dry-run mode completes without API keys

## Product proof

Bound step: P12

## Verification

- [ ] `./scripts/agent-eval/run-task.sh --dry-run`
EOF
)" harness

create_issue 13 "Task A - agent patch add_two to exit 4" "$(cat <<'EOF'
## Problem

Core hypothesis test: agent converges on valid patch without golden leakage.

## Acceptance

- [ ] Task spec in `scripts/agent-eval/task-add-two-exit4.md`
- [ ] Success = exit 4 + parse ok + audit precondition chain
- [ ] Agent may use ngb-patch, ngb-parse --json, nano-probe diff
- [ ] Agent may NOT read `fixtures/add_two_patched.ngb` or patch fixture source

## Product proof

Bound step: P13

## Verification

- [ ] Manual or harness run documented in eval log artifact
EOF
)" harness

create_issue 14 "Task B - agent patch print_42 to 43" "$(cat <<'EOF'
## Problem

Stdout patch is harder than exit-code patch; tests rodata/code deltas.

## Acceptance

- [ ] `scripts/agent-eval/task-print-42-43.md`
- [ ] Success = stdout `43\n`, exit 0, probes match
- [ ] Same tool constraints as Task A

## Product proof

Bound step: P14

## Verification

- [ ] Eval log artifact
EOF
)" harness

create_issue 15 "ELF hex baseline tasks" "$(cat <<'EOF'
## Problem

Must compare agent effort against editing raw ELF without NanoGraph.

## Acceptance

- [ ] `scripts/agent-eval/task-elf-baseline-exit4.md`
- [ ] `scripts/agent-eval/task-elf-baseline-43.md`
- [ ] Same success criteria, raw `fixtures/*_elf.bin` only

## Product proof

Bound step: P15

## Verification

- [ ] Baseline task docs complete
EOF
)" harness

create_issue 16 "Metrics comparison ngb vs ELF" "$(cat <<'EOF'
## Problem

P20 verdict needs evidence, not intuition.

## Acceptance

- [ ] `docs/specs/AGENT-EVAL-METRICS.md` table: success, iterations, wall time, tool calls
- [ ] Filled from P13–P15 runs (placeholders OK until runs complete)

## Product proof

Bound step: P16

## Verification

- [ ] Doc reviewed against PRODUCT-PROOF falsification criteria
EOF
)" docs

create_issue 17 "nanograph-adversary milestone gate" "$(cat <<'EOF'
## Problem

Script green is not enough for trust-boundary milestones.

## Acceptance

- [ ] `.cursor/agents/nanograph-adversary.md` read-only interrogate wrapper
- [ ] `AGENT-HARNESS.md` documents optional gate after P04+ product-proof steps
- [ ] NanoGraph-specific rubric (I1–I6, goldens, spec drift)

## Product proof

Bound step: P17

## Verification

- [ ] Agent file present; dry-run on last merged PR
EOF
)" harness

create_issue 18 "NGB C API integration doc" "$(cat <<'EOF'
## Problem

Embedders and agent runtimes need a stable surface beyond CLI binaries.

## Acceptance

- [ ] `docs/specs/NGB-C-API.md` lists public functions in `ngb.h` + probe entry points
- [ ] Ownership, error codes, thread safety stance documented

## Product proof

Bound step: P18

## Verification

- [ ] Review against actual headers
EOF
)" docs

create_issue 19 "Loop driver product-proof queue mode" "$(cat <<'EOF'
## Problem

Autonomous `/loop` needs to bind P01–P20 sequentially.

## Acceptance

- [ ] `loop_state.json` schema adds `product_proof_step` optional field
- [ ] `nanograph-loop-driver` reads PRODUCT-PROOF.md for next open P issue
- [ ] `07-harness-loop.mdc` mentions product-proof queue

## Product proof

Bound step: P19

## Verification

- [ ] `./scripts/harness-session-start.sh` reports current P step
EOF
)" harness

create_issue 20 "ADR product verdict continue pivot or kill" "$(cat <<'EOF'
## Problem

Program exists to force a decision.

## Acceptance

- [ ] `docs/adr/ADR-001-product-verdict.md` with Continue / Pivot / Kill
- [ ] Cites P13–P16 metrics and falsification criteria from PRODUCT-PROOF.md
- [ ] Lists explicit next investment or archive steps

## Product proof

Bound step: P20

## Verification

- [ ] ADR merged; GitHub issue comment links evidence artifacts
EOF
)" docs

echo "OK: product proof issues created"
