#define _XOPEN_SOURCE 700

#include "io_access.h"

#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int g_fd = -1;
static uint32_t g_size = 0;

void wop_test_io_bind(int fd, uint32_t size) {
    g_fd = fd;
    g_size = size;
}

static void ensure_bounds(uint32_t addr) {
    if (g_fd < 0) {
        fprintf(stderr, "[IO_STUB] device not bound\n");
        exit(EXIT_FAILURE);
    }
    if (addr + sizeof(uint32_t) > g_size) {
        fprintf(stderr, "[IO_STUB] address 0x%08X out of range (size=0x%08X)\n", addr, g_size);
        exit(EXIT_FAILURE);
    }
}

uint32_t wop_test_io_read32(uint32_t addr) {
    ensure_bounds(addr);
    uint32_t value = 0;
    const ssize_t ret = pread(g_fd, &value, sizeof(value), (off_t)addr);
    if (ret != (ssize_t)sizeof(value)) {
        fprintf(stderr, "[IO_STUB] pread failed: %s\n", strerror(errno));
        exit(EXIT_FAILURE);
    }
    return value;
}

void wop_test_io_write32(uint32_t addr, uint32_t value) {
    ensure_bounds(addr);
    const ssize_t ret = pwrite(g_fd, &value, sizeof(value), (off_t)addr);
    if (ret != (ssize_t)sizeof(value)) {
        fprintf(stderr, "[IO_STUB] pwrite failed: %s\n", strerror(errno));
        exit(EXIT_FAILURE);
    }
}
