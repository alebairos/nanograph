/* G33 specimen. Freestanding x86_64 Linux ELF, no libc.
 *
 * Trusted driver modeling Knuth SGB save_graph erratum (page 414, Dec 2025).
 * fopen(f,"w") on Windows expands internal newlines to CRLF on disk; restore on
 * Linux reads those bytes literally and the graph no longer round-trips.
 * fopen(f,"wb") fixes it. We model the buggy save path with BUGGY_TEXTMODE.
 *
 *   save <packed>    serializes 0x01 ++ payload bytes (decimal packed input).
 *   restore <packed>   reads serialized bytes literally, re-packs canonical form.
 *
 * Honest revisions keep binary save (one byte per payload byte). The buggy
 * revision expands 0x0A to 0x0D 0x0A on save. restore never normalizes CRLF,
 * matching Linux reading a Windows text-mode graph file. */

#define REJECT 4294967295UL
#define MAX_BYTES 8

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

static int unpack(unsigned long packed, unsigned char *out) {
  int n = 0;
  for (int k = 1; k <= MAX_BYTES; k++) {
    if ((packed >> (8 * k)) == 1UL) {
      n = k;
      break;
    }
  }
  if (n == 0)
    return 0;
  for (int k = 0; k < n; k++)
    out[k] = (unsigned char)((packed >> (8 * (n - 1 - k))) & 0xFFUL);
  return n;
}

static unsigned long pack_bytes(const unsigned char *b, int n) {
  unsigned long r = 1UL;
  for (int k = 0; k < n; k++)
    r = (r << 8) | (unsigned long)b[k];
  return r;
}

static int save_emit(const unsigned char *in, int in_len, unsigned char *out) {
  int pos = 0;
  for (int i = 0; i < in_len; i++) {
    unsigned char b = in[i];
    if (b == '\n') {
      if (pos + 2 > MAX_BYTES)
        return 0;
      out[pos++] = '\r';
      out[pos++] = '\n';
    } else {
      if (pos >= MAX_BYTES)
        return 0;
      out[pos++] = b;
    }
  }
  return pos;
}

static unsigned long graph_save(unsigned long packed) {
  unsigned char in[MAX_BYTES];
  int in_len = unpack(packed, in);
  if (in_len == 0)
    return REJECT;
  unsigned char out[MAX_BYTES];
  int out_len = save_emit(in, in_len, out);
  if (out_len == 0)
    return REJECT;
  return pack_bytes(out, out_len);
}

static unsigned long graph_restore(unsigned long serialized) {
  unsigned char b[MAX_BYTES];
  int n = unpack(serialized, b);
  if (n == 0)
    return REJECT;
  return pack_bytes(b, n);
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *operand) {
  if (argc < 3)
    sys_exit(1);
  unsigned long x = parse_u(operand);
  if (mode[0] == 's')
    print_u(graph_save(x));
  else if (mode[0] == 'r')
    print_u(graph_restore(x));
  else
    sys_exit(1);
  sys_exit(0);
}

__attribute__((naked))
void _start(void) {
  __asm__("mov (%rsp), %rdi\n"
          "mov 16(%rsp), %rsi\n"
          "mov 24(%rsp), %rdx\n"
          "call real_start\n");
}
