#include "audit_log.h"

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

static uint32_t count_patches(const uint8_t *data, size_t len, uint32_t patch_off) {
  uint32_t count = 0;
  size_t pos = patch_off;
  while (pos + NGB_PATCH_HDR <= len) {
    uint32_t delta_len = u32le(data + pos + 76);
    size_t next = pos + NGB_PATCH_HDR + delta_len;
    if (next > len || next <= pos)
      break;
    count++;
    pos = next;
  }
  return count;
}

NgbStatus ngb_probe_audit_log(const uint8_t *data, size_t len, FILE *out) {
  NgbStatus st = ngb_parse_validate(data, len);
  if (st != NGB_OK)
    return st;

  uint16_t arch_id = (uint16_t)(data[6] | (data[7] << 8));
  uint32_t image_len = u32le(data + 16);
  uint32_t node_off = u32le(data + 20);
  uint32_t node_count = u32le(data + 24);
  uint32_t patch_off = u32le(data + 28);

  char root[65];
  ngb_root_hash_hex(data, len, root);

  fprintf(out, "format=nano-probe-audit-log-v0\n");
  fprintf(out, "graph_root_hash=%s\n", root);
  fprintf(out, "arch_id=%u\n", (unsigned)arch_id);
  fprintf(out, "image_len=%u\n", image_len);
  fprintf(out, "node_count=%u\n", node_count);

  uint32_t patch_count = count_patches(data, len, patch_off);
  fprintf(out, "patch_count=%u\n", patch_count);

  for (uint32_t i = 0; i < node_count; i++) {
    const uint8_t *n = data + node_off + i * NGB_NODE_SIZE;
    fprintf(out, "node id=%" PRIu64 " offset=%u length=%u content_hash=",
            u64le(n), u32le(n + 8), u32le(n + 12));
    hex64(out, n + 16, 32);
    fputc('\n', out);
  }

  size_t pos = patch_off;
  for (uint32_t p = 0; p < patch_count; p++) {
    const uint8_t *h = data + pos;
    uint32_t delta_len = u32le(h + 76);
    fprintf(out, "patch id=%" PRIu64 " parent=", u64le(h));
    hex64(out, h + 8, 32);
    fprintf(out, " precondition=");
    hex64(out, h + 40, 32);
    fprintf(out, " delta_off=%u delta_len=%u timestamp=%" PRIu64 " sig=",
            u32le(h + 72), delta_len, u64le(h + 120));
    hex64(out, h + 80, 40);
    fputc('\n', out);
    pos += NGB_PATCH_HDR + delta_len;
  }

  return NGB_OK;
}
