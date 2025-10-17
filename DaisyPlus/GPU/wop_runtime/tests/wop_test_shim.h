#pragma once

#include "wop_storage.h"

#ifdef __cplusplus
extern "C" {
#endif

void wop_test_clear_asset_windows(void);
void wop_test_set_asset_window(uint16_t slot, const wop_asset_window_t *window);

#ifdef __cplusplus
}
#endif
