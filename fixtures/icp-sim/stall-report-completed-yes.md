step=1 surface=README action=read README.md verdict=ok
note=ICP section matches me; quick-start commands are listed in a sensible order

step=2 surface=README action=read README.md prerequisites verdict=ok
note=Docker called out once; easy to skim past if you already have a Mac dev box

step=3 surface=CLI action=./nanograph doctor verdict=ok
note=nanograph doctor OK runner=docker — would have been stuck without Colima already up

step=4 surface=CLI action=./nanograph demo utf8 verdict=ok
note=The unit-test-green / relation-reject contrast is the first thing that felt real

step=5 surface=CLI action=./nanograph fit fixtures/fit-cases/rust-base64-invalid-last.fit verdict=ok
note=gate=FIT fit_score=8/8 — scores someone else's base64 bug, not my hex, but the rubric is readable

step=6 surface=CLI action=./nanograph verify fixtures/metamorphic/utf8_overlong.ngb fixtures/metamorphic/utf8.req verdict=ok
note=verdict=reject with witness hex=C080 — actionable bytes, not a coverage percent

step=7 surface=README action=read README.md adoption path verdict=ok
note=Step 2 points at ADOPTION.md for transcribing a codec; good, that's my actual goal

step=8 surface=ADOPTION action=read docs/ADOPTION.md verdict=ok
note=Minimal workflow mirrors README; "Bring your own codec" is where the pitch gets tested

step=9 surface=own-code action=read maintainer-home/hex.c verdict=ok
note=Hosted C with hex_encode/hex_decode; nothing here looks like an ELF entry point

step=10 surface=CLI action=./nanograph mint c maintainer-home/hex.c /tmp/my-hex-bad.ngb verdict=friction
note=Linker error: undefined reference to `_start` — ADOPTION.md warns against this but I tried anyway before finishing that section

step=11 surface=ADOPTION action=read docs/ADOPTION.md section Bring your own codec verdict=ok
note=Freestanding wall is explicit; templates table under fixtures/templates/ is the documented off-ramp

step=12 surface=docs action=read fixtures/templates/icp-hex-specimen.c verdict=friction
note=Naked _start and raw syscalls — ADOPTION says "adapt encode/decode logic" but not how to write this harness from scratch

step=13 surface=docs action=read docs/specs/METAMORPHIC-RELATIONS.md section domain=bytes verdict=friction
note=Needed wire=hex and gen_bytes budget semantics; ADOPTION mentions wire=hex in one line only

step=14 surface=own-code action=compare maintainer-home/hex.c to icp-hex-specimen.c verdict=ok
note=Nibble tables match; specimen speaks argv hex wire, my library speaks byte buffers — same failure modes on bad digits

step=15 surface=CLI action=./nanograph mint c fixtures/templates/icp-hex-specimen.c /tmp/my-hex.ngb verdict=ok
note=mint-one-elf OK /tmp/my-hex.ngb — Docker pull on first mint cost a minute

step=16 surface=CLI action=./nanograph verify /tmp/my-hex.ngb fixtures/templates/icp-hex-roundtrip.req verdict=ok
note=verdict=accept relation=round_trip accepted=... separator=none — round-trip holds on the transcribed specimen

step=17 surface=own-code action=reflect on completed verification verdict=ok
note=I verified the template specimen that already embeds my logic, not a specimen I wrote solo; good enough for a first pass, would want a shorter harness story before I'd trust this on a production fork

ICP-SIM RESULT completed=yes first_stall=none friction=3
