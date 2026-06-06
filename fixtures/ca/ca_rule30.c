/* Route B specimen for G17. Freestanding x86_64 Linux ELF, no libc.
 * Realizes op=eca rule=30 width=31 gens=16 init=center yield=stdout.
 * The bytes are compiler output, minted once in a pinned container; CI runs
 * the committed image and never recompiles. See docs/specs/CA-CONFORMANCE.md. */

#define WIDTH 31
#define GENS 16
#ifndef RULE
#define RULE 30
#endif

static long sys_write(long fd, const void *buf, long n) {
  long ret;
  __asm__ volatile("syscall"
                   : "=a"(ret)
                   : "a"(1L), "D"(fd), "S"(buf), "d"(n)
                   : "rcx", "r11", "memory");
  return ret;
}

static void sys_exit(long code) {
  __asm__ volatile("syscall" : : "a"(60L), "D"(code) : "rcx", "r11", "memory");
  __builtin_unreachable();
}

void _start(void) {
  unsigned char cur[WIDTH], nxt[WIDTH];
  char line[WIDTH + 1];

  for (int i = 0; i < WIDTH; i++)
    cur[i] = 0;
  cur[WIDTH / 2] = 1;

  for (int g = 0; g < GENS; g++) {
    for (int i = 0; i < WIDTH; i++)
      line[i] = cur[i] ? '#' : '.';
    line[WIDTH] = '\n';
    sys_write(1, line, WIDTH + 1);

    for (int i = 0; i < WIDTH; i++) {
      int l = i > 0 ? cur[i - 1] : 0;
      int c = cur[i];
      int r = i < WIDTH - 1 ? cur[i + 1] : 0;
      int idx = (l << 2) | (c << 1) | r;
      nxt[i] = (RULE >> idx) & 1;
    }
    for (int i = 0; i < WIDTH; i++)
      cur[i] = nxt[i];
  }

  sys_exit(0);
}
