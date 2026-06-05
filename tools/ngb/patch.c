#include "ngb.h"
#include "sha256.h"

#include <stdlib.h>
#include <string.h>

#define NGB_PATCH_HDR 128
#define NGB_PATCH_SIG 40

static uint32_t u32le(const uint8_t *p) {
  return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) |
         ((uint32_t)p[3] << 24);
}

static int ranges_overlap(uint32_t a0, uint32_t alen, uint32_t b0, uint32_t blen) {
  uint64_t a1 = (uint64_t)a0 + alen;
  uint64_t b1 = (uint64_t)b0 + blen;
  return a0 < b1 && b0 < a1;
}

NgbStatus ngb_apply_patch(const uint8_t *base, size_t base_len,
                          const NgbPatchInput *patch, uint8_t **out,
                          size_t *out_len) {
  if (!base || !patch || !out || !out_len || !patch->delta || patch->delta_len == 0)
    return NGB_ERR_IO;

  NgbStatus st = ngb_parse_validate(base, base_len);
  if (st != NGB_OK)
    return st;

  uint32_t image_off = u32le(base + 12);
  uint32_t image_len = u32le(base + 16);
  uint32_t node_off = u32le(base + 20);
  uint32_t node_count = u32le(base + 24);
  uint32_t patch_off = u32le(base + 28);

  if (patch->delta_len == 0 || patch->delta_len % 2 != 0)
    return NGB_ERR_IO;
  uint32_t delta_pairs = patch->delta_len / 2;
  if ((uint64_t)patch->delta_off + delta_pairs > image_len)
    return NGB_ERR_I3_NODE_RANGE;

  uint8_t *image = malloc(image_len);
  if (!image)
    return NGB_ERR_ALLOC;
  memcpy(image, base + image_off, image_len);
  for (uint32_t i = 0; i < delta_pairs; i++)
    image[patch->delta_off + i] = patch->delta[2 * i + 1];

  size_t nodes_sz = node_count * NGB_NODE_SIZE;
  uint8_t *nodes = malloc(nodes_sz);
  if (!nodes) {
    free(image);
    return NGB_ERR_ALLOC;
  }
  memcpy(nodes, base + node_off, nodes_sz);

  for (uint32_t i = 0; i < node_count; i++) {
    uint8_t *n = nodes + i * NGB_NODE_SIZE;
    uint32_t off = u32le(n + 8);
    uint32_t nlen = u32le(n + 12);
    if (ranges_overlap(off, nlen, patch->delta_off, delta_pairs))
      ngb_sha256(image + off, nlen, n + 16);
  }

  size_t patch_log_len = NGB_PATCH_HDR + patch->delta_len;
  size_t total = patch_off + patch_log_len;
  uint8_t *buf = malloc(total);
  if (!buf) {
    free(image);
    free(nodes);
    return NGB_ERR_ALLOC;
  }

  memcpy(buf, base, patch_off);
  memcpy(buf + image_off, image, image_len);
  memcpy(buf + node_off, nodes, nodes_sz);

  uint8_t *ph = buf + patch_off;
  memset(ph, 0, NGB_PATCH_HDR);
  memcpy(ph, &patch->patch_id, 8);
  memcpy(ph + 40, base + 32, 32);
  memcpy(ph + 72, &patch->delta_off, 4);
  memcpy(ph + 76, &patch->delta_len, 4);
  memcpy(ph + 120, &patch->timestamp, 8);
  memcpy(ph + NGB_PATCH_HDR, patch->delta, patch->delta_len);

  st = ngb_fill_root_hash(buf, total);
  free(image);
  free(nodes);
  if (st != NGB_OK) {
    free(buf);
    return st;
  }

  *out = buf;
  *out_len = total;
  return NGB_OK;
}

