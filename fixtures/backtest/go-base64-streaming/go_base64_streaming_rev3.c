/* G58 specimen. golang/go encoding/base64 RawURLEncoding streaming decode.
 * Parent 8971d618 Read dropped final nbuf<4; fix 20d745c decodes tail fragment.
 * flow <len> <seed|token> — partial at len==4, token prefix '2'. */

#define PARTIAL_N 4

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

static void print_u64(unsigned long long n) {
  char buf[32];
  int i = 0;
  if (n == 0)
    buf[i++] = '0';
  else {
    char tmp[32];
    int j = 0;
    while (n > 0) {
      tmp[j++] = (char)('0' + (n % 10ULL));
      n /= 10ULL;
    }
    while (j > 0)
      buf[i++] = tmp[--j];
  }
  buf[i++] = '\n';
  sys_write(1, buf, i);
}

static const char *probe_b64(unsigned long seed) {
  switch (seed) {
  case 5:
    return "AAAAAA";
  case 7:
    return "BBBBBB";
  case 42:
    return "YWJjZA";
  case 13:
    return "AAABBB";
  default:
    return 0;
  }
}

static int probe_len(const char *s) {
  int n = 0;
  while (s[n])
    n++;
  return n;
}

static unsigned char dec_map[256];

static void init_maps(void) {
  static const char enc[] =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
  for (int i = 0; i < 256; i++)
    dec_map[i] = 0xFF;
  for (int i = 0; i < 64; i++)
    dec_map[(unsigned char)enc[i]] = (unsigned char)i;
}

static int decode_quantum(const unsigned char *dbuf, int dlen, unsigned char *dst) {
  unsigned val = ((unsigned)dbuf[0] << 18) | ((unsigned)dbuf[1] << 12) | ((unsigned)dbuf[2] << 6) |
                 (unsigned)dbuf[3];
  int n = 0;
  if (dlen >= 2)
    dst[n++] = (unsigned char)(val >> 16);
  if (dlen >= 3)
    dst[n++] = (unsigned char)(val >> 8);
  if (dlen >= 4)
    dst[n++] = (unsigned char)(val);
  return n;
}

static int decode_one_shot(const char *src, int len, unsigned char *dst, int cap) {
  int si = 0, n = 0;
  while (si < len) {
    unsigned char dbuf[4];
    int dlen = 0;
    for (int j = 0; j < 4; j++) {
      if (si >= len) {
        if (j < 2)
          return -1;
        dlen = j;
        break;
      }
      unsigned char c = (unsigned char)src[si++];
      if (dec_map[c] == 0xFF)
        return -1;
      dbuf[j] = dec_map[c];
      dlen = j + 1;
    }
    int nw = decode_quantum(dbuf, dlen, dst + n);
    if (n + nw > cap)
      return -1;
    n += nw;
  }
  return n;
}

typedef struct {
  int err;
  int read_eof;
  int end;
  int nbuf;
  unsigned char buf[256];
  int out_len;
  unsigned char outbuf[192];
  int pos;
  const char *input;
  int input_len;
  unsigned long long orig_seed;
  int produced;
} stream_dec;

static int dec_read(stream_dec *d, unsigned char *p, int plen) {
  if (d->out_len > 0) {
    int n = d->out_len < plen ? d->out_len : plen;
    for (int i = 0; i < n; i++)
      p[i] = d->outbuf[i];
    for (int i = 0; i < d->out_len - n; i++)
      d->outbuf[i] = d->outbuf[i + n];
    d->out_len -= n;
    return n;
  }
  if (d->err)
    return 0;

  while (d->nbuf < 4 && !d->read_eof && d->pos < d->input_len) {
    d->buf[d->nbuf++] = (unsigned char)d->input[d->pos++];
  }
  if (d->pos >= d->input_len)
    d->read_eof = 1;

  if (d->nbuf < 4) {
    if (d->nbuf > 0 && d->read_eof) {
      unsigned char q[4];
      for (int i = 0; i < d->nbuf; i++)
        q[i] = dec_map[d->buf[i]];
      int nw = decode_quantum(q, d->nbuf, d->outbuf);
      d->nbuf = 0;
      d->end = 1;
      d->out_len = nw;
      int n = nw < plen ? nw : plen;
      for (int i = 0; i < n; i++)
        p[i] = d->outbuf[i];
      for (int i = 0; i < d->out_len - n; i++)
        d->outbuf[i] = d->outbuf[i + n];
      d->out_len -= n;
      return n;
    }
    if (d->read_eof && d->nbuf > 0) {
      d->err = 1;
      return 0;
    }
    return 0;
  }

  unsigned char q[4];
  for (int i = 0; i < 4; i++)
    q[i] = dec_map[d->buf[i]];
  unsigned char out[192];
  int dn = decode_quantum(q, 4, out);
  d->nbuf = 0;
  int n = dn < plen ? dn : plen;
  for (int i = 0; i < n; i++)
    p[i] = out[i];
  if (dn > n) {
    d->out_len = dn - n;
    for (int i = 0; i < d->out_len; i++)
      d->outbuf[i] = out[i + n];
  }
  return n;
}

