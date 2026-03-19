# 2026-03-19 TAP Runtime Wave 0 And Activation Integration

## 当前阶段结论

`TAP` 第三阶段的第一波编码已经真实落地，不再只是任务包和蓝图。

当前已完成：

- `00` 协议冻结
- activation contracts
- activation factory resolver
- activation materializer
- activation driver
- runtime activation integration
- `TMA planner` helper
- `TMA executor` helper
- checkpoint `pool-runtime-checkpoint` helper
- `runtime-snapshot` / `runtime-recovery` helper

## 当前 runtime 新能力

`AgentCoreRuntime` 当前新增：

- `registerTaActivationFactory(...)`
- `activateTaProvisionAsset(...)`
- `createTapRuntimeSnapshot()`
- `createPoolRuntimeSnapshots()`
- activation attempt 索引读取

## 当前验证基线

- `npm run typecheck` 通过
- `npx tsx --test src/agent_core/**/*.test.ts` 通过
- 当前 `agent_core` 定向测试：`182 pass / 0 fail`

## 当前还没完成的事

- durable checkpoint 写入点还没有正式接进 human gate / replay / activation 主链
- `TMA executor` 还只是 helper contract，不是真正接进 provisioner runtime
- human gate / replay 的恢复还没接到 runtime 主链恢复入口
