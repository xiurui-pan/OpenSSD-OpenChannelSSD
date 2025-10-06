#include "wop_gpu_runtime.hpp"
#include "nvme.h"

#include <chrono>
#include <cstring>
#include <fcntl.h>
#include <stdexcept>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

namespace {
constexpr size_t kDescriptorSize = sizeof(wop_descriptor_t);
constexpr size_t kResultSize = sizeof(wop_result_t);
}

WopGpuRuntime::WopGpuRuntime(const WopGpuConfig &cfg) : cfg_(cfg) {
    doorbell_fd_ = open(cfg_.doorbell_path.c_str(), O_RDONLY | O_NONBLOCK);
    if (doorbell_fd_ < 0) {
        throw std::runtime_error("failed to open doorbell path: " + cfg_.doorbell_path);
    }
    dram_fd_ = open(cfg_.dram_path.c_str(), O_RDWR);
    if (dram_fd_ < 0) {
        throw std::runtime_error("failed to open dram path: " + cfg_.dram_path);
    }
}

WopGpuRuntime::~WopGpuRuntime() {
    if (doorbell_fd_ >= 0) close(doorbell_fd_);
    if (dram_fd_ >= 0) close(dram_fd_);
}

DoorbellToken WopGpuRuntime::wait_for_token() {
    DoorbellToken token{};
    while (true) {
        ssize_t ret = read(doorbell_fd_, &token, sizeof(token));
        if (ret == sizeof(token)) {
            return token;
        }
        if (ret < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
            usleep(1000);
            continue;
        }
        throw std::runtime_error("doorbell read failed");
    }
}

wop_descriptor_t WopGpuRuntime::load_descriptor(uint64_t desc_addr) {
    wop_descriptor_t desc{};
    if (pread(dram_fd_, &desc, kDescriptorSize, static_cast<off_t>(desc_addr)) != static_cast<ssize_t>(kDescriptorSize)) {
        throw std::runtime_error("failed to load descriptor");
    }
    return desc;
}

void WopGpuRuntime::store_result(const wop_descriptor_t &desc, uint32_t status, uint32_t latency_cycles, uint8_t error_code) {
    wop_result_t result{};
    result.status = status;
    result.latency_cycles = latency_cycles;
    result.cmd_id = desc.cmd_id;
    result.error_code = error_code;
    if (pwrite(dram_fd_, &result, kResultSize, static_cast<off_t>(desc.gpu_shared_addr)) != static_cast<ssize_t>(kResultSize)) {
        throw std::runtime_error("failed to write result");
    }
}

int WopGpuRuntime::process_descriptor(const wop_descriptor_t &desc) {
    auto start = std::chrono::high_resolution_clock::now();

    // TODO: replace with actual GPU kernels. For now, perform a memcpy on CPU.
    std::vector<uint32_t> buffer(desc.tlwe_words, 0);
    if (desc.tlwe_words > 0) {
        if (pread(dram_fd_, buffer.data(), desc.tlwe_words * sizeof(uint32_t), static_cast<off_t>(desc.tlwe_src_addr))
            != static_cast<ssize_t>(desc.tlwe_words * sizeof(uint32_t))) {
            return SC_DATA_TRANSFER_ERROR;
        }
        if (pwrite(dram_fd_, buffer.data(), desc.tlwe_words * sizeof(uint32_t), static_cast<off_t>(desc.glwe_dst_addr))
            != static_cast<ssize_t>(desc.tlwe_words * sizeof(uint32_t))) {
            return SC_DATA_TRANSFER_ERROR;
        }
    }

    auto end = std::chrono::high_resolution_clock::now();
    uint32_t latency = static_cast<uint32_t>(std::chrono::duration_cast<std::chrono::microseconds>(end - start).count());
    store_result(desc, WOP_STATUS_GPU_READY_MASK, latency, 0);

    history_.push_back({desc.cmd_id, desc.mode, latency, 0});
    return SC_SUCCESSFUL_COMPLETION;
}

void WopGpuRuntime::run_once() {
    DoorbellToken token = wait_for_token();

    uint64_t desc_addr = WOP_DESC_RING_BASE_ADDR; // future: ring index via cmd_id
    wop_descriptor_t desc = load_descriptor(desc_addr);
    (void)token; // placeholder for mode matching

    int sc = process_descriptor(desc);
    if (sc != SC_SUCCESSFUL_COMPLETION) {
        store_result(desc, WOP_STATUS_ERROR_MASK, 0, static_cast<uint8_t>(sc));
    }
}

