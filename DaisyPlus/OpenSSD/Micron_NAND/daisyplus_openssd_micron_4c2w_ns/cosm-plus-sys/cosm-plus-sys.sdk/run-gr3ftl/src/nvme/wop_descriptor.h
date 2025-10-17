#ifndef __WOP_DESCRIPTOR_H_
#define __WOP_DESCRIPTOR_H_

#include <stdint.h>

#define WOP_MODE_VP 0U
#define WOP_MODE_BE 1U
#define WOP_MODE_CB 2U

#define WOP_DESC_FLAG_RANGE_MASK         (0x0FU)
#define WOP_DESC_FLAG_STEP5_BATCH_MASK   (0x07U << 4)
#define WOP_DESC_FLAG_STEP5_BATCH_SHIFT  (4U)
#define WOP_DESC_FLAG_STEP5_ONLY         (1U << 7)

#define WOP_DESC_RING_CAPACITY       16U
#define WOP_DESC_RING_SLOT_MASK      (WOP_DESC_RING_CAPACITY - 1U)
#define WOP_DESC_RING_META_BYTES     64U

#pragma pack(push, 1)
typedef struct {
    uint16_t cmd_id;            /* Host supplied command identifier */
    uint8_t  mode;              /* WOP_MODE_* */
    uint8_t  flags;             /* Control flags / pipeline hints */
    uint64_t tlwe_src_addr;     /* DRAM address for TLWE inputs */
    uint64_t glwe_dst_addr;     /* DRAM address for GLWE output */
    uint64_t gpu_shared_addr;   /* DRAM address for GPU shared workspace / status */
    uint16_t tlwe_words;        /* TLWE word count */
    uint8_t  glwe_words;        /* GLWE word count */
    uint8_t  reserved;          /* Align to 32 bytes */
} wop_descriptor_t;

typedef struct {
    uint64_t timestamp_ns;
    uint64_t latency_ns;
    uint32_t error_code;
    uint32_t status;
    uint16_t cmd_id;
    uint16_t reserved0;
    uint32_t reserved1;
} wop_result_status_t;

#define WOP_RESULT_STATUS_BYTES        (sizeof(wop_result_status_t))
#define WOP_RESULT_STATUS_PENDING      (0x00000001u)
#define WOP_RESULT_STATUS_COMPLETE     (0x00000002u)
#define WOP_RESULT_STATUS_ERROR        (0x80000000u)
#pragma pack(pop)

typedef struct {
    uint16_t head;
    uint16_t tail;
    uint16_t pending;
    uint16_t capacity;
    uint32_t busy_mask;
    uint32_t doorbell_count;
    uint32_t release_count;
    uint32_t last_cmd_id;
    uint32_t reserved[4];
} wop_desc_ring_ctrl_t;

#define WOP_DESC_CTRL_ADDR(BASE)      ((uint64_t)(BASE))
#define WOP_DESC_SLOT_OFFSET(SLOT)    ((uint32_t)(SLOT) * (uint32_t)sizeof(wop_descriptor_t))
#define WOP_DESC_DESC_BASE(BASE)      ((uint64_t)(BASE) + (uint64_t)WOP_DESC_RING_META_BYTES)
#define WOP_DESC_SLOT_ADDR(BASE,SLOT) (WOP_DESC_DESC_BASE(BASE) + (uint64_t)WOP_DESC_SLOT_OFFSET((SLOT)))

#endif /* __WOP_DESCRIPTOR_H_ */
