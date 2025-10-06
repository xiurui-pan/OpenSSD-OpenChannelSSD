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

#ifdef __cplusplus
extern "C" {
#endif

int wop_stage_assets_from_nand(uint16_t cmd_id);

#ifdef __cplusplus
}
#endif

#endif /* __WOP_STORAGE_H_ */
