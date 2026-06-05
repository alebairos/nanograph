#ifndef NGB_MICROOP_H
#define NGB_MICROOP_H

#include "ngb.h"

#include <stddef.h>
#include <stdint.h>

typedef enum {
  MICROOP_OK = 0,
  MICROOP_ERR_IO,
  MICROOP_ERR_SPEC,
  MICROOP_ERR_BOUNDS,
  MICROOP_ERR_NOT_RODATA,
  MICROOP_ERR_EXPECT_OLD
} MicroOpStatus;

const char *microop_status_str(MicroOpStatus s);

typedef struct {
  uint32_t image_off;
  uint8_t new_byte;
  int have_expect_old;
  uint8_t expect_old;
} MicroOpRodataByteWrite;

MicroOpStatus microop_parse_rodata_byte_write(const char *spec_path,
                                              MicroOpRodataByteWrite *out);

MicroOpStatus microop_validate_rodata_byte_write(const uint8_t *genesis,
                                                 size_t genesis_len,
                                                 const MicroOpRodataByteWrite *op);

MicroOpStatus microop_apply_rodata_byte_write(const uint8_t *genesis,
                                              size_t genesis_len,
                                              const MicroOpRodataByteWrite *op,
                                              uint64_t patch_id, uint64_t timestamp,
                                              uint8_t **out, size_t *out_len);

#endif
