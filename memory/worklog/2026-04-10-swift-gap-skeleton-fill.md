# 2026-04-10 Swift Gap Skeleton Fill

## 做了什么

- 根据旧 TypeScript 代码复核结果，补了一批 Swift skeleton 文件，只做最基础的类型和协议声明，不提前落具体实现。

## 这次补到的缺口

- Capability 执行面：
  - `PraxisCapabilityExecutionModels.swift`
  - `PraxisCapabilityExecutionProtocols.swift`
- TAP 治理细项：
  - `PraxisTapContextModels.swift`
  - `PraxisTapSafetyModels.swift`
  - `PraxisTapToolReviewModels.swift`
  - `PraxisTapRuntimeSupportModels.swift`
- CMP infra / runtime 相关模型：
  - `PraxisCmpGitRuntimeModels.swift`
  - `PraxisCmpDbBootstrapModels.swift`
  - `PraxisCmpMqBootstrapModels.swift`
- CMP five-agent live / observability：
  - `PraxisCmpFiveAgentLiveModels.swift`
  - `PraxisCmpFiveAgentObservabilityModels.swift`
- Host-facing surface / provider 补口：
  - `PraxisRuntimeSurfaceModels.swift`
  - `PraxisProviderWebSearchModels.swift`
  - `PraxisProviderWebSearchProtocols.swift`

## 当前结论

- 这轮补的是“名词层”和“协议层”，不是实现层。
- 目标是把旧 TS 里已经明确存在、但 Swift target 里还没落类型名字的组件先固定下来。
- 当前 Swift skeleton 现在已经能显式表达这些子域：
  - capability gateway / pool / port
  - context aperture / plain-language risk / safety interception
  - tool review governance session
  - CMP git/db/mq bootstrap
  - five-agent live llm / tap bridge / observability
  - runtime readback / smoke DTO
  - provider websearch

## 还没做的

- 没有补具体 service 实现。
- 没有补新的架构测试断言。
- 没有把这些类型接进 `RuntimeUseCases`、`PresentationBridge`、CLI 或 Apple UI 的实际流程。

## 验证

- `swift build`
- `swift test`

## 后续接入补充

- 已把一条最小占位链路接通：`RuntimeComposition -> RuntimeUseCases -> RuntimeFacades -> RuntimePresentationBridge -> CLI / AppleUI`。
- `PraxisInspectTapUseCase`、`PraxisInspectCmpUseCase`、`PraxisBuildCapabilityCatalogUseCase` 现在会返回结构化 placeholder 数据，而不是只停留在空壳 target。
- `PraxisRuntimeFacade` 补了 inspection / run 两组 facade，presentation bridge 可以把这些结果映射成 CLI 和 Apple UI 可直接消费的状态。
- `PraxisCLICommand` 现在能转换为统一的 `PraxisPresentationCommand`，Apple bridge 也补了 TAP / CMP inspection 入口。
- 这一轮为了通过 Swift 6 并发检查，明确了两条约束：
  - Apple presentation bridge 归 `@MainActor`，表示它是 UI 主线程入口。
  - facade 层是只读包装对象，声明为 `Sendable`，避免桥接层跨并发边界时触发数据竞争告警。

## 这轮新增验证

- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeSurfaceTests.swift` 新增集成向测试，覆盖：
  - dependency graph 组装
  - use case / facade 装配
  - CLI bridge 的 inspectArchitecture / inspectTap / inspectCmp 流程
  - capability catalog snapshot 输出
- `swift test` 通过，当前共 `16` 个测试。
