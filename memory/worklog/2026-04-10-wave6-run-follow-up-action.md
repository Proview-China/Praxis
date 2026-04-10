# 2026-04-10 Wave6 Run Follow-Up Action

## 做了什么

- 继续推进 `Wave 6 / HostRuntime` 的 run 表面，把 `runGoal / resumeRun` 从“只返回 run 状态摘要”推进到“同时返回下一步动作提示”。
- `PraxisRuntimeUseCases` 新增了 `PraxisRunFollowUpAction`，当前会稳定透出：
  - action kind
  - action reason
  - intent id
  - intent kind

## 当前接通的运行语义

- `runGoal`
  - 直接复用 `PraxisRunLifecycleService.advance(...)` 产生的 `nextAction`
  - 当前最小样本会返回 `model_inference`
- `resumeRun`
  - 因为当前恢复路径采用的是“恢复投影”而不是普通 transition hot path
  - 所以 HostRuntime 在 use case 层显式补出了 recovery follow-up action
  - 当前最小样本会返回 `internal_step`

## 为什么这一步重要

- 这让 HostRuntime facade 不再只是“对 run phase 做文字转述”，而开始承接最小 orchestration surface。
- Presentation bridge 现在也可以把“当前 run 之后该做什么”带给 CLI / Apple UI，而不需要入口层自己猜。
- 同时这一步仍然没有把 executor/planner 重新塞回 runtime；它只是暴露已经存在的 Core 决策结果。

## 新增验证

- 更新 `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeSurfaceTests.swift`
- 新增断言：
  - facade 层 `runGoal` 会透出 `model_inference`
  - facade 层 `resumeRun` 会透出 `internal_step`
  - bridge 映射后的 `PraxisPresentationState.summary` 会包含 `Next action ...`

## 当前结论

- Wave6 的 run facade / bridge 已经开始提供“状态 + 下一步动作”的稳定宿主表面。
- 下一步可以继续考虑把 paused/failed 恢复分支、resume 后的 pending intent / event stream，或者更真实的 entry 交互面接上。
