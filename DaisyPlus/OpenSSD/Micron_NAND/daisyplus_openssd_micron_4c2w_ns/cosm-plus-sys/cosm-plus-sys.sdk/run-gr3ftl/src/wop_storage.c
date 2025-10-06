#include "wop_storage.h"

#include "xil_printf.h"

int wop_stage_assets_from_nand(uint16_t cmd_id)
{
    xil_printf("[WOP] stage_assets_from_nand(cmd=0x%04X) stub\r\n", cmd_id);
    /* TODO: issue NAND --> DRAM DMA transfers for LUT/BSK/KSK buffers */
    return 0;
}
