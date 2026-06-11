/* G52 specimen. Freestanding x86_64 Linux ELF, no libc.
 *
 * Faithful C transcription of ziglang/zig std.hash.Adler32 (lib/std/hash/adler.zig).
 * Parent e3d12471 uses input[i + n * j] with n = nmax/16 inside the NMAX block
 * loop instead of advancing i; fix a5af78c3 restores input[i + j] with i += 16.
 *
 *   dec <hex>   hex-decode the operand to raw bytes, print Adler-32 as unsigned
 *               decimal, or REJECT on invalid or empty hex.
 *
 * value_oracle: dec(s) must match the reference Adler-32 for accepted inputs; the
 * buggy rev drifts past one block (5552 bytes). */

#define BASE 65521U
#define NMAX 5552

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

static int hexval(unsigned char c) {
  if (c >= '0' && c <= '9')
    return c - '0';
  if (c >= 'a' && c <= 'f')
    return c - 'a' + 10;
  if (c >= 'A' && c <= 'F')
    return c - 'A' + 10;
  return -1;
}

static int hex_decode(const char *s, unsigned char *out) {
  int n = 0;
  while (s[2 * n] && s[2 * n + 1]) {
    int hi = hexval((unsigned char)s[2 * n]);
    int lo = hexval((unsigned char)s[2 * n + 1]);
    if (hi < 0 || lo < 0)
      return -1;
    out[n] = (unsigned char)((hi << 4) | lo);
    n++;
  }
  if (s[2 * n])
    return -1;
  return n;
}

static void print_str(const char *s) {
  int n = 0;
  while (s[n])
    n++;
  sys_write(1, s, n);
}

static void print_u(unsigned long n) {
  char buf[16];
  int i = 0;
  if (n == 0) {
    buf[i++] = '0';
  } else {
    while (n) {
      buf[i++] = (char)('0' + (n % 10UL));
      n /= 10UL;
    }
    for (int l = 0, r = i - 1; l < r; l++, r--) {
      char t = buf[l];
      buf[l] = buf[r];
      buf[r] = t;
    }
  }
  buf[i++] = '\n';
  sys_write(1, buf, i);
}

static int adler_byte_index(int base, int j, int rounds_per_block, int len,
                            int misindex) {
  int idx;
  if (misindex)
    idx = base + rounds_per_block * j;
  else
    idx = base + j;
  if (idx >= len)
    idx = len - 1;
  return idx;
}

static unsigned int adler32(const unsigned char *buf, int len) {
  unsigned int s1 = 1;
  unsigned int s2 = 0;
  int i = 0;
  const int rounds_per_block = NMAX / 16;

  if (len == 1) {
    s1 += buf[0];
    if (s1 >= BASE)
      s1 -= BASE;
    s2 += s1;
    if (s2 >= BASE)
      s2 -= BASE;
    return s1 | (s2 << 16);
  }

  if (len < 16) {
    for (int k = 0; k < len; k++) {
      s1 += buf[k];
      s2 += s1;
    }
    if (s1 >= BASE)
      s1 -= BASE;
    s2 %= BASE;
    return s1 | (s2 << 16);
  }

  while (i + NMAX <= len) {
#if defined(WRONG_INDEX)
    int misindex = (i + NMAX < len);
#else
    int misindex = 0;
#endif
    int rounds = 0;
    while (rounds < rounds_per_block) {
      for (int j = 0; j < 16; j++) {
        int idx = adler_byte_index(i, j, rounds_per_block, len, misindex);
        s1 += buf[idx];
        s2 += s1;
      }
      if (!misindex)
        i += 16;
      rounds++;
    }
    if (misindex) {
      i += NMAX;
    } else {
      s1 %= BASE;
      s2 %= BASE;
    }
  }

  if (i < len) {
    while (i + 16 <= len) {
      for (int j = 0; j < 16; j++) {
        s1 += buf[i + j];
        s2 += s1;
      }
      i += 16;
    }
    while (i < len) {
      s1 += buf[i];
      s2 += s1;
      i++;
    }
    s1 %= BASE;
    s2 %= BASE;
  }

  return s1 | (s2 << 16);
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *operand) {
  if (argc < 3 || mode[0] != 'd' || mode[1] != 'e' || mode[2] != 'c' ||
      mode[3] != '\0')
    sys_exit(1);
  unsigned char in[8192];
  int n = hex_decode(operand, in);
  if (n <= 0) {
    print_str("REJECT\n");
    sys_exit(0);
  }
  print_u((unsigned long)adler32(in, n));
  sys_exit(0);
}

__attribute__((naked))
void _start(void) {
  __asm__("mov (%rsp), %rdi\n"
          "mov 16(%rsp), %rsi\n"
          "mov 24(%rsp), %rdx\n"
          "call real_start\n");
}
