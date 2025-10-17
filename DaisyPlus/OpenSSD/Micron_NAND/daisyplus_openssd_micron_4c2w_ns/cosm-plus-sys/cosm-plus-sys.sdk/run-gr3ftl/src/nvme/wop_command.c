#include "xil_printf.h"

#include "io_access.h"
#include "wop_command.h"
#include "wop_storage.h"
#include "../memory_map.h"
#include "wop_descriptor.h"

#include <stdbool.h>
#include <stdint.h>
#include <string.h>

typedef struct {
    bool     busy;
    uint16_t cmd_id;
    uint64_t host_desc_ptr;
    uint64_t result_status_addr;
} wop_desc_slot_state_t;

static wop_desc_slot_state_t g_desc_slots[WOP_DESC_RING_CAPACITY];

static inline unsigned int wop_ctrl_status(void);

static inline void wop_ctrl_ack(uint16_t cmd_id)
{
    unsigned int value = (unsigned int)cmd_id & WOP_CTRL_CMD_CMD_ID_MASK;
    value |= WOP_CTRL_CMD_ACK_MASK;
    IO_WRITE32(WOP_CTRL_CMD_ADDR, value);
}

typedef struct {
    bool     valid;
    uint16_t cmd_id;
    uint16_t slot;
    uint8_t  mode;
    uint64_t ring_desc_addr;
    uint64_t host_desc_ptr;
    uint64_t result_status_addr;
} wop_desc_queue_entry_t;

static wop_desc_queue_entry_t g_queue[WOP_DESC_RING_CAPACITY];
static uint32_t g_queue_head;
static uint32_t g_queue_tail;
static uint32_t g_queue_count;
static bool     g_cmd_in_flight;
static wop_desc_queue_entry_t g_active_entry;
static volatile wop_desc_ring_ctrl_t *g_ring_ctrl;

static inline uint32_t wop_calc_stride_bytes(uint32_t words)
{
    uint64_t bytes = (uint64_t)words * sizeof(uint32_t);
    if (bytes == 0U) {
        return 64U;
    }
    if (bytes > (uint64_t)UINT32_MAX) {
        return UINT32_MAX;
    }
    return (uint32_t)bytes;
}

static inline void wop_write64(uint32_t addr_lo, uint32_t addr_hi, uint64_t value)
{
    IO_WRITE32(addr_lo, (uint32_t)(value & 0xFFFFFFFFu));
    IO_WRITE32(addr_hi, (uint32_t)((value >> 32) & 0xFFFFFFFFu));
}

static inline bool wop_ctrl_is_doorbell_ready(void)
{
    return (wop_ctrl_status() & WOP_STATUS_DOORBELL_READY_MASK) != 0U;
}

static void wop_status_write(uint64_t status_addr, uint16_t cmd_id, uint32_t status_code, uint32_t error_code)
{
    if (status_addr == 0U) {
        return;
    }

    volatile wop_result_status_t *status_ptr = (volatile wop_result_status_t *)(uintptr_t)status_addr;
    status_ptr->cmd_id       = cmd_id;
    status_ptr->reserved0    = 0U;
    status_ptr->reserved1    = 0U;
    status_ptr->latency_ns   = 0U;
    status_ptr->timestamp_ns = 0U;
    status_ptr->error_code   = error_code;
    status_ptr->status       = status_code;
}

