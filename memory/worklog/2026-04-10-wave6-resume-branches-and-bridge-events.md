# 2026-04-10 Wave6 Resume Branches And Bridge Events

## 做了什么

- 继续推进 `Wave 6 / HostRuntime`，把上一轮的最小 `runGoal / resumeRun` 收口再往前推两步：
  - 补齐 `paused / failed` checkpoint 恢复样本
  - 给 presentation bridge 暴露最小可消费的 `pending intent + event stream` 接口

## 这轮补齐的恢复分支

- `resumeRun` 现在不只是对“刚创建后被恢复”的样本有效。
- HostRuntime 测试已覆盖：
  - 从 `paused` checkpoint 恢复
  - 从 `failed` checkpoint 恢复
  - 从 `failed` checkpoint 恢复时保留 replay evidence 计数
- 当前恢复语义仍保持在 Wave6 的安全边界内：
  - 使用 checkpoint snapshot + journal replay evidence
  - 输出恢复后的 run receipt
  - 不提前把完整 executor / kernel loop 重新塞回 runtime use case

## 这轮补齐的 bridge 接口

- `PraxisPresentationState` 现在开始暴露：
  - `pendingIntentID`
  - `events`
- `PraxisPresentationEvent` 现在开始暴露：
  - `runID`
  - `sessionID`
  - `intentID`
- `PraxisPresentationEventStream` 现在支持：
  - `append(contentsOf:)`
  - `snapshot()`
  - `drain()`
- `PraxisCLICommandBridge` 和 `PraxisApplePresentationBridge` 现在都会在 run-related bridge 调用中把生成的 presentation events 写进 event stream。

## 当前 bridge 语义

- `runGoal`
  - 会生成 `run.started`
  - 如果已有下一步动作，还会生成 `run.follow_up_ready`
- `resumeRun`
  - 会生成 `run.resumed`
  - 如果已有下一步动作，还会生成 `run.follow_up_ready`
- `pendingIntentID` 当前直接承接 `followUpAction.intentID`，让后续 Wave7 入口层可以先消费“下一步 intent”而不必等完整 interactive runtime。

## 新增验证

- 更新 `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeSurfaceTests.swift`
- 新增验证内容：
  - bridge 输出的 run state 包含 `pendingIntentID`
  - bridge 能回读 `run.started / run.resumed / run.follow_up_ready`
  - `paused` checkpoint 能恢复并产出 event stream
  - `failed` checkpoint 能恢复并保留 replay evidence 计数

## 当前结论

- Wave6 现在已经不只是“能装起来、能 inspect、能恢复一个 run”。
- 它已经开始具备最小可消费的运行桥接面，后续 Wave7 的 CLI / Apple UI 可以直接接这些稳定接口，而不必再从 facade summary 里硬解析信息。
