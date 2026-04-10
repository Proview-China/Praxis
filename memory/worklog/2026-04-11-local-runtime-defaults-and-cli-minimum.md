# 2026-04-11 Local Runtime Defaults And CLI Minimum

## 做了什么

- 在 `PraxisRuntimeComposition` 新增了本地默认 host adapter 组装：
  - `PraxisHostAdapterRegistry.localDefaults(rootDirectory:)`
- 默认 profile 不再只依赖 `scaffoldDefaults()`。
- 第一批真实本地 adapter 已落下：
  - `PraxisLocalCheckpointStore`
  - `PraxisLocalJournalStore`
  - `PraxisLocalProjectionStore`
  - `PraxisLocalDeliveryTruthStore`
  - `PraxisLocalEmbeddingStore`
  - `PraxisLocalSemanticMemoryStore`
  - `PraxisLocalSemanticSearchIndex`
  - `PraxisLocalMessageBus`
  - `PraxisSystemShellExecutor`
  - `PraxisSystemGitAvailabilityProbe`

## 当前策略

- infra / git / shell 改成真实 local runtime 默认实现
- provider / browser / user-io 这批暂时仍复用 scaffold surface
- 这轮补的 CLI 只视为最小 debug / smoke adapter，不视为当前产品主路径
- 后续如果 UI / shell 有其它语言代码进入，默认优先衔接 `RuntimeInterface / PraxisFFI`

一句白话：

- 这轮不是一次把所有宿主都做真
- 而是先把最关键的本地运行底座做真

## 默认装配切换

- `PraxisRuntimeCompositionRoot` 的默认 `hostAdapters` 已从 `.scaffoldDefaults()` 切到 `.localDefaults()`
- `PraxisHostAdapterFactory` 新增：
  - `makeLocalAdapters(rootDirectory:)`
- `PraxisRuntimeBridgeFactory` 的默认共享 host adapters 已从 scaffold profile 切到 local profile

这意味着：

- 无参 `makeRuntimeFacade()`
- 无参 `makeCLICommandBridge()`
- 无参 `makeRuntimeInterface()`
- 无参 `makeFFIBridge()`

现在默认都会吃本地 profile，而不是纯 fake store。

## CLI 最小可用面

- `PraxisCLI` 不再只打印 blueprint scaffold
- 已新增最小命令解析与文本渲染：
  - `inspect-architecture`
  - `inspect-tap`
  - `inspect-cmp`
  - `inspect-mp`
  - `run-goal <summary>`
  - `resume-run <run-id>`
  - `events [--drain]`
  - `help`

当前边界仍然保持：

- CLI runtime request 默认先走 `PraxisRuntimeInterface`
- `PraxisRuntimePresentationBridge` 不再作为 CLI 的直接主 contract
- 不直接下钻到 Core / HostContracts
- 不提前复制旧 TS `live-agent-chat`

## 测试补齐

- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeSurfaceTests.swift`
  - 新增 local defaults 跨 registry 的 checkpoint/journal persistence 验证
  - 默认 bridge factory 测试已改成 shared local adapters 语义
- 新增 `Tests/PraxisCLITests/PraxisCLITests.swift`
  - 验证最小 inspection 命令
  - 验证 run-goal -> events --drain 流程
  - 验证 help / 参数校验
  - 验证 CLI 可只依赖 portal-agnostic runtime interface session 工作
- `Package.swift` 新增 `PraxisCLITests` test target

## 当前验证

- `swift test` 通过
- 当前测试数提升到：
  - `120` tests
  - `39` suites

## 当前仍然刻意没做的

- 还没有把 provider live execution 换成真正本地默认实现
- 还没有把 workspace read/search/write 换成真正本地默认实现
- 还没有做完整 SQLite schema 或正式 `PraxisFFI`
- `PraxisAppleUI` 仍保持在壳层阶段

## 下一步建议

- 继续把 local runtime profile 往“真实 SQLite-backed schema + local semantic index + workspace adapters”推进
- 优先稳住中立导出边界，不急着把 CLI / GUI 做厚