static void wop_log_error_vector(const char *context, uint32_t status)
{
    const uint32_t vector = status & WOP_STATUS_ERROR_VECTOR_MASK;
    if (vector == 0U) {
        return;
    }

    const unsigned int code = (unsigned int)(vector >> WOP_STATUS_ERROR_VECTOR_SHIFT);
    xil_printf("[WOP] %s error_vector=0x%02X\r\n", context, code);

    if ((vector & WOP_STATUS_ERR_DMA_MASK) != 0U) {
        xil_printf("[WOP]   - DMA/status writer error\r\n");
    }
    if ((vector & WOP_STATUS_ERR_GPU_OVERFLOW_MASK) != 0U) {
        xil_printf("[WOP]   - GPU notification overflow\r\n");
    }
    if ((vector & WOP_STATUS_ERR_DOORBELL_MASK) != 0U) {
        xil_printf("[WOP]   - Doorbell rejected while controller busy\r\n");
    }
    if ((vector & WOP_STATUS_ERR_DESC_MASK) != 0U) {
        xil_printf("[WOP]   - Descriptor decode failure\r\n");
    }
    if ((vector & WOP_STATUS_ERR_BSK_LOADER_MASK) != 0U) {
        xil_printf("[WOP]   - BSK loader AXI error\r\n");
    }
    if ((vector & WOP_STATUS_ERR_GLWE_LOADER_MASK) != 0U) {
        xil_printf("[WOP]   - GLWE/TLWE loader AXI error\r\n");
    }
    if ((vector & WOP_STATUS_ERR_STRIDE_MASK) != 0U) {
        xil_printf("[WOP]   - Resource stride configuration invalid\r\n");
    }
    if ((vector & WOP_STATUS_ERR_KSK_LOADER_MASK) != 0U) {
        xil_printf("[WOP]   - KSK loader AXI error\r\n");
    }
}

static void wop_program_asset_registers(uint16_t slot, uint8_t mode)
{
    const wop_asset_window_t *window = wop_get_asset_window(slot);
    if (window == NULL) {
        return;
    }

    uint64_t bsk_base = window->bsk_base ? window->bsk_base : window->tlwe_base;
    uint32_t bsk_stride = wop_calc_stride_bytes(window->bsk_words ? window->bsk_words : window->tlwe_words);

    uint64_t ksk_base = window->ksk_base ? window->ksk_base : window->glwe_base;
    uint32_t ksk_stride = wop_calc_stride_bytes(window->ksk_words ? window->ksk_words : window->glwe_words);

    if (mode == WOP_MODE_CB && window->ksk_base == 0U) {
        ksk_base = window->bsk_base ? window->bsk_base : window->tlwe_base;
        ksk_stride = wop_calc_stride_bytes(window->ksk_words ? window->ksk_words : window->tlwe_words);
    }

    uint64_t glwe_base = window->glwe_base ? window->glwe_base : window->tlwe_base;
    uint32_t glwe_stride = wop_calc_stride_bytes(window->glwe_words ? window->glwe_words : window->tlwe_words);

    wop_write64(WOP_CTRL_BSK_BASE_LO_ADDR, WOP_CTRL_BSK_BASE_HI_ADDR, bsk_base);
    IO_WRITE32(WOP_CTRL_BSK_STRIDE_ADDR, bsk_stride);
    wop_write64(WOP_CTRL_KSK_BASE_LO_ADDR, WOP_CTRL_KSK_BASE_HI_ADDR, ksk_base);
    IO_WRITE32(WOP_CTRL_KSK_STRIDE_ADDR, ksk_stride);
    wop_write64(WOP_CTRL_GLWE_BASE_LO_ADDR, WOP_CTRL_GLWE_BASE_HI_ADDR, glwe_base);
    IO_WRITE32(WOP_CTRL_GLWE_STRIDE_ADDR, glwe_stride);
}

static inline uint16_t wop_slot_next(uint16_t slot)
{
    slot++;
    if (slot >= WOP_DESC_RING_CAPACITY) {
        slot = 0U;
    }
    return slot;
}

static inline uint32_t wop_slot_mask(uint16_t slot)
{
    return 1U << (slot & WOP_DESC_RING_SLOT_MASK);
}

static void wop_ring_mark_busy(uint16_t slot, uint16_t cmd_id)
{
    if (g_ring_ctrl == NULL) {
        return;
    }

    uint32_t mask = wop_slot_mask(slot);
    uint16_t prev_pending = g_ring_ctrl->pending;

    g_ring_ctrl->busy_mask |= mask;
    g_ring_ctrl->pending = prev_pending + 1U;
    g_ring_ctrl->tail = wop_slot_next(slot);
    if (prev_pending == 0U) {
        g_ring_ctrl->head = slot;
    }
    g_ring_ctrl->last_cmd_id = cmd_id;
}

