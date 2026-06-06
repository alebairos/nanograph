CC ?= cc
CFLAGS ?= -std=c11 -Wall -Wextra -O2 -Ingb
ROOT := $(abspath ..)

LIB_SRCS := ngb/sha256.c ngb/canonical_elf.c ngb/hello_elf.c ngb/add_two_elf.c \
            ngb/print_42_elf.c ngb/pack.c ngb/parse.c ngb/hash_root.c \
            ngb/patch.c ngb/microop.c ngb/status.c
PROBE_SRCS := probe/audit_log.c probe/diff.c probe/disassemble.c probe/trace.c
LIB_OBJS := $(LIB_SRCS:.c=.o)
PROBE_OBJS := $(PROBE_SRCS:.c=.o)

BINS := bin/ngb-pack bin/ngb-parse bin/ngb-patch bin/ngb-extract bin/hello-fixture \
        bin/add-two-fixture bin/add-two-patch-fixture bin/print-42-fixture \
        bin/print-42-patch-fixture bin/add-two-chain-fixture bin/ngb-fuzz \
        bin/ca-rule30-fixture bin/ca-rule30-patch-fixture \
        bin/nano-probe bin/conf-eval bin/ngb-microop

.PHONY: all clean test

all: $(BINS)

ngb/%.o: ngb/%.c ngb/ngb.h ngb/sha256.h
	$(CC) $(CFLAGS) -c $< -o $@

probe/%.o: probe/%.c probe/audit_log.h probe/diff.h probe/disassemble.h probe/trace.h ngb/ngb.h
	$(CC) $(CFLAGS) -c $< -o $@

bin/ngb-pack: bin/ngb-pack.c $(LIB_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

bin/ngb-parse: bin/ngb-parse.c $(LIB_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

bin/ngb-patch: bin/ngb-patch.c $(LIB_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

bin/hello-fixture: bin/hello-fixture.c $(LIB_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

bin/add-two-fixture: bin/add-two-fixture.c $(LIB_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

bin/add-two-patch-fixture: bin/add-two-patch-fixture.c $(LIB_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

bin/print-42-fixture: bin/print-42-fixture.c $(LIB_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

bin/print-42-patch-fixture: bin/print-42-patch-fixture.c $(LIB_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

bin/add-two-chain-fixture: bin/add-two-chain-fixture.c $(LIB_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

bin/ca-rule30-fixture: bin/ca-rule30-fixture.c $(LIB_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

bin/ca-rule30-patch-fixture: bin/ca-rule30-patch-fixture.c $(LIB_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

bin/ngb-fuzz: bin/ngb-fuzz.c $(LIB_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

bin/ngb-extract: bin/ngb-extract.c
	$(CC) $(CFLAGS) $^ -o $@

bin/conf-eval: bin/conf-eval.c
	$(CC) $(CFLAGS) $^ -o $@

bin/ngb-microop: bin/ngb-microop.c $(LIB_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

bin/nano-probe: bin/nano-probe.c $(LIB_OBJS) $(PROBE_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

clean:
	rm -f $(LIB_OBJS) $(PROBE_OBJS) $(BINS)

test: all
	$(ROOT)/scripts/check-ngb-roundtrip.sh
