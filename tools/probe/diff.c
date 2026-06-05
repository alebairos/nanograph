#include "diff.h"

#include <inttypes.h>
#include <stdio.h>
#include <string.h>

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

static int find_node(const uint8_t *data, uint32_t node_off, uint32_t node_count,
                     uint64_t id, const uint8_t **out) {
  for (uint32_t i = 0; i < node_count; i++) {
    const uint8_t *n = data + node_off + i * NGB_NODE_SIZE;
    if (u64le(n) == id) {
      *out = n;
      return 1;
    }
  }
  return 0;
}

NgbStatus ngb_probe_diff(const uint8_t *left, size_t left_len, const uint8_t *right,
                         size_t right_len, FILE *out) {
  NgbStatus st = ngb_parse_validate(left, left_len);
  if (st != NGB_OK)
    return st;
  st = ngb_parse_validate(right, right_len);
  if (st != NGB_OK)
    return st;

  uint32_t left_image_off = u32le(left + 12);
  uint32_t left_image_len = u32le(left + 16);
  uint32_t left_node_off = u32le(left + 20);
  uint32_t left_node_count = u32le(left + 24);

  uint32_t right_image_off = u32le(right + 12);
  uint32_t right_image_len = u32le(right + 16);
  uint32_t right_node_off = u32le(right + 20);
  uint32_t right_node_count = u32le(right + 24);

  char left_root[65];
  char right_root[65];
  ngb_root_hash_hex(left, left_len, left_root);
  ngb_root_hash_hex(right, right_len, right_root);

  fprintf(out, "format=nano-probe-diff-v0\n");
  fprintf(out, "left_graph_root_hash=%s\n", left_root);
  fprintf(out, "right_graph_root_hash=%s\n", right_root);

  uint32_t max_image = left_image_len > right_image_len ? left_image_len : right_image_len;
  for (uint32_t i = 0; i < max_image; i++) {
    uint8_t lb = i < left_image_len ? left[left_image_off + i] : 0;
    uint8_t rb = i < right_image_len ? right[right_image_off + i] : 0;
    if (lb != rb)
      fprintf(out, "image_byte offset=%u left=%02x right=%02x\n", i, lb, rb);
  }

  for (uint32_t i = 0; i < left_node_count; i++) {
    const uint8_t *ln = left + left_node_off + i * NGB_NODE_SIZE;
    uint64_t id = u64le(ln);
    const uint8_t *rn = NULL;
    if (!find_node(right, right_node_off, right_node_count, id, &rn)) {
      fprintf(out, "node_removed id=%" PRIu64 "\n", id);
      continue;
    }
    if (u32le(ln + 8) != u32le(rn + 8) || u32le(ln + 12) != u32le(rn + 12)) {
      fprintf(out, "node_changed id=%" PRIu64 " field=span left_offset=%u left_length=%u "
                     "right_offset=%u right_length=%u\n",
              id, u32le(ln + 8), u32le(ln + 12), u32le(rn + 8), u32le(rn + 12));
    }
    if (memcmp(ln + 16, rn + 16, 32) != 0) {
      fprintf(out, "node_changed id=%" PRIu64 " field=content_hash left=", id);
      hex64(out, ln + 16, 32);
      fprintf(out, " right=");
      hex64(out, rn + 16, 32);
      fputc('\n', out);
    }
  }

  for (uint32_t i = 0; i < right_node_count; i++) {
    const uint8_t *rn = right + right_node_off + i * NGB_NODE_SIZE;
    uint64_t id = u64le(rn);
    const uint8_t *ln = NULL;
    if (!find_node(left, left_node_off, left_node_count, id, &ln))
      fprintf(out, "node_added id=%" PRIu64 "\n", id);
  }

  return NGB_OK;
}