NgbStatus ngb_validate_patch_chain(const uint8_t *data, size_t len) {
  uint32_t image_off = u32le(data + 12);
  uint32_t image_len = u32le(data + 16);
  uint32_t node_off = u32le(data + 20);
  uint32_t node_count = u32le(data + 24);
  uint32_t patch_off = u32le(data + 28);

  if (patch_off >= len)
    return NGB_OK;

  uint8_t *image = malloc(image_len);
  if (!image)
    return NGB_ERR_ALLOC;
  memcpy(image, data + image_off, image_len);

  size_t patch_count = 0;
  size_t scan = patch_off;
  while (scan + NGB_PATCH_HDR <= len) {
    uint32_t dlen = u32le(data + scan + 76);
    if (dlen == 0 || dlen % 2 != 0)
      return NGB_ERR_I6_PATCH_CHAIN;
    size_t next = scan + NGB_PATCH_HDR + dlen;
    if (next > len || next <= scan)
      break;
    patch_count++;
    scan = next;
  }

  for (size_t rev = patch_count; rev > 0; rev--) {
    size_t pos = patch_off;
    for (size_t skip = 1; skip < rev; skip++) {
      uint32_t dlen = u32le(data + pos + 76);
      pos += NGB_PATCH_HDR + dlen;
    }
    const uint8_t *ph = data + pos;
    uint32_t delta_len = u32le(ph + 76);
    uint32_t delta_off = u32le(ph + 72);
    uint32_t pairs = delta_len / 2;
    const uint8_t *delta = ph + NGB_PATCH_HDR;
    if ((uint64_t)delta_off + pairs > image_len)
      return NGB_ERR_I6_PATCH_CHAIN;
    for (uint32_t i = 0; i < pairs; i++)
      image[delta_off + i] = delta[2 * i];
  }

  size_t nodes_sz = node_count * NGB_NODE_SIZE;
  uint8_t *nodes = malloc(nodes_sz);
  if (!nodes) {
    free(image);
    return NGB_ERR_ALLOC;
  }
  memcpy(nodes, data + node_off, nodes_sz);

  uint8_t expect[32];
  size_t hash_in_len = 32 + 24 + image_len + nodes_sz;
  uint8_t *hash_in = malloc(hash_in_len);
  if (!hash_in) {
    free(image);
    free(nodes);
    return NGB_ERR_ALLOC;
  }

  size_t pos = patch_off;
  while (pos + NGB_PATCH_HDR <= len) {
    const uint8_t *ph = data + pos;
    uint32_t delta_len = u32le(ph + 76);
    if (delta_len == 0 || delta_len % 2 != 0) {
      free(image);
      free(nodes);
      free(hash_in);
      return NGB_ERR_I6_PATCH_CHAIN;
    }
    uint32_t pairs = delta_len / 2;
    if (pos + NGB_PATCH_HDR + delta_len > len) {
      free(image);
      free(nodes);
      free(hash_in);
      return NGB_ERR_I6_PATCH_CHAIN;
    }

    memcpy(hash_in, data, 32);
    memset(hash_in + 32, 0, 24);
    memcpy(hash_in + 32 + 24, image, image_len);
    memcpy(hash_in + 32 + 24 + image_len, nodes, nodes_sz);
    ngb_sha256(hash_in, hash_in_len, expect);

    if (memcmp(expect, ph + 40, 32) != 0) {
      free(image);
      free(nodes);
      free(hash_in);
      return NGB_ERR_I6_PATCH_CHAIN;
    }

    uint32_t delta_off = u32le(ph + 72);
    if ((uint64_t)delta_off + pairs > image_len) {
      free(image);
      free(nodes);
      free(hash_in);
      return NGB_ERR_I6_PATCH_CHAIN;
    }
    const uint8_t *delta = ph + NGB_PATCH_HDR;
    for (uint32_t i = 0; i < pairs; i++)
      image[delta_off + i] = delta[2 * i + 1];

    for (uint32_t i = 0; i < node_count; i++) {
      uint8_t *n = nodes + i * NGB_NODE_SIZE;
      uint32_t off = u32le(n + 8);
      uint32_t nlen = u32le(n + 12);
      if (ranges_overlap(off, nlen, delta_off, pairs))
        ngb_sha256(image + off, nlen, n + 16);
    }

    pos += NGB_PATCH_HDR + delta_len;
  }

  free(image);
  free(nodes);
  free(hash_in);
  return NGB_OK;
}