static void wop_ring_mark_free(uint16_t slot, bool account_release, uint16_t cmd_id)
{
    if (g_ring_ctrl == NULL) {
        return;
    }

  uint32_t mask = wop_slot_mask(slot);
  g_ring_ctrl->busy_mask &= ~mask;
    if (g_ring_ctrl->pending > 0U) {
        g_ring_ctrl->pending--;
    }

    if (account_release) {
        g_ring_ctrl->release_count++;
        g_ring_ctrl->last_cmd_id = cmd_id;
    }

    if (g_ring_ctrl->head == slot) {
        uint16_t next = slot;
        for (uint32_t i = 0U; i < WOP_DESC_RING_CAPACITY; ++i) {
            next = wop_slot_next(next);
            if (g_ring_ctrl->busy_mask & wop_slot_mask(next)) {
                g_ring_ctrl->head = next;
                return;
            }
        }
        g_ring_ctrl->head = g_ring_ctrl->tail;
    }
}

static bool wop_desc_try_acquire(uint16_t slot, uint16_t cmd_id, uint64_t host_ptr)
{
    if (g_desc_slots[slot].busy) {
        xil_printf("[WOP] slot %u busy (cmd=0x%04X owner=0x%04X host=0x%08X%08X)\r\n",
                   slot, cmd_id, g_desc_slots[slot].cmd_id,
                   (unsigned int)(g_desc_slots[slot].host_desc_ptr >> 32),
                   (unsigned int)(g_desc_slots[slot].host_desc_ptr & 0xFFFFFFFFu));
        return false;
    }

    g_desc_slots[slot].busy = true;
    g_desc_slots[slot].cmd_id = cmd_id;
    g_desc_slots[slot].host_desc_ptr = host_ptr;
    g_desc_slots[slot].result_status_addr = 0U;
    return true;
}

static void wop_desc_force_release(uint16_t slot)
{
    g_desc_slots[slot].busy = false;
    g_desc_slots[slot].cmd_id = 0U;
    g_desc_slots[slot].host_desc_ptr = 0U;
    g_desc_slots[slot].result_status_addr = 0U;
}

static void wop_reset_state(void)
{
    memset(g_desc_slots, 0, sizeof(g_desc_slots));
    memset(g_queue, 0, sizeof(g_queue));
    g_queue_head = 0U;
    g_queue_tail = 0U;
    g_queue_count = 0U;
    g_cmd_in_flight = false;
    memset(&g_active_entry, 0, sizeof(g_active_entry));

    if (g_ring_ctrl != NULL) {
        g_ring_ctrl->head = 0U;
        g_ring_ctrl->tail = 0U;
        g_ring_ctrl->pending = 0U;
        g_ring_ctrl->capacity = WOP_DESC_RING_CAPACITY;
        g_ring_ctrl->busy_mask = 0U;
        g_ring_ctrl->doorbell_count = 0U;
        g_ring_ctrl->release_count = 0U;
        g_ring_ctrl->last_cmd_id = 0U;
    }
}

static inline bool wop_ctrl_is_busy(void)
{
    return (wop_ctrl_status() & WOP_STATUS_BUSY_MASK) != 0U;
}

static inline void wop_program_desc_ptr(uint64_t ring_desc_addr)
{
    IO_WRITE32(WOP_CTRL_DESC_PTR_LO_ADDR, (unsigned int)(ring_desc_addr & 0xFFFFFFFFu));
    IO_WRITE32(WOP_CTRL_DESC_PTR_HI_ADDR, (unsigned int)(ring_desc_addr >> 32));
    IO_WRITE32(WOP_CTRL_INT_STATUS_ADDR, WOP_INT_DONE_MASK | WOP_INT_ERROR_MASK);
}

