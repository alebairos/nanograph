#ifndef PROBE_DISASSEMBLE_H
#define PROBE_DISASSEMBLE_H

#include "../ngb/ngb.h"

#include <stdio.h>

NgbStatus ngb_probe_disassemble(const uint8_t *data, size_t len, FILE *out);

#endif
