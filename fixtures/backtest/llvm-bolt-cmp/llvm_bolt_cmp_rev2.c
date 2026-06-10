/* G48 specimen. Freestanding x86_64 Linux ELF, no libc.
 *
 * Faithful C transcription of llvm/llvm-project BOLT getCodeSections
 * compareSections lambda (bolt/lib/Rewrite/RewriteInstance.cpp). Parent
 * e8606ab omits the identity guard; fix 5fe235b adds `if (A == B) return false`.
 *
 *   cmp <i> <j>   print 1 if section i sorts before j, else 0.
 *
 * cmp_order: cmp(i,i) must be 0; cmp(i,j)==1 implies cmp(j,i)==0. Buggy rev
 * returns 1 on self-pair (0,0) when HotText places the mover first. */

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

static int str_eq(const char *a, const char *b) {
  while (*a && *b && *a == *b) {
    a++;
    b++;
  }
  return *a == *b && *a == '\0';
}

static int starts_with(const char *s, const char *pfx) {
  while (*pfx) {
    if (*s++ != *pfx++) return 0;
  }
  return 1;
}

static int str_len(const char *s) {
  int n = 0;
  while (s[n]) n++;
  return n;
}

static int str_cmp(const char *a, const char *b) {
  while (*a && *b && *a == *b) {
    a++;
    b++;
  }
  return (unsigned char)*a - (unsigned char)*b;
}

#define HOT_TEXT 1
#define HOT_FUNCTIONS_AT_END 0

static const char *const kSections[] = {
    ".bolt.hot.text",
    ".text",
    ".text.warm",
    ".text.cold",
};
#define NSECTIONS 4

static const char *kColdPrefix = ".text.cold";
static const char *kMover = ".bolt.hot.text";
static const char *kMain = ".text";
static const char *kWarm = ".text.warm";

static int compare_sections(int ai, int bj) {
  const char *an = kSections[ai];
  const char *bn = kSections[bj];


  if (starts_with(an, kColdPrefix) && starts_with(bn, kColdPrefix)) {
    int alen = str_len(an);
    int blen = str_len(bn);
    if (alen != blen)
      return HOT_FUNCTIONS_AT_END ? (alen > blen) : (alen < blen);
    return HOT_FUNCTIONS_AT_END ? (str_cmp(an, bn) > 0) : (str_cmp(an, bn) < 0);
  }

  if (HOT_TEXT) {
    if (str_eq(an, kMover))
      return 1;
    if (str_eq(bn, kMover))
      return 0;
  }

  if (HOT_FUNCTIONS_AT_END) {
    if (str_eq(bn, kMain))
      return 1;
    if (str_eq(an, kMain))
      return 0;
    return str_eq(bn, kWarm);
  }
  if (str_eq(an, kMain))
    return 1;
  if (str_eq(bn, kMain))
    return 0;
  return str_eq(an, kWarm);
}

static void print_digit(int d) {
  char c = (char)('0' + d);
  sys_write(1, &c, 1);
  c = '\n';
  sys_write(1, &c, 1);
}

static int parse_u32(const char *s) {
  int v = 0;
  while (*s >= '0' && *s <= '9') {
    v = v * 10 + (*s - '0');
    s++;
  }
  return v;
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *a0, const char *a1) {
  if (argc < 4 || mode[0] != 'c')
    sys_exit(1);
  int i = parse_u32(a0);
  int j = parse_u32(a1);
  if (i < 0 || j < 0 || i >= NSECTIONS || j >= NSECTIONS)
    sys_exit(1);
  print_digit(compare_sections(i, j));
  sys_exit(0);
}

__attribute__((naked))
void _start(void) {
  __asm__("mov (%rsp), %rdi\n"
          "mov 16(%rsp), %rsi\n"
          "mov 24(%rsp), %rdx\n"
          "mov 32(%rsp), %rcx\n"
          "mov 40(%rsp), %r8\n"
          "call real_start\n");
}
