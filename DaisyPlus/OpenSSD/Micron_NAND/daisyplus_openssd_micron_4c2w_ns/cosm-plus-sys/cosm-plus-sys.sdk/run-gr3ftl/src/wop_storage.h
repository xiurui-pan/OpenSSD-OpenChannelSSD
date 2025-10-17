#ifndef __WOP_STORAGE_H_
#define __WOP_STORAGE_H_

#include <stdint.h>

/* Placeholder NAND layout, subject to refinement */
#define WOP_NAND_REGION_BASE_BLOCK   0x3C00U
#define WOP_NAND_BLOCKS_LUT          16U
#define WOP_NAND_BLOCKS_BSK          64U
#define WOP_NAND_BLOCKS_KSK          64U

#define WOP_TLWE_MAX_WORDS           4096U
#define WOP_GLWE_MAX_WORDS           4096U

typedef struct {
    uint8_t  channel;
    uint8_t  way;
    uint16_t block_start;
    uint16_t block_count;
} wop_asset_bank_t;

typedef struct {
    uint64_t tlwe_base;
    uint32_t tlwe_words;
    uint64_t glwe_base;
    uint32_t glwe_words;
    uint64_t bsk_base;
    uint32_t bsk_words;
    uint64_t ksk_base;
    uint32_t ksk_words;
    uint8_t  mode;
} wop_asset_window_t;

#ifdef __cplusplus
extern "C" {
#endif

int wop_stage_assets_from_nand(uint16_t cmd_id);
void wop_reserve_asset_blocks(void);
const wop_asset_window_t *wop_get_asset_window(uint16_t slot);

#ifdef __cplusplus
}
#endif

#endif /* __WOP_STORAGE_H_ */
