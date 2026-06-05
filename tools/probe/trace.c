#include "trace.h"

#include <inttypes.h>
#include <stdio.h>
#include <string.h>

#define NGB_PATCH_HDR 128

static uint32_t u32le(const uint8_t *p) {
  return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) |
         ((uint32_t)p[3] << 24);
}

static uint64_t u64le(const uint8_t *p) {
  uint64_t v = 0;
  for (int i = 7; i >= 0; i--)
    v = (v << 8) | p[i];
  return v;
}

static void hex64(FILE *out, const uint8_t *b, size_t n) {
  static const char *d = "0123456789abcdef";
  for (size_t i = 0; i < n; i++) {
    fputc(d[(b[i] >> 4) & 0xf], out);
    fputc(d[b[i] & 0xf], out);
  }
}

NgbStatus ngb_probe_trace(const uint8_t *data, size_t len, FILE *out) {
  NgbStatus st = ngb_parse_validate(data, len);
  if (st != NGB_OK)
    return st;

  uint32_t patch_off = u32le(data + 28);
  char root[65];
  ngb_root_hash_hex(data, len, root);

  uint32_t patch_count = 0;
  size_t pos = patch_off;
  while (pos + NGB_PATCH_HDR <= len) {
    uint32_t delta_len = u32le(data + pos + 76);
    size_t next = pos + NGB_PATCH_HDR + delta_len;
    if (next > len || next <= pos)
      break;
    patch_count++;
    pos = next;
  }

  fprintf(out, "format=nano-probe-trace-v0\n");
  fprintf(out, "graph_root_hash=%s\n", root);
  fprintf(out, "patch_count=%u\n", patch_count);

  pos = patch_off;
  for (uint32_t step = 1; step <= patch_count; step++) {
    const uint8_t *h = data + pos;
    uint32_t delta_len = u32le(h + 76);
    fprintf(out, "trace step=%u patch_id=%" PRIu64 " precondition=", step,
            u64le(h));
    hex64(out, h + 40, 32);
    fprintf(out, " delta_off=%u delta_len=%u timestamp=%" PRIu64 "\n",
            u32le(h + 72), delta_len, u64le(h + 120));
    pos += NGB_PATCH_HDR + delta_len;
  }

  return NGB_OK;
}
