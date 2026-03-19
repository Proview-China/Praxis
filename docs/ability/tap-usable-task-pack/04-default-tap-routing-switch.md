# 04 Default TAP Routing Switch

## 任务目标

把 `capability_call` 的默认主路径切到 `TAP`，让 reviewer 成为正式总闸门。

## 必须完成

- 调整 `dispatchIntent(...)`
- 调整 `runUntilTerminal()`
- 为 capability call 默认先走 `dispatchCapabilityIntentViaTaPool(...)`
- 保留显式 bypass 入口，仅供测试/调试
- 明确 `model_inference` 仍可暂时走现有路径

## 允许修改范围

- `src/agent_core/runtime.ts`
- `src/agent_core/runtime.test.ts`
- 必要时少量改 transition 相关测试

## 不要做

- 不要同时接 reviewer worker bridge
- 不要同时接 provision activation

## 验收标准

- 默认 capability_call 不再绕过 TAP
- 旧路径仍可用于显式 bypass 测试
- end-to-end 测试能证明默认路由已切换
