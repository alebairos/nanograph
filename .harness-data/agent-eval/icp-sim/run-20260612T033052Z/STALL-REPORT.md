step=1 surface=README action=read README.md (entrypoint, ICP, quick start, adoption path) verdict=ok
note=Clear who this is for; quick start lists doctor, demo, fit, verify, mint without dumping internals.

step=2 surface=docs action=read docs/ICP.md (linked from README "Who it is for") verdict=ok
note=The UTF-8 overlong story matches my fear — silent acceptance bugs that unit tests miss; round_trip as self-oracle is the hook.

step=3 surface=CLI action=./nanograph doctor verdict=stall
note=Command could not be executed in this evaluation session (shell harness rejected ./nanograph before start); ls shows tools/bin has only .c sources (no ngb-pack binary yet) and /var/run/docker.sock missing while ~/.colima/default/docker.sock exists — README says Docker but not Colima DOCKER_HOST setup.

step=4 surface=README action=read README quick start ./nanograph demo utf8 (blocked; did not run) verdict=friction
note=Cannot confirm demo output without a working doctor/runner; would need Linux ELF via docker, qemu, or native Linux per scripts/check-linux-runner.sh.

step=5 surface=CLI action=./nanograph fit fixtures/fit-cases/rust-base64-invalid-last.fit (blocked; did not run) verdict=friction
note=score-case-fit.sh is pure bash over .fit files and likely works without docker, but I could not execute it here; rust-base64 case scores oracle_hardness=2 silent_survival=2 on paper.

step=6 surface=CLI action=./nanograph verify fixtures/metamorphic/utf8_overlong.ngb fixtures/metamorphic/utf8.req (blocked; did not run) verdict=friction
note=Docs and METAMORPHIC-RELATIONS.md promise verdict=reject witness hex=C080 for overlong UTF-8; fixtures exist on disk but verify was not run.

step=7 surface=ADOPTION action=read docs/ADOPTION.md (README adoption path steps 2 and 6) verdict=ok
note=Minimal workflow and "Bring your own codec" are the real path; explicit warning not to ./nanograph mint c maintainer-home/hex.c.

step=8 surface=own-code action=read maintainer-home/hex.c verdict=ok
note=Hosted C with hex_encode/hex_decode; no _start, no argv driver — cannot be the verify artifact without transcription.

step=9 surface=docs action=read fixtures/templates/icp-hex-specimen.c verdict=friction
note=Freestanding syscall specimen, not my file; comment claims transcription of maintainer-home/hex.c but I must rewrite or audit nibble logic in an alien driver shape.

step=10 surface=docs action=read fixtures/templates/icp-hex-roundtrip.req verdict=ok
note=Six lines: relation=round_trip domain=bytes wire=hex encode=enc decode=dec reject=REJECT — readable without opening metamorphic-verify.sh.

step=11 surface=docs action=read docs/specs/METAMORPHIC-RELATIONS.md section "Generic byte domain (domain=bytes, G81)" verdict=ok
note=ADOPTION pointed here for domain=bytes wire=hex; confirms I do not need a new hard-coded domain name.

step=12 surface=CLI action=./nanograph mint c fixtures/templates/icp-hex-specimen.c /tmp/my-hex.ngb (blocked; did not run) verdict=stall
note=ls /tmp/my-hex.ngb: No such file or directory; mint-one-elf.sh needs docker + gcc:13 image + make tools/bin/ngb-pack — documented in LANG-PACKS.md but not in README quick start; no documented way to verify my codec without mint succeeding.

step=13 surface=CLI action=./nanograph verify /tmp/my-hex.ngb fixtures/templates/icp-hex-roundtrip.req (blocked; did not run) verdict=stall
note=Cannot reach verify without /tmp/my-hex.ngb; goal was decode(encode(x)) round-trip on maintainer-home/hex.c and I never got an artifact for my codec.

ICP-SIM RESULT completed=no first_stall=3 friction=5
