# Praxis Swift 类级架构计划书

## 1. 目标

这份计划书把粒度从 target 继续下压到“类型设计”层。

它回答的问题是：

- 哪些东西应该是 `struct`
- 哪些东西应该是 `final class`
- 哪些东西应该是 `actor`
- 哪些东西应该是 `protocol`
- 哪些地方允许 `extension`
- 依赖注入应该怎么布

一句白话：

- 不是为了用 OOP 而用 OOP，而是为了让 Swift 架构既可复用、又可测试、还不重新长成大总装器。

## 2. 先定类型哲学

### 2.1 不强行“万物 class”

虽然这份计划书按“类级”组织，但真正的类型选择必须遵守 Swift 语义：

- 纯领域真相：优先 `struct`
- 有共享生命周期的服务：优先 `final class`
- 有并发可变状态的协调器：优先 `actor`
- 外部能力抽象：优先 `protocol`
- 有限状态集合：优先 `enum`

### 2.2 继承只在两个地方允许

只建议在下面两类场景使用继承：

1. Apple 平台桥接
   - 比如 `ObservableObject`、`NSObject`、`NSViewController`
2. 明确需要模板方法模式的宿主适配基类
   - 但默认仍优先 `protocol + composition`

除此之外：

- 不建议设计抽象基类树
- 不建议用继承表达业务层级
- 不建议造 Java 风格的 `BaseManager` / `BaseService`

## 3. 统一对象角色表

后续所有类型，尽量只落在下面 8 种角色里。

| 角色 | 推荐 Swift 形式 | 说明 |
| --- | --- | --- |
| 领域值对象 | `struct` | 真相数据，不带共享可变状态 |
| 领域状态枚举 | `enum` | phase/status/mode/error kind |
| 领域服务 | `struct` 或 `final class` | 纯规则时可无状态，带缓存或策略组合时用 `final class` |
| 协调器 | `actor` 或 `final class` | 多步骤流程、会跨用例持有状态 |
| 仓储接口 | `protocol` | 面向存储/外部系统的抽象 |
| 宿主适配器 | `final class` | 具体接 OpenAI、Git、DB、MQ、CLI、UI |
| 门面 | `final class` | 压平内部用例，给宿主消费 |
| DTO / 展示模型 | `struct` | CLI/UI/FFI 可消费的稳定数据 |

## 4. 依赖注入总规则

### 4.1 只允许构造注入

默认规则：

- 统一使用 initializer injection
- 不允许在业务层用全局单例
- 不允许在 use case 内直接 new 具体 adapter

### 4.2 Composition Root 是唯一拼装点

只有 `PraxisRuntimeComposition` 可以知道：

- 用了哪些具体 provider adapter
- 用了哪些 git/db/mq 实现
- 用了哪些 CLI / SwiftUI presenter

其它层不应知道：

- 具体实现类名
- 默认配置来源
- 环境变量读取逻辑

### 4.3 建议的依赖注入对象

推荐存在下面几个 DI 对象：

- `PraxisDependencyGraph`
  - 全部运行时依赖注册表
- `PraxisCoreServiceFactory`
  - 负责构建核心领域服务
- `PraxisHostAdapterFactory`
  - 负责构建 provider/workspace/tooling/infra/userio adapters
- `PraxisUseCaseFactory`
  - 负责构建 use cases
- `PraxisPresentationFactory`
  - 负责构建 CLI / SwiftUI / FFI bridge

这些 factory 本身建议用：

- `final class` 或 `struct`

如果它们不持有可变状态，优先 `struct`。

## 5. Foundation 类型清单

### 5.1 `PraxisCoreTypes`

建议类型：

- `PraxisBoundaryDescriptor`: `struct`
- `PraxisIdentifier`: `protocol`
- `GoalID`, `RunID`, `SessionID`, `CheckpointID`: `struct`
- `PraxisError`: `enum`
- `PraxisVersion`: `struct`
- `PraxisTraceTag`: `struct`

建议扩展：

- `extension PraxisBoundaryDescriptor`
  - 提供 debug label / display name
- `extension PraxisError`
  - 提供 display message

不建议：

- `CoreTypesManager`
- `SharedUtils`

### 5.2 `PraxisGoal`

建议类型：

- `GoalSourceKind`: `enum`
- `GoalSource`: `struct`
- `NormalizedGoal`: `struct`
- `CompiledGoal`: `struct`
- `GoalNormalizer`: `protocol`
- `DefaultGoalNormalizer`: `struct`
- `GoalCompiler`: `protocol`
- `DefaultGoalCompiler`: `struct`
- `GoalValidationService`: `struct`

