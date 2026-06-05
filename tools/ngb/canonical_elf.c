#include "ngb.h"

#include <string.h>

size_t ngb_canonical_elf_build(const uint8_t *code, size_t code_len, uint8_t *out,
                               size_t cap) {
  const uint64_t e_entry = 0x400078;
  const uint32_t ph_off = 64;
  const uint32_t ph_num = 1;
  const uint32_t ph_entsize = 56;
  const uint64_t code_off = (uint64_t)ph_off + (uint64_t)ph_num * ph_entsize;
  const size_t total = 64 + 56 + code_len;

  if (!code || code_len == 0 || cap < total)
    return 0;

  static const uint8_t elf_magic[4] = {0x7f, 'E', 'L', 'F'};
  memset(out, 0, 64);
  memcpy(out, elf_magic, 4);
  out[4] = 2;
  out[5] = 1;
  out[6] = 1;
  out[16] = 2;
  out[18] = 0x3e;
  out[20] = 1;
  memcpy(out + 24, &e_entry, 8);
  const uint64_t ph_off64 = ph_off;
  memcpy(out + 32, &ph_off64, 8);
  out[52] = 64;
  out[54] = 56;
  out[56] = 1;

  uint8_t *ph = out + 64;
  memset(ph, 0, 56);
  uint32_t load = 1;
  memcpy(ph, &load, 4);
  uint32_t flags = 5;
  memcpy(ph + 4, &flags, 4);
  uint64_t code_vaddr = e_entry;
  memcpy(ph + 8, &code_off, 8);
  memcpy(ph + 16, &code_vaddr, 8);
  memcpy(ph + 24, &code_off, 8);
  uint64_t filesz = code_len;
  memcpy(ph + 32, &filesz, 8);
  memcpy(ph + 40, &filesz, 8);
  uint64_t align = 0x1000;
  memcpy(ph + 48, &align, 8);

  memcpy(out + (size_t)code_off, code, code_len);
  return total;
}
