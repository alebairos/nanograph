#include "ngb.h"

const char *ngb_status_str(NgbStatus s) {
  switch (s) {
  case NGB_OK:
    return "ok";
  case NGB_ERR_IO:
    return "io";
  case NGB_ERR_ALLOC:
    return "alloc";
  case NGB_ERR_I1_MAGIC:
    return "I1:magic";
  case NGB_ERR_I1_VERSION:
    return "I1:version";
  case NGB_ERR_I2_BOUNDS:
    return "I2:bounds";
  case NGB_ERR_I3_NODE_RANGE:
    return "I3:node_range";
  case NGB_ERR_I4_NODE_HASH:
    return "I4:node_hash";
  case NGB_ERR_I5_NODE_DUP:
    return "I5:node_dup";
  case NGB_ERR_I6_PATCH_CHAIN:
    return "I6:patch_chain";
  case NGB_ERR_ROOT_HASH:
    return "root_hash";
  }
  return "unknown";
}
