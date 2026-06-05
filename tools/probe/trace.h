#ifndef PROBE_TRACE_H
#define PROBE_TRACE_H

#include "../ngb/ngb.h"

#include <stdio.h>

NgbStatus ngb_probe_trace(const uint8_t *data, size_t len, FILE *out);

#endif
