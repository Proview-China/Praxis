# 2026-04-10 Wave6 Host-Backed Inspection

## 做了什么

- 继续推进 `Wave 6 / HostRuntime`，把 `PraxisRuntimeUseCases` 从静态 inspection 文案推进到“真实消费 HostContracts doubles 的 host-facing read model”。
- 当前 `inspectTap / inspectCmp / inspectMp / buildCapabilityCatalog` 已开始读取 `PraxisDependencyGraph.hostAdapters`。

## 本轮接通的宿主读取面

- `inspectTap`
  - 读取已注册的 host capability surfaces
  - 读取 checkpoint store / journal store 的 inspection 状态
  - 把 checkpoint availability 与 replay evidence 写回 TAP inspection summary
- `inspectCmp`
  - 读取 git readiness probe
  - 读取 projection store / delivery truth store
  - 读取 semantic search / semantic memory / embedding store 的装配完整度
  - 把 projection count、delivery truth count、git status 写回 CMP host summary
- `inspectMp`
  - 读取 semantic memory bundle
  - 读取 semantic search match count
  - 读取 audio / speech / image / browser grounding adapter presence
  - 把 memory bundle 与 multimodal chip 状态写回 MP inspection
- `buildCapabilityCatalog`
  - 现在会把已注册的 host capability surfaces 一并纳入 summary，而不只列 boundary 名字

## 这轮明确的边界

- 宿主状态读取继续放在 `PraxisRuntimeUseCases`，由 use case 整理成应用层 inspection 结果。
- `PraxisRuntimeFacades` 继续只负责压平 DTO，不承担 host adapter 查询逻辑。
- `PraxisRuntimePresentationBridge` 继续只负责状态映射，不承担 inspection read model 组装逻辑。

## 新增验证

- 更新 `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeSurfaceTests.swift`
- 断言从“桥能通”升级为“桥输出中包含来自 host adapters 的 inspection 状态”
- `swift test` 通过，当前仍为 `89` 个测试全绿

## 当前结论

- Wave6 现在已经不只是“装配链能通”，而是开始具备最小的 host-backed inspection 行为。
- 下一步可以继续把 `runGoal / resumeRun` 从 placeholder run id 生成推进到真正消费 Core run/session/journal/checkpoint 的应用用例。
