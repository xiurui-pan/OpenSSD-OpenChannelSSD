#include "wop_gpu_runtime.hpp"

#include <array>
#include <cinttypes>
#include <cstdio>
#include <cstdlib>

#include "test_dram_image.hpp"

int main() {
    try {
        constexpr std::size_t kDramImageSize = 0x0040'0000;
        wop::test::DramImage image(kDramImageSize);
        const std::string &dram_path = image.path;
        const int dram_fd = image.fd;

        wop_desc_ring_ctrl_t ctrl{};
        ctrl.head = 0;
        ctrl.tail = 1;
        ctrl.pending = 1;
        ctrl.capacity = WOP_DESC_RING_CAPACITY;
        ctrl.busy_mask = 0x1;
        ctrl.doorbell_count = 1;
        wop::test::write_all(dram_fd, &ctrl, sizeof(ctrl), wop::test::kDescRingBase);

        wop_descriptor_t desc{};
        desc.cmd_id = 0x0123;
        desc.mode = WOP_MODE_CB;
        desc.flags = 0;
        desc.tlwe_src_addr = wop::test::kScratchSrc;
        desc.glwe_dst_addr = wop::test::kScratchDst;
        desc.gpu_shared_addr = wop::test::kStatusBase;
        desc.tlwe_words = 4;
        desc.glwe_words = 4;
        desc.reserved = 0;
        wop::test::write_all(dram_fd, &desc, sizeof(desc), wop::test::slot_addr(0));

        wop_result_status_t status{};
        status.status = WOP_RESULT_STATUS_PENDING;
        status.cmd_id = desc.cmd_id;
        wop::test::write_all(dram_fd, &status, sizeof(status), wop::test::kStatusBase);

        std::array<std::uint32_t, 4> src_data{{0xDEADBEEF, 0xCAFEBABE, 0x01234567, 0x89ABCDEF}};
        wop::test::write_all(dram_fd, src_data.data(),
                             src_data.size() * sizeof(std::uint32_t), desc.tlwe_src_addr);

        WopGpuConfig cfg;
        cfg.doorbell_path.clear();  // ring mode
        cfg.dram_path = dram_path;

        {
            WopGpuRuntime runtime(cfg);
            runtime.run_once();
        }

        wop_result_status_t status_after{};
        wop::test::read_all(dram_fd, &status_after, sizeof(status_after), wop::test::kStatusBase);
        if (status_after.status != WOP_RESULT_STATUS_COMPLETE) {
            std::fprintf(stderr, "[TEST] expected COMPLETE status, got 0x%08X\n", status_after.status);
            return 1;
        }
        if (status_after.cmd_id != desc.cmd_id) {
            std::fprintf(stderr, "[TEST] cmd_id mismatch: expected %u got %u\n",
                         static_cast<unsigned>(desc.cmd_id),
                         static_cast<unsigned>(status_after.cmd_id));
            return 1;
        }

        std::array<std::uint32_t, 4> dst_data{};
        wop::test::read_all(dram_fd, dst_data.data(),
                            dst_data.size() * sizeof(std::uint32_t), desc.glwe_dst_addr);
        if (dst_data != src_data) {
            std::fprintf(stderr, "[TEST] destination payload mismatch\n");
            return 1;
        }

        wop_desc_ring_ctrl_t ctrl_after{};
        wop::test::read_all(dram_fd, &ctrl_after, sizeof(ctrl_after), wop::test::kDescRingBase);
        if (ctrl_after.release_count == ctrl.release_count) {
            std::fprintf(stderr, "[TEST] release_count not updated\n");
            return 1;
        }

        std::printf("[TEST] GPU runtime ring-mode smoke test passed (cmd_id=%u)\n",
                    static_cast<unsigned>(desc.cmd_id));
        return 0;
    } catch (const std::exception &ex) {
        std::fprintf(stderr, "[TEST] exception: %s\n", ex.what());
        return 1;
    }
}
