#include "wop_gpu_runtime.hpp"
#include "nvme.h"
#include "wop_command.h"

#include <chrono>
#include <cstring>
#include <fcntl.h>
#include <stdexcept>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <cerrno>

namespace {
constexpr size_t kDescriptorSize = sizeof(wop_descriptor_t);
constexpr size_t kResultSize = sizeof(wop_result_status_t);
constexpr size_t kRingCtrlSize = sizeof(wop_desc_ring_ctrl_t);

#ifndef WOP_DESC_RING_BASE_ADDR
#define WOP_DESC_RING_BASE_ADDR 0x00300000ULL
#endif

constexpr uint16_t next_slot(uint16_t slot) {
    return static_cast<uint16_t>((slot + 1u) & WOP_DESC_RING_SLOT_MASK);
}
}

WopGpuRuntime::WopGpuRuntime(const WopGpuConfig &cfg) : cfg_(cfg) {
    if (!cfg_.doorbell_path.empty()) {
        doorbell_fd_ = open(cfg_.doorbell_path.c_str(), O_RDONLY | O_NONBLOCK);
        if (doorbell_fd_ < 0) {
            throw std::runtime_error("failed to open doorbell path: " + cfg_.doorbell_path);
        }
    } else {
        ring_mode_ = true;
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
        if (ret == 0) {
            usleep(1000);
            continue;
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

wop_desc_ring_ctrl_t WopGpuRuntime::load_ring_ctrl() {
    wop_desc_ring_ctrl_t ctrl{};
    if (pread(dram_fd_, &ctrl, kRingCtrlSize, static_cast<off_t>(WOP_DESC_RING_BASE_ADDR)) != static_cast<ssize_t>(kRingCtrlSize)) {
        throw std::runtime_error("failed to load ring control");
    }
    return ctrl;
}

void WopGpuRuntime::store_ring_ctrl(const wop_desc_ring_ctrl_t &ctrl) {
    if (pwrite(dram_fd_, &ctrl, kRingCtrlSize, static_cast<off_t>(WOP_DESC_RING_BASE_ADDR)) != static_cast<ssize_t>(kRingCtrlSize)) {
        throw std::runtime_error("failed to store ring control");
    }
}

void WopGpuRuntime::store_result(const wop_descriptor_t &desc,
                                 uint32_t status_code,
                                 uint32_t latency_cycles,
                                 uint32_t error_code) {
    wop_result_status_t result{};
    result.cmd_id       = desc.cmd_id;
    result.status       = status_code;
    result.error_code   = error_code;
    result.latency_ns   = static_cast<uint64_t>(latency_cycles) * 1000ULL;
    result.timestamp_ns = 0U;
    result.reserved0    = 0U;
    result.reserved1    = 0U;
    if (pwrite(dram_fd_, &result, kResultSize, static_cast<off_t>(desc.gpu_shared_addr)) != static_cast<ssize_t>(kResultSize)) {
        throw std::runtime_error("failed to write result");
    }
}

void WopGpuRuntime::notify_completion(uint16_t slot,
                                      const wop_descriptor_t &desc,
                                      uint32_t status_code,
                                      uint32_t error_code) {
    (void)status_code;
    (void)error_code;
    try {
        wop_desc_ring_ctrl_t ctrl = load_ring_ctrl();
        ctrl.release_count++;
        ctrl.last_cmd_id = desc.cmd_id;
        store_ring_ctrl(ctrl);
    } catch (const std::exception &) {
        // Ignore failures in stub environment; PS side will still poll results.
    }

}

int WopGpuRuntime::process_descriptor(const wop_descriptor_t &desc,
                                      uint32_t &latency_cycles,
                                      uint32_t &status_code,
                                      uint32_t &error_code) {
    auto start = std::chrono::high_resolution_clock::now();

    status_code = WOP_RESULT_STATUS_COMPLETE;
    error_code = 0U;

    if (desc.tlwe_words > 0) {
        std::vector<uint32_t> buffer(desc.tlwe_words, 0);
        const ssize_t transfer_bytes = static_cast<ssize_t>(desc.tlwe_words * sizeof(uint32_t));
        if (pread(dram_fd_, buffer.data(), transfer_bytes, static_cast<off_t>(desc.tlwe_src_addr)) != transfer_bytes) {
            status_code = WOP_RESULT_STATUS_ERROR;
            error_code = SC_DATA_TRANSFER_ERROR;
        } else if (pwrite(dram_fd_, buffer.data(), transfer_bytes, static_cast<off_t>(desc.glwe_dst_addr)) != transfer_bytes) {
            status_code = WOP_RESULT_STATUS_ERROR;
            error_code = SC_DATA_TRANSFER_ERROR;
        }
    }

    auto end = std::chrono::high_resolution_clock::now();
    latency_cycles = static_cast<uint32_t>(std::chrono::duration_cast<std::chrono::microseconds>(end - start).count());

    if (status_code == WOP_RESULT_STATUS_ERROR && error_code == 0U) {
        error_code = SC_DATA_TRANSFER_ERROR;
    }

    if (error_code != 0U) {
        return SC_DATA_TRANSFER_ERROR;
    }
    return SC_SUCCESSFUL_COMPLETION;
}

bool WopGpuRuntime::find_pending_slot(uint16_t &slot_out, wop_descriptor_t &desc_out) {
    wop_desc_ring_ctrl_t ctrl = load_ring_ctrl();
    if (ctrl.busy_mask == 0U) {
        return false;
    }

    uint16_t slot = ctrl.head;
    for (uint32_t i = 0; i < WOP_DESC_RING_CAPACITY; ++i) {
        uint32_t mask = 1U << (slot & WOP_DESC_RING_SLOT_MASK);
        if (ctrl.busy_mask & mask) {
            const uint64_t desc_addr = WOP_DESC_SLOT_ADDR(WOP_DESC_RING_BASE_ADDR, slot);
            wop_descriptor_t desc = load_descriptor(desc_addr);
            wop_result_status_t result{};
            if (pread(dram_fd_, &result, kResultSize, static_cast<off_t>(desc.gpu_shared_addr)) != static_cast<ssize_t>(kResultSize)) {
                slot = next_slot(slot);
                continue;
            }
            if (result.status == WOP_RESULT_STATUS_PENDING) {
                slot_out = slot;
                desc_out = desc;
                last_slot_checked_ = slot;
                return true;
            }
        }
        slot = next_slot(slot);
    }
    return false;
}

void WopGpuRuntime::run_once() {
    bool processed = false;
    constexpr uint64_t kAlignMask = 0x1FULL;

    while (true) {
        uint16_t slot = 0;
        wop_descriptor_t desc{};

        if (ring_mode_) {
            if (!find_pending_slot(slot, desc)) {
                if (processed) {
                    break;
                }
                usleep(1000);
                continue;
            }
        } else {
            DoorbellToken token = wait_for_token();
            slot = token.cmd_id & WOP_DESC_RING_SLOT_MASK;
            const uint64_t desc_addr = WOP_DESC_SLOT_ADDR(WOP_DESC_RING_BASE_ADDR, slot);
            desc = load_descriptor(desc_addr);
        }

        uint32_t latency = 0;
        uint32_t status_code = WOP_RESULT_STATUS_COMPLETE;
        uint32_t error_code = 0U;
        int sc = SC_SUCCESSFUL_COMPLETION;

        const bool addr_aligned =
            ((desc.tlwe_src_addr & kAlignMask) == 0U) &&
            ((desc.glwe_dst_addr & kAlignMask) == 0U) &&
            ((desc.gpu_shared_addr & kAlignMask) == 0U);

        if (!addr_aligned) {
            status_code = WOP_RESULT_STATUS_ERROR;
            error_code = SC_INVALID_FIELD_IN_COMMAND;
            sc = SC_INVALID_FIELD_IN_COMMAND;
        } else {
            sc = process_descriptor(desc, latency, status_code, error_code);
            if (sc != SC_SUCCESSFUL_COMPLETION && status_code != WOP_RESULT_STATUS_ERROR) {
                status_code = WOP_RESULT_STATUS_ERROR;
                if (error_code == 0U) {
                    error_code = static_cast<uint32_t>(sc);
                }
            }
        }

        store_result(desc, status_code, (sc == SC_SUCCESSFUL_COMPLETION) ? latency : 0U, error_code);
        notify_completion(slot, desc, status_code, error_code);

        history_.push_back({desc.cmd_id, desc.mode, latency, error_code});
        processed = true;

        if (!ring_mode_) {
            break;
        }
    }
}

void WopGpuRuntime::run_loop() {
    while (true) {
        run_once();
    }
}
