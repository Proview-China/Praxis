# 2026-04-09: 首批 Swift Package 骨架落地

## 做了什么

- 新增根目录 `Package.swift`
- 新增首批 SwiftPM target 目录：
  - `Sources/PraxisCoreTypes`
  - `Sources/PraxisGoal`
  - `Sources/PraxisState`
  - `Sources/PraxisTransition`
  - `Sources/PraxisRun`
  - `Sources/PraxisSession`
  - `Sources/PraxisJournal`
  - `Sources/PraxisCheckpoint`
  - `Sources/PraxisCapabilityContracts`
  - `Sources/PraxisCapabilityPlanning`
  - `Sources/PraxisCapabilityResults`
  - `Sources/PraxisCapabilityCatalog`
  - `Sources/PraxisTapTypes`
  - `Sources/PraxisTapGovernance`
  - `Sources/PraxisTapReview`
  - `Sources/PraxisTapProvision`
  - `Sources/PraxisTapRuntime`
  - `Sources/PraxisTapAvailability`
  - `Sources/PraxisCmpTypes`
  - `Sources/PraxisCmpSections`
  - `Sources/PraxisCmpProjection`
  - `Sources/PraxisCmpDelivery`
  - `Sources/PraxisCmpGitModel`
  - `Sources/PraxisCmpDbModel`
  - `Sources/PraxisCmpMqModel`
  - `Sources/PraxisCmpFiveAgent`
  - `Sources/PraxisProviderContracts`
  - `Sources/PraxisWorkspaceContracts`
  - `Sources/PraxisToolingContracts`
  - `Sources/PraxisInfraContracts`
  - `Sources/PraxisUserIOContracts`
  - `Sources/PraxisRuntimeComposition`
  - `Sources/PraxisRuntimeUseCases`
  - `Sources/PraxisRuntimeFacades`
  - `Sources/PraxisRuntimePresentationBridge`
  - `Sources/PraxisCLI`
  - `Sources/PraxisAppleUI`
- 每个 target 先放了最小可编译骨架，用来表达职责边界和 TS 对照来源。

## 为什么这样拆

- 目标不是把 TS 一级目录原样映射成 Swift 模块。
- 先把“纯核心子域”和“宿主装配层”拆开，后续迁移时才不会继续把 runtime / adapter / UI 缠在一起。
- 当前入口只保留：
  - `PraxisCLI` 作为未来 TUI/CLI 入口
  - `PraxisAppleUI` 作为 SwiftUI 宿主入口
- Host 层已经继续拆成五个 contracts target 和四个 runtime target，避免重新长成单体总装器。

## 当前约束

- 这一步只是骨架，不代表真实运行逻辑已经迁过去。
- provider SDK、Git/DB/MQ executor、workspace tooling 还没有进入 Swift 实现。
- 当前 Swift target 主要用于稳定后续迁移落点与依赖方向。

## 对后续工作的直接意义

- 后续从 TS 往 Swift 迁移时，已经有明确的 target 落点。
- 后续拆 `src/agent_core/runtime.ts` 时，可以优先把纯规则往 Core targets 搬，把装配逻辑拆进 `PraxisRuntimeComposition` / `PraxisRuntimeUseCases` / `PraxisRuntimeFacades` / `PraxisRuntimePresentationBridge`。
