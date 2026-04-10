# Swift Refactor Boundaries

## 当前稳定结论

- 当前仓库的真实核心主要在 `src/agent_core/`，不是 `src/rax/`。
- `src/rax/` 更接近统一 facade、provider 兼容层和能力接缝层。
- 当前仓库没有成熟独立的 TUI 子系统；界面层实质上是 `src/agent_core/live-agent-chat.ts` 这套 CLI harness。
- `src/agent_core/runtime.ts` 是当前最重的总编排器，后续重构不应原样迁移。
- Swift 重构的正式分层已经冻结为：
  - `PraxisCore`
  - `PraxisHostContracts`
  - `PraxisHostRuntime`
  - `PraxisCLI / PraxisAppleUI / PraxisFFI`
- `PraxisCore` 只代表逻辑层，不代表具体模块名或产品名。
- 当前产品策略上，`PraxisCLI / PraxisAppleUI` 都不作为近期必须优先做厚的实现面。
- 如果后续 UI / shell 有其它语言代码进入，默认优先通过：
  - `PraxisRuntimeInterface`
  - `PraxisFFIBridge`
  - 后续正式 `PraxisFFI`
  接入系统。

## 对 Swift 重构的约束

- Swift Core 只承接纯领域模型、状态机、规则与编排协议。
- Git / Postgres / Redis / provider SDK / CLI 输入输出都应作为宿主适配器存在。
- Apple 端 UI 可以使用 SwiftUI，但跨平台复用必须建立在可导出的 Core ABI/API 上，而不是建立在 SwiftUI 上。
- `live-agent-chat` 只作为行为参考，不作为未来 UI 代码结构模板。

## 首批 SwiftPM target 骨架

- Core targets:
  - `PraxisCoreTypes`
  - `PraxisGoal`
  - `PraxisState`
  - `PraxisTransition`
  - `PraxisRun`
  - `PraxisSession`
  - `PraxisJournal`
  - `PraxisCheckpoint`
  - `PraxisCapabilityContracts`
  - `PraxisCapabilityPlanning`
  - `PraxisCapabilityResults`
  - `PraxisCapabilityCatalog`
  - `PraxisTapTypes`
  - `PraxisTapGovernance`
  - `PraxisTapReview`
  - `PraxisTapProvision`
  - `PraxisTapRuntime`
  - `PraxisTapAvailability`
  - `PraxisCmpTypes`
  - `PraxisCmpSections`
  - `PraxisCmpProjection`
  - `PraxisCmpDelivery`
  - `PraxisCmpGitModel`
  - `PraxisCmpDbModel`
  - `PraxisCmpMqModel`
  - `PraxisCmpFiveAgent`
- Host targets:
  - `PraxisProviderContracts`
  - `PraxisWorkspaceContracts`
  - `PraxisToolingContracts`
  - `PraxisInfraContracts`
  - `PraxisUserIOContracts`
  - `PraxisRuntimeComposition`
  - `PraxisRuntimeUseCases`
  - `PraxisRuntimeFacades`
  - `PraxisRuntimePresentationBridge`
- Entrypoints:
  - `PraxisCLI`
  - `PraxisAppleUI`
  - 未来 `PraxisFFI`

- 当前 target 设计原则：
  - 先按功能边界拆到“可编译、可继续细分”的粒度
  - 不直接按现有 TS 一级目录 1:1 镜像
  - `runtime.ts`、`rax runtime/facade` 这类总装器，应拆入 `PraxisRuntimeComposition` / `PraxisRuntimeUseCases` / `PraxisRuntimeFacades` / `PraxisRuntimePresentationBridge`

## 必须长期遵守的规则

- Core 禁止依赖 provider SDK、Git CLI、数据库客户端、消息队列客户端、SwiftUI、终端 I/O。
- Git / DB / MQ / provider 相关能力都必须拆成：
  - Core planner/model
  - Host executor
- Swift-native CLI 和 SwiftUI 只能通过 `PraxisRuntimePresentationBridge` 调用系统能力。
- 但跨语言 UI / shell 不应被迫先经过 CLI；默认优先走 `PraxisRuntimeInterface` / `PraxisFFI`。
- `live-agent-chat`、`rax facade/runtime`、`runtime.ts` 只保留为行为参考，不作为代码结构模板。
- Capability / TAP / CMP / HostContracts / HostRuntime 当前都已经拆到 phase-1 target 粒度，不允许再回并成粗模块。
