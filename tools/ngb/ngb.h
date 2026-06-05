#ifndef NGB_H
#define NGB_H

#include <stddef.h>
#include <stdint.h>

#define NGB_MAGIC "NGB\x00"
#define NGB_HEADER_SIZE 64
#define NGB_NODE_SIZE 48
#define NGB_VERSION 0
#define NGB_ARCH_X86_64_LINUX_ELF 1

typedef struct {
  uint8_t magic[4];
  uint16_t version;
  uint16_t arch_id;
  uint32_t flags;
  uint32_t image_off;
  uint32_t image_len;
  uint32_t node_off;
  uint32_t node_count;
  uint32_t patch_off;
  uint32_t patch_count;
  uint8_t graph_root_hash[32];
  uint8_t reserved[8];
} NgbHeader;

typedef struct {
  uint64_t node_id;
  uint32_t offset;
  uint32_t length;
  uint8_t content_hash[32];
} NgbNode;

typedef struct {
  uint64_t node_id;
  uint32_t offset;
  uint32_t length;
} NgbNodeSpec;

typedef enum {
  NGB_OK = 0,
  NGB_ERR_IO,
  NGB_ERR_ALLOC,
  NGB_ERR_I1_MAGIC,
  NGB_ERR_I1_VERSION,
  NGB_ERR_I2_BOUNDS,
  NGB_ERR_I3_NODE_RANGE,
  NGB_ERR_I4_NODE_HASH,
  NGB_ERR_I5_NODE_DUP,
  NGB_ERR_I6_PATCH_CHAIN,
  NGB_ERR_ROOT_HASH
} NgbStatus;

const char *ngb_status_str(NgbStatus s);

size_t ngb_canonical_elf_build(const uint8_t *code, size_t code_len, uint8_t *out,
                               size_t cap);

size_t ngb_hello_elf_build(uint8_t *out, size_t cap);
size_t ngb_add_two_elf_build(uint8_t *out, size_t cap);

NgbStatus ngb_pack_elf_nodes(const uint8_t *elf, size_t elf_len, uint16_t arch_id,
                             const NgbNodeSpec *specs, uint32_t node_count,
                             uint8_t **out, size_t *out_len);

NgbStatus ngb_pack_elf(const uint8_t *elf, size_t elf_len, uint16_t arch_id,
                       uint64_t node_id, uint8_t **out, size_t *out_len);

/* parse.c — validate invariants I1–I6 */
NgbStatus ngb_parse_validate(const uint8_t *data, size_t len);

void ngb_root_hash_hex(const uint8_t *ngb, size_t len, char hex[65]);

#endif