static unsigned long stream_len(stream_dec *d) {
  unsigned char tmp[64];
  unsigned long n = 0;
  for (;;) {
    int r = dec_read(d, tmp, (int)sizeof(tmp));
    if (r <= 0)
      break;
    n += (unsigned long)r;
  }
  return n;
}

static void put_u20(char *out, int *pos, int cap, unsigned long long v) {
  for (int d = 19; d >= 0; d--) {
    unsigned long long div = 1;
    for (int e = 0; e < d; e++)
      div *= 10ULL;
    if (*pos + 1 >= cap)
      return;
    out[(*pos)++] = (char)('0' + ((v / div) % 10ULL));
  }
}

static void pack_token(const stream_dec *d) {
  char out[1200];
  int pos = 0;
  out[pos++] = '2';
  put_u20(out, &pos, (int)sizeof(out), d->orig_seed);
  put_u20(out, &pos, (int)sizeof(out), (unsigned long long)d->pos);
  put_u20(out, &pos, (int)sizeof(out), (unsigned long long)d->nbuf);
  put_u20(out, &pos, (int)sizeof(out), (unsigned long long)d->out_len);
  put_u20(out, &pos, (int)sizeof(out), (unsigned long long)d->end);
  put_u20(out, &pos, (int)sizeof(out), (unsigned long long)d->err);
  put_u20(out, &pos, (int)sizeof(out), (unsigned long long)d->read_eof);
  put_u20(out, &pos, (int)sizeof(out), (unsigned long long)d->produced);
  if (pos + 3 >= (int)sizeof(out))
    return;
  out[pos++] = (char)('0' + (d->nbuf / 100) % 10);
  out[pos++] = (char)('0' + (d->nbuf / 10) % 10);
  out[pos++] = (char)('0' + d->nbuf % 10);
  for (int i = 0; i < d->nbuf; i++) {
    if (pos + 3 >= (int)sizeof(out))
      return;
    out[pos++] = (char)('0' + (d->buf[i] / 100) % 10);
    out[pos++] = (char)('0' + (d->buf[i] / 10) % 10);
    out[pos++] = (char)('0' + d->buf[i] % 10);
  }
  if (pos + 3 >= (int)sizeof(out))
    return;
  out[pos++] = (char)('0' + (d->out_len / 100) % 10);
  out[pos++] = (char)('0' + (d->out_len / 10) % 10);
  out[pos++] = (char)('0' + d->out_len % 10);
  for (int i = 0; i < d->out_len; i++) {
    if (pos + 3 >= (int)sizeof(out))
      return;
    out[pos++] = (char)('0' + (d->outbuf[i] / 100) % 10);
    out[pos++] = (char)('0' + (d->outbuf[i] / 10) % 10);
    out[pos++] = (char)('0' + d->outbuf[i] % 10);
  }
  out[pos++] = '\n';
  sys_write(1, out, pos);
}

