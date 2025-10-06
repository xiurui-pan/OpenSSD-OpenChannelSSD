#ifndef __WOP_COMMAND_H_
#define __WOP_COMMAND_H_

#include "nvme.h"

#define WOP_CTRL_CMD_MODE_SHIFT          16
#define WOP_CTRL_CMD_CMD_ID_MASK         0x0000FFFFu
#define WOP_CTRL_CMD_DOORBELL_MASK       0x80000000u

#define WOP_STATUS_BUSY_MASK             (1u << 21)
#define WOP_STATUS_ERROR_MASK            (1u << 22)
#define WOP_STATUS_GPU_READY_MASK        (1u << 23)

#define WOP_INT_DONE_MASK                (1u << 0)
#define WOP_INT_ERROR_MASK               (1u << 1)

typedef union _ADMIN_WOP_CONTROL_DW10
{
    unsigned int dword;
    struct {
        unsigned int cmd_id  : 16;  // Host-supplied command identifier
        unsigned int flags   : 14;  // Reserved for batching/pipeline hints
        unsigned int mode    : 2;   // 0:VP 1:BE 2:CB
    } field;
} ADMIN_WOP_CONTROL_DW10;

void wop_ctrl_init(void);
void handle_wop_vendor_cmd(NVME_ADMIN_COMMAND *nvmeAdminCmd, NVME_COMPLETION *nvmeCPL);

#endif /* __WOP_COMMAND_H_ */
