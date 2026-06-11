/* Freestanding x86_64 Linux ELF metamorphic specimen, no libc.
 *
 * Models Frommi/miniz_oxide init_tree Huffman validation during inflate table
 * construction. Parent d0f3e0cb accepted incomplete literal/length trees; fix
 * c40992ad rejects them per madler/zlib issue #137 semantics.
 *
 *   dec <hex>   hex-decode operand to per-symbol code lengths (0-15, up to 288
 *               symbols), build bl_count[1..15], validate zlib-style.
 *
 * value_oracle: dec(s) must match expected for accepted length vectors; the lax
 * rev accepts an incomplete litlen tree the fix rejects. */

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
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  return -1;
}

static int hex_decode(const char *s, unsigned char *out) {
  int n = 0;
  while (s[2 * n] && s[2 * n + 1]) {
    int hi = hexval((unsigned char)s[2 * n]);
    int lo = hexval((unsigned char)s[2 * n + 1]);
    if (hi < 0 || lo < 0) return -1;
    out[n] = (unsigned char)((hi << 4) | lo);
    n++;
  }
  if (s[2 * n]) return -1;
  return n;
}

static void print_str(const char *s) {
  int n = 0;
  while (s[n]) n++;
  sys_write(1, s, n);
}

static void print_bl_count(const unsigned char bl_count[16]) {
  static const char hexd[] = "0123456789abcdef";
  char out[32];
  int i = 0;
  for (int bits = 1; bits <= 15; bits++) {
    out[i++] = hexd[bl_count[bits] >> 4];
    out[i++] = hexd[bl_count[bits] & 15];
  }
  out[i++] = '\n';
  sys_write(1, out, i);
}

static int validate_lengths(const unsigned char *lens, int n,
                            unsigned char bl_count[16]) {
  int nonzero = 0;
  int max_len = 0;

  for (int i = 0; i < 16; i++)
    bl_count[i] = 0;
  for (int i = 0; i < n; i++) {
    if (lens[i] > 15)
      return 1;
    if (lens[i] == 0)
      continue;
    bl_count[lens[i]]++;
    nonzero++;
    if (lens[i] > max_len)
      max_len = lens[i];
  }

  int left = 1;
  for (int bits = 1; bits <= 15; bits++) {
    left <<= 1;
    left -= bl_count[bits];
    if (left < 0)
      return 1;
  }
  if (left == 0)
    return 0;
  if (nonzero == 1 && max_len == 1)
    return 0;
#if defined(LAX_TREE)
  return 0;
#else
  return 1;
#endif
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *operand) {
  if (argc < 3 || mode[0] != 'd')
    sys_exit(1);
  unsigned char lens[288];
  int n = hex_decode(operand, lens);
  if (n < 0 || n > 288) {
    print_str("REJECT\n");
    sys_exit(0);
  }
  unsigned char bl_count[16];
  if (validate_lengths(lens, n, bl_count))
    print_str("REJECT\n");
  else
    print_bl_count(bl_count);
  sys_exit(0);
}

__attribute__((naked))
void _start(void) {
  __asm__("mov (%rsp), %rdi\n"
          "mov 16(%rsp), %rsi\n"
          "mov 24(%rsp), %rdx\n"
          "call real_start\n");
}
