#pragma once

#include "wop_descriptor.h"

#include <cerrno>
#include <cstdint>
#include <cstring>
#include <stdexcept>
#include <string>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>

namespace wop::test {

struct DramImage {
  int fd;
  std::string path;
  std::size_t size;

  explicit DramImage(std::size_t image_size) : fd(-1), size(image_size) {
    char tmpl[] = "/tmp/wop_dram_XXXXXX";
    fd = mkstemp(tmpl);
    if (fd < 0) {
      throw std::runtime_error(std::string("mkstemp failed: ") + std::strerror(errno));
    }
    path = tmpl;
    if (ftruncate(fd, static_cast<off_t>(size)) != 0) {
      ::close(fd);
      ::unlink(path.c_str());
      throw std::runtime_error(std::string("ftruncate failed: ") + std::strerror(errno));
    }
  }

  ~DramImage() {
    if (fd >= 0) {
      ::close(fd);
    }
    if (!path.empty()) {
      ::unlink(path.c_str());
    }
  }
};

inline void write_all(int fd, const void *buf, std::size_t len, std::uint64_t offset) {
  const auto *ptr = static_cast<const std::uint8_t *>(buf);
  std::size_t written = 0;
  while (written < len) {
    const ssize_t ret = pwrite(fd, ptr + written, len - written, static_cast<off_t>(offset + written));
    if (ret < 0) {
      throw std::runtime_error(std::string("pwrite failed: ") + std::strerror(errno));
    }
    written += static_cast<std::size_t>(ret);
  }
}

inline void read_all(int fd, void *buf, std::size_t len, std::uint64_t offset) {
  auto *ptr = static_cast<std::uint8_t *>(buf);
  std::size_t read_bytes = 0;
  while (read_bytes < len) {
    const ssize_t ret = pread(fd, ptr + read_bytes, len - read_bytes, static_cast<off_t>(offset + read_bytes));
    if (ret < 0) {
      throw std::runtime_error(std::string("pread failed: ") + std::strerror(errno));
    }
    if (ret == 0) {
      throw std::runtime_error("unexpected EOF while reading dram image");
    }
    read_bytes += static_cast<std::size_t>(ret);
  }
}

constexpr std::uint64_t kDescRingBase = 0x0030'0000ULL;
constexpr std::uint64_t kDescRingMetaBytes = 0x40ULL;
constexpr std::uint64_t kStatusBase = 0x0031'0000ULL;
constexpr std::uint64_t kScratchSrc = 0x0032'0000ULL;
constexpr std::uint64_t kScratchDst = 0x0033'0000ULL;

inline std::uint64_t slot_addr(std::uint16_t slot) {
  return kDescRingBase + kDescRingMetaBytes +
         static_cast<std::uint64_t>(slot) * sizeof(wop_descriptor_t);
}

}  // namespace wop::test
