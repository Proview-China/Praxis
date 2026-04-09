# Swift Test Topology

## 目标

测试层也必须按模块边界设计，不能重新做成一个大而全的总测试包。

当前阶段先冻结测试模块拓扑，而不是追求覆盖率数字。

## Phase-1 已冻结的架构守卫测试

### 1. Foundation 架构测试

- target: `PraxisFoundationArchitectureTests`
- 负责：
  - Foundation 八个 target 的存在性
  - 边界名称稳定
  - 依赖方向不被粗暴合并

### 2. Capability 架构测试

- target: `PraxisCapabilityArchitectureTests`
- 负责：
  - `Contracts / Planning / Results / Catalog` 四分结构稳定
  - Capability 子域不反向依赖 TAP / CMP

### 3. TAP 架构测试

- target: `PraxisTapArchitectureTests`
- 负责：
  - `Types / Governance / Review / Provision / Runtime / Availability` 六分结构稳定
  - TAP 子域存在性

### 4. CMP 架构测试

- target: `PraxisCmpArchitectureTests`
- 负责：
  - `Types / Sections / Projection / Delivery / GitModel / DbModel / MqModel / FiveAgent` 八分结构稳定
  - CMP 子域存在性

### 5. HostContracts 架构测试

- target: `PraxisHostContractsArchitectureTests`
- 负责：
  - `Provider / Workspace / Tooling / Infra / UserIO` 五分结构稳定
  - 宿主协议层不再回并成单一大接口包

### 6. HostRuntime 架构测试

- target: `PraxisHostRuntimeArchitectureTests`
- 负责：
  - `Composition / UseCases / Facades / PresentationBridge` 四分结构稳定
  - Entry 是否仍只通过 `PraxisRuntimePresentationBridge` 进入

## 当前阶段这些测试的本质

当前这批测试不是业务测试，而是架构守卫测试。

它们主要防止：

- 粗模块回归
- target 边界漂移
- `Package.swift` 与架构蓝图不一致
- Entry 越层依赖 Core / HostContracts

## 下一阶段的测试模块规划

等真实迁移开始后，测试模块按功能继续下钻，但仍保持与 target 拓扑对齐。

### Foundation 逻辑测试

建议逐步增加：

- `PraxisGoalTests`
- `PraxisStateTests`
- `PraxisTransitionTests`
- `PraxisRunTests`
- `PraxisSessionTests`
- `PraxisJournalTests`
- `PraxisCheckpointTests`

职责：

- 纯模型约束
- 状态机与生命周期规则
- 快照恢复边界

### Capability 子域测试

建议逐步增加：

- `PraxisCapabilityContractsTests`
- `PraxisCapabilityPlanningTests`
- `PraxisCapabilityResultsTests`
- `PraxisCapabilityCatalogTests`

职责：

- manifest / invocation / result normalize
- routing / planning / catalog build 的纯规则

### TAP 子域测试

建议逐步增加：

- `PraxisTapGovernanceTests`
- `PraxisTapReviewTests`
- `PraxisTapProvisionTests`
- `PraxisTapRuntimeTests`
- `PraxisTapAvailabilityTests`

职责：

- risk / policy / review / gate / availability 的纯规则

### CMP 子域测试

建议逐步增加：

- `PraxisCmpSectionsTests`
- `PraxisCmpProjectionTests`
- `PraxisCmpDeliveryTests`
- `PraxisCmpGitModelTests`
- `PraxisCmpDbModelTests`
- `PraxisCmpMqModelTests`
- `PraxisCmpFiveAgentTests`

职责：

- section ownership
- projection / delivery planner
- git/db/mq/five-agent 的纯模型行为

### HostContracts 合约测试

建议逐步增加：

- `PraxisProviderContractsTests`
- `PraxisWorkspaceContractsTests`
- `PraxisToolingContractsTests`
- `PraxisInfraContractsTests`
- `PraxisUserIOContractsTests`

职责：

- 协议输入输出的一致性
- fake / spy / mock adapter 的契约验证

说明：

- 这里测的是“宿主实现必须遵守什么约束”，不是测真实 SDK 本身。

### HostRuntime 集成测试

建议逐步增加：

- `PraxisRuntimeCompositionTests`
- `PraxisRuntimeUseCasesTests`
- `PraxisRuntimeFacadesTests`
- `PraxisRuntimePresentationBridgeTests`

职责：

- composition root 装配正确性
- facade / use case 行为稳定
- presentation state 映射正确

### Entry 冒烟测试

建议逐步增加：

- `PraxisCLISmokeTests`
- `PraxisAppleUISmokeTests`
- 未来的 `PraxisFFISmokeTests`

职责：

- 入口层只验证启动、路由和基础交互
- 不承担核心业务规则测试

## 一条硬规则

业务测试可以慢慢补，但架构守卫测试必须和 target 拆分同步更新。
