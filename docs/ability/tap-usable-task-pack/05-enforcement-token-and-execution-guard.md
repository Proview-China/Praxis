# 05 Enforcement Token And Execution Guard

## 任务目标

把 reviewer 的审批结果真正接到 execution plane 的门禁上。

## 必须完成

- 新增 `DecisionToken`
- execution plane 在 prepare/dispatch 前校验 token 与 grant
- 强制检查：
  - requestId
  - capabilityKey
  - tier
  - scope
  - mode
  - expiry
  - constraints
- 不合法 token/grant 直接拒绝执行

## 允许修改范围

- `src/agent_core/ta-pool-runtime/**`
- `src/agent_core/capability-gateway/**`
- `src/agent_core/capability-pool/**`
- `src/agent_core/runtime.ts`

## 验收标准

- 正常 token 可执行
- mismatch token 被拒绝
- 负向测试补齐
