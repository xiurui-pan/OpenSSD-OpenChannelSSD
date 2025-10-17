#include "wop_storage.h"

#include <errno.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#include "xil_printf.h"
#include "wop_descriptor.h"
#include "../memory_map.h"
#include "ftl_config.h"
#include "address_translation.h"
#include "request_allocation.h"
#include "request_schedule.h"
#include "request_transform.h"
#include "nsc_driver.h"

#define WOP_WORDS_PER_PAGE   (BYTES_PER_DATA_REGION_OF_NAND_ROW / sizeof(uint32_t))
#define WOP_PAGES_PER_BLOCK  (ROWS_PER_SLC_BLOCK)
#define WOP_WORDS_PER_BLOCK  (WOP_WORDS_PER_PAGE * WOP_PAGES_PER_BLOCK)

#define WOP_POLL_LIMIT             1000000U
#define WOP_STAGE_WAIT_LIMIT       (WOP_POLL_LIMIT * 16U)
#define WOP_STAGE_MAX_OUTSTANDING  4U

typedef enum {
    WOP_ASSET_LUT,
    WOP_ASSET_BSK,
    WOP_ASSET_KSK,
    WOP_ASSET_COUNT
} wop_asset_e;

typedef struct {
    const wop_asset_bank_t *banks;
    uint32_t                bank_count;
} wop_asset_layout_t;

static const wop_asset_bank_t kLutBanks[] = {
    { .channel = 3U, .way = 1U, .block_start = 16U, .block_count = WOP_NAND_BLOCKS_LUT }
};

static const wop_asset_bank_t kBskBanks[] = {
    { .channel = 3U, .way = 1U, .block_start = 32U, .block_count = WOP_NAND_BLOCKS_BSK }
};

static const wop_asset_bank_t kKskBanks[] = {
    { .channel = 3U, .way = 1U, .block_start = 96U, .block_count = WOP_NAND_BLOCKS_KSK }
};

static const wop_asset_layout_t kAssetLayouts[WOP_ASSET_COUNT] = {
    [WOP_ASSET_LUT] = { kLutBanks, sizeof(kLutBanks) / sizeof(kLutBanks[0]) },
    [WOP_ASSET_BSK] = { kBskBanks, sizeof(kBskBanks) / sizeof(kBskBanks[0]) },
    [WOP_ASSET_KSK] = { kKskBanks, sizeof(kKskBanks) / sizeof(kKskBanks[0]) },
};

static wop_asset_window_t g_asset_windows[WOP_DESC_RING_CAPACITY];

static uint32_t page_scratch[WOP_STAGE_MAX_OUTSTANDING]
                           [(BYTES_PER_DATA_REGION_OF_SLICE + BYTES_PER_SPARE_REGION_OF_SLICE) / sizeof(uint32_t)];

typedef struct {
    bool         active;
    unsigned int req_slot;
    uint32_t     words;
    uint32_t     guard;
    uint8_t      scratch_idx;
    uint8_t     *dst_ptr;
    uint8_t      channel;
    uint8_t      way;
    uint16_t     block;
    uint16_t     page;
} wop_stage_pending_t;

static int wop_issue_read_request(uint8_t channel,
                                  uint8_t way,
                                  uint16_t block,
                                  uint16_t page,
                                  uint8_t scratch_idx,
                                  unsigned int *slot_out)
{
    const unsigned int slot = GetFromFreeReqQ();

    reqPoolPtr->reqPool[slot].reqType = REQ_TYPE_NAND;
    reqPoolPtr->reqPool[slot].reqCode = REQ_CODE_READ;
    reqPoolPtr->reqPool[slot].reqOpt.dataBufFormat = REQ_OPT_DATA_BUF_ADDR;
    reqPoolPtr->reqPool[slot].reqOpt.nandAddr = REQ_OPT_NAND_ADDR_PHY_ORG;
    reqPoolPtr->reqPool[slot].reqOpt.nandEcc = REQ_OPT_NAND_ECC_ON;
    reqPoolPtr->reqPool[slot].reqOpt.nandEccWarning = REQ_OPT_NAND_ECC_WARNING_ON;
    reqPoolPtr->reqPool[slot].reqOpt.rowAddrDependencyCheck = REQ_OPT_ROW_ADDR_DEPENDENCY_NONE;
    reqPoolPtr->reqPool[slot].reqOpt.blockSpace = REQ_OPT_BLOCK_SPACE_TOTAL;

    reqPoolPtr->reqPool[slot].dataBufInfo.addr =
        (unsigned int)(uintptr_t)&page_scratch[scratch_idx][0];

    reqPoolPtr->reqPool[slot].nandInfo.physicalCh = channel;
    reqPoolPtr->reqPool[slot].nandInfo.physicalWay = way;
    reqPoolPtr->reqPool[slot].nandInfo.physicalBlock = block;
    reqPoolPtr->reqPool[slot].nandInfo.physicalPage = page;

    SelectLowLevelReqQ(slot);

    *slot_out = slot;
    return 0;
}