建议：

- 这里的 service 全部优先无状态 `struct`

### 5.3 `PraxisState`

建议类型：

- `StateSnapshot`: `struct`
- `StateDelta`: `struct`
- `StateInvariantViolation`: `enum`
- `StateProjector`: `protocol`
- `DefaultStateProjector`: `struct`
- `StateValidator`: `protocol`
- `DefaultStateValidator`: `struct`

### 5.4 `PraxisTransition`

建议类型：

- `TransitionPhase`: `enum`
- `TransitionRule`: `struct`
- `TransitionGuard`: `protocol`
- `TransitionTable`: `struct`
- `NextActionDecision`: `struct`
- `TransitionEvaluator`: `struct`

建议：

- `TransitionGuard` 用协议抽象
- 每类 guard 用小类型实现，不要做巨型 if-else

### 5.5 `PraxisRun`

建议类型：

- `RunPhase`: `enum`
- `RunAggregate`: `struct`
- `RunTick`: `struct`
- `RunLifecycleService`: `struct`
- `RunCoordinator`: `actor`

关键点：

- 纯生命周期规则放 `RunLifecycleService`
- 真正会被并发访问的运行协调状态放 `RunCoordinator`

### 5.6 `PraxisSession`

建议类型：

- `SessionHeader`: `struct`
- `SessionAttachment`: `struct`
- `SessionTemperature`: `enum`
- `SessionLifecycleService`: `struct`
- `SessionRegistry`: `actor`

### 5.7 `PraxisJournal`

建议类型：

- `JournalEvent`: `struct`
- `JournalCursor`: `struct`
- `JournalSlice`: `struct`
- `JournalAppender`: `protocol`
- `JournalReader`: `protocol`
- `InMemoryJournalBuffer`: `actor`

### 5.8 `PraxisCheckpoint`

建议类型：

- `CheckpointSnapshot`: `struct`
- `RecoveryEnvelope`: `struct`
- `CheckpointPointer`: `struct`
- `CheckpointCodec`: `protocol`
- `JSONCheckpointCodec`: `struct`
- `CheckpointRecoveryService`: `struct`

## 6. Capability 类型清单

### 6.1 `PraxisCapabilityContracts`

建议类型：

- `CapabilityID`: `struct`
- `CapabilityManifest`: `struct`
- `CapabilityBinding`: `struct`
- `CapabilityInvocationRequest`: `struct`
- `CapabilityExecutionPolicy`: `struct`
- `CapabilityContract`: `protocol`

### 6.2 `PraxisCapabilityResults`

建议类型：

- `CapabilityResultEnvelope`: `struct`
- `NormalizedCapabilityOutput`: `struct`
- `CapabilityFailure`: `enum`
- `CapabilityResultNormalizer`: `protocol`
- `DefaultCapabilityResultNormalizer`: `struct`

### 6.3 `PraxisCapabilityPlanning`

建议类型：

- `CapabilitySelector`: `protocol`
- `DefaultCapabilitySelector`: `struct`
- `CapabilityInvocationPlan`: `struct`
- `CapabilityLease`: `struct`
- `CapabilityDispatchPlan`: `struct`
- `CapabilityPlanner`: `struct`

关键点：

- planner 只生成 plan
- executor 不在这个 target

### 6.4 `PraxisCapabilityCatalog`

建议类型：

- `CapabilityCatalog`: `struct`
- `CapabilityFamily`: `struct`
- `CapabilityAvailabilityEntry`: `struct`
- `CapabilityCatalogBuilder`: `struct`
- `CapabilityRegistrySnapshot`: `struct`

## 7. TAP 类型清单

### 7.1 `PraxisTapTypes`

建议类型：

- `TapMode`: `enum`
- `TapRiskLevel`: `enum`
- `ReviewKind`: `enum`
- `ProvisionKind`: `enum`
- `HumanGateState`: `enum`

### 7.2 `PraxisTapGovernance`

建议类型：

- `TapGovernanceObject`: `struct`
- `GovernanceSnapshot`: `struct`
- `RiskClassifier`: `protocol`
- `DefaultRiskClassifier`: `struct`
- `ModePolicyResolver`: `struct`

### 7.3 `PraxisTapReview`

建议类型：