static void wop_issue_doorbell(const wop_desc_queue_entry_t *entry)
{
    unsigned int ctrl_cmd;

    g_desc_slots[entry->slot].result_status_addr = entry->result_status_addr;
    if (entry->result_status_addr != 0U) {
        wop_status_write(entry->result_status_addr, entry->cmd_id, WOP_RESULT_STATUS_PENDING, 0U);
    }

    wop_program_asset_registers(entry->slot, entry->mode);
    wop_program_desc_ptr(entry->ring_desc_addr);

    ctrl_cmd = (entry->cmd_id & WOP_CTRL_CMD_CMD_ID_MASK) |
               (((unsigned int)entry->mode & 0x3u) << WOP_CTRL_CMD_MODE_SHIFT) |
               WOP_CTRL_CMD_DOORBELL_MASK;
    IO_WRITE32(WOP_CTRL_CMD_ADDR, ctrl_cmd);

    g_cmd_in_flight = true;
    g_active_entry = *entry;
    if (g_ring_ctrl != NULL) {
        g_ring_ctrl->doorbell_count++;
    }

    xil_printf("[WOP] launch cmd_id=%u slot=%u mode=%u desc=0x%08X%08X\r\n",
               entry->cmd_id,
               entry->slot,
               entry->mode,
               (unsigned int)(entry->ring_desc_addr >> 32),
               (unsigned int)(entry->ring_desc_addr & 0xFFFFFFFFu));
}

static bool wop_queue_push(const wop_desc_queue_entry_t *entry)
{
    if (g_queue_count >= WOP_DESC_RING_CAPACITY) {
        return false;
    }

    g_queue[g_queue_tail] = *entry;
    g_queue[g_queue_tail].valid = true;
    g_queue_tail = (g_queue_tail + 1U) % WOP_DESC_RING_CAPACITY;
    g_queue_count++;
    return true;
}

static bool wop_queue_pop(wop_desc_queue_entry_t *entry_out)
{
    if (g_queue_count == 0U) {
        return false;
    }

    *entry_out = g_queue[g_queue_head];
    g_queue[g_queue_head].valid = false;
    g_queue_head = (g_queue_head + 1U) % WOP_DESC_RING_CAPACITY;
    g_queue_count--;
    return true;
}

static void wop_try_kick_next(void)
{
    wop_desc_queue_entry_t entry;

    if (g_cmd_in_flight) {
        return;
    }
    if (g_queue_count == 0U) {
        return;
    }
    unsigned int status = wop_ctrl_status();
    if ((status & WOP_STATUS_BUSY_MASK) != 0U) {
        return;
    }
    if ((status & WOP_STATUS_DOORBELL_READY_MASK) == 0U) {
        return;
    }

    if (wop_queue_pop(&entry)) {
        wop_issue_doorbell(&entry);
        xil_printf("[WOP] dequeue cmd_id=%u depth=%u\r\n",
                   entry.cmd_id,
                   (unsigned int)g_queue_count);
    }
}

static int wop_desc_release_internal(uint16_t cmd_id, bool account_release, uint32_t error_code)
{
    const uint16_t slot = cmd_id & WOP_DESC_RING_SLOT_MASK;
    if (!g_desc_slots[slot].busy) {
        xil_printf("[WOP] release ignored: slot %u already free\r\n", slot);
        return -1;
    }
    if (g_desc_slots[slot].cmd_id != cmd_id) {
        xil_printf("[WOP] release mismatch: slot %u owner=0x%04X req=0x%04X\r\n",
                   slot, g_desc_slots[slot].cmd_id, cmd_id);
        return -1;
    }

    wop_ctrl_ack(cmd_id);

    const uint64_t status_addr = g_desc_slots[slot].result_status_addr;
    if (status_addr != 0U) {
        uint32_t status_code = account_release ? WOP_RESULT_STATUS_ERROR : WOP_RESULT_STATUS_COMPLETE;
        wop_status_write(status_addr, cmd_id, status_code, error_code);
    }

    wop_desc_force_release(slot);
    if (g_cmd_in_flight && g_active_entry.cmd_id == cmd_id) {
        g_cmd_in_flight = false;
        memset(&g_active_entry, 0, sizeof(g_active_entry));
    }

    wop_ring_mark_free(slot, account_release, cmd_id);
    wop_try_kick_next();
    return 0;
}

