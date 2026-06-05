#include "ngb.h"
#include "sha256.h"

#include <stdlib.h>
#include <string.h>

static uint32_t u32le(const uint8_t *p) {
  return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) |
         ((uint32_t)p[3] << 24);
}

NgbStatus ngb_fill_root_hash(uint8_t *buf, size_t len) {
  if (!buf || len < NGB_HEADER_SIZE)
    return NGB_ERR_I2_BOUNDS;

  uint32_t image_off = u32le(buf + 12);
  uint32_t image_len = u32le(buf + 16);
  uint32_t node_off = u32le(buf + 20);
  uint32_t node_count = u32le(buf + 24);
  uint32_t patch_off = u32le(buf + 28);

  if ((uint64_t)image_off + image_len > len)
    return NGB_ERR_I2_BOUNDS;
  if ((uint64_t)node_off + (uint64_t)node_count * NGB_NODE_SIZE > len)
    return NGB_ERR_I2_BOUNDS;
  if (patch_off > len || patch_off < node_off + node_count * NGB_NODE_SIZE)
    return NGB_ERR_I2_BOUNDS;

  size_t patch_len = len - patch_off;
  size_t hash_in_len = 32 + 24 + image_len + node_count * NGB_NODE_SIZE + patch_len;
  uint8_t *hash_in = malloc(hash_in_len);
  if (!hash_in)
    return NGB_ERR_ALLOC;

  memcpy(hash_in, buf, 32);
  memset(hash_in + 32, 0, 24);
  memcpy(hash_in + 32 + 24, buf + image_off, image_len);
  if (node_count > 0)
    memcpy(hash_in + 32 + 24 + image_len, buf + node_off,
           node_count * NGB_NODE_SIZE);
  if (patch_len > 0)
    memcpy(hash_in + 32 + 24 + image_len + node_count * NGB_NODE_SIZE,
           buf + patch_off, patch_len);

  ngb_sha256(hash_in, hash_in_len, buf + 32);
  free(hash_in);
  return NGB_OK;
}
