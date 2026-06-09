/* G35 specimen. Freestanding x86_64 Linux ELF, no libc.
 *
 * The first real-Knuth-canon backtest. It runs Knuth's actual GB_FLIP generator
 * and the rand_len draw, no simulation. Vendors gb_flip (gb_flip.w, Stanford
 * GraphBase) and the rand_len macro (gb_rand.w), transcribed from ascherer/sgb
 * at the buggy revision fd99287. The erratum: rand_len drew gb_unif_rand with
 * span max_len-min_len, a range [min_len, max_len-1] that never reaches max_len;
 * the fix 65433e2 adds +1. gb_flip and gb_unif_rand are Knuth's verbatim
 * arithmetic, validated against his test_flip values (gb_init_rand(-314159) then
 * gb_next_rand() == 119318998). _start, the argv parse, and print are our driver.
 *
 *   draw <seed>   gb_init_rand(seed); print min_len + gb_unif_rand(span).
 * range_coverage over a seed sweep: the honest span max-min+1 lets a draw reach
 * max_len; the buggy span max-min never does, so the observed maximum across the
 * sweep tops out at max_len-1. */

#ifndef MIN_LEN
#define MIN_LEN 1
#endif
#ifndef MAX_LEN
#define MAX_LEN 10
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

static long A[56] = {-1};
static long *gb_flip_ptr = A;

static long gb_flip_cycle(void) {
  long *ii, *jj;
  for (ii = &A[1], jj = &A[32]; jj <= &A[55]; ii++, jj++)
    *ii = (*ii - *jj) & 0x7fffffff;
  for (jj = &A[1]; ii <= &A[55]; ii++, jj++)
    *ii = (*ii - *jj) & 0x7fffffff;
  gb_flip_ptr = &A[54];
  return A[55];
}

#define gb_next_rand() (*gb_flip_ptr >= 0 ? *gb_flip_ptr-- : gb_flip_cycle())

static void gb_init_rand(long seed) {
  int i;
  long prev = seed, next = 1;
  seed = prev = prev & 0x7fffffff;
  A[55] = prev;
  for (i = 21; i; i = (i + 21) % 55) {
    A[i] = next;
    next = (prev - next) & 0x7fffffff;
    if (seed & 1)
      seed = 0x40000000 + (seed >> 1);
    else
      seed >>= 1;
    next = (next - seed) & 0x7fffffff;
    prev = A[i];
  }
  (void)gb_flip_cycle();
  (void)gb_flip_cycle();
  (void)gb_flip_cycle();
  (void)gb_flip_cycle();
  (void)gb_flip_cycle();
}

#define two_to_the_31 ((unsigned long)0x80000000)

static long gb_unif_rand(long m) {
  unsigned long t = two_to_the_31 - (two_to_the_31 % (unsigned long)m);
  long r;
  do {
    r = gb_next_rand();
  } while (t <= (unsigned long)r);
  return r % m;
}

static long rand_len(void) {
  if (MIN_LEN == MAX_LEN)
    return MIN_LEN;
  long span = MAX_LEN - MIN_LEN;
  return MIN_LEN + gb_unif_rand(span);
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
  char buf[24];
  int i = 0;
  if (n == 0) {
    buf[i++] = '0';
  } else {
    char tmp[24];
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

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *operand) {
  if (argc < 3 || mode[0] != 'd')
    sys_exit(1);
  gb_init_rand((long)parse_u(operand));
  print_u((unsigned long)rand_len());
  sys_exit(0);
}

__attribute__((naked))
void _start(void) {
  __asm__("mov (%rsp), %rdi\n"
          "mov 16(%rsp), %rsi\n"
          "mov 24(%rsp), %rdx\n"
          "call real_start\n");
}
