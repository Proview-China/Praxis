# 03 Durable Pool Runtime Snapshot

## 任务目标

冻结 `checkpoint-first` 的 pool runtime snapshot 形状，为 human gate / replay / activation recovery 打底。

## 必须完成

- 为 checkpoint snapshot 增加 `poolRuntimeSnapshots`
- 第一版挂载 `tap`
- `tap` 下最少包含：
  - `humanGates`
  - `humanGateEvents`
  - `pendingReplays`
  - `activationAttempts`
- 定义恢复时如何把 snapshot 装回 runtime 内存索引

## 允许修改范围

- `src/agent_core/checkpoint/**`
- `src/agent_core/ta-pool-runtime/**`
- 必要时少量改 `src/agent_core/types/**`

## 不要做的事

- 不要现在就重构 `KernelEventType`
- 不要把别的 pool 的语义硬塞进来

## 验收标准

- snapshot 结构可序列化、可恢复
- 未来 `mp/cmp` 可以继续挂第二个 pool snapshot
- 不需要进程常驻内存才能知道 gate/replay 卡在哪
