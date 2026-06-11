/* G55 H3 novel holdout. Freestanding x86_64 Linux ELF, no libc.
 *
 * relation=round_trip
 * wire=ascii
 *   enc <byte 0-255>  prints two uppercase hex digits + newline.
 *   dec <wire>        parses an even-length uppercase hex string; prints
 *                     the packed byte value 0x01 ++ bytes as decimal, or REJECT.
 *
 * ODD_LEN_OK (bug build only) pads a lone trailing nibble with '0' instead of
 * rejecting odd-length input. round_trip catches it: dec("F") -> 15, enc(15) -> "0F". */

#define REJECT 1114112UL

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
  if (c >= 'A' && c <= 'F')
    return c - 'A' + 10;
  return -1;
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

static void print_hex2(unsigned char b);

static unsigned long parse_u(const char *s) {
  unsigned long n = 0;
  while (*s >= '0' && *s <= '9')
    n = n * 10UL + (unsigned long)(*s++ - '0');
  return n;
}

static unsigned long unpack_byte(unsigned long packed) {
  if ((packed >> 8) != 1UL)
    return REJECT;
  return packed & 0xFFUL;
}

static void enc_operand(const char *operand) {
  unsigned long x = parse_u(operand);
  unsigned long b;
  if (x <= 255UL)
    b = x;
  else
    b = unpack_byte(x);
  if (b == REJECT || b > 255UL)
    sys_exit(1);
  print_hex2((unsigned char)b);
}

static unsigned long pack_byte(unsigned char b) {
  return (1UL << 8) | (unsigned long)b;
}

static unsigned long decode_wire(const char *s) {
  int len = 0;
  while (s[len])
    len++;
#if !defined(ODD_LEN_OK)
  if (len == 0 || (len & 1))
    return REJECT;
#else
  if (len == 0)
    return REJECT;
  if (len & 1) {
    char tmp[3];
    tmp[0] = s[0];
    tmp[1] = '0';
    tmp[2] = '\0';
    s = tmp;
    len = 2;
  }
#endif
  unsigned char b = 0;
  for (int i = 0; i < len; i += 2) {
    int hi = hexval((unsigned char)s[i]);
    int lo = hexval((unsigned char)s[i + 1]);
    if (hi < 0 || lo < 0)
      return REJECT;
    b = (unsigned char)((hi << 4) | lo);
  }
  if (len > 2)
    return REJECT;
  return pack_byte(b);
}

static void print_hex2(unsigned char b) {
  static const char *hex = "0123456789ABCDEF";
  char out[3];
  out[0] = hex[(b >> 4) & 0xF];
  out[1] = hex[b & 0xF];
  out[2] = '\n';
  sys_write(1, out, 3);
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *operand) {
  if (argc < 3)
    sys_exit(1);
  if (mode[0] == 'e') {
    enc_operand(operand);
  } else if (mode[0] == 'd') {
    print_u(decode_wire(operand));
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
