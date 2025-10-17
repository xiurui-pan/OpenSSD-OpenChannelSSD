#include "wop_gpu_runtime.hpp"

extern "C" {
#include "nvme.h"
#include "wop_command.h"
#include "wop_descriptor.h"
#include "wop_test_shim.h"
#include "memory_map.h"
}

#include <array>
#include <cstdint>
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <unistd.h>

#include <sys/mman.h>

#include "test_dram_image.hpp"
#include "io_access.h"

namespace {
constexpr std::size_t kDramImageSize = 0x0040'0000;
constexpr uint16_t kCmdId = 0x0012;
constexpr uint16_t kSlot = kCmdId & WOP_DESC_RING_SLOT_MASK;
constexpr uint64_t kHostDescPtr = 0x0000'1000ULL;
}

int main() {
    try {
        wop::test::DramImage image(kDramImageSize);
        const int dram_fd = image.fd;
        wop_test_io_bind(dram_fd, static_cast<uint32_t>(image.size));
        wop_test_clear_asset_windows();

        void *mapped = mmap(reinterpret_cast<void *>(0x00200000ULL),
                            kDramImageSize,
                            PROT_READ | PROT_WRITE,
                            MAP_SHARED | MAP_FIXED,
                            dram_fd,
                            0);
        if (mapped == MAP_FAILED) {
            std::perror("mmap");
            return 1;
        }

        wop_ctrl_init();
        auto dump_status = []() {
            const uint32_t status = wop_test_io_read32(WOP_CTRL_STATUS_ADDR);
            std::printf("[TEST] CTRL_STATUS=0x%08X\n", status);
            std::fflush(stdout);
            return status;
        };
        auto dump_ring_ctrl = []() {
            volatile wop_desc_ring_ctrl_t *ctrl = reinterpret_cast<volatile wop_desc_ring_ctrl_t *>(WOP_DESC_RING_BASE_ADDR);
            std::printf("[TEST] RING_CTRL head=%u tail=%u pending=%u capacity=%u busy_mask=0x%08X doorbell=%u release=%u last_cmd_id=%u\n",
                        ctrl->head, ctrl->tail, ctrl->pending, ctrl->capacity,
                        ctrl->busy_mask, ctrl->doorbell_count, ctrl->release_count, ctrl->last_cmd_id);
            std::fflush(stdout);
        };
        auto sync_ring_ctrl = [&](int fd) {
            volatile wop_desc_ring_ctrl_t *ctrl = reinterpret_cast<volatile wop_desc_ring_ctrl_t *>(WOP_DESC_RING_BASE_ADDR);
            wop_desc_ring_ctrl_t snapshot;
            const volatile void *src = reinterpret_cast<const volatile void *>(ctrl);
            std::memcpy(&snapshot, const_cast<const void *>(src), sizeof(snapshot));
            wop::test::write_all(fd, &snapshot, sizeof(snapshot), wop::test::kDescRingBase);
        };

        wop_descriptor_t desc{};
        desc.cmd_id = kCmdId;
        desc.mode = WOP_MODE_CB;
        desc.flags = 0;
        desc.tlwe_src_addr = wop::test::kScratchSrc;
        desc.glwe_dst_addr = wop::test::kScratchDst;
        desc.gpu_shared_addr = wop::test::kStatusBase;
        desc.tlwe_words = 4;
        desc.glwe_words = 4;
        desc.reserved = 0;
        wop::test::write_all(dram_fd, &desc, sizeof(desc), wop::test::slot_addr(kSlot));

        wop_result_status_t status{};
        status.cmd_id = desc.cmd_id;
        status.status = WOP_RESULT_STATUS_PENDING;
        wop::test::write_all(dram_fd, &status, sizeof(status), desc.gpu_shared_addr);

        wop_asset_window_t window = {
            .tlwe_base = desc.tlwe_src_addr,
            .tlwe_words = desc.tlwe_words,
            .glwe_base = desc.glwe_dst_addr,
            .glwe_words = desc.glwe_words,
            .bsk_base = 0,
            .bsk_words = 0,
            .ksk_base = 0,
            .ksk_words = 0,
            .mode = desc.mode,
        };
        wop_test_set_asset_window(kSlot, &window);

        std::array<uint32_t, 4> src_data{{0x11223344, 0x55667788, 0x99AABBCC, 0xDDEEFF00}};
        wop::test::write_all(dram_fd, src_data.data(),
                             src_data.size() * sizeof(uint32_t), desc.tlwe_src_addr);

        wop_test_io_write32(WOP_CTRL_STATUS_ADDR,
                            WOP_STATUS_DOORBELL_READY_MASK | WOP_STATUS_GPU_READY_MASK);
        dump_status();
        dump_ring_ctrl();
        sync_ring_ctrl(dram_fd);

        volatile wop_desc_ring_ctrl_t *ring_ctrl =
            reinterpret_cast<volatile wop_desc_ring_ctrl_t *>(WOP_DESC_RING_BASE_ADDR);
        if (ring_ctrl->pending != 0 || ring_ctrl->busy_mask != 0) {
            std::fprintf(stderr, "[TEST] ring ctrl not released: pending=%u busy_mask=0x%08X\n",
                         ring_ctrl->pending, ring_ctrl->busy_mask);
            munmap(mapped, kDramImageSize);
            return 1;
        }

        NVME_ADMIN_COMMAND cmd{};
        ADMIN_WOP_CONTROL_DW10 ctrl_dw10{};
        ctrl_dw10.field.cmd_id = kCmdId;
        ctrl_dw10.field.mode = WOP_MODE_CB;
        cmd.dword10 = ctrl_dw10.dword;
        cmd.dword11 = static_cast<uint32_t>(kHostDescPtr & 0xFFFFFFFFu);
        cmd.dword12 = static_cast<uint32_t>((kHostDescPtr >> 32) & 0xFFFFFFFFu);

        std::puts("[TEST] Launching handle_wop_vendor_cmd");
        std::fflush(stdout);

        NVME_COMPLETION cpl{};
        handle_wop_vendor_cmd(&cmd, &cpl);
        if (cpl.statusField.SC != SC_SUCCESSFUL_COMPLETION) {
            std::fprintf(stderr, "[TEST] handle_wop_vendor_cmd failed SC=0x%02X\n", cpl.statusField.SC);
            munmap(mapped, kDramImageSize);
            return 1;
        }
        uint32_t status_after_cmd = dump_status();
        dump_ring_ctrl();
        wop_test_io_write32(WOP_CTRL_STATUS_ADDR,
                            (status_after_cmd | WOP_STATUS_BUSY_MASK) &
                                ~WOP_STATUS_DOORBELL_READY_MASK);
        dump_status();
        dump_ring_ctrl();
        sync_ring_ctrl(dram_fd);

        WopGpuConfig cfg;
        cfg.doorbell_path.clear();
        cfg.dram_path = image.path;

        std::puts("[TEST] Running GPU runtime");
        std::fflush(stdout);
        {
            WopGpuRuntime runtime(cfg);
            runtime.run_once();
        }

        std::puts("[TEST] Invoking wop_service");
        std::fflush(stdout);
        wop_service();
        wop_test_io_write32(WOP_CTRL_STATUS_ADDR,
                            WOP_STATUS_DOORBELL_READY_MASK | WOP_STATUS_GPU_READY_MASK);
        dump_status();
        dump_ring_ctrl();
        sync_ring_ctrl(dram_fd);

        wop_result_status_t status_after{};
        wop::test::read_all(dram_fd, &status_after, sizeof(status_after), desc.gpu_shared_addr);
        if (status_after.status != WOP_RESULT_STATUS_COMPLETE) {
            std::fprintf(stderr, "[TEST] result status not COMPLETE: 0x%08X\n", status_after.status);
            munmap(mapped, kDramImageSize);
            return 1;
        }

        std::array<uint32_t, 4> dst_data{};
        wop::test::read_all(dram_fd, dst_data.data(),
                            dst_data.size() * sizeof(uint32_t), desc.glwe_dst_addr);
        if (dst_data != src_data) {
            std::fprintf(stderr, "[TEST] GLWE payload mismatch\n");
            munmap(mapped, kDramImageSize);
            return 1;
        }

        munmap(mapped, kDramImageSize);

        std::puts("[TEST] GR3FTL↔GPU closed-loop smoke test passed");
        return 0;
    } catch (const std::exception &ex) {
        std::fprintf(stderr, "[TEST] exception: %s\n", ex.what());
        return 1;
    }
}