int wop_desc_release(uint16_t cmd_id, bool account_release)
{
    return wop_desc_release_internal(cmd_id, account_release, 0U);
}

static inline unsigned int wop_ctrl_status(void)
{
    return IO_READ32(WOP_CTRL_STATUS_ADDR);
}

void wop_ctrl_init(void)
{
    /* Enable DONE/ERROR interrupts and clear any stale status bits. */
    IO_WRITE32(WOP_CTRL_INT_MASK_ADDR, WOP_INT_DONE_MASK | WOP_INT_ERROR_MASK);
    IO_WRITE32(WOP_CTRL_INT_STATUS_ADDR, WOP_INT_DONE_MASK | WOP_INT_ERROR_MASK);
    g_ring_ctrl = (volatile wop_desc_ring_ctrl_t *)(uintptr_t)WOP_DESC_CTRL_ADDR(WOP_DESC_RING_BASE_ADDR);
    wop_reset_state();
    xil_printf("[WOP] ctrl_init: mask=0x%08X base=0x%08X\r\n",
               IO_READ32(WOP_CTRL_INT_MASK_ADDR), WOP_CTRL_BASE_ADDR);
}

void handle_wop_vendor_cmd(NVME_ADMIN_COMMAND *nvmeAdminCmd, NVME_COMPLETION *nvmeCPL)
{
    ADMIN_WOP_CONTROL_DW10 ctrl_dw10;
    unsigned long long desc_ptr;
    unsigned int status;
    uint16_t slot;
    uint64_t ring_desc_addr;

    ctrl_dw10.dword = nvmeAdminCmd->dword10;
    desc_ptr = ((unsigned long long)nvmeAdminCmd->dword12 << 32) | nvmeAdminCmd->dword11;
    slot = ctrl_dw10.field.cmd_id & WOP_DESC_RING_SLOT_MASK;
    ring_desc_addr = WOP_DESC_SLOT_ADDR(WOP_DESC_RING_BASE_ADDR, slot);

    status = wop_ctrl_status();

    if (!wop_desc_try_acquire(slot, ctrl_dw10.field.cmd_id, desc_ptr)) {
        nvmeCPL->dword[0] = 0;
        nvmeCPL->statusField.SC = SC_COMMAND_SEQUENCE_ERROR;
        nvmeCPL->statusField.SCT = 0;
        nvmeCPL->statusField.DNR = 0;
        nvmeCPL->specific = status;
        return;
    }

    if (wop_stage_assets_from_nand(ctrl_dw10.field.cmd_id) != 0) {
        xil_printf("[WOP] NAND staging failed for cmd=0x%04X\r\n", ctrl_dw10.field.cmd_id);
        wop_desc_force_release(slot);
        nvmeCPL->dword[0] = 0;
        nvmeCPL->statusField.SC = SC_INTERNAL_DEVICE_ERROR;
        nvmeCPL->statusField.SCT = 0;
        nvmeCPL->statusField.DNR = 0;
        nvmeCPL->specific = status;
        return;
    }

    wop_ring_mark_busy(slot, ctrl_dw10.field.cmd_id);

    volatile wop_descriptor_t *ring_desc_ptr =
        (volatile wop_descriptor_t *)(uintptr_t)ring_desc_addr;
    uint64_t result_status_addr = 0U;
    if (ring_desc_ptr != NULL) {
        result_status_addr = ring_desc_ptr->gpu_shared_addr;
    }
    g_desc_slots[slot].result_status_addr = result_status_addr;

    wop_desc_queue_entry_t entry = {
        .valid = true,
        .cmd_id = ctrl_dw10.field.cmd_id,
        .slot = slot,
        .mode = (uint8_t)(ctrl_dw10.field.mode & 0x3u),
        .ring_desc_addr = ring_desc_addr,
        .host_desc_ptr = desc_ptr,
        .result_status_addr = result_status_addr
    };

    if (!g_cmd_in_flight && !wop_ctrl_is_busy() && wop_ctrl_is_doorbell_ready()) {
        wop_issue_doorbell(&entry);
    } else {
        if (!wop_queue_push(&entry)) {
            xil_printf("[WOP] queue full cmd_id=%u slot=%u\r\n", entry.cmd_id, entry.slot);
            wop_desc_force_release(slot);
            wop_ring_mark_free(slot, true, entry.cmd_id);
            nvmeCPL->dword[0] = 0;
            nvmeCPL->statusField.SC = SC_INTERNAL_DEVICE_ERROR;
            nvmeCPL->statusField.SCT = 0;
            nvmeCPL->statusField.DNR = 0;
            nvmeCPL->specific = status;
            return;
        }
        xil_printf("[WOP] queued cmd_id=%u slot=%u depth=%u\r\n",
                   entry.cmd_id,
                   entry.slot,
                   (unsigned int)g_queue_count);
    }

    nvmeCPL->dword[0] = 0;
    nvmeCPL->statusField.SCT = 0;
    nvmeCPL->statusField.DNR = 0;

    status = wop_ctrl_status();
    if ((status & WOP_STATUS_ERROR_MASK) != 0u)
    {
        xil_printf("[WOP] error detected status=0x%08X\r\n", status);
        wop_log_error_vector("ctrl_status (doorbell)", status);
        nvmeCPL->statusField.SC = SC_INTERNAL_DEVICE_ERROR;
        nvmeCPL->specific = status;
    }
    else
    {
        nvmeCPL->statusField.SC = SC_SUCCESSFUL_COMPLETION;
        nvmeCPL->specific = status;
    }

    wop_log_error_vector("ctrl_status (doorbell)", status);

    wop_try_kick_next();
}