static void wop_reset_pending(wop_stage_pending_t pending[WOP_STAGE_MAX_OUTSTANDING])
{
    for (uint32_t i = 0U; i < WOP_STAGE_MAX_OUTSTANDING; ++i) {
        pending[i].active      = false;
        pending[i].req_slot    = 0U;
        pending[i].words       = 0U;
        pending[i].guard       = 0U;
        pending[i].scratch_idx = (uint8_t)i;
        pending[i].dst_ptr     = NULL;
        pending[i].channel     = 0U;
        pending[i].way         = 0U;
        pending[i].block       = 0U;
        pending[i].page        = 0U;
    }
}

static int wop_enqueue_page(uint8_t channel,
                            uint8_t way,
                            uint16_t block,
                            uint16_t page,
                            uint32_t words,
                            uint8_t *dst_ptr,
                            wop_stage_pending_t pending[WOP_STAGE_MAX_OUTSTANDING],
                            uint32_t *outstanding)
{
    uint32_t slot_idx = WOP_STAGE_MAX_OUTSTANDING;
    for (uint32_t i = 0U; i < WOP_STAGE_MAX_OUTSTANDING; ++i) {
        if (!pending[i].active) {
            slot_idx = i;
            break;
        }
    }

    if (slot_idx == WOP_STAGE_MAX_OUTSTANDING) {
        return -EAGAIN;
    }

    SyncAvailFreeReq();

    unsigned int req_slot = 0U;
    const int rc = wop_issue_read_request(channel, way, block, page, (uint8_t)slot_idx, &req_slot);
    if (rc != 0) {
        return rc;
    }

    pending[slot_idx].active      = true;
    pending[slot_idx].req_slot    = req_slot;
    pending[slot_idx].words       = words;
    pending[slot_idx].guard       = WOP_STAGE_WAIT_LIMIT;
    pending[slot_idx].scratch_idx = (uint8_t)slot_idx;
    pending[slot_idx].dst_ptr     = dst_ptr;
    pending[slot_idx].channel     = channel;
    pending[slot_idx].way         = way;
    pending[slot_idx].block       = block;
    pending[slot_idx].page        = page;

    (*outstanding)++;
    return 0;
}

static int wop_poll_pending(wop_stage_pending_t pending[WOP_STAGE_MAX_OUTSTANDING],
                            uint32_t *outstanding,
                            bool wait_for_completion)
{
    if (*outstanding == 0U) {
        return 0;
    }

    do {
        bool progress = false;

        CheckDoneNvmeDmaReq();
        SchedulingNandReq();

        for (uint32_t i = 0U; i < WOP_STAGE_MAX_OUTSTANDING; ++i) {
            wop_stage_pending_t *entry = &pending[i];
            if (!entry->active) {
                continue;
            }

            const unsigned int queue_type = reqPoolPtr->reqPool[entry->req_slot].reqQueueType;
            if (queue_type == REQ_QUEUE_TYPE_FREE || queue_type == REQ_QUEUE_TYPE_NONE) {
                unsigned int status = statusReportTablePtr->statusReport[entry->channel][entry->way];
                status = V2FEliminateReportDoneFlag(status);
                if (V2FRequestFail(status)) {
                    xil_printf("[WOP] NAND status fail ch=%u way=%u block=%u page=%u status=0x%08X\r\n",
                               entry->channel, entry->way, entry->block, entry->page, status);
                    entry->active = false;
                    (*outstanding)--;
                    return -EIO;
                }

                if (!V2FPageDecodeSuccess(eccErrorInfoTablePtr->errorInfo[entry->channel][entry->way])) {
                    xil_printf("[WOP] NAND ECC failure ch=%u way=%u block=%u page=%u err0=0x%08X\r\n",
                               entry->channel, entry->way, entry->block, entry->page,
                               eccErrorInfoTablePtr->errorInfo[entry->channel][entry->way][0]);
                    entry->active = false;
                    (*outstanding)--;
                    return -EIO;
                }

                const size_t copy_bytes = (size_t)entry->words * sizeof(uint32_t);
                if (copy_bytes > 0U && entry->dst_ptr != NULL) {
                    memcpy(entry->dst_ptr, page_scratch[entry->scratch_idx], copy_bytes);
                }

                entry->active = false;
                (*outstanding)--;
                progress = true;
            } else {
                if (entry->guard > 0U) {
                    entry->guard--;
                } else {
                    xil_printf("[WOP] NAND read timeout ch=%u way=%u block=%u page=%u\r\n",
                               entry->channel, entry->way, entry->block, entry->page);
                    entry->active = false;
                    (*outstanding)--;
                    return -ETIMEDOUT;
                }
            }
        }

        if (!wait_for_completion) {
            return 0;
        }

        if (!progress) {
            // If no request completed this cycle, loop again until guard expires.
            continue;
        }
    } while (*outstanding > 0U);

    return 0;
}

