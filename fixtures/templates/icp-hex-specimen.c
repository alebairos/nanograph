/* ICP maintainer template. Freestanding x86_64 Linux ELF, no libc.
 *
 * Transcription of the hosted hex codec in maintainer-home/hex.c (ICP sim persona).
 * Use this shape when verifying a hex round_trip property with domain=bytes.
 *
 *   dec <hex>   validate even-length hex digits; print normalized lowercase hex
 *               or REJECT on odd length or bad digit.
 *   enc <hex>   same validation; print normalized lowercase hex.
 *
 * round_trip with wire=hex requires encode(decode(b)) == b for accepted wire b. */

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

static int hex_nibble(char c) {
  if (c >= '0' && c <= '9')
    return c - '0';
  if (c >= 'a' && c <= 'f')
    return c - 'a' + 10;
  if (c >= 'A' && c <= 'F')
    return c - 'A' + 10;
  return -1;
}

static void print_str(const char *s) {
  long n = 0;
  while (s[n])
    n++;
  sys_write(1, s, n);
}

static void print_hex_normalized(const char *s) {
  static const char digits[] = "0123456789abcdef";
  char out[260];
  int i = 0;
  while (s[0] && s[1]) {
    int hi = hex_nibble(s[0]);
    int lo = hex_nibble(s[1]);
    if (hi < 0 || lo < 0 || i + 2 >= (int)sizeof(out))
      return;
    out[i++] = digits[hi];
    out[i++] = digits[lo];
    s += 2;
  }
  if (s[0])
    return;
  out[i++] = '\n';
  sys_write(1, out, i);
}

static int valid_hex_wire(const char *s) {
  if (!s[0])
    return 0;
  while (s[0] && s[1]) {
    if (hex_nibble(s[0]) < 0 || hex_nibble(s[1]) < 0)
      return 0;
    s += 2;
  }
  return s[0] == '\0';
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *operand) {
  if (argc < 3)
    sys_exit(1);
  if (!valid_hex_wire(operand)) {
    print_str("REJECT\n");
    sys_exit(0);
  }
  if (mode[0] == 'd' || mode[0] == 'e') {
    print_hex_normalized(operand);
  } else {
    sys_exit(1);
  }
  sys_exit(0);
}

__attribute__((naked))
void _start(void) {
  __asm__("mov (%rsp), %rdi\n"
          "mov 16(%rsp), %rsi\n"
          "mov 24(%rsp), %rdx\n"
          "call real_start\n");
}
