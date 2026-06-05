#ifndef PROBE_AUDIT_LOG_H
#define PROBE_AUDIT_LOG_H

#include "../ngb/ngb.h"

#include <stdio.h>

NgbStatus ngb_probe_audit_log(const uint8_t *data, size_t len, FILE *out);

#endif
