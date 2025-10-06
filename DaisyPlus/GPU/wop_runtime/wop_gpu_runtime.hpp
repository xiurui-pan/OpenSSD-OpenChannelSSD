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

    const std::vector<WopExecutionStats> &stats() const { return history_; }

  private:
    wop_descriptor_t load_descriptor(uint64_t desc_addr);
    void store_result(const wop_descriptor_t &desc, uint32_t status, uint32_t latency_cycles, uint8_t error_code);
    int process_descriptor(const wop_descriptor_t &desc);

    DoorbellToken wait_for_token();

    int doorbell_fd_ = -1;
    int dram_fd_ = -1;
    WopGpuConfig cfg_{};
    std::vector<WopExecutionStats> history_;
};

