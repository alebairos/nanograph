# capnproto decodeBase64 real-history backtest (G39)

Second ICP follow-through from the G32 shortlist (`capnproto-base64.fit` 8/8). It runs capnproto/kj's libb64-derived base64 decode on real inputs, native on the Linux runner, with no simulation.

## The bug

capnproto `c++/src/kj/encoding.c++`, `decodeBase64` (public-domain libb64 core). Before the fix, invalid characters and padding mistakes were skipped or ignored and decode never failed. Fix PR #595 (`f3e0ed2`, merge `6a59486`) adds `hadErrors` reporting aligned with WHATWG `atob` rules.

| Revision | SHA | behavior |
| --- | --- | --- |
| buggy parent | `9306bc0` | skip invalid/padding bytes, never fail |
| fix | `f3e0ed2` | `hadErrors` on bad charset and padding |

Upstream: https://github.com/capnproto/capnproto

## Faithfulness and its limit

`fixtures/metamorphic/capnproto_base64.c` transcribes libb64 encode/decode from capnproto's `encoding.c++` into freestanding C. The permissive skip-invalid loop is the pre-fix libb64 path; the strict table, `had_errors`, and padding checks are the post-fix path. Encode is shared. This is not a verbatim build of capnproto's C++, which depends on kj headers and is not freestanding. The honest claim is a faithful transcription behind a trusted driver (`_start`, argv parse, print), the same standard as G34.

`mint-backtest.sh` strips the `#if !defined(INVALID_OK)` strict dispatcher and compiles rev2 with `-DINVALID_OK` so the permissive decode is selected.

## Pre-registered property

`round_trip` via `fixtures/metamorphic/capnproto_base64.req`: `enc(dec(b)) == b` for accepted `b`. The wire is the base64 string as ASCII bytes (`wire=ascii`), so witness hex is the UTF-8/ASCII encoding of the probe (e.g. `Zm9v@` → `5a6d397640`).

Witness `5a6d397640` (`Zm9v@`). The buggy revision skips `@`, decodes to `foo` (`666f6f`), re-encodes to `Zm9v`, which differs. The honest revision rejects `Zm9v@` outright. Both accept canonical `Zm9v` and `Y29yZ2U=`.

## Mint

```
./scripts/mint-backtest.sh fixtures/metamorphic/capnproto_base64.c INVALID_OK \
  fixtures/backtest/capnproto-base64 fixtures/metamorphic/capnproto_base64.req invalidok
```

## Result

Catch. Timeline accept, reject (`hex=5a6d397640`), accept. Fix returns to revision one's `graph_root_hash`.
