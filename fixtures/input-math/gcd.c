/* Route B specimen for G21. Freestanding x86_64 Linux ELF, no libc.
 * Reads argv[1], argv[2] as integers; prints gcd(a,b) to stdout.
 * Linux x86_64 ABI: argc at [rsp], argv[i] at rsp+8+i*8.
 * Minted once in a pinned container; CI runs the committed image. */

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

static long parse_long(const char *s) {
  long n = 0;
  int neg = 0;
  if (*s == '-') {
    neg = 1;
    s++;
  }
  while (*s >= '0' && *s <= '9') {
    n = n * 10 + (*s - '0');
    s++;
  }
  return neg ? -n : n;
}

static void print_long(long n) {
  char buf[32];
  int i = 0;

  if (n < 0)
    n = -n;
  if (n == 0) {
    buf[i++] = '0';
  } else {
    char tmp[32];
    int j = 0;
    while (n > 0) {
      tmp[j++] = (char)('0' + (n % 10));
      n /= 10;
    }
    while (j > 0)
      buf[i++] = tmp[--j];
  }
  buf[i++] = '\n';
  sys_write(1, buf, i);
}

#ifdef WRONG_GCD
static long gcd(long a, long b) {
  return a + b;
}
#else
static long gcd(long a, long b) {
  if (a < 0)
    a = -a;
  if (b < 0)
    b = -b;
  while (b != 0) {
    long t = b;
    b = a % b;
    a = t;
  }
  return a;
}
#endif

__attribute__((noreturn))
void real_start(long argc, const char *arg1, const char *arg2) {
  if (argc < 3)
    sys_exit(1);
  print_long(gcd(parse_long(arg1), parse_long(arg2)));
  sys_exit(0);
}

__attribute__((naked))
void _start(void) {
  __asm__("mov (%rsp), %rdi\n"
          "mov 16(%rsp), %rsi\n"
          "mov 24(%rsp), %rdx\n"
          "call real_start\n");
}
