#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void wop_test_io_bind(int fd, uint32_t size);
uint32_t wop_test_io_read32(uint32_t addr);
void wop_test_io_write32(uint32_t addr, uint32_t value);

#ifdef __cplusplus
}
#endif

#define IO_WRITE32(addr, val) wop_test_io_write32((uint32_t)(addr), (uint32_t)(val))
#define IO_READ32(addr)       wop_test_io_read32((uint32_t)(addr))
