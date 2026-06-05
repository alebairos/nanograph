#include "ngb.h"
#include "sha256.h"

#include <stdlib.h>
#include <string.h>

static NgbStatus build_nodes(const uint8_t *elf, size_t elf_len,
                             const NgbNodeSpec *specs, uint32_t node_count,
                             NgbNode *nodes) {
  for (uint32_t i = 0; i < node_count; i++) {
    uint64_t nid = specs[i].node_id;
    uint32_t off = specs[i].offset;
    uint32_t nlen = specs[i].length;
    if ((uint64_t)off + nlen > elf_len)
      return NGB_ERR_I3_NODE_RANGE;
    for (uint32_t j = i + 1; j < node_count; j++) {
      if (nid == specs[j].node_id)
        return NGB_ERR_I5_NODE_DUP;
    }
    memset(&nodes[i], 0, sizeof(nodes[i]));
    nodes[i].node_id = nid;
    nodes[i].offset = off;
    nodes[i].length = nlen;
    ngb_sha256(elf + off, nlen, nodes[i].content_hash);
  }
  return NGB_OK;
}

NgbStatus ngb_pack_elf_nodes(const uint8_t *elf, size_t elf_len, uint16_t arch_id,
                             const NgbNodeSpec *specs, uint32_t node_count,
                             uint8_t **out, size_t *out_len) {
  if (!elf || !out || !out_len || !specs || elf_len == 0 || node_count == 0)
    return NGB_ERR_IO;

  const uint32_t image_off = NGB_HEADER_SIZE;
  const uint32_t node_off = image_off + (uint32_t)elf_len;
  const uint32_t patch_off = node_off + node_count * NGB_NODE_SIZE;

  NgbNode *nodes = calloc(node_count, sizeof(NgbNode));
  if (!nodes)
    return NGB_ERR_ALLOC;

  NgbStatus st = build_nodes(elf, elf_len, specs, node_count, nodes);
  if (st != NGB_OK) {
    free(nodes);
    return st;
  }

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
  if (!buf) {
    free(nodes);
    return NGB_ERR_ALLOC;
  }

  memcpy(buf, hdr, sizeof(hdr));
  memcpy(buf + image_off, elf, elf_len);
  memcpy(buf + node_off, nodes, node_count * sizeof(NgbNode));

  size_t hash_len = 32 + 24 + elf_len + node_count * sizeof(NgbNode);
  uint8_t *hash_in = malloc(hash_len);
  if (!hash_in) {
    free(buf);
    free(nodes);
    return NGB_ERR_ALLOC;
  }
  memcpy(hash_in, buf, 32);
  memcpy(hash_in + 32, buf + 40, 24);
  memcpy(hash_in + 32 + 24, elf, elf_len);
  memcpy(hash_in + 32 + 24 + elf_len, nodes, node_count * sizeof(NgbNode));
  ngb_sha256(hash_in, hash_len, buf + 32);
  free(hash_in);
  free(nodes);

  *out = buf;
  *out_len = total;
  return NGB_OK;
}

NgbStatus ngb_pack_elf(const uint8_t *elf, size_t elf_len, uint16_t arch_id,
                       uint64_t node_id, uint8_t **out, size_t *out_len) {
  NgbNodeSpec spec = {node_id, 0, (uint32_t)elf_len};
  return ngb_pack_elf_nodes(elf, elf_len, arch_id, &spec, 1, out, out_len);
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
