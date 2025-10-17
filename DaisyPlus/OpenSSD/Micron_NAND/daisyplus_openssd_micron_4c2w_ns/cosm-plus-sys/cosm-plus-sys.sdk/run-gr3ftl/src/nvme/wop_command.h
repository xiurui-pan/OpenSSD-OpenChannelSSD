#ifndef __WOP_COMMAND_H_
#define __WOP_COMMAND_H_

#include <stdbool.h>
#include "nvme.h"

#define WOP_CTRL_CMD_MODE_SHIFT          16
#define WOP_CTRL_CMD_CMD_ID_MASK         0x0000FFFFu
#define WOP_CTRL_CMD_DOORBELL_MASK       0x80000000u
#define WOP_CTRL_CMD_ACK_MASK            0x40000000u

#define WOP_STATUS_DOORBELL_READY_MASK   (1u << 20)
#define WOP_STATUS_BUSY_MASK             (1u << 21)
#define WOP_STATUS_ERROR_MASK            (1u << 22)
#define WOP_STATUS_GPU_READY_MASK        (1u << 23)
#define WOP_STATUS_ERROR_VECTOR_SHIFT    (24u)
#define WOP_STATUS_ERROR_VECTOR_MASK     (0xFFu << WOP_STATUS_ERROR_VECTOR_SHIFT)

#define WOP_STATUS_ERR_DMA_MASK          (1u << 24)
#define WOP_STATUS_ERR_GPU_OVERFLOW_MASK (1u << 25)
#define WOP_STATUS_ERR_DOORBELL_MASK     (1u << 26)
#define WOP_STATUS_ERR_DESC_MASK         (1u << 27)
#define WOP_STATUS_ERR_BSK_LOADER_MASK   (1u << 28)
#define WOP_STATUS_ERR_GLWE_LOADER_MASK  (1u << 29)
#define WOP_STATUS_ERR_STRIDE_MASK       (1u << 30)
#define WOP_STATUS_ERR_KSK_LOADER_MASK   (1u << 31)

#define WOP_INT_DONE_MASK                (1u << 0)
#define WOP_INT_ERROR_MASK               (1u << 1)

#define WOP_RESULT_STATUS_PENDING        (0x00000001u)
#define WOP_RESULT_STATUS_COMPLETE       (0x00000002u)
#define WOP_RESULT_STATUS_ERROR          (0x80000000u)

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
int wop_desc_release(uint16_t cmd_id, bool account_release);
void wop_service(void);

#endif /* __WOP_COMMAND_H_ */
