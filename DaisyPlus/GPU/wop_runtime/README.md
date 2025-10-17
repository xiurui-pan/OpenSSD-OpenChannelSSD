# DaisyPlus WoP GPU Runtime Stub

## 目标
- 监听 DaisyPlus SSD Doorbell，共享 `wop_descriptor_t` 描述符，与 GPU 侧内核协同执行 TFHE WoP 算法。
- 当前版本提供最小可编译框架（基于 C++17/CUDA 可选），读取描述符后执行占位计算并写回结果结构。

## 模块
1. `wop_gpu_runtime.hpp/cpp`
   - `WopGpuRuntime` 负责：
     - 初始化（映射共享内存、配置日志）。
     - 监听 doorbell token（目前模拟为阻塞 `read()`）。
  - 解析 `wop_descriptor_t`，触发占位 CUDA kernel。
  - 写回 `wop_result_status_t`（cmd_id/status/error_code/latency）。
2. `wop_gpu_kernels.cu`
   - 简单 kernel：将 TLWE 输入复制到 GLWE 输出，并统计耗时。
3. `main.cpp`
   - 演示如何启动 runtime，循环处理若干描述符。

## 构建
```bash
mkdir build && cd build
cmake .. -DWOP_ENABLE_CUDA=ON
make -j
```

无 CUDA 时将自动使用 CPU stub。

## 快速冒烟测试（无 CUDA）
在当前目录执行下面命令，可借助 ring-mode 冒烟测试验证 Result Status 写回闭环：
```bash
g++ -std=c++17 -Wall -Wextra \
    -I../OpenSSD/Micron_NAND/daisyplus_openssd_micron_4c2w_ns/cosm-plus-sys/cosm-plus-sys.sdk/run-gr3ftl/src \
    -I../OpenSSD/Micron_NAND/daisyplus_openssd_micron_4c2w_ns/cosm-plus-sys/cosm-plus-sys.sdk/run-gr3ftl/src/nvme \
    -I. \
    tests/test_ring_runtime.cpp wop_gpu_runtime.cpp -o /tmp/test_ring_runtime
/tmp/test_ring_runtime
```
运行成功会输出 `GPU runtime ring-mode smoke test passed`，并验证：
- `wop_result_status_t` 从 `PENDING` 变为 `COMPLETE`
- TLWE payload 被复制到 GLWE 目的地址
- Ring Control `release_count` 自增，方便固件侧统计门铃完成次数

## GR3FTL ↔ GPU 闭环验证（无 CUDA）
再次在本目录执行：
```bash
gcc -std=c17 -Wall -Wextra \
    -Itests \
    -I../OpenSSD/Micron_NAND/daisyplus_openssd_micron_4c2w_ns/cosm-plus-sys/cosm-plus-sys.sdk/run-gr3ftl/src \
    -I../OpenSSD/Micron_NAND/daisyplus_openssd_micron_4c2w_ns/cosm-plus-sys/cosm-plus-sys.sdk/run-gr3ftl/src/nvme \
    -include stdint.h \
    -c ../OpenSSD/Micron_NAND/daisyplus_openssd_micron_4c2w_ns/cosm-plus-sys/cosm-plus-sys.sdk/run-gr3ftl/src/nvme/wop_command.c
g++ -std=c++17 -Wall -Wextra \
    -Itests \
    -I../OpenSSD/Micron_NAND/daisyplus_openssd_micron_4c2w_ns/cosm-plus-sys/cosm-plus-sys.sdk/run-gr3ftl/src \
    -I../OpenSSD/Micron_NAND/daisyplus_openssd_micron_4c2w_ns/cosm-plus-sys/cosm-plus-sys.sdk/run-gr3ftl/src/nvme \
    tests/io_access_stub.c tests/wop_command_test_stubs.c tests/test_gr3ftl_gpu_loop.cpp \
    wop_gpu_runtime.cpp wop_command.o -o /tmp/test_gr3ftl_gpu_loop
/tmp/test_gr3ftl_gpu_loop
```
输出 `GR3FTL↔GPU closed-loop smoke test passed` 表示：
- GR3FTL 固件 `handle_wop_vendor_cmd()` 成功发令并在 `wop_service()` 中依靠 Result Status 释放槽位
- GPU runtime 将 TLWE 载荷复制到 GLWE 目标，并写回 `WOP_RESULT_STATUS_COMPLETE`
- Stub 环境通过 doorbell ready/忙碌位模拟，实现一次完整的 descriptor → GPU → 结果回写闭环

## TODO
- 对接真实 doorbell（PCIe BAR 或共享内存信号），当前默认轮询环控制块。
- 实现 TLWE→GLWE WoP 算法流程，调用已有 GPU 库。
- 将 `wop_result_status_t` 写回 SSD 中断通道（MSI-X / MMIO）。
- 与 DaisyPlus 固件联合调试 33×64 缩参场景。
