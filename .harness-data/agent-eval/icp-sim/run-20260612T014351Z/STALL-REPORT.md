step=1 surface=README action=read README.md (entrypoint, quick start, adoption path) verdict=ok
note=Clear pitch for codec maintainers; tells me to run doctor, demo, fit, verify, then ADOPTION.md.

step=2 surface=CLI action=./nanograph doctor verdict=ok
note=Printed "nanograph doctor OK" — but this only checks that docker/qemu exists, not that it runs.

step=3 surface=CLI action=./nanograph demo utf8 verdict=stall
note=Exit 1. Step 1 blew up: "./scripts/demo-utf8.sh: line 57: packed[@]: unbound variable" — all five canonical round-trip checks show "[FAIL] … got " with empty output. Step 3 says "unexpected: honest codec rejected". The wedge demo is broken on my machine.

step=4 surface=CLI action=./nanograph fit fixtures/fit-cases/rust-base64-invalid-last.fit verdict=ok
note=gate=FIT fit_score=8/8 — reassuring for a codec like mine, but this scores a pre-made case file, not my code.

step=5 surface=CLI action=./nanograph verify fixtures/metamorphic/utf8_overlong.ngb fixtures/metamorphic/utf8.req verdict=stall
note=Exit 2: "metamorphic-verify: round_trip accepted 0 inputs (domain has no canonical sample)". README promised a reject witness; I got an error that does not mention docker or how to fix the runner.

step=6 surface=ADOPTION action=read docs/ADOPTION.md verdict=ok
note=Minimal workflow matches README: doctor → fit → mint → verify. Points to LANG-PACKS for language-pack details.

step=7 surface=CLI action=./nanograph fit fixtures/fit-cases/go-hex-decode-dst.fit verdict=ok
note=gate=FIT fit_score=7/8 relation=value_oracle — closest shipped case to a hex codec; still not a path for my tree.

step=8 surface=CLI action=./nanograph mint c fixtures/metamorphic/bswap32.c /tmp/bswap32.ngb verdict=stall
note=Exit 1: "permission denied while trying to connect to the docker API at unix:///Users/alebairos/.colima/default/docker.sock". ADOPTION step 3 requires mint; doctor already said OK, so I have no documented recovery step.

step=9 surface=CLI action=./nanograph verify fixtures/metamorphic/bswap32.ngb fixtures/metamorphic/bswap32.req verdict=stall
note=Exit 1: "./scripts/agent-eval/metamorphic-verify.sh: line 680: ys[@]: unbound variable" — second verify attempt, different opaque failure; still no runner troubleshooting in the docs I have read.

step=10 surface=docs action=read docs/specs/LANG-PACKS.md (linked from README adoption path) verdict=friction
note=Learned my hosted C cannot be minted as-is: artifact must be static freestanding x86_64 Linux with _start, argv enc/dec modes, stdout out. ADOPTION never said "transcribe" in the minimal workflow; ICP.md mentions it but README did not point me there.

step=11 surface=docs action=read docs/specs/METAMORPHIC-RELATIONS.md (not linked from README adoption steps; found via LANG-PACKS cross-ref) verdict=friction
note=round_trip is encode(decode(b))==b, not decode(encode(x)) — the property I wanted is explicitly the weak unit-test direction the UTF-8 demo contrasts against. Domains are a fixed list (utf8, leb128, wabt_leb128, …); no generic hex domain.

step=12 surface=own-code action=read maintainer-home/hex.c; compare to LANG-PACKS artifact contract verdict=stall
note=My codec is hosted C with no _start, no enc/dec argv driver, no reject sentinel. Docs say transcribe and write a .req but give no maintainer-facing recipe, template, or extractor — ADR-020 admits extractor is not productized.

step=13 surface=CLI action=./nanograph mint c maintainer-home/hex.c /tmp/hex.ngb verdict=stall
note=Same docker.sock permission denied. Even if docker worked, mint-one-elf.sh compiles with -nostdlib -ffreestanding; this file would not compile without a full rewrite the docs do not walk through.

step=14 surface=own-code action=attempt to draft hex round_trip .req using METAMORPHIC-RELATIONS schema (relation=round_trip entry=argv_mode encode=enc decode=dec domain=?) verdict=stall
note=No documented domain=hex or wire format for arbitrary hex strings. Supported domains are hard-coded in the verifier; choosing utf8 or leb128 would test the wrong codec. No documented way to verify my hex property end to end.

ICP-SIM RESULT completed=no first_stall=3 friction=2