- `ReviewRequest`: `struct`
- `ReviewDecision`: `struct`
- `ReviewerRoute`: `enum`
- `ReviewTrail`: `struct`
- `ReviewDecisionEngine`: `struct`
- `ReviewerCoordinator`: `actor`

### 7.4 `PraxisTapProvision`

建议类型：

- `ProvisionRequest`: `struct`
- `ProvisionAsset`: `struct`
- `ProvisionRegistry`: `struct`
- `ProvisionPlan`: `struct`
- `ProvisionPlanner`: `struct`

### 7.5 `PraxisTapRuntime`

建议类型：

- `TapControlPlaneState`: `struct`
- `TapRuntimeSnapshot`: `struct`
- `ReplayPolicy`: `struct`
- `ActivationLifecycleService`: `struct`
- `TapRuntimeCoordinator`: `actor`

### 7.6 `PraxisTapAvailability`

建议类型：

- `AvailabilityState`: `enum`
- `TapGateRule`: `struct`
- `TapFailureTaxonomy`: `enum`
- `AvailabilityReport`: `struct`
- `AvailabilityAuditor`: `struct`

## 8. CMP 类型清单

### 8.1 `PraxisCmpTypes`

建议类型：

- `CmpSectionID`: `struct`
- `CmpPackageID`: `struct`
- `CmpProjectionID`: `struct`
- `CmpLineageID`: `struct`
- `CmpPriority`: `enum`
- `CmpScope`: `enum`

### 8.2 `PraxisCmpSections`

建议类型：

- `SectionIngressRequest`: `struct`
- `CmpSection`: `struct`
- `SectionOwnershipRule`: `struct`
- `SectionLoweringPlan`: `struct`
- `SectionBuilder`: `struct`

### 8.3 `PraxisCmpProjection`

建议类型：

- `ProjectionRecord`: `struct`
- `MaterializationPlan`: `struct`
- `VisibilityPolicy`: `struct`
- `ProjectionRecoveryPlan`: `struct`
- `ProjectionMaterializer`: `struct`

### 8.4 `PraxisCmpDelivery`

建议类型：

- `ContextPackage`: `struct`
- `DeliveryPlan`: `struct`
- `DispatchInstruction`: `struct`
- `DeliveryFallbackPlan`: `struct`
- `DeliveryPlanner`: `struct`

### 8.5 `PraxisCmpGitModel`

建议类型：

- `GitBranchFamily`: `struct`
- `GitRefLifecycle`: `struct`
- `GitLineagePolicy`: `struct`
- `GitSyncPlan`: `struct`

### 8.6 `PraxisCmpDbModel`

建议类型：

- `StorageTopology`: `struct`
- `ProjectionPersistencePlan`: `struct`
- `PackagePersistencePlan`: `struct`
- `DeliveryPersistencePlan`: `struct`

### 8.7 `PraxisCmpMqModel`

建议类型：

- `TopicTopology`: `struct`
- `RoutingPlan`: `struct`
- `NeighborhoodGraph`: `struct`
- `EscalationPlan`: `struct`

### 8.8 `PraxisCmpFiveAgent`

建议类型：

- `FiveAgentRole`: `enum`
- `AgentHandOff`: `struct`
- `RoleAssignment`: `struct`
- `FiveAgentProtocolDefinition`: `struct`
- `FiveAgentCoordinator`: `actor`

## 9. HostContracts 协议面

这里原则上不放具体 class，只放协议与最小 DTO。

### 9.1 `PraxisProviderContracts`

建议协议：

- `ProviderInferenceExecutor`
- `ProviderEmbeddingExecutor`
- `ProviderFileStore`
- `ProviderBatchExecutor`
- `ProviderSkillRegistry`
- `ProviderSkillActivator`
- `ProviderMCPExecutor`

建议 DTO：

- `ProviderInferenceRequest`
- `ProviderInferenceResponse`
- `ProviderExecutionReceipt`

### 9.2 `PraxisWorkspaceContracts`

建议协议：

- `WorkspaceReader`
- `WorkspaceSearcher`
- `WorkspaceWriter`

### 9.3 `PraxisToolingContracts`

建议协议：

- `ShellExecutor`
- `BrowserExecutor`
- `GitExecutor`
- `ProcessSupervisor`

### 9.4 `PraxisInfraContracts`

建议协议：

- `JournalStore`
- `CheckpointStore`
- `ProjectionStore`
- `MessageBus`
- `LineageStore`

### 9.5 `PraxisUserIOContracts`

建议协议：

- `UserInputDriver`
- `PermissionDriver`
- `TerminalPresenter`
- `ConversationPresenter`

