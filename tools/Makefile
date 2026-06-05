CC ?= cc
CFLAGS ?= -std=c11 -Wall -Wextra -O2 -Ingb
ROOT := $(abspath ..)

LIB_SRCS := ngb/sha256.c ngb/hello_elf.c ngb/pack.c ngb/parse.c ngb/status.c
PROBE_SRCS := probe/audit_log.c
LIB_OBJS := $(LIB_SRCS:.c=.o)
PROBE_OBJS := $(PROBE_SRCS:.c=.o)

BINS := bin/ngb-pack bin/ngb-parse bin/ngb-extract bin/hello-fixture bin/nano-probe

.PHONY: all clean test

all: $(BINS)

ngb/%.o: ngb/%.c ngb/ngb.h ngb/sha256.h
	$(CC) $(CFLAGS) -c $< -o $@

probe/%.o: probe/%.c probe/audit_log.h ngb/ngb.h
	$(CC) $(CFLAGS) -c $< -o $@

bin/ngb-pack: bin/ngb-pack.c $(LIB_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

bin/ngb-parse: bin/ngb-parse.c $(LIB_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

bin/hello-fixture: bin/hello-fixture.c $(LIB_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

bin/ngb-extract: bin/ngb-extract.c
	$(CC) $(CFLAGS) $^ -o $@

bin/nano-probe: bin/nano-probe.c $(LIB_OBJS) $(PROBE_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

clean:
	rm -f $(LIB_OBJS) $(PROBE_OBJS) $(BINS)

test: all
	$(ROOT)/scripts/check-ngb-roundtrip.sh
