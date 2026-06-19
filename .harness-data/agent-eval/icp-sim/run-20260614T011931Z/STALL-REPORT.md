step=1 surface=README action=read README.md verdict=ok
note=Clear wedge pitch; prerequisites mention Docker only indirectly via "Linux ELF runner"

step=2 surface=CLI action=./nanograph doctor verdict=ok
note=Printed nanograph doctor OK runner=docker; first reassurance that this might run on my Mac

step=3 surface=CLI action=./nanograph demo utf8 verdict=ok
note=Demo lands the silent-bug story; I buy the problem statement more than the product yet

step=4 surface=CLI action=./nanograph fit fixtures/fit-cases/rust-base64-invalid-last.fit verdict=ok
note=gate=FIT fit_score=8/8; scoring rubric is opaque but my hex case would score similarly

step=5 surface=CLI action=./nanograph verify fixtures/metamorphic/utf8_overlong.ngb fixtures/metamorphic/utf8.req verdict=friction
note=Exit code 1 with verdict=reject witness line; README never says reject is the expected outcome here

step=6 surface=README action=read adoption path section verdict=ok
note=Numbered steps point to ADOPTION.md and fixtures/templates/ before I touch my codec

step=7 surface=ADOPTION action=read docs/ADOPTION.md verdict=ok
note=Minimal workflow repeats doctor/fit/mint/verify with --expect; Bring your own codec names the freestanding wall upfront

step=8 surface=CLI action=./nanograph mint c fixtures/metamorphic/bswap32.c /tmp/bswap32.ngb verdict=ok
note=mint-one-elf OK; Docker pull on first run was slow but documented nowhere in README

step=9 surface=CLI action=./nanograph verify /tmp/bswap32.ngb fixtures/metamorphic/bswap32.req verdict=ok
note=verdict=accept relation=involution; first time verify exit 0 matched my expectation

step=10 surface=ADOPTION action=read Bring your own codec section verdict=ok
note=Explicit do-not mint maintainer-home/hex.c; table lists icp-hex-specimen.c and icp-hex-roundtrip.req

step=11 surface=own-code action=read maintainer-home/hex.c verdict=ok
note=Hosted libc-style functions only; no _start, no argv driver — matches the freestanding warning

step=12 surface=docs action=read fixtures/templates/icp-hex-specimen.c verdict=ok
note=ADOPTION pointed here; comment claims it transcribes my hex.c into enc/dec argv modes

step=13 surface=docs action=read fixtures/templates/icp-hex-roundtrip.req verdict=ok
note=relation=round_trip domain=bytes wire=hex; I can copy this without writing a .req from scratch

step=14 surface=CLI action=./nanograph mint c fixtures/templates/icp-hex-specimen.c /tmp/my-hex.ngb verdict=friction
note=Had to read scripts/mint-one-elf.sh to learn mint always uses docker --platform linux/amd64; ADOPTION only says "Docker" in prerequisites

step=15 surface=CLI action=./nanograph verify /tmp/my-hex.ngb fixtures/templates/icp-hex-roundtrip.req verdict=friction
note=verdict=accept but I peeked at fixtures/metamorphic/utf8.req first because README verify step trained me not to trust exit codes alone

step=16 surface=own-code action=attempt to verify maintainer-home/hex.c directly verdict=stall
note=ADOPTION forbids minting the hosted file and offers only a template specimen; no documented path to prove my tree's hex.c without manual transcription I must maintain myself

step=17 surface=docs action=read docs/specs/METAMORPHIC-RELATIONS.md section on domain=bytes wire=hex verdict=ok
note=Confirms wire=hex enumeration exists; still no guidance on keeping hosted source and specimen synchronized

ICP-SIM RESULT completed=no first_stall=16 friction=4
