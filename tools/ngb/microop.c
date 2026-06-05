#include "microop.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum { CLS_DB = 0, CLS_INSTR = 1 } DisasmClass;

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

static int elf_code_region(const uint8_t *image, uint32_t image_len,
                           uint32_t *code_off, uint32_t *code_len) {
  if (image_len < 120 || image[0] != 0x7f || image[1] != 'E' || image[2] != 'L' ||
      image[3] != 'F')
    return 0;
  uint64_t off = u64le(image + 72);
  uint64_t filesz = u64le(image + 96);
  if (off >= image_len || filesz == 0 || off + filesz > image_len)
    return 0;
  *code_off = (uint32_t)off;
  *code_len = (uint32_t)filesz;
  return 1;
}

static size_t classify_one(const uint8_t *p, size_t avail, DisasmClass *cls) {
  if (avail == 0)
    return 0;
  if (p[0] == 0xB8 && avail >= 5) {
    *cls = CLS_INSTR;
    return 5;
  }
  if (p[0] == 0xBF && avail >= 5) {
    *cls = CLS_INSTR;
    return 5;
  }
  if (p[0] == 0xBE && avail >= 5) {
    *cls = CLS_INSTR;
    return 5;
  }
  if (p[0] == 0xBA && avail >= 5) {
    *cls = CLS_INSTR;
    return 5;
  }
  if (p[0] == 0x83 && avail >= 3 && p[1] == 0xC0) {
    *cls = CLS_INSTR;
    return 3;
  }
  if (p[0] == 0x89 && avail >= 2 && p[1] == 0xC7) {
    *cls = CLS_INSTR;
    return 2;
  }
  if (p[0] == 0x48 && avail >= 3 && p[1] == 0x31 && p[2] == 0xFF) {
    *cls = CLS_INSTR;
    return 3;
  }
  if (p[0] == 0x31 && avail >= 2 && p[1] == 0xFF) {
    *cls = CLS_INSTR;
    return 2;
  }
  if (p[0] == 0x0F && avail >= 2 && p[1] == 0x05) {
    *cls = CLS_INSTR;
    return 2;
  }
  *cls = CLS_DB;
  return 1;
}

static int image_offset_is_rodata(const uint8_t *image, uint32_t image_len,
                                  uint32_t image_off) {
  uint32_t code_off = 0, code_len = 0;
  if (!elf_code_region(image, image_len, &code_off, &code_len))
    return 0;
  if (image_off < code_off || image_off >= code_off + code_len)
    return 0;

  uint8_t *kinds = calloc(code_len, 1);
  if (!kinds)
    return 0;

  uint32_t pos = 0;
  while (pos < code_len) {
    DisasmClass cls = CLS_DB;
    size_t step = classify_one(image + code_off + pos, code_len - pos, &cls);
    if (step == 0)
      break;
    for (size_t i = 0; i < step && pos + i < code_len; i++)
      kinds[pos + i] = (uint8_t)(cls == CLS_DB ? 1 : 2);
    pos += (uint32_t)step;
  }

  uint32_t rel = image_off - code_off;
  int ok = rel < code_len && kinds[rel] == 1;
  free(kinds);
  return ok;
}

const char *microop_status_str(MicroOpStatus s) {
  switch (s) {
  case MICROOP_OK:
    return "ok";
  case MICROOP_ERR_IO:
    return "io";
  case MICROOP_ERR_SPEC:
    return "spec";
  case MICROOP_ERR_BOUNDS:
    return "bounds";
  case MICROOP_ERR_NOT_RODATA:
    return "not_rodata";
  case MICROOP_ERR_EXPECT_OLD:
    return "expect_old";
  default:
    return "unknown";
  }
}

