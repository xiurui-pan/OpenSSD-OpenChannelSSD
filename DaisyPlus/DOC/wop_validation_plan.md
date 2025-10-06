# DaisyPlus WoP 验证计划 (2025-10-05)

## 1. 编译/综合闭环
1. `vivado -mode batch -source build_wop.tcl`（位于 `DaisyPlus/OpenSSD/Micron_NAND/daisyplus_openssd_micron_4c2w_ns`）。
   - 当前阻塞：大量 IP 需要升级且综合阶段因 `xczu17eg` 许可缺失而终止。
   - 行动：联系许可管理员启用 ZU17EG Synthesis 许可，或替换为已授权器件，再次运行脚本。
2. GR3FTL 固件：在 Vitis/XSCT 中导入 `run-gr3ftl` 工程，确认 `wop_command.c`、`wop_descriptor.h` 已纳入构建，生成 `BOOT.BIN`。

## 2. 仿真策略
- **短期**：
  - GPU stub (`DaisyPlus/GPU/wop_runtime`) 结合 `test_stub.sh` 模拟 doorbell/TLWE 数据，验证 SSD→GPU→SSD stub 路径。
  - 针对 `openssd_wop_wrapper` 构建 XSim testbench，检查 AXI-Lite Doorbell、DMA 读写握手，与 `wop_pbs_kernel_unified` 的联动。
- **中期**：
  - 在 ZU19/VCU1525 平台上运行 GR3FTL + wrapper + GPU stub，触发 `ADMIN_WOP_CONTROL`，监控 `INT_STATUS`、`wop_result_t`。
  - 使用缩参 (33×64) 向量，验证 TLWE→GLWE 数据路径与延迟计数。

## 3. 日志采集
- Vivado: 保存 `build_wop.tcl.log`，包括 IP 锁定和许可错误，供许可处理后复测。
- GPU stub: `wop_gpu_daemon` 输出 `[WOP] doorbell ...`、`latency`，验证读写结果。
- 固件: `wop_command.c` `[WOP]` 日志，计划通过 NVMe `GET LOG` 导出。

## 4. 后续工作
- 解决 Vivado IP 锁定：执行 `upgrade_ip [get_ips]` 后检查 `report_ip_status`，必要时迁移至 inline HDL。
- 实现 AXI DMA 写回/写入流水线，完成 TLWE/GLWE 调度。
- 将 GPU stub 替换为真实 WoP CUDA/HIP 内核，接入 PCIe Doorbell 通道。
