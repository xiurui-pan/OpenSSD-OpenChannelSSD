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

## 3. 加载流程（现状）
1. NVMe Vendor 命令进入 `handle_wop_vendor_cmd()` 时，会先调用 `wop_stage_assets_from_nand(cmd_id)` 完成资产搬运，随后才 Doorbell WoP Wrapper。`cmd_id` 的低 4 位用于索引描述符环槽（`slot = cmd_id & WOP_DESC_RING_SLOT_MASK`），并在提交前通过 `wop_desc_try_acquire()` 检查槽是否空闲；调度完成后等待上层调用 `wop_desc_release()` 清理 busy 标志。
2. `wop_stage_assets_from_nand()` 根据 `wop_descriptor_t` 的 `mode/tlwe_words/glwe_words` 选出需要的 bank，并为 TLWE/GPU 区分别准备目标地址；描述符环前 64B 作为 `wop_desc_ring_ctrl_t` 元数据区（head/tail/pending/slot mask），供 GPU 轮询可用槽位。
3. `wop_stage_assets_from_nand()` 现改为窗口化加载：每页调用 `wop_enqueue_page()` 将请求放入最多 4 个并行槽位，再由 `wop_poll_pending()` 轮询 `CheckDoneNvmeDmaReq()` / `SchedulingNandReq()`，待完成后校验 `statusReportTable`、`eccErrorInfoTable` 并将数据 memcpy 至 descriptor 指定的 DRAM 地址；GPU stub 会在处理完写回 `wop_result_t` 同时递增环控制区 `release_count`，供 PS 侧统计。
4. Scratch buffer 改为按槽位切分，支持最多 `WOP_STAGE_MAX_OUTSTANDING=4` 个未完成请求；每个槽位自带超时计数（原 `WOP_STAGE_WAIT_LIMIT`），发现状态失败 / ECC 错误 / 超时即返回 `-EIO/-ETIMEDOUT` 并打印日志，触发 NVMe 层回滚。

## 4. 近期任务
- 描述符 ring 多 slot：固件已实现队列化 doorbell，下一步在 DRAM 侧补充 head/tail/busy 字段并与 GPU 回写协议对齐。
- 完成回收路径：PS 已在 `wop_service()` 监测 DONE/ERROR 并调用 `wop_desc_release(cmd_id)`；下一步需约定 GPU 写回结果、置位 DONE/ERROR 的时序，确保槽位复用与状态上报一致。
- 批量预取：已实现 `WOP_STAGE_MAX_OUTSTANDING=4` 的窗口化挂起；后续可依据剩余请求池容量调整上限，并按 QoS 规则为不同资产配置配额。
- 与主机 IO 协调：根据 `notCompletedNandReqCnt`/NVMe 队列水位调节窗口大小，避免 WoP 请求长时间占满 NAND 通道。
- 资产增量更新：规划 PROGRAM/ERASE 流程及镜像冗余表，支撑密钥刷新与容错。

## 5. 目前实现
- `wop_storage.c` 通过 FTL 请求池排队读取 NAND，使用 `REQ_OPT_DATA_BUF_ADDR` 将数据写入本地 scratch buffer，调度完成后再 memcpy 到 `tlwe_src_addr` / `gpu_shared_addr`。
- 读取完成后会检查 `statusReportTable` 与 `eccErrorInfoTable`，若检测到失败或超时，直接返回 `-EIO/-ETIMEDOUT` 并打印日志。
- `wop_stage_assets_from_nand()` 现在直接依赖窗口化轮询而非 `SyncAllLowLevelReqDone()` 全局清空；资产块仍由 `wop_reserve_asset_blocks()` 在初始化时标记为 `BAD`，描述符地址通过 `WOP_DESC_SLOT_ADDR(WOP_DESC_RING_BASE_ADDR, slot)` 计算，与 GPU stub / Wrapper 使用的地址保持一致。
- 读取逻辑采用 4 槽窗口化并行，不再在阶段前调用 `SyncAllLowLevelReqDone()`；后续可依据系统负载自适应调节窗口大小并与主机 IO QoS 协调。

## 6. FTL 与 NAND 组织分析
- CosmosPlus FTL 依靠 `reqPool` + `nandReqQ[ch][way]` 调度 NAND 指令，WoP 读取现已复用这套路径，可沿用 `dieStateTable`、`rowAddrDependency` 与 ECC/重试逻辑。
- 资产布局维持在 `channel=3 / way=1`：
  | 资产 | 通道 | Way | 起始块 | 块数 |
  | --- | --- | --- | --- | --- |
  | LUT | 3 | 1 | 16 | 16 |
  | BSK | 3 | 1 | 32 | 64 |
  | KSK | 3 | 1 | 96 | 64 |
  这些块位于 die 尾部，通过 `wop_reserve_asset_blocks()` 在初始化阶段写为 `BLOCK_STATE_BAD`，避免被自由块池复用。
- 请求遍历顺序遵循 “bank → block → page”，对应 `GenerateNandRowAddr()` 的寻址形式；后续若需要多通道条带，只需扩展 `kAssetLayouts` 表即可。
- 与主机 IO 并存时要注意：窗口化调度仍需依赖 `CheckDoneNvmeDmaReq()`/`SchedulingNandReq()` 前进，建议结合 `notCompletedNandReqCnt` 与 NVMe 队列深度设定水位，避免 WoP 请求长期占满调度表。

## 7. 资产窗口与寄存器编程（2025-10-08）
- `wop_stage_assets_from_nand()` 现为每个 slot 维护 `wop_asset_window_t`：记录 TLWE/GLWE 目标地址与字数，并根据 `tlwe_layout/gpu_layout` 推导出 BSK/KSK 在 DRAM 中的缓存位置。
- Doorbell 前 GR3FTL 会调用 `wop_program_asset_registers()` 写入 wrapper 寄存器：
  | 寄存器 | 填充值 | 备注 |
  | --- | --- | --- |
  | `BSK_BASE_{LO,HI}` | `window->bsk_base`；若为空则回退至 `tlwe_base` | 地址按 64B 对齐截断 |
  | `BSK_STRIDE` | `max(window->bsk_words, window->tlwe_words) * 4`（最小 64B） | 防止 stride=0 触发 `cfg_param_error` |
  | `KSK_BASE_{LO,HI}` | `window->ksk_base`；CB 模式缺省时回退至 `bsk_base` | |
  | `KSK_STRIDE` | `max(window->ksk_words, window->glwe_words) * 4`（最小 64B） | |
  | `GLWE_BASE_{LO,HI}` | `window->glwe_base`；若未配置则使用 `tlwe_base` | |
  | `GLWE_STRIDE` | `max(window->glwe_words, window->tlwe_words) * 4`（最小 64B） | |
- GPU stub `wop_gpu_runtime` 在处理 descriptor 前会检查 `tlwe_src_addr/glwe_dst_addr/gpu_shared_addr` 是否满足 32B 对齐，若不满足则回写 `WOP_STATUS_ERROR_MASK` 并使用 `SC_INVALID_FIELD_IN_COMMAND` 告警，有助于快速定位固件配置错误。
- 后续需要结合实际 BSK/KSK 批次规模优化回退策略（目前回退至 TLWE/GLWE 缓冲），并在 GPU 实核对接后替换 memcpy stub。
