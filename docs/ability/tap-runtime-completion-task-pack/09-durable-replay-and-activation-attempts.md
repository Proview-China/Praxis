# 09 Durable Replay And Activation Attempts

## 任务目标

把 replay 与 activation attempt 都推进到可恢复状态。

## 必须完成

- `TaPendingReplay` durable 化
- 新增 `TaActivationAttemptRecord`
- replay state 与 suggested trigger 落入 snapshot
- activation start / success / failure / retry 信息落入 snapshot
- 恢复后可继续：
  - `pending_manual`
  - `pending_after_verify`
  - `pending_re_review`
  - `activating`

## 允许修改范围

- `src/agent_core/ta-pool-runtime/**`
- `src/agent_core/checkpoint/**`
- `src/agent_core/runtime.ts`

## 依赖前置

- `00`
- `01`
- `03`

## 不要做的事

- 不要把 replay 做成另一个主 agent loop
- 不要在这一任务里先做复杂 UI 或调度拓扑

## 验收标准

- replay 不再只活在内存 map 中
- activation 半途中断后可以知道该重试还是回滚
- 恢复后的 replay/handoff 语义和中断前一致
