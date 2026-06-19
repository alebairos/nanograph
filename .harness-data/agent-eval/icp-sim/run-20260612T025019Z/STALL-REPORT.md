step=1 surface=README action=read README.md verdict=ok
note=Clear entrypoint; ICP paragraph matches me; quick-start commands are copy-pasteable.

step=2 surface=README action=read docs/ICP.md (linked from README) verdict=ok
note=Codec-maintainer pitch lands; round_trip as self-oracle is exactly my decode(encode(x)) worry.

step=3 surface=ADOPTION action=read docs/ADOPTION.md (linked from README adoption path) verdict=ok
note=Minimal workflow mirrors README; still no detail on writing a .req for my own function.

step=4 surface=CLI action=./nanograph doctor verdict=ok
note=nanograph doctor OK runner=docker — prerequisite Docker was already running.

step=5 surface=CLI action=./nanograph demo utf8 verdict=ok
note=Demo is compelling; the green unit-test vs round_trip reject contrast is the silent-bug story I lived through.

step=6 surface=CLI action=./nanograph fit fixtures/fit-cases/rust-base64-invalid-last.fit verdict=ok
note=case=rust-base64-invalid-last gate=FIT fit_score=8/8 — scoring works without touching my code.

step=7 surface=CLI action=./nanograph verify fixtures/metamorphic/utf8_overlong.ngb fixtures/metamorphic/utf8.req verdict=ok
note=verdict=reject with hex=C080 witness — bundled verify path works as README claims.

step=8 surface=ADOPTION action=follow adoption step 3: ./nanograph mint c fixtures/metamorphic/bswap32.c /tmp/bswap32.ngb verdict=ok
note=mint-one-elf OK /tmp/bswap32.ngb — first Docker pull of gcc:13 took a minute but mint succeeded.

step=9 surface=ADOPTION action=follow adoption step 4: ./nanograph verify /tmp/bswap32.ngb fixtures/metamorphic/bswap32.req verdict=ok
note=verdict=accept hash=... relation=involution — tutorial loop closes on their specimen, not mine.

step=10 surface=own-code action=read maintainer-home/hex.c verdict=ok
note=My codec is hosted C (comment says so); I want round_trip on decode(encode(b))==b for accepted hex strings.

step=11 surface=ADOPTION action=adoption step 2 "Define a property in .req" — search README and ADOPTION for .req authoring verdict=friction
note=Neither doc shows .req fields or a hex example; LANG-PACKS is linked but reads like contributor plumbing, not maintainer onboarding.

step=12 surface=docs action=read docs/specs/LANG-PACKS.md (README adoption pointer) verdict=friction
note=Learned minted ELF must be freestanding x86_64 with enc/dec argv modes — my hex.c is not that and README never said transcribe first.

step=13 surface=CLI action=./nanograph mint c maintainer-home/hex.c /tmp/hex.ngb verdict=friction
note=Docker gcc failed: undefined reference to `_start` — obvious in hindsight, but adoption said `mint c <src.c>` with no hosted-vs-freestanding warning on the CLI.

step=14 surface=docs action=read fixtures/metamorphic/utf8.c and fixtures/metamorphic/utf8.req as template verdict=friction
note=Had to open fixtures/ to learn the freestanding driver ABI; docs should have told me this before I wasted a mint attempt.

step=15 surface=docs action=read docs/specs/METAMORPHIC-RELATIONS.md (found via LANG-PACKS contribution checklist, not adoption path) verdict=friction
note=round_trip needs encode/dec/reject/wire keys — useful, but buried; still no maintainer recipe from hosted library to specimen.

step=16 surface=CLI action=./nanograph fit fixtures/fit-cases/go-hex-decode-dst.fit verdict=ok
note=case=go-hex-decode-dst gate=FIT fit_score=7/8 — hex decode is scored as a fit, so the product thinks my problem class belongs here.

step=17 surface=CLI action=draft hex.req (relation=round_trip encode=enc decode=dec wire=hex reject=REJECT domain=hex) and ./nanograph verify /tmp/hex.ngb hex.req verdict=friction
note=Even after mentally transcribing hex.c to a utf8-style driver, verify dies before running: metamorphic-verify: unsupported domain=hex.

step=18 surface=docs action=read scripts/agent-eval/metamorphic-verify.sh gen_probes case list verdict=friction
note=Domains are hardcoded (utf8, capnproto_base64, ...); no doc explains how a maintainer registers hex probes without editing the verifier.

step=19 surface=own-code action=search adoption docs and ./nanograph help for propose-req / extractor / blind-domain workflow verdict=stall
note=ICP.md admits extractor is agent-delegated not product; propose-req.py lives under spike/ and is not in README/ADOPTION; no documented way to verify my codec end to end.

ICP-SIM RESULT completed=no first_stall=19 friction=7
