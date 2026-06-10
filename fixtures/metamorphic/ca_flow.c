/* G69 specimen. Multi-step elementary CA on a WIDTH-bit row.
 *
 *   flow <steps> <seed>   print state after <steps> generations (decimal u32).
 *
 * EVIL_SKIP omits one middle generation when steps >= 2 (breaks composition). */

#ifndef WIDTH
#define WIDTH 32
#endif
#ifndef RULE
#define RULE 90
#endif

static long sys_write(long fd, const void *buf, long n) {
  long ret;
  __asm__ volatile("syscall"
                   : "=a"(ret)
                   : "a"(1L), "D"(fd), "S"(buf), "d"(n)
                   : "rcx", "r11", "memory");
  return ret;
}

static void sys_exit(long code) __attribute__((noreturn));
static void sys_exit(long code) {
  __asm__ volatile("syscall" : : "a"(60L), "D"(code) : "rcx", "r11", "memory");
  __builtin_unreachable();
}

static unsigned long parse_u(const char *s) {
  unsigned long n = 0;
  while (*s >= '0' && *s <= '9') {
    n = n * 10UL + (unsigned long)(*s - '0');
    s++;
  }
  return n;
}

static void print_u(unsigned long n) {
  char buf[32];
  int i = 0;
  if (n == 0) {
    buf[i++] = '0';
  } else {
    char tmp[32];
    int j = 0;
    while (n > 0) {
      tmp[j++] = (char)('0' + (n % 10UL));
      n /= 10UL;
    }
    while (j > 0)
      buf[i++] = tmp[--j];
  }
  buf[i++] = '\n';
  sys_write(1, buf, i);
}

static unsigned ca_step(unsigned cur) {
  unsigned nxt = 0;
  unsigned mask = (WIDTH >= 32) ? 0xFFFFFFFFu : ((1u << WIDTH) - 1u);
  cur &= mask;
  for (int i = 0; i < WIDTH; i++) {
    int l = (i > 0) ? ((cur >> (i - 1)) & 1) : 0;
    int c = (cur >> i) & 1;
    int r = (i < WIDTH - 1) ? ((cur >> (i + 1)) & 1) : 0;
    int idx = (l << 2) | (c << 1) | r;
    if ((RULE >> idx) & 1)
      nxt |= (1u << i);
  }
  return nxt & mask;
}

static unsigned ca_flow(unsigned cur, unsigned steps) {
  unsigned mask = (WIDTH >= 32) ? 0xFFFFFFFFu : ((1u << WIDTH) - 1u);
  cur &= mask;
  for (unsigned s = 0; s < steps; s++) {
#if defined(EVIL_SKIP)
    if (steps >= 2u && s == steps / 2u)
      continue;
#endif
    cur = ca_step(cur);
  }
  return cur & mask;
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *arg1, const char *arg2) {
  if (argc < 4)
    sys_exit(1);
  if (mode[0] != 'f' || mode[1] != 'l' || mode[2] != 'o' || mode[3] != 'w' ||
      mode[4] != '\0')
    sys_exit(1);
  unsigned steps = (unsigned)parse_u(arg1);
  unsigned seed = (unsigned)parse_u(arg2);
  print_u((unsigned long)ca_flow(seed, steps));
  sys_exit(0);
}

__attribute__((naked))
void _start(void) {
  __asm__("mov (%rsp), %rdi\n"
          "mov 16(%rsp), %rsi\n"
          "mov 24(%rsp), %rdx\n"
          "mov 32(%rsp), %rcx\n"
          "call real_start\n");
}
