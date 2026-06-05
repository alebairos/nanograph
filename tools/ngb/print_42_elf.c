#include "ngb.h"

#include <string.h>

#define PRINT_42_E_ENTRY 0x400078ULL
#define PRINT_42_CODE_LEN 31U

size_t ngb_print_42_elf_build(uint8_t *out, size_t cap) {
  static const uint8_t data[] = {'4', '2', '\n'};
  const uint32_t data_vaddr = (uint32_t)(PRINT_42_E_ENTRY + PRINT_42_CODE_LEN);

  uint8_t code[PRINT_42_CODE_LEN] = {
      0xB8, 0x01, 0x00, 0x00, 0x00, 0xBF, 0x01, 0x00, 0x00, 0x00, 0xBE,
      (uint8_t)(data_vaddr & 0xff), (uint8_t)((data_vaddr >> 8) & 0xff),
      (uint8_t)((data_vaddr >> 16) & 0xff), (uint8_t)((data_vaddr >> 24) & 0xff),
      0xBA, 0x03, 0x00, 0x00, 0x00, 0x0F, 0x05, 0xB8, 0x3C, 0x00, 0x00,
      0x00, 0x31, 0xFF, 0x0F, 0x05,
  };

  return ngb_canonical_elf_build_segment(code, sizeof(code), data, sizeof(data), out,
                                         cap);
}
