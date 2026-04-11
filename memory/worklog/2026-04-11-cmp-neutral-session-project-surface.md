# 2026-04-11 CMP Neutral Session And Project Surface

## 做了什么

- 在 `PraxisRuntimeUseCases` 新增了第一批 CMP 宿主无关应用层 command / result：
  - `PraxisOpenCmpSessionCommand`
  - `PraxisReadbackCmpProjectCommand`
  - `PraxisSmokeCmpProjectCommand`
  - `PraxisCmpSession`
  - `PraxisCmpProjectReadback`
  - `PraxisCmpProjectSmoke`
- 在 `PraxisRuntimeFacades` 新增 `PraxisCmpFacade`，作为当前第一批 CMP neutral facade：
  - `openSession(...)`
  - `readbackProject(...)`
  - `smokeProject(...)`
- 在 `PraxisRuntimeInterface` 新增对应 neutral request：
  - `openCmpSession`
  - `readbackCmpProject`
  - `smokeCmpProject`

## 当前边界

- 这轮只补了 `session + project readback/smoke`。
- 还没有把下面这些表面也一并做进去：
  - `flow`
  - `roles`
  - `history`
  - `project bootstrap`
- CLI 没有新增这些命令；它继续保持薄壳，不反向决定 runtime contract。
- `PraxisRuntimeInterface` 当前为这些新命令返回的是 neutral snapshot/event，而不是 CLI-specific 文本结构。

## 实现方式

- `PraxisInspectCmpUseCase` 当前不再独占 CMP local-runtime 读模型逻辑。
- `PraxisRuntimeUseCases` 内新增了共享 readback builder，用同一份 host-backed local runtime truth 组装：
  - workspace 状态
  - sqlite persistence
  - delivery truth
  - message bus
  - git probe / git executor
  - lineage store
  - semantic memory/search/embedding presence
- `openCmpSession(...)` 当前先返回 host-neutral session descriptor，不强行引入新的 CLI/GUI 会话状态机。

## 新增验证

- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeSurfaceTests.swift`
  - 新增 `cmpFacadeExposesNeutralSessionReadbackAndSmokeSnapshots`
- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeInterfaceTests.swift`
  - 新增 `runtimeInterfaceRoutesCmpSessionAndProjectRequests`
  - 新增 `runtimeInterfaceCodecEncodesCmpProjectRequestsAsNestedPayloads`

## 当前验证

- `swift test` 通过
- 当前测试快照更新为：
  - `131` tests
  - `39` suites

## 下一步建议

- 继续沿同一路径补：
  - `bootstrapCmpProject`
  - `flow.ingest / commit / resolve / materialize / dispatch`
  - `roles.resolveCapabilityAccess / dispatchCapability / approvePeerExchange`
- 仍然保持顺序：
  - 先 `UseCases`
  - 再 `Facades`
  - 再 `RuntimeInterface`
  - 最后按需给 CLI / Apple UI 增加薄路由
