# DaisyPlus OpenSSD WoP-PBS Wrapper 占位说明 (2025-10-05)

## 目的
- 在 DaisyPlus Micron 4C2W 设计中集成独立 WoP-PBS Wrapper，桥接 NVMe 主机（GR3FTL 固件）与 `wop_pbs_kernel_unified`。
- Wrapper 暴露 AXI-Lite 控制、AXI 主口 DMA 以及 GPU doorbell 通道，便于后续与 DaisyPlus Block Design 对接。

## 端口草案
1. **AXI-Lite (`S_AXI`)**
   - `CTRL_CMD`：bit[31] doorbell，bit[1:0] 模式选择 (VP/BE/CB)，控制窗口默认映射到 `WOP_CTRL_BASE_ADDR = 0x0028_0000`
   - `CTRL_STATUS`：busy/error、GPU ready、最近一次任务 ID
   - `CTRL_DESC_PTR_LO/HI`：64-bit DRAM 描述符指针
   - `INT_STATUS/INT_MASK`：Done/Error 中断控制
2. **AXI 主接口 (`M_AXI`)**
   - DaisyPlus DDR 地址空间内预留 `WOP_DESC_RING_BASE_ADDR` / `WOP_GPU_SHARED_BASE_ADDR`（参考 `memory_map.h`），用于批量搬运 TLWE/GLWE 数据
   - 256-bit 数据宽度与 CosmosPlus DMA 兼容；必要时支持突发长度扩展
3. **AXI4-Stream GPU Doorbell (可选)**
   - 发送任务 token 至 GPU 控制器 / PCIe 侧桥接逻辑
4. **WoP 内核接口**
   - `unified_pbs_inst`、RegFile、BSK/NTT 服务、clk/reset 与 HPU 核心保持一致

## RTL 结构
```
openssd_wop_wrapper
  |- openssd_wop_axi_lite_ctrl.sv   // 寄存器映射 + Doorbell 仲裁
  |- openssd_wop_dma_descriptor.sv // 描述符读取（单拍 DMA，后续扩展写回）
  |- openssd_wop_gpu_notify.sv     // GPU doorbell token 输出
  |- openssd_wop_kernel_bridge.sv  // descriptor 缓冲 → wop_pbs_kernel_unified
```

## 待办事项
- 根据 DaisyPlus `memory_map.h` 划分 WoP 控制窗口、描述符环与缓冲区，导出固件头文件。
- 在 DaisyPlus Vivado 工程中实例化 Wrapper，连接 AXI-Lite / AXI 主口与现有互连。
- 与 GR3FTL 固件对齐 Vendor 命令号、Doorbell 中断、共享内存状态布局。

