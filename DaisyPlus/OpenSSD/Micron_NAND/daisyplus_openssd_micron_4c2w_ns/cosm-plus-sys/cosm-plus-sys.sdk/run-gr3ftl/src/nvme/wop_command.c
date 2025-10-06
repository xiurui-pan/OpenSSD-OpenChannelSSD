#include "xil_printf.h"

#include "io_access.h"
#include "wop_command.h"
#include "wop_storage.h"
#include "../memory_map.h"
#include "wop_descriptor.h"

static inline unsigned int wop_ctrl_status(void)
{
    return IO_READ32(WOP_CTRL_STATUS_ADDR);
}

void wop_ctrl_init(void)
{
    /* Enable DONE/ERROR interrupts and clear any stale status bits. */
    IO_WRITE32(WOP_CTRL_INT_MASK_ADDR, WOP_INT_DONE_MASK | WOP_INT_ERROR_MASK);
    IO_WRITE32(WOP_CTRL_INT_STATUS_ADDR, WOP_INT_DONE_MASK | WOP_INT_ERROR_MASK);
    xil_printf("[WOP] ctrl_init: mask=0x%08X base=0x%08X\r\n",
               IO_READ32(WOP_CTRL_INT_MASK_ADDR), WOP_CTRL_BASE_ADDR);
}

void handle_wop_vendor_cmd(NVME_ADMIN_COMMAND *nvmeAdminCmd, NVME_COMPLETION *nvmeCPL)
{
    ADMIN_WOP_CONTROL_DW10 ctrl_dw10;
    unsigned long long desc_ptr;
    unsigned int status;
    unsigned int ctrl_cmd;

    ctrl_dw10.dword = nvmeAdminCmd->dword10;
    desc_ptr = ((unsigned long long)nvmeAdminCmd->dword12 << 32) | nvmeAdminCmd->dword11;

    status = wop_ctrl_status();
    if ((status & WOP_STATUS_BUSY_MASK) != 0u)
    {
        xil_printf("[WOP] controller busy status=0x%08X\r\n", status);
        nvmeCPL->dword[0] = 0;
        nvmeCPL->statusField.SC = SC_COMMAND_SEQUENCE_ERROR;
        nvmeCPL->statusField.SCT = 0;
        nvmeCPL->statusField.DNR = 0;
        nvmeCPL->specific = status;
        return;
    }

    if (wop_stage_assets_from_nand(ctrl_dw10.field.cmd_id) != 0) {
        xil_printf("[WOP] NAND staging failed for cmd=0x%04X\r\n", ctrl_dw10.field.cmd_id);
        nvmeCPL->dword[0] = 0;
        nvmeCPL->statusField.SC = SC_INTERNAL_DEVICE_ERROR;
        nvmeCPL->statusField.SCT = 0;
        nvmeCPL->statusField.DNR = 0;
        nvmeCPL->specific = status;
        return;
    }

    /* Program descriptor pointer and clear any pending interrupts. */
    IO_WRITE32(WOP_CTRL_DESC_PTR_LO_ADDR, (unsigned int)(desc_ptr & 0xFFFFFFFFu));
    IO_WRITE32(WOP_CTRL_DESC_PTR_HI_ADDR, (unsigned int)(desc_ptr >> 32));
    IO_WRITE32(WOP_CTRL_INT_STATUS_ADDR, WOP_INT_DONE_MASK | WOP_INT_ERROR_MASK);

    ctrl_cmd = (ctrl_dw10.field.cmd_id & WOP_CTRL_CMD_CMD_ID_MASK) |
               ((ctrl_dw10.field.mode & 0x3u) << WOP_CTRL_CMD_MODE_SHIFT) |
               WOP_CTRL_CMD_DOORBELL_MASK;
    IO_WRITE32(WOP_CTRL_CMD_ADDR, ctrl_cmd);

    xil_printf("[WOP] doorbell cmd_id=%u mode=%u desc=0x%08X%08X\r\n",
               ctrl_dw10.field.cmd_id, ctrl_dw10.field.mode,
               (unsigned int)(desc_ptr >> 32), (unsigned int)(desc_ptr & 0xFFFFFFFFu));

    nvmeCPL->dword[0] = 0;
    nvmeCPL->statusField.SCT = 0;
    nvmeCPL->statusField.DNR = 0;

    status = wop_ctrl_status();
    if ((status & WOP_STATUS_ERROR_MASK) != 0u)
    {
        xil_printf("[WOP] error detected status=0x%08X\r\n", status);
        nvmeCPL->statusField.SC = SC_INTERNAL_DEVICE_ERROR;
        nvmeCPL->specific = status;
    }
    else
    {
        nvmeCPL->statusField.SC = SC_SUCCESSFUL_COMPLETION;
        nvmeCPL->specific = status;
    }
}
