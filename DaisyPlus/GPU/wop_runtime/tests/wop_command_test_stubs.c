#include "wop_test_shim.h"

#include "wop_descriptor.h"

#include <stdarg.h>
#include <stdio.h>

static wop_asset_window_t g_windows[WOP_DESC_RING_CAPACITY];

void wop_test_clear_asset_windows(void) {
    for (unsigned int i = 0; i < WOP_DESC_RING_CAPACITY; ++i) {
        g_windows[i] = (wop_asset_window_t){0};
    }
}

void wop_test_set_asset_window(uint16_t slot, const wop_asset_window_t *window) {
    if (window == NULL) {
        return;
    }
    g_windows[slot & WOP_DESC_RING_SLOT_MASK] = *window;
}

int wop_stage_assets_from_nand(uint16_t cmd_id) {
    (void)cmd_id;
    return 0;
}

void wop_reserve_asset_blocks(void) {}

const wop_asset_window_t *wop_get_asset_window(uint16_t slot) {
    return &g_windows[slot & WOP_DESC_RING_SLOT_MASK];
}

int xil_printf(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    const int rc = vprintf(fmt, args);
    va_end(args);
    return rc;
}
