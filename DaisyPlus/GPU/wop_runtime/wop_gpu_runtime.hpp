#pragma once

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

#include "wop_descriptor.h"

struct DoorbellToken {
    uint16_t cmd_id;
    uint8_t mode;
};

struct WopGpuConfig {
    std::string doorbell_path;     // e.g. FIFO or character device
    std::string dram_path;         // memory-mapped DRAM simulation file
    bool enable_cuda = false;
};

struct WopExecutionStats {
    uint16_t cmd_id;
    uint8_t mode;
    uint32_t latency_cycles;
    uint32_t error_code;
};

class WopGpuRuntime {
  public:
    explicit WopGpuRuntime(const WopGpuConfig &cfg);
    ~WopGpuRuntime();

    void run_once();
    void run_loop();

    const std::vector<WopExecutionStats> &stats() const { return history_; }

  private:
    wop_descriptor_t load_descriptor(uint64_t desc_addr);
    wop_desc_ring_ctrl_t load_ring_ctrl();
    void store_ring_ctrl(const wop_desc_ring_ctrl_t &ctrl);
    void store_result(const wop_descriptor_t &desc, uint32_t status_code, uint32_t latency_cycles, uint32_t error_code);
    void notify_completion(uint16_t slot, const wop_descriptor_t &desc, uint32_t status_code, uint32_t error_code);
    int process_descriptor(const wop_descriptor_t &desc, uint32_t &latency_cycles, uint32_t &status_code, uint32_t &error_code);

    bool find_pending_slot(uint16_t &slot_out, wop_descriptor_t &desc_out);
    DoorbellToken wait_for_token(); // deprecated path for FIFO doorbells

    int doorbell_fd_ = -1;
    int dram_fd_ = -1;
    WopGpuConfig cfg_{};
    std::vector<WopExecutionStats> history_;
    bool ring_mode_ = false;
    uint16_t last_slot_checked_ = 0;
};
