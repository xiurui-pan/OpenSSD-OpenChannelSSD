# DaisyPlus WoP NAND 存储规划 (草案，2025-10-05)

## 1. 目标
- 在 NAND Flash 中长期保存 LUT、BSK、KSK 等大容量数据。
- 通过 GR3FTL -> WoP Wrapper -> GPU 链路将这些数据搬运至 DRAM/GPU。

## 2. 建议布局
| 资源 | 起始块 (相对) | 块数 | 备注 |
| --- | --- | --- | --- |
| LUT  | `WOP_NAND_REGION_BASE_BLOCK + 0` | 16  | 预存 LUT 表，约 16MB |
| BSK  | `WOP_NAND_REGION_BASE_BLOCK + 16` | 64 | 每块 256KB，覆盖多组 BSK |
| KSK  | `WOP_NAND_REGION_BASE_BLOCK + 80` | 64 | 预留足够的 KSK 批次 |

> `WOP_NAND_REGION_BASE_BLOCK` 当前定义 `0x3C00`，位于高地址区，待 FTL 评估后调整。

## 3. 加载流程 (待实现)
1. `wop_stage_assets_from_nand(cmd_id)` 根据命令/模式选择需要的 LUT/BSK/KSK。
2. 通过现有 NAND controller (T4NFC) 读取对应块，写入 `wop_descriptor_t` 中的 `tlwe_src_addr/glwe_dst_addr`。
3. 完成后设置共享结果结构中 `status` 的相应位，若失败则返回错误码。

## 4. 近期任务
- FTL 分配块：在 `data_buffer.c` / `garbage_collection.c` 中预留 WoP 专用块，禁止映射到主机地址空间。
- 实现 DMA 拷贝：封装 T4NFC -> DRAM 传输 API，并在 `wop_storage.c` 中调用。
- 描述符扩展：如需支持多批次/分段加载，考虑新增 `flags` 位用于选择 LUT/BSK/KSK 子集。

## 5. 目前实现
- `wop_storage.c` 提供 stub，记录 `[WOP] stage_assets_from_nand` 日志，后续将替换为真实代码。
- `wop_command.c` 在 Doorbell 前调用该 stub，如返回非 0 即报错退出。