static int unpack_token(const char *s, stream_dec *d) {
  if (s[0] != '2')
    return -1;
  s++;
  unsigned long long fields[8];
  for (int f = 0; f < 8; f++) {
    unsigned long long v = 0;
    for (int j = 0; j < 20; j++) {
      if (*s < '0' || *s > '9')
        return -1;
      v = v * 10ULL + (unsigned long long)(*s - '0');
      s++;
    }
    fields[f] = v;
  }
  d->orig_seed = fields[0];
  d->pos = (int)fields[1];
  d->nbuf = (int)fields[2];
  d->out_len = (int)fields[3];
  d->end = (int)fields[4];
  d->err = (int)fields[5];
  d->read_eof = (int)fields[6];
  d->produced = (int)fields[7];
  int bl = 0;
  for (int j = 0; j < 3; j++) {
    if (*s < '0' || *s > '9')
      return -1;
    bl = bl * 10 + (*s - '0');
    s++;
  }
  if (bl != d->nbuf)
    return -1;
  for (int i = 0; i < d->nbuf; i++) {
    int b = 0;
    for (int j = 0; j < 3; j++) {
      if (*s < '0' || *s > '9')
        return -1;
      b = b * 10 + (*s - '0');
      s++;
    }
    d->buf[i] = (unsigned char)b;
  }
  int ol = 0;
  for (int j = 0; j < 3; j++) {
    if (*s < '0' || *s > '9')
      return -1;
    ol = ol * 10 + (*s - '0');
    s++;
  }
  if (ol != d->out_len)
    return -1;
  for (int i = 0; i < d->out_len; i++) {
    int b = 0;
    for (int j = 0; j < 3; j++) {
      if (*s < '0' || *s > '9')
        return -1;
      b = b * 10 + (*s - '0');
      s++;
    }
    d->outbuf[i] = (unsigned char)b;
  }
  return 0;
}

static stream_dec make_dec(unsigned long seed) {
  stream_dec d = {0};
  d.orig_seed = seed;
  d.input = probe_b64(seed);
  if (!d.input)
    sys_exit(1);
  d.input_len = probe_len(d.input);
  return d;
}

static void flow_partial(unsigned long partial_in, unsigned long seed) {
  stream_dec d = make_dec(seed);
  int limit = (int)partial_in;
  if (limit > d.input_len)
    limit = d.input_len;
  d.input_len = limit;
  unsigned char tmp[64];
  while (!d.err && !d.end) {
    int n = dec_read(&d, tmp, (int)sizeof(tmp));
    if (n <= 0 && d.read_eof)
      break;
    if (n <= 0 && d.nbuf >= 4)
      continue;
    if (n <= 0)
      break;
    d.produced += n;
  }
  d.input = probe_b64(seed);
  d.input_len = probe_len(d.input);
  pack_token(&d);
}

static unsigned long flow_one_shot(unsigned long total, unsigned long seed) {
  const char *in = probe_b64(seed);
  if (!in)
    sys_exit(1);
  int in_len = probe_len(in);
  if ((unsigned long)in_len != total)
    sys_exit(1);
  unsigned char out[64];
  int n = decode_one_shot(in, in_len, out, (int)sizeof(out));
  if (n < 0)
    sys_exit(1);
  return (unsigned long)n;
}

static void flow_continue(unsigned long seed_or_dummy, const char *token) {
  (void)seed_or_dummy;
  stream_dec d = {0};
  if (unpack_token(token, &d) != 0)
    sys_exit(1);
  d.input = probe_b64((unsigned long)d.orig_seed);
  if (!d.input)
    sys_exit(1);
  d.input_len = probe_len(d.input);
  d.read_eof = d.pos >= d.input_len ? 1 : 0;
  d.err = 0;
  print_u64((unsigned long long)(d.produced + stream_len(&d)));
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *len_s, const char *arg) {
  init_maps();
  if (argc < 4)
    sys_exit(1);
  if (mode[0] != 'f' || mode[1] != 'l' || mode[2] != 'o' || mode[3] != 'w' || mode[4])
    sys_exit(1);
  unsigned long len = parse_u(len_s);
  if (arg[0] == '2') {
    flow_continue(0, arg);
    sys_exit(0);
  }
  unsigned long seed = parse_u(arg);
  if (len == PARTIAL_N) {
    flow_partial(len, seed);
    sys_exit(0);
  }
  print_u64((unsigned long long)flow_one_shot(len, seed));
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
