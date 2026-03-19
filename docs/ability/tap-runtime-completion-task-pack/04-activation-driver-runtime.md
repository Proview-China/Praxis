# 04 Activation Driver Runtime

## 任务目标

把 activation driver 真正接进 runtime，让 `ready bundle` 能自动注册回 `CapabilityPool`。

## 必须完成

- 新增 activation driver runtime 模块
- 把 `ready_for_review -> activating -> active/failed` 接成真链
- 支持 `register / replace / register_or_replace`
- 产出 activation receipt
- 失败时写 activation failure / rollback 信息

## 允许修改范围

- `src/agent_core/ta-pool-runtime/**`
- `src/agent_core/runtime.ts`
- 必要时少量改 `src/agent_core/capability-pool/**`

## 依赖前置

- `00`
- `01`
- `05`

## 不要做的事

- 不要让 activation driver 直接改 reviewer 决策
- 不要把 activation 放进 worker bridge 里执行

## 验收标准

- 不再需要测试里手工 `registerCapabilityAdapter(...)` 才能模拟激活
- asset 状态能真实反映 activating/active/failed
- runtime 可以读到 activation receipt
