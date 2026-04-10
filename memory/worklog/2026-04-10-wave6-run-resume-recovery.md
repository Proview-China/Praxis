# 2026-04-10 Wave6 Run Resume Recovery

## 做了什么

- 继续推进 `Wave 6 / HostRuntime` 的运行链路，把 `runGoal / resumeRun` 从只返回占位 `runID`，推进到最小可恢复的 run/session/journal/checkpoint 应用用例。
- `PraxisRunGoalUseCase` 现在会：
  - 生成稳定的 `sessionID / runID`
  - 创建并挂接 `PraxisSessionHeader`
  - 写入 `run.created` journal event
  - 持久化包含 `PraxisRunAggregate + PraxisSessionHeader` 的 checkpoint payload
- `PraxisResumeRunUseCase` 现在会：
  - 从 checkpoint store 读取已保存的 run/session 快照
  - 通过 journal recovery service 计算恢复后 replay cursor 和 replayed event count
  - 写入 `run.resumed` journal event
  - 保存更新后的 checkpoint

## 这轮明确下来的恢复语义

- `resume` 在当前 Wave6 阶段不再强行走一次普通 runtime transition hot path。
- 原因是 checkpoint 恢复出的 run 很可能已经处在 `acting` 等活跃状态，而 `run.resumed` 只允许从 `paused / waiting / failed` 进入 transition evaluator。
- 因此当前实现改成“恢复投影”：
  - 保留 `run.resumed` 事件作为 journal / checkpoint 事实
  - 用 `applyEventToState` 直接把恢复事件投影到 state
  - 再从投影后的 state 重建 `PraxisRunAggregate`
- 这让 HostRuntime 在 phase-1 先拿到稳定、可测的 checkpoint 恢复语义，而不需要提前引入完整 kernel recovery loop。

## 顺手修正的测试底座问题

- `PraxisFakeJournalStore` 之前直接信任传入 event 的 `sequence`，导致 HostRuntime 里自己构造的 journal event 一直返回 cursor `0`。
- 这轮把 fake store 改成 append 时自己分配递增 sequence，行为更接近 append-only journal 的真实契约。
- 修正后 `runGoal` 首次写入 journal cursor 为 `1`，`resumeRun` 再追加后为 `2`。

## 新增验证

- 更新 `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeSurfaceTests.swift`
- 新增 `runFacadePersistsCheckpointedLifecycleForResume()`
- 验证内容包括：
  - `runGoal` 会返回稳定 `runID / sessionID`
  - `runGoal` 会写入 checkpoint reference 与第一条 journal cursor
  - `resumeRun` 会基于 checkpoint 恢复，并追加第二条 journal cursor
  - `resumeRun` 当前返回 `queued` phase，对应恢复投影后的 `deciding/recovery` 状态

## 当前结论

- Wave6 的 HostRuntime 已经具备最小可恢复运行链路，不再只是“能生成一个 run id”。
- 下一步可以继续把 checkpoint payload 和 replay evidence 接进更完整的 runtime orchestration，例如 paused/failed 恢复路径、resume 后的下一步 action 恢复，以及更真实的 host executor 协调。
