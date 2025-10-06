# DaisyPlus WoP-PBS 集成方案（Micron 4C2W，2025-10-05）

## 1. 目标与范围
- 将 HPU `wop_pbs_kernel_unified` 与 OpenSSD DaisyPlus Micron 4C2W 设计打通，实现 TFHE WoP 流程的 SSD→GPU 协同。
- DaisyPlus 侧负责轻量控制、密钥缓存与数据搬运；高开销 NTT/PrivKS/外积迁移至 GPU。
- 通过 NVMe Vendor 命令与 GR3FTL 固件扩展，实现主机发令、GPU Doorbell、执行状态回报的闭环。

## 2. 现有实现体检（2025-10-05）
- **RTL（HPU 仓）**：`wop_pbs_kernel_unified.sv` 已整合 VP/BE/CB，并新增 `openssd_wop_wrapper` 骨架（AXI-Lite 控制、单拍 DMA 描述符读取、GPU doorbell stub、descriptor → kernel 缓冲）。
  - 待办：PrivKS 结果路径闭环 (`int_ks_seq_result_vld`)、DMA 写回通路、descriptor → `vp_pbs_inst` 映射。
- **固件（DaisyPlus Micron）**：`run-gr3ftl/src` 中含 NVMe/FTL 处理，尚未定义 Vendor 命令入口，也缺少 WoP 控制寄存器映射与 doorbell 逻辑。
  - `memory_map.h` 现有保留段 `0x0030_0000~0x0FFF_FFFF` 可划出 WoP 控制窗口、描述符环、GPU 共享缓冲。

## 3. 架构分工
| 模块 | DaisyPlus SSD (FPGA/ARM) | GPU |
| --- | --- | --- |
| 指令处理 | 解析 Vendor 命令、填充 WoP 描述符、写 `openssd_wop_wrapper` 控制寄存器 | N/A |
| 数据搬运 | AXI 主机 DMA → DRAM → GPU 共享区；采集 WoP 结果 | DMA 接受 TLWE/GLWE 数据，执行 WoKS/PrivKS |
| 运算 | 预处理/寄存器回写/结果校验 | WoKS NTT、外积、PrivKS ACC、结果打包 |
| 状态反馈 | NVMe Completion、GET LOG、自定义 doorbell 中断 | 共享内存更新状态、触发回写中断 |

## 4. DaisyPlus 接口设计对照
1. **AXI-Lite 控制窗口**（映射至 `WOP_CTRL_BASE_ADDR = 0x0028_0000`）：
   - `CTRL_CMD/STATUS/DESC_PTR/INT_*` 寄存器由 `openssd_wop_axi_lite_ctrl` 提供，固件写入前需轮询 `CTRL_STATUS[BUSY]` 为 0。
   - Busy 状态下重复 Doorbell 会触发 `error_evt`，固件须读取 `INT_STATUS` 并写 1 清除。
2. **Descriptor & DRAM 布局**：
   - `WOP_DESC_RING_BASE_ADDR = 0x0030_0000`（4KB）用于描述符镜像，`WOP_GPU_SHARED_BASE_ADDR = 0x0031_0000`（256KB）用于 TLWE/GLWE 缓冲与 GPU 共享区。
   - 保持 4KB 对齐，避免与现有 FTL/缓冲映射冲突。
3. **GPU Doorbell**：
   - 固件写 `CTRL_CMD[31]=1` 发令，wrapper 通过 `openssd_wop_gpu_notify` 生成 token，GPU 侧需监听 AXI4-Stream/SMMU。
4. **日志/调试**：
   - DaisyPlus 端补充 Vendor 日志（`[WOPDBG]`）并通过 `GET LOG`/UART 输出；GPU 配合记录 `unified_ack`、性能计数。

## 5. 开发里程碑
1. **M0**：HPU 侧保证 `openssd_wop_wrapper` → `wop_pbs_kernel_unified` 功能完备。
2. **M1**：DaisyPlus GR3FTL 引入 WoP Vendor 命令、Doorbell/描述符管理，并在 `memory_map.h` 划定缓冲区。
3. **M2**：GPU stub 接入，完成 33×64 缩参端到端验证。
4. **M3**：实参（631×2048）长跑 + NVMe Host I/O 回归。

## 6. 风险与缓解
- **DRAM 资源冲突**：与现有数据缓冲共享地址空间 → 需谨慎规划地址、增加越界保护。
- **NVMe 控制路径延迟**：Vendor 命令执行需保证不阻塞常规 IO；建议使用单独队列或异步完成。
- **GPU 依赖**：需确认 DaisyPlus ↔ GPU 通道（PCIe/AXI Bridge）带宽、doorbell 机制可复用。

## 7. 近期行动
- 在 DaisyPlus `nvme_main.c` / `nvme_admin_cmd.c` 中注册 WoP Vendor 命令处理器。
- 编写 `wop_command.h/wop_command.c`，负责描述符填充、Doorbell 写入、状态回读。
- 更新 `memory_map.h`，预留 WoP 控制窗口与描述符队列。

## 8. 最新跟踪（2025-10-05）
- [x] HPU 仓内完成 `openssd_wop_wrapper` 骨架，AXI-Lite/描述符/GPU Doorbell 均已通过 lint。
- [x] DaisyPlus 固件新增 `ADMIN_WOP_CONTROL` Vendor 命令（`wop_command.c`），可写入 `WOP_CTRL_*` 寄存器并触发 Doorbell。
- [ ] GPU 协同接口、Doorbell ISR、TLWE/GLWE 缓冲管理待落地。

## 9. 后续短期任务
- [ ] 完成 descriptor → `vp_pbs_inst` 映射，定义 TLWE/GLWE 缓冲布局与批次字段。
- [ ] 扩展 DMA 通路：实现 TLWE 读入 GPU、GLWE 写回 SSD 的 AXI burst，完成 `openssd_wop_dma_descriptor` 写通路。
- [ ] GPU 协同：定义 Doorbell token 格式、共享内存状态机以及中断回调，规划 33×64 缩参联调脚本。
- [ ] 日志与调试：增加 `[WOPDBG]` 过滤脚本、GET LOG 扩展项，记录 Doorbell/状态变化。
- [ ] 长跑验证：准备 NVMe 主机端测试程序，触发 Vendor 命令并监控 `INT_STATUS`/结果写回。
- [ ] FTL 集成：依据 `wop_storage_plan.md` 预留 NAND 区域，落地 `wop_stage_assets_from_nand()` 的 NAND→DRAM 搬运逻辑。

## 10. GPU 端进展
- [x] 创建 `GPU/wop_runtime` 框架：提供 C++17/CUDA 可选 runtime，解析 `wop_descriptor_t`、写回 `wop_result_t`，含占位 memcpy kernel。
- [ ] Doorbell 真实接口对接（PCIe BAR / AXI4-Stream）。
- [ ] GPU 内核替换为实际 WoP 算法，实现 TLWE→GLWE 转换与 PrivKS/NTT 流程。
- [ ] 与 SSD 联调脚本：使用 FIFO/DRAM 镜像驱动验证 33×64 缩参路径。
