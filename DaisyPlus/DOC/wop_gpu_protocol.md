# DaisyPlus WoP-PBS GPU 协议说明 (2025-10-05)

## 1. 描述符结构
固件在 DRAM `WOP_DESC_RING_BASE_ADDR` 处填入 32 字节对齐的 `wop_descriptor_t`：

| 字段 | 位宽 | 描述 |
| --- | --- | --- |
| `cmd_id` | 16 | 主机命令 ID，SSD/GPU 日志关联键 |
| `mode` | 8 | 0=VP，1=BE，2=CB |
| `flags` | 8 | `BIT0`=GPU 写回结果，`BIT1`=黄金比对，其余保留 |
| `tlwe_src_addr` | 64 | TLWE 输入数据（SSD DRAM 物理地址） |
| `glwe_dst_addr` | 64 | GLWE 输出写回地址 |
| `gpu_shared_addr` | 64 | GPU 工作区/中间缓冲 |
| `tlwe_words` | 16 | TLWE 字数（32-bit words） |
| `glwe_words` | 8 | GLWE 字数 |
| `reserved` | 8 | 保留，用于 32 字节对齐 |

GPU 端按照结构读取后即可定位数据缓冲。

## 2. Doorbell 工作流
1. 主机发送 `ADMIN_WOP_CONTROL`，固件写 `WOP_CTRL_*` 寄存器并 Doorbell。
2. DaisyPlus wrapper 将描述符地址传递给 GPU，并通过 AXI4-Stream doorbell 输出 token（`cmd_id|mode`）。
3. GPU 侧监听 doorbell FIFO：
   - 读取描述符，执行对应 WoP 算法（或 stub）。
   - 将结果写回 `glwe_dst_addr` / `gpu_shared_addr`。
   - 在共享结果结构 (`wop_result_t`) 中填入 `status`（如复制 CTRL_STATUS）、`latency_cycles`、`error_code`。
   - 触发完成中断（例如写回 `WOP_CTRL_INT_STATUS` 或通过 PCIe MSI-X）。

## 3. 共享结果结构
`wop_result_t` 位于 `gpu_shared_addr` 的首地址，由 GPU 在完成后填充：

| 字段 | 描述 |
| --- | --- |
| `status` | GPU 观察的 CTRL_STATUS 快照或自定义状态 |
| `latency_cycles` | GPU 计算周期数（可选） |
| `cmd_id` | 回显命令 ID |
| `error_code` | GPU 特定错误码（0 表示成功） |

SSD 在处理中断时读取该结构，若 `error_code != 0`，则将 `ADMIN` 完成状态置为 `SC_INTERNAL_DEVICE_ERROR` 并记录日志。

## 4. 日志建议
- 固件：在 `wop_command.c` 中打印 `[WOP] doorbell cmd_id=...`、错误日志；将完成状态写入 WoP 专用 GET LOG 页。
- GPU：记录收到的 `cmd_id/mode/flags`、执行耗时与错误码，必要时回传调试信息至共享缓冲。

## 5. 待办
- 定义 doorbell token 具体格式（bit31:doorbell、bit15:cmd_id、bit1:0 mode）。
- 与 GPU 团队确认 `gpu_shared_addr` 内数据布局，预留 NTT/KS 中间缓冲。 
- 互测 33×64 缩参：固件使用 stub GPU 内核返回固定模式，完成一次 WoP 流程验证。