void wop_service(void)
{
    const unsigned int int_status = IO_READ32(WOP_CTRL_INT_STATUS_ADDR);
    unsigned int status = 0U;

    if ((int_status & WOP_INT_ERROR_MASK) != 0U) {
        status = wop_ctrl_status();
        xil_printf("[WOP] interrupt error int_status=0x%08X status=0x%08X\r\n", int_status, status);
        wop_log_error_vector("ctrl_status (interrupt)", status);
        IO_WRITE32(WOP_CTRL_INT_STATUS_ADDR, WOP_INT_ERROR_MASK);
        if (g_cmd_in_flight) {
            uint16_t cmd_id = g_active_entry.cmd_id;
            wop_desc_release_internal(cmd_id, true, status);
        }
    }

    if ((int_status & WOP_INT_DONE_MASK) != 0U) {
        IO_WRITE32(WOP_CTRL_INT_STATUS_ADDR, WOP_INT_DONE_MASK);
        if (g_cmd_in_flight) {
            uint16_t cmd_id = g_active_entry.cmd_id;
            wop_desc_release(cmd_id, false);
        }
        return;
    }

    status = wop_ctrl_status();
    if ((status & WOP_STATUS_ERROR_MASK) != 0U && g_cmd_in_flight) {
        uint16_t cmd_id = g_active_entry.cmd_id;
        xil_printf("[WOP] status error for cmd_id=%u status=0x%08X\r\n", cmd_id, status);
        wop_log_error_vector("ctrl_status (poll)", status);
        wop_desc_release_internal(cmd_id, true, status);
        return;
    }

    if (g_cmd_in_flight) {
        volatile wop_result_status_t *result_ptr =
            (volatile wop_result_status_t *)(uintptr_t)g_active_entry.result_status_addr;
        if (result_ptr != NULL) {
            const uint32_t res_status = result_ptr->status;
            if (res_status == WOP_RESULT_STATUS_COMPLETE) {
                wop_desc_release_internal(g_active_entry.cmd_id, false, 0U);
            } else if (res_status == WOP_RESULT_STATUS_ERROR) {
                xil_printf("[WOP] result error cmd_id=%u code=0x%08X\r\n",
                           g_active_entry.cmd_id, result_ptr->error_code);
                wop_desc_release_internal(g_active_entry.cmd_id, true, result_ptr->error_code);
            }
        }
    }
}