MicroOpStatus microop_parse_rodata_byte_write(const char *spec_path,
                                              MicroOpRodataByteWrite *out) {
  if (!spec_path || !out)
    return MICROOP_ERR_IO;

  FILE *f = fopen(spec_path, "r");
  if (!f)
    return MICROOP_ERR_IO;

  memset(out, 0, sizeof(*out));
  int have_kind = 0, have_off = 0, have_new = 0;
  char line[256];

  while (fgets(line, sizeof line, f)) {
    char *eq = strchr(line, '=');
    if (line[0] == '#' || line[0] == '\n' || !eq)
      continue;
    *eq = '\0';
    char *key = line;
    char *val = eq + 1;
    val[strcspn(val, "\r\n")] = '\0';

    if (strcmp(key, "kind") == 0) {
      if (strcmp(val, "rodata_byte_write") != 0) {
        fclose(f);
        return MICROOP_ERR_SPEC;
      }
      have_kind = 1;
    } else if (strcmp(key, "image_off") == 0) {
      out->image_off = (uint32_t)strtoul(val, NULL, 10);
      have_off = 1;
    } else if (strcmp(key, "new") == 0) {
      unsigned int v = 0;
      if (sscanf(val, "%2x", &v) != 1 || v > 255) {
        fclose(f);
        return MICROOP_ERR_SPEC;
      }
      out->new_byte = (uint8_t)v;
      have_new = 1;
    } else if (strcmp(key, "expect_old") == 0) {
      unsigned int v = 0;
      if (sscanf(val, "%2x", &v) != 1 || v > 255) {
        fclose(f);
        return MICROOP_ERR_SPEC;
      }
      out->expect_old = (uint8_t)v;
      out->have_expect_old = 1;
    }
  }
  fclose(f);

  if (!have_kind || !have_off || !have_new)
    return MICROOP_ERR_SPEC;
  return MICROOP_OK;
}

static int ngb_image_slice(const uint8_t *genesis, size_t genesis_len,
                           const uint8_t **image, uint32_t *image_len) {
  if (genesis_len < 64 || memcmp(genesis, "NGB\x00", 4) != 0)
    return 0;
  uint32_t off = u32le(genesis + 12);
  uint32_t len = u32le(genesis + 16);
  if ((uint64_t)off + len > genesis_len)
    return 0;
  *image = genesis + off;
  *image_len = len;
  return 1;
}

MicroOpStatus microop_validate_rodata_byte_write(const uint8_t *genesis,
                                                 size_t genesis_len,
                                                 const MicroOpRodataByteWrite *op) {
  if (!genesis || !op)
    return MICROOP_ERR_IO;

  const uint8_t *image = NULL;
  uint32_t image_len = 0;
  if (!ngb_image_slice(genesis, genesis_len, &image, &image_len))
    return MICROOP_ERR_IO;

  if (op->image_off >= image_len)
    return MICROOP_ERR_BOUNDS;

  if (!image_offset_is_rodata(image, image_len, op->image_off))
    return MICROOP_ERR_NOT_RODATA;

  if (op->have_expect_old && image[op->image_off] != op->expect_old)
    return MICROOP_ERR_EXPECT_OLD;

  return MICROOP_OK;
}

MicroOpStatus microop_apply_rodata_byte_write(const uint8_t *genesis,
                                              size_t genesis_len,
                                              const MicroOpRodataByteWrite *op,
                                              uint64_t patch_id, uint64_t timestamp,
                                              uint8_t **out, size_t *out_len) {
  MicroOpStatus ms = microop_validate_rodata_byte_write(genesis, genesis_len, op);
  if (ms != MICROOP_OK)
    return ms;

  const uint8_t *image = NULL;
  uint32_t image_len = 0;
  if (!ngb_image_slice(genesis, genesis_len, &image, &image_len))
    return MICROOP_ERR_IO;

  uint8_t delta[2] = {image[op->image_off], op->new_byte};
  NgbPatchInput patch = {
      .patch_id = patch_id,
      .delta_off = op->image_off,
      .delta_len = 2,
      .delta = delta,
      .timestamp = timestamp,
  };

  NgbStatus st = ngb_apply_patch(genesis, genesis_len, &patch, out, out_len);
  if (st != NGB_OK)
    return MICROOP_ERR_IO;
  return MICROOP_OK;
}
