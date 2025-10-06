#include "wop_storage.h"

#include <string.h>

#include "xil_printf.h"
#include "wop_descriptor.h"
#include "../memory_map.h"

static uint32_t lut_buffer[WOP_TLWE_MAX_WORDS];
static uint32_t bsk_buffer[WOP_GLWE_MAX_WORDS];
static uint32_t ksk_buffer[WOP_GLWE_MAX_WORDS];

static void init_mock_assets(void)
{
    static int initialized = 0;
    if (initialized) {
        return;
    }
    for (uint32_t i = 0; i < WOP_TLWE_MAX_WORDS; ++i) {
        lut_buffer[i] = 0xA5A50000U | (i & 0xFFFFU);
    }
    for (uint32_t i = 0; i < WOP_GLWE_MAX_WORDS; ++i) {
        bsk_buffer[i] = 0x5AA50000U | (i & 0xFFFFU);
        ksk_buffer[i] = 0x3C3C0000U | (i & 0xFFFFU);
    }
    initialized = 1;
}

static int copy_asset(uint64_t dest_addr, const uint32_t *src, uint32_t words)
{
    if (words == 0 || words > WOP_GLWE_MAX_WORDS) {
        return 0;
    }
    volatile uint32_t *dst = (volatile uint32_t *)(uintptr_t)dest_addr;
    memcpy((void *)dst, src, (size_t)words * sizeof(uint32_t));
    return 0;
}

int wop_stage_assets_from_nand(uint16_t cmd_id)
{
    (void)cmd_id;
    init_mock_assets();

    const wop_descriptor_t *desc = (const wop_descriptor_t *)(uintptr_t)WOP_DESC_RING_BASE_ADDR;
    uint32_t tlwe_words = desc->tlwe_words;
    uint32_t glwe_words = desc->glwe_words;

    if (tlwe_words > WOP_TLWE_MAX_WORDS || glwe_words > WOP_GLWE_MAX_WORDS) {
        xil_printf("[WOP] descriptor words overflow tlwe=%u glwe=%u\r\n", tlwe_words, glwe_words);
        return -1;
    }

    switch (desc->mode) {
    case WOP_MODE_VP:
        copy_asset(desc->tlwe_src_addr, lut_buffer, tlwe_words);
        copy_asset(desc->gpu_shared_addr, bsk_buffer, glwe_words);
        break;
    case WOP_MODE_BE:
        copy_asset(desc->tlwe_src_addr, bsk_buffer, tlwe_words);
        copy_asset(desc->gpu_shared_addr, lut_buffer, glwe_words);
        break;
    case WOP_MODE_CB:
    default:
        copy_asset(desc->tlwe_src_addr, bsk_buffer, tlwe_words);
        copy_asset(desc->gpu_shared_addr, ksk_buffer, glwe_words);
        break;
    }

    xil_printf("[WOP] staged assets tlwe=%u glwe=%u mode=%u\r\n", tlwe_words, glwe_words, desc->mode);
    return 0;
}
