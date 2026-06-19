step=1 surface=README action=read README.md verdict=ok
note=Clear ICP pitch and a numbered adoption path; I know where to click next.

step=2 surface=CLI action=./nanograph doctor verdict=stall
note=runner probe failed (runner=docker). Start docker/colima, install qemu-x86_64, or use native Linux.

step=3 surface=CLI action=./nanograph demo utf8 verdict=stall
note=demo-utf8: runner returned no output; run ./nanograph doctor — dead end before the wedge demo runs.

step=4 surface=CLI action=./nanograph fit fixtures/fit-cases/rust-base64-invalid-last.fit verdict=ok
note=fit_score=8/8 gate=FIT — rubric works without Docker; first thing that felt useful.

step=5 surface=ADOPTION action=read docs/ADOPTION.md verdict=ok
note=Minimal workflow mirrors README; help lists the commands I need.

step=6 surface=CLI action=./nanograph help verdict=ok
note=Surface is small and readable; mint/verify/fit/doctor all there.

step=7 surface=CLI action=./nanograph fit fixtures/fit-cases/rust-base64-invalid-last.fit verdict=ok
note=Repeated ADOPTION step 2; same 8/8. Confirms fit is stable.

step=8 surface=CLI action=./nanograph verify fixtures/metamorphic/utf8_overlong.ngb fixtures/metamorphic/utf8.req verdict=stall
note=metamorphic-verify: round_trip accepted 0 inputs (domain has no canonical sample) — README quick-start verify ran but produced no verdict I can act on.

step=9 surface=CLI action=./nanograph mint c fixtures/metamorphic/bswap32.c /tmp/bswap32.ngb verdict=stall
note=permission denied while trying to connect to the docker API at unix:///Users/alebairos/.colima/default/docker.sock

step=10 surface=docs action=read docs/specs/LANG-PACKS.md (README adoption link) verdict=friction
note=My maintainer-home/hex.c is hosted library code; the pack contract wants freestanding x86_64 ELF with enc/dec argv modes — not mentioned in ADOPTION step 3.

step=11 surface=docs action=read docs/specs/METAMORPHIC-RELATIONS.md (linked from LANG-PACKS) verdict=friction
note=ADOPTION says "define a property in .req" but the kv schema lives here, not in the adoption guide; utf8.req and leb128.req are the templates I need.

step=12 surface=CLI action=./nanograph fit fixtures/fit-cases/go-hex-decode-dst.fit verdict=ok
note=fit_score=7/8 gate=FIT — hex decode bugs are explicitly in scope; good signal for my codec.

step=13 surface=own-code action=./nanograph mint c maintainer-home/hex.c /tmp/hex.ngb verdict=stall
note=Same docker.sock permission denied; cannot mint my file even if it were the right shape.

step=14 surface=own-code action=./nanograph verify fixtures/metamorphic/bswap32.ngb /tmp/hex-roundtrip.req verdict=stall
note=metamorphic-verify: unsupported domain=hex — no documented hex round_trip domain; leb128/utf8 domains exist but not generic hex.

step=15 surface=CLI action=./nanograph verify fixtures/metamorphic/bswap32.ngb fixtures/metamorphic/bswap32.req verdict=friction
note=./scripts/agent-eval/metamorphic-verify.sh: line 689: ys_filled[@]: unbound variable then verdict=reject hash=75467b6310b3 relation=involution witness x=1 fx= ffx= — script error plus empty witness fields; cannot trust this on a broken runner.

step=16 surface=own-code action=attempt decode(encode(x)) round-trip on maintainer-home/hex.c via documented path verdict=stall
note=Blocked twice: cannot mint specimen without Docker, and no hex domain in .req even if I transcribed to freestanding C like utf8.c — adoption path has no documented next step for my codec.

ICP-SIM RESULT completed=no first_stall=2 friction=3