static int load_asset_region(const wop_asset_layout_t *layout,
                             uint32_t words,
                             uint64_t dest_addr)
{
    if (words == 0U || layout->bank_count == 0U) {
        return 0;
    }

    uint32_t words_remaining = words;
    uint8_t *next_dst = (uint8_t *)(uintptr_t)dest_addr;
    wop_stage_pending_t pending[WOP_STAGE_MAX_OUTSTANDING];
    uint32_t outstanding = 0U;

    wop_reset_pending(pending);

    for (uint32_t bank_idx = 0U; bank_idx < layout->bank_count && words_remaining > 0U; ++bank_idx) {
        const wop_asset_bank_t *bank = &layout->banks[bank_idx];
        const uint64_t bank_capacity_words = (uint64_t)bank->block_count * (uint64_t)WOP_WORDS_PER_BLOCK;
        if (bank_capacity_words == 0U) {
            continue;
        }

        for (uint16_t block_offset = 0U; block_offset < bank->block_count && words_remaining > 0U; ++block_offset) {
            const uint16_t block = (uint16_t)(bank->block_start + block_offset);

            for (uint16_t page = 0U; page < WOP_PAGES_PER_BLOCK && words_remaining > 0U; ++page) {
                const uint32_t page_words =
                    (words_remaining > WOP_WORDS_PER_PAGE) ? WOP_WORDS_PER_PAGE : words_remaining;

                while (outstanding >= WOP_STAGE_MAX_OUTSTANDING) {
                    const int wait_rc = wop_poll_pending(pending, &outstanding, true);
                    if (wait_rc != 0) {
                        return wait_rc;
                    }
                }

                int rc = wop_enqueue_page(bank->channel,
                                          bank->way,
                                          block,
                                          page,
                                          page_words,
                                          next_dst,
                                          pending,
                                          &outstanding);
                if (rc != 0) {
                    return rc;
                }

                next_dst += (size_t)page_words * sizeof(uint32_t);
                words_remaining -= page_words;

                rc = wop_poll_pending(pending, &outstanding, false);
                if (rc != 0) {
                    return rc;
                }
            }
        }
    }

    if (words_remaining > 0U) {
        xil_printf("[WOP] asset banks exhausted words_remaining=%u\r\n", words_remaining);
        return -ENOSPC;
    }

    const int drain_rc = wop_poll_pending(pending, &outstanding, true);
    if (drain_rc != 0) {
        return drain_rc;
    }

    return 0;
}

