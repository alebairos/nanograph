/* G71 specimen. Freestanding crc32fast combine() from srijs/rust-crc32fast combine.rs.
 *
 * Parent cdbd51f: combine(crc1,crc2,len2=0) returns crc1^crc2; fix 724ceb6 returns crc1.
 *
 *   flow <len2> <seed>
 *
 * seed 5 -> crc1=0 crc2=1; other seeds -> crc1=0 crc2=0. */

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
  while (*s >= '0' && *s <= '9')
    n = n * 10UL + (unsigned long)(*s++ - '0');
  return n;
}

static void print_u32(unsigned int n) {
  char buf[16];
  int i = 0;
  if (n == 0)
    buf[i++] = '0';
  else {
    char tmp[16];
    int j = 0;
    while (n > 0) {
      tmp[j++] = (char)('0' + (n % 10U));
      n /= 10U;
    }
    while (j > 0)
      buf[i++] = tmp[--j];
  }
  buf[i++] = '\n';
  sys_write(1, buf, i);
}

static const unsigned int X2N_TABLE[32] = {
    0x00800000, 0x00008000, 0xedb88320, 0xb1e6b092, 0xa06a2517, 0xed627dae, 0x88d14467,
    0xd7bbfe6a, 0xec447f11, 0x8e7ea170, 0x6427800e, 0x4d47bae0, 0x09fe548f, 0x83852d0f,
    0x30362f1a, 0x7b5a9cc3, 0x31fec169, 0x9fec022a, 0x6c8dedc4, 0x15d6874d, 0x5fde7a4e,
    0xbad90e37, 0x2e4e5eef, 0x4eaba214, 0xa8a472c0, 0x429a969e, 0x148d302a, 0xc40ba6d0,
    0xc4e22c3c, 0x40000000, 0x20000000, 0x08000000,
};

static unsigned int multiply(unsigned int a, unsigned int b) {
  unsigned int p = 0;
  for (int i = 0; i < 32; i++) {
    p ^= b & (unsigned int)(-((int)((a >> (31 - i)) & 1U)));
    b = (b >> 1) ^ ((b & 1U) ? 0xedb88320U : 0U);
  }
  return p;
}

static unsigned int leading_zeros_u64(unsigned long long v) {
  if (v == 0)
    return 64;
  int n = 0;
  while ((v & (1ULL << 63)) == 0) {
    v <<= 1;
    n++;
  }
  return n;
}

static unsigned int probe_crc2(unsigned long seed) {
  return seed == 5 ? 1U : 0U;
}

static unsigned int combine(unsigned int crc1, unsigned int crc2, unsigned long long len2) {
#if !defined(LEN2_ZERO_CHECK)
  if (len2 == 0)
    return crc1;
#endif
  unsigned int p = crc1;
  int n = 64 - leading_zeros_u64(len2);
  for (int i = 0; i < n; i++) {
    if ((len2 >> i) & 1ULL)
      p = multiply(X2N_TABLE[i & 31], p);
  }
  return p ^ crc2;
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *len_s, const char *seed_s) {
  if (argc < 4 || mode[0] != 'f' || mode[1] != 'l' || mode[2] != 'o' || mode[3] != 'w' || mode[4])
    sys_exit(1);
  unsigned long long len2 = parse_u(len_s);
  unsigned long seed = parse_u(seed_s);
  print_u32(combine(0U, probe_crc2(seed), len2));
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
