#include "ngb.h"
#include "sha256.h"

#include <stdlib.h>
#include <string.h>

NgbStatus ngb_pack_elf(const uint8_t *elf, size_t elf_len, uint16_t arch_id,
                       uint64_t node_id, uint8_t **out, size_t *out_len) {
  if (!elf || !out || !out_len || elf_len == 0)
    return NGB_ERR_IO;

  const uint32_t node_count = 1;
  const uint32_t image_off = NGB_HEADER_SIZE;
  const uint32_t node_off = image_off + (uint32_t)elf_len;
  const uint32_t patch_off = node_off + node_count * NGB_NODE_SIZE;

  NgbNode node;
  memset(&node, 0, sizeof(node));
  node.node_id = node_id;
  node.offset = 0;
  node.length = (uint32_t)elf_len;
  ngb_sha256(elf, elf_len, node.content_hash);

  uint8_t hdr[NGB_HEADER_SIZE];
  memset(hdr, 0, sizeof(hdr));
  memcpy(hdr, NGB_MAGIC, 4);
  uint16_t ver = NGB_VERSION;
  memcpy(hdr + 4, &ver, 2);
  memcpy(hdr + 6, &arch_id, 2);
  uint32_t flags = 0;
  memcpy(hdr + 8, &flags, 4);
  memcpy(hdr + 12, &image_off, 4);
  uint32_t image_len = (uint32_t)elf_len;
  memcpy(hdr + 16, &image_len, 4);
  memcpy(hdr + 20, &node_off, 4);
  memcpy(hdr + 24, &node_count, 4);
  memcpy(hdr + 28, &patch_off, 4);

  size_t total = patch_off;
  uint8_t *buf = malloc(total);
  if (!buf)
    return NGB_ERR_ALLOC;

  memcpy(buf, hdr, sizeof(hdr));
  memcpy(buf + image_off, elf, elf_len);
  memcpy(buf + node_off, &node, sizeof(node));

  size_t hash_len = 32 + 24 + elf_len + sizeof(node);
  uint8_t *hash_in = malloc(hash_len);
  if (!hash_in) {
    free(buf);
    return NGB_ERR_ALLOC;
  }
  memcpy(hash_in, buf, 32);
  memcpy(hash_in + 32, buf + 40, 24);
  memcpy(hash_in + 32 + 24, elf, elf_len);
  memcpy(hash_in + 32 + 24 + elf_len, &node, sizeof(node));
  ngb_sha256(hash_in, hash_len, buf + 32);
  free(hash_in);

  *out = buf;
  *out_len = total;
  return NGB_OK;
}

void ngb_root_hash_hex(const uint8_t *ngb, size_t len, char hex[65]) {
  static const char *digits = "0123456789abcdef";
  if (len < 40) {
    hex[0] = '\0';
    return;
  }
  for (int i = 0; i < 32; i++) {
    hex[i * 2] = digits[(ngb[32 + i] >> 4) & 0xf];
    hex[i * 2 + 1] = digits[ngb[32 + i] & 0xf];
  }
  hex[64] = '\0';
}
