#include "ngb.h"

size_t ngb_hello_elf_build(uint8_t *out, size_t cap) {
  static const uint8_t code[] = {0xB8, 0x3C, 0x00, 0x00, 0x00, 0x48,
                                 0x31, 0xFF, 0x0F, 0x05};
  return ngb_canonical_elf_build(code, sizeof(code), out, cap);
}
