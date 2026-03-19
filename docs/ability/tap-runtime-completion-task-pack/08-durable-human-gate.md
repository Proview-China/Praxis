# 08 Durable Human Gate

## 任务目标

把现有 human gate 从 runtime 内存态推进到可恢复状态。

## 必须完成

- `TaHumanGateState` durable 化
- `TaHumanGateEvent[]` durable 化
- gate open / approve / reject 时写入 snapshot
- runtime 恢复时重建 human gate 索引
- 保持 `waiting_human` 不入侵 `core-agent loop`

## 允许修改范围

- `src/agent_core/ta-pool-runtime/**`
- `src/agent_core/checkpoint/**`
- `src/agent_core/runtime.ts`

## 依赖前置

- `00`
- `03`

## 不要做的事

- 不要在这里做产品级 UI
- 不要让 human gate 状态散落到别的模块各自存一份

## 验收标准

- gate 状态可从 durable snapshot 恢复
- 恢复后仍能继续 approve / reject
- 重启后不会丢掉等待中的人工审批
