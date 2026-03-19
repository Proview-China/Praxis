# 00 Runtime Completion Protocol Freeze

## 任务目标

冻结这轮补全所需的共享协议，避免 activation、TMA、durable recovery 三条线互相打架。

## 必须完成

- 冻结 `ActivationReceipt / ActivationFailure / ActivationAttemptRecord`
- 冻结 `TmaBuildPlan / TmaExecutionReport / VerificationEvidence`
- 冻结 `PoolRuntimeSnapshots.tap.*` 最小形状
- 明确 `ready_for_review / activating / active / failed / superseded` 的状态语义
- 明确 replay policy 与 activation 之间的责任边界

## 允许修改范围

- `src/agent_core/ta-pool-types/**`
- `src/agent_core/ta-pool-runtime/**`
- 必要时少量改 `src/agent_core/checkpoint/**`

## 不要做的事

- 不要在这一任务里直接写 activation runtime 逻辑
- 不要在这一任务里直接做 builder 执行器
- 不要提前抽 shared framework

## 验收标准

- 三条线用的是同一套术语和状态枚举
- 后续任务不需要再争论“activation receipt 长什么样”
- 后续任务不需要再争论“durable snapshot 最小字段是什么”
