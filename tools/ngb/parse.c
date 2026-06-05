#include "ngb.h"
#include "sha256.h"

#include <stdlib.h>
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

NgbStatus ngb_parse_validate(const uint8_t *data, size_t len) {
  if (!data || len < NGB_HEADER_SIZE)
    return NGB_ERR_I2_BOUNDS;

  if (memcmp(data, NGB_MAGIC, 4) != 0)
    return NGB_ERR_I1_MAGIC;

  uint16_t version = (uint16_t)(data[4] | (data[5] << 8));
  if (version != NGB_VERSION)
    return NGB_ERR_I1_VERSION;

  uint32_t image_off = u32le(data + 12);
  uint32_t image_len = u32le(data + 16);
  uint32_t node_off = u32le(data + 20);
  uint32_t node_count = u32le(data + 24);
  uint32_t patch_off = u32le(data + 28);

  if (image_off < NGB_HEADER_SIZE || image_len == 0)
    return NGB_ERR_I2_BOUNDS;
  if ((uint64_t)image_off + image_len > len)
    return NGB_ERR_I2_BOUNDS;
  if (node_off < image_off + image_len)
    return NGB_ERR_I2_BOUNDS;
  if ((uint64_t)node_off + (uint64_t)node_count * NGB_NODE_SIZE > len)
    return NGB_ERR_I2_BOUNDS;
  if (patch_off < node_off + node_count * NGB_NODE_SIZE)
    return NGB_ERR_I2_BOUNDS;
  if (patch_off > len)
    return NGB_ERR_I2_BOUNDS;

  uint8_t *tmp = malloc(len);
  if (!tmp)
    return NGB_ERR_ALLOC;
  memcpy(tmp, data, len);
  NgbStatus st = ngb_fill_root_hash(tmp, len);
  if (st != NGB_OK) {
    free(tmp);
    return st;
  }
  if (memcmp(tmp + 32, data + 32, 32) != 0) {
    free(tmp);
    return NGB_ERR_ROOT_HASH;
  }
  free(tmp);

  for (uint32_t i = 0; i < node_count; i++) {
    const uint8_t *n = data + node_off + i * NGB_NODE_SIZE;
    uint64_t nid = u64le(n);
    uint32_t off = u32le(n + 8);
    uint32_t nlen = u32le(n + 12);
    if ((uint64_t)off + nlen > image_len)
      return NGB_ERR_I3_NODE_RANGE;
    uint8_t h[32];
    ngb_sha256(data + image_off + off, nlen, h);
    if (memcmp(h, n + 16, 32) != 0)
      return NGB_ERR_I4_NODE_HASH;
    for (uint32_t j = i + 1; j < node_count; j++) {
      if (nid == u64le(data + node_off + j * NGB_NODE_SIZE))
        return NGB_ERR_I5_NODE_DUP;
    }
  }

  if (patch_off < len) {
    st = ngb_validate_patch_chain(data, len);
    if (st != NGB_OK)
      return st;
  }

  return NGB_OK;
}
