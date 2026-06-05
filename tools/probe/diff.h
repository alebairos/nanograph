#ifndef PROBE_DIFF_H
#define PROBE_DIFF_H

#include "../ngb/ngb.h"

#include <stdio.h>

NgbStatus ngb_probe_diff(const uint8_t *left, size_t left_len, const uint8_t *right,
                         size_t right_len, FILE *out);

#endif