## 10. HostRuntime 类图

### 10.1 `PraxisRuntimeComposition`

建议类型：

- `PraxisDependencyGraph`: `final class`
- `PraxisCoreServiceFactory`: `struct`
- `PraxisHostAdapterFactory`: `final class`
- `PraxisBootstrapValidator`: `struct`

说明：

- `PraxisDependencyGraph` 可以持有引用型依赖，因此用 `final class`
- `BootstrapValidator` 纯规则，因此用 `struct`

### 10.2 `PraxisRuntimeUseCases`

建议类型：

- `RunGoalUseCase`: `final class`
- `ResumeRunUseCase`: `final class`
- `InspectTapUseCase`: `final class`
- `InspectCmpUseCase`: `final class`
- `BuildCapabilityCatalogUseCase`: `final class`

建议协议：

- `RunGoalUseCaseProtocol`
- `ResumeRunUseCaseProtocol`
- `InspectTapUseCaseProtocol`
- `InspectCmpUseCaseProtocol`

说明：

- use case 默认用 `final class`
- 因为它们通常要持有多组 service / repository / coordinator 引用

### 10.3 `PraxisRuntimeFacades`

建议类型：

- `PraxisRuntimeFacade`: `final class`
- `PraxisInspectionFacade`: `final class`
- `PraxisRunFacade`: `final class`
- `PraxisRuntimeBlueprint`: `struct`

说明：

- facade 是宿主表面，用 `final class`
- blueprint 和 DTO 仍然用 `struct`

### 10.4 `PraxisRuntimePresentationBridge`

建议类型：

- `CLICommandBridge`: `final class`
- `ApplePresentationBridge`: `final class`
- `FFIBridge`: `final class`
- `PresentationStateMapper`: `struct`
- `PresentationEventStream`: `actor`

说明：

- 这里是最容易失控的层
- 必须坚持“桥接宿主，不再实现业务”

## 11. Entry 层对象

### 11.1 `PraxisCLI`

建议类型：

- `PraxisCLIApp`: `final class`
- `CLICommandRouter`: `final class`
- `InteractiveSessionController`: `actor`
- `TerminalRenderer`: `final class`
- `CLIConfiguration`: `struct`

### 11.2 `PraxisAppleUI`

建议类型：

- `PraxisAppleAppModel`: `@MainActor final class`
- `RunDashboardViewState`: `struct`
- `SessionListViewState`: `struct`
- `BridgeStore`: `@MainActor final class`

建议：

- SwiftUI 侧如果需要观察对象，才使用 `@MainActor final class`
- 页面数据模型继续优先 `struct`

## 12. Extension 使用规则

允许：

- 给值对象补 display / debug / formatting
- 给协议补默认实现
- 给 DTO 补 mapping helper

不允许：

- 用 extension 偷塞核心业务流程
- 把 500 行逻辑藏进 `extension Foo`
- 用 extension 模拟多层继承

建议：

- 一个 extension 只做一件事
- 文件名要反映扩展职责，比如 `RunAggregate+Display.swift`

## 13. 测试双对象设计

为了确保解耦，所有协议层都要有测试双对象。

建议类型：

- `FakeWorkspaceReader`
- `FakeShellExecutor`
- `SpyConversationPresenter`
- `StubProviderInferenceExecutor`
- `InMemoryCheckpointStore`
- `InMemoryProjectionStore`

建议位置：

- 先放在对应 test target 内
- 只有当多个 test target 共用时，才提炼 shared test support

## 14. 类级实施顺序

不是所有类型都要一起写，建议按下面顺序：

### Phase A

- 所有 Foundation 值对象
- Foundation 纯服务

### Phase B

- Capability 值对象与 planner
- TAP / CMP 的纯值对象与纯服务

### Phase C

- HostContracts 协议
- 对应 fake / stub / spy

### Phase D

- Runtime factories
- Runtime use cases
- Runtime facades

### Phase E

- Presentation bridges
- CLI / SwiftUI 宿主对象

## 15. 最后建议

如果你下一步真的开始写实现，我建议始终按下面这条判断：

- 这个类型如果删掉引用共享身份后还能作为纯值成立，就不要写成 `class`

再补一条更硬的：

- 只有“协调流程”与“承载外部依赖”的对象，才默认进入 `final class` 或 `actor`

这样做的结果是：

- 领域层保持值语义
- 运行时保持可注入
- 宿主层保持可替换
- 整个系统不会因为 OOP 过度而重新变重
