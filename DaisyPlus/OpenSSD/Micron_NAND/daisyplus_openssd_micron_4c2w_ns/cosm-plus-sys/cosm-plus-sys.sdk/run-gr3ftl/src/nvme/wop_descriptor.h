#ifndef __WOP_DESCRIPTOR_H_
#define __WOP_DESCRIPTOR_H_

#include <stdint.h>

#define WOP_MODE_VP 0U
#define WOP_MODE_BE 1U
#define WOP_MODE_CB 2U

#define WOP_DESC_FLAG_GPU_READBACK   (1U << 0)
#define WOP_DESC_FLAG_GOLDEN_COMPARE (1U << 1)
#define WOP_DESC_FLAG_RESERVED_MASK  (0xFCU)

#pragma pack(push, 1)
typedef struct {
    uint16_t cmd_id;            /* Host supplied command identifier */
    uint8_t  mode;              /* WOP_MODE_* */
    uint8_t  flags;             /* Control flags / pipeline hints */
    uint64_t tlwe_src_addr;     /* DRAM address for TLWE inputs */
    uint64_t glwe_dst_addr;     /* DRAM address for GLWE output */
    uint64_t gpu_shared_addr;   /* DRAM address for GPU shared workspace */
    uint16_t tlwe_words;        /* TLWE word count */
    uint8_t  glwe_words;        /* GLWE word count */
    uint8_t  reserved;          /* Align to 32 bytes */
} wop_descriptor_t;

typedef struct {
    uint32_t status;            /* Mirror of CTRL_STATUS when GPU completed */
    uint32_t latency_cycles;    /* GPU measured latency */
    uint16_t cmd_id;            /* Echo back command identifier */
    uint8_t  error_code;        /* GPU-specific error */
    uint8_t  reserved;          /* Future use */
} wop_result_t;
#pragma pack(pop)

#endif /* __WOP_DESCRIPTOR_H_ */