static int stage_descriptor_assets(const wop_descriptor_t *desc,
                                   wop_asset_window_t *window)
{
    const wop_asset_layout_t *tlwe_layout = NULL;
    const wop_asset_layout_t *gpu_layout  = NULL;

    switch (desc->mode) {
    case WOP_MODE_VP:
        tlwe_layout = &kAssetLayouts[WOP_ASSET_LUT];
        gpu_layout  = &kAssetLayouts[WOP_ASSET_BSK];
        break;
    case WOP_MODE_BE:
        tlwe_layout = &kAssetLayouts[WOP_ASSET_BSK];
        gpu_layout  = &kAssetLayouts[WOP_ASSET_LUT];
        break;
    case WOP_MODE_CB:
    default:
        tlwe_layout = &kAssetLayouts[WOP_ASSET_BSK];
        gpu_layout  = &kAssetLayouts[WOP_ASSET_KSK];
        break;
    }

    int rc = load_asset_region(tlwe_layout, desc->tlwe_words, desc->tlwe_src_addr);
    if (rc != 0) {
        return rc;
    }

    rc = load_asset_region(gpu_layout, desc->glwe_words, desc->gpu_shared_addr);
    if (rc != 0) {
        return rc;
    }

    if (window != NULL) {
        window->mode = desc->mode;
        window->tlwe_base = desc->tlwe_src_addr;
        window->tlwe_words = desc->tlwe_words;
        window->glwe_base = desc->glwe_dst_addr;
        window->glwe_words = desc->glwe_words;
        window->bsk_base = 0U;
        window->bsk_words = 0U;
        window->ksk_base = 0U;
        window->ksk_words = 0U;

        if (tlwe_layout == &kAssetLayouts[WOP_ASSET_BSK]) {
            window->bsk_base = desc->tlwe_src_addr;
            window->bsk_words = desc->tlwe_words;
        }
        if (gpu_layout == &kAssetLayouts[WOP_ASSET_BSK]) {
            window->bsk_base = desc->gpu_shared_addr;
            window->bsk_words = desc->glwe_words;
        }
        if (tlwe_layout == &kAssetLayouts[WOP_ASSET_KSK]) {
            window->ksk_base = desc->tlwe_src_addr;
            window->ksk_words = desc->tlwe_words;
        }
        if (gpu_layout == &kAssetLayouts[WOP_ASSET_KSK]) {
            window->ksk_base = desc->gpu_shared_addr;
            window->ksk_words = desc->glwe_words;
        }
    }

    return 0;
}

int wop_stage_assets_from_nand(uint16_t cmd_id)
{
    const uint16_t slot = cmd_id & WOP_DESC_RING_SLOT_MASK;
    const uintptr_t desc_addr = (uintptr_t)WOP_DESC_SLOT_ADDR(WOP_DESC_RING_BASE_ADDR, slot);
    const wop_descriptor_t *desc = (const wop_descriptor_t *)desc_addr;

    if (desc->tlwe_words > WOP_TLWE_MAX_WORDS || desc->glwe_words > WOP_GLWE_MAX_WORDS) {
        xil_printf("[WOP] descriptor words overflow tlwe=%u glwe=%u\r\n",
                   desc->tlwe_words, desc->glwe_words);
        return -EINVAL;
    }

    wop_asset_window_t *window = &g_asset_windows[slot];
    const int rc = stage_descriptor_assets(desc, window);
    if (rc != 0) {
        xil_printf("[WOP] NAND staging failed rc=%d mode=%u\r\n", rc, desc->mode);
        return rc;
    }

    xil_printf("[WOP] staged assets slot=%u tlwe=%u glwe=%u mode=%u\r\n",
               slot, desc->tlwe_words, desc->glwe_words, desc->mode);
    return 0;
}

void wop_reserve_asset_blocks(void)
{
    if (phyBlockMapPtr == NULL) {
        xil_printf("[WOP] phyBlockMapPtr not initialized; skip asset reservation\r\n");
        return;
    }

    for (uint32_t asset = 0U; asset < WOP_ASSET_COUNT; ++asset) {
        const wop_asset_layout_t *layout = &kAssetLayouts[asset];
        for (uint32_t bank_idx = 0U; bank_idx < layout->bank_count; ++bank_idx) {
            const wop_asset_bank_t *bank = &layout->banks[bank_idx];
            const uint32_t die = Pcw2VdieTranslation(bank->channel, bank->way);

            for (uint16_t block_offset = 0U; block_offset < bank->block_count; ++block_offset) {
                const uint32_t phy_block = bank->block_start + block_offset;
                if (phy_block >= TOTAL_BLOCKS_PER_DIE) {
                    xil_printf("[WOP] reserve skip invalid block ch=%u way=%u block=%u\r\n",
                               bank->channel, bank->way, phy_block);
                    continue;
                }
                phyBlockMapPtr->phyBlock[die][phy_block].bad = BLOCK_STATE_BAD;
            }
        }
    }
}

const wop_asset_window_t *wop_get_asset_window(uint16_t slot)
{
    if (slot >= WOP_DESC_RING_CAPACITY) {
        return NULL;
    }
    return &g_asset_windows[slot];
}
