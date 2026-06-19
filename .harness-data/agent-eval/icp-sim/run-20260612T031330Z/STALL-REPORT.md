step=1 surface=README action=read README.md verdict=ok
note=ICP is explicit (codec maintainer); quick start lists doctor, demo, fit, verify, mint in sensible order.

step=2 surface=docs action=read docs/ICP.md (linked from README) verdict=ok
note=Round-trip as self-oracle matches what I want on hex; honest about freestanding specimen + Docker.

step=3 surface=ADOPTION action=read docs/ADOPTION.md (linked from README) verdict=ok
note=Minimal workflow mirrors README; still specimen-first, not "point at my .c file."

step=4 surface=CLI action=./nanograph doctor verdict=ok
note=nanograph doctor OK runner=docker

step=5 surface=CLI action=./nanograph demo utf8 verdict=ok
note=Demo lands the wedge: unit test green on buggy decoder, round_trip rejects with hex=C080 witness — that's the pitch I came for.

step=6 surface=CLI action=./nanograph fit fixtures/fit-cases/rust-base64-invalid-last.fit verdict=ok
note=case=rust-base64-invalid-last relation=round_trip gate=FIT fit_score=8/8 — scoring works, relation name matches my goal.

step=7 surface=CLI action=./nanograph verify fixtures/metamorphic/utf8_overlong.ngb fixtures/metamorphic/utf8.req verdict=ok
note=verdict=reject relation=round_trip witness ... hex=C080 decode=0 reencode=256 — concrete bytes, not a coverage %.

step=8 surface=CLI action=./nanograph mint c fixtures/metamorphic/bswap32.c /tmp/bswap32.ngb verdict=ok
note=mint-one-elf OK /tmp/bswap32.ngb

step=9 surface=CLI action=./nanograph verify /tmp/bswap32.ngb fixtures/metamorphic/bswap32.req verdict=ok
note=verdict=accept hash=... relation=involution probes=... separator=none

step=10 surface=own-code action=read maintainer-home/hex.c verdict=ok
note=My codec is here; header says "Hosted C, not freestanding" — already nervous vs mint c <src.c>.

step=11 surface=CLI action=./nanograph fit fixtures/fit-cases/go-hex-decode-dst.fit verdict=ok
note=case=go-hex-decode-dst relation=value_oracle gate=FIT fit_score=7/8 — hex-ish domain scores, but it's someone else's dst-overflow bug, not my round-trip.

step=12 surface=docs action=README adoption step 2 "Define a property in .req" — no .req template linked verdict=friction
note=Had to open fixtures/metamorphic/utf8.req and capnproto_base64.req to learn encode=enc decode=dec wire= reject= keys.

step=13 surface=docs action=read docs/specs/LANG-PACKS.md (README defers lang-pack details here) verdict=friction
note=Artifact contract wants freestanding _start + argv enc/dec driver; not in ADOPTION.md numbered steps — explains why my file won't just work.

step=14 surface=own-code action=draft /tmp/hex.req (relation=round_trip entry=argv_mode encode=enc decode=dec domain=bytes reject=REJECT eq=exact wire=hex) verdict=friction
note=Inferred from metamorphic examples + LANG-PACKS; no hex round_trip .req shipped in fixtures/metamorphic/.

step=15 surface=CLI action=./nanograph mint c maintainer-home/hex.c /tmp/hex.ngb verdict=friction
note=/usr/bin/ld: warning: cannot find entry symbol _start; defaulting to 0000000000401000 — mint-one-elf OK /tmp/hex.ngb anyway; docs implied mint takes my source, not a 400-line freestanding rewrite.

step=16 surface=CLI action=./nanograph verify /tmp/hex.ngb /tmp/hex.req verdict=stall
note=metamorphic-verify: runner returned no output; run ./nanograph doctor — no enc/dec argv surface in my .c, adoption path has no documented next step to get there from maintainer-home/hex.c.

ICP-SIM RESULT completed=no first_stall=16 friction=4
