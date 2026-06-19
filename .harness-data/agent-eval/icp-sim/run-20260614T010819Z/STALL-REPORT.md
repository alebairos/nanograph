step=1 surface=README action=read README.md verdict=ok
note=Wedge is clear; quick start lists doctor, demo, fit, verify, mint in order

step=2 surface=README action=read README prerequisites verdict=ok
note=Needs make plus Docker or qemu for Linux ELF; fine on macOS if Docker is up

step=3 surface=README action=read README adoption path verdict=ok
note=Six-step ladder ends at backtests; points to docs/ADOPTION.md for onboarding

step=4 surface=ADOPTION action=read docs/ADOPTION.md verdict=ok
note=Minimal workflow mirrors README; bring-your-own-code section names templates

step=5 surface=ADOPTION action=read docs/ADOPTION.md Bring your own codec verdict=ok
note=Explicit warning not to mint maintainer-home/hex.c; start from icp-hex templates

step=6 surface=own-code action=read maintainer-home/hex.c verdict=ok
note=Hosted static encode/decode only; no _start, no argv driver

step=7 surface=docs action=read fixtures/templates/icp-hex-specimen.c verdict=ok
note=Freestanding argv enc/dec driver; comment claims transcription of my hex.c

step=8 surface=docs action=read fixtures/templates/icp-hex-roundtrip.req verdict=ok
note=relation=round_trip domain=bytes wire=hex; matches how I think about the property

step=9 surface=docs action=read docs/specs/METAMORPHIC-RELATIONS.md verdict=ok
note=round_trip family documented; argv_mode entry shape not spelled out for wire=hex

step=10 surface=CLI action=./nanograph doctor verdict=friction
note=Execution blocked in this session; read scripts/nanograph to learn doctor prints runner=

step=11 surface=CLI action=./nanograph demo utf8 verdict=friction
note=Cannot run demo; read scripts/demo-utf8.sh to see reject witness C080 narrative

step=12 surface=CLI action=./nanograph mint c maintainer-home/hex.c /tmp/hosted-hex.ngb verdict=friction
note=Skipped live run; read scripts/mint-one-elf.sh and confirmed -nostdlib would fail on hosted C

step=13 surface=CLI action=./nanograph mint c fixtures/templates/icp-hex-specimen.c /tmp/my-hex.ngb verdict=friction
note=Documented one-liner in ADOPTION but cannot execute mint here to produce /tmp/my-hex.ngb

step=14 surface=CLI action=./nanograph verify /tmp/my-hex.ngb fixtures/templates/icp-hex-roundtrip.req verdict=stall
note=No /tmp/my-hex.ngb without mint; no documented offline verify path; cannot confirm round_trip on my codec

step=15 surface=own-code action=transcribe maintainer-home/hex.c into freestanding specimen verdict=stall
note=ADOPTION says copy my logic but every example mints fixtures/templates/ in-repo; no /tmp transcription walkthrough

ICP-SIM RESULT completed=no first_stall=14 friction=4
