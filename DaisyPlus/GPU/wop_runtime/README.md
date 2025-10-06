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
     - 写回 `wop_result_t` 并上报错误码。
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

## TODO
- 对接真实 doorbell（PCIe BAR 或共享内存信号）。
- 实现 TLWE→GLWE WoP 算法流程，调用已有 GPU 库。
- 将 `wop_result_t` 写回 SSD 中断通道（MSI-X / MMIO）。
- 与 DaisyPlus 固件联合调试 33×64 缩参场景。
