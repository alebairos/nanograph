/* G26 real-code specimen. Freestanding x86_64 Linux ELF, no libc.
 *
 * The function under test is vendored, not ours. reverse32 below is the
 * "Reverse bits in parallel" routine from Sean Eron Anderson's Bit Twiddling
 * Hacks (https://graphics.stanford.edu/~seander/bithacks.html), which the
 * author places in the public domain. NanoGraph verifies these bytes; it did
 * not author them. The _start/parse/print code is our trusted driver: it reads
 * argv[1] as a u32, calls reverse32, and prints the result in decimal.
 *
 * Bit reversal is an involution (reversing twice restores the input) and is not
 * a byte swap, so a value oracle is needed to tell it from another involution.
 * EVIL_REVERSE plants a mask typo that drops bits, breaking the involution. */

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

/* vendored: Bit Twiddling Hacks, "Reverse bits in parallel" (public domain). */
static unsigned long reverse32(unsigned long x) {
  unsigned int v = (unsigned int)(x & 0xFFFFFFFFUL);
  v = ((v >> 1) & 0x55555555u) | ((v & 0x55555555u) << 1);
#if defined(EVIL_REVERSE)
  v = ((v >> 2) & 0x11111111u) | ((v & 0x11111111u) << 2);
#else
  v = ((v >> 2) & 0x33333333u) | ((v & 0x33333333u) << 2);
#endif
  v = ((v >> 4) & 0x0F0F0F0Fu) | ((v & 0x0F0F0F0Fu) << 4);
  v = ((v >> 8) & 0x00FF00FFu) | ((v & 0x00FF00FFu) << 8);
  v = (v >> 16) | (v << 16);
  return (unsigned long)v;
}

__attribute__((noreturn))
void real_start(long argc, const char *arg1) {
  if (argc < 2)
    sys_exit(1);
  print_u(reverse32(parse_u(arg1)));
  sys_exit(0);
}

__attribute__((naked))
void _start(void) {
  __asm__("mov (%rsp), %rdi\n"
          "mov 16(%rsp), %rsi\n"
          "call real_start\n");
}
