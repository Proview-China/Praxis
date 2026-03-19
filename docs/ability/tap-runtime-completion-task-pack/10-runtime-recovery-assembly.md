# 10 Runtime Recovery Assembly

## 任务目标

把 durable human gate / replay / activation attempts 真正组装回 runtime 恢复链。

## 必须完成

- runtime 启动时装载 pool runtime snapshot
- 提供恢复后的 list/get API
- 恢复后 human gate / replay / activation attempt 能进入下一步链路
- 保持与现有 checkpoint 恢复接口兼容

## 允许修改范围

- `src/agent_core/runtime.ts`
- `src/agent_core/checkpoint/**`
- `src/agent_core/ta-pool-runtime/**`

## 依赖前置

- `03`
- `08`
- `09`

## 不要做的事

- 不要重写整个 run recovery 体系
- 不要把 TAP recovery 写死成未来别的 pool 无法接入

## 验收标准

- checkpoint 恢复后，runtime 能看见等待中的 gate/replay/activation
- 恢复后的 runtime 行为与冷启动一致
- 不需要人工重新补录中断前的控制面状态
