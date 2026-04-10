# Praxis Swift Target 重构计划书

## 1. 目标

这份计划书只回答一个问题：

- 后续真正开始 Swift 重构时，应该按什么 target 顺序推进，才能在风险最低的前提下持续得到可验证成果。

它不替代架构蓝图，也不替代总工单。

配套文档：

- [SWIFT_ARCHITECTURE.md](/Users/shiyu/Documents/Project/Praxis/SWIFT_ARCHITECTURE.md)
- [REFACTOR_SWIFT_WORKORDER.md](/Users/shiyu/Documents/Project/Praxis/REFACTOR_SWIFT_WORKORDER.md)
- [Package.swift](/Users/shiyu/Documents/Project/Praxis/Package.swift)

## 2. 总原则

### 2.1 顺序原则

重构顺序固定为：

1. 先低层纯模型
2. 再纯规则与 planner
3. 再宿主协议
4. 再运行时装配
5. 最后入口层

一句白话：

- 先把“系统是什么”写清楚，再写“系统怎么跑”，最后再写“人怎么用”。

### 2.2 验收原则

每个波次结束时，至少满足四件事：

1. target 内 TODO 已转成实际文件与类型
2. 架构守卫测试仍通过
3. 新 target 不引入越层依赖
4. 可以明确说出“这波没有碰哪些高风险 live 能力”

### 2.3 并行原则

只有三类工作适合并行：

- 同层且互不依赖的纯模型 target
- 同一子域下的独立 planner target
- 宿主协议定义与 fake/mock 测试

不适合并行的：

- `PraxisRuntimeComposition`
- `PraxisRuntimeUseCases`
- `PraxisRuntimePresentationBridge`
- 任何真正接入 live provider / git / db / mq 的落地波次

## 3. 总体执行波次

建议分成 8 个波次，而不是按 1 个 target 1 个 PR 机械推进。

| 波次 | 主题 | 目标 |
| --- | --- | --- |
| Wave 0 | 骨架冻结 | 只维护 target 拓扑、TODO、测试守卫 |
| Wave 1 | Foundation 纯模型 | 建立最低层领域真相 |
| Wave 2 | Capability 基础能力 | 建立能力声明、规划、结果归一化 |
| Wave 3 | TAP 纯治理规则 | 建立 review/provision/governance 语义 |
| Wave 4 | CMP 纯上下文规则 | 建立 section/projection/delivery/model |
| Wave 5 | HostContracts | 建立宿主协议与 fake 契约 |
| Wave 6 | HostRuntime | 建立 composition/use case/facade/bridge |
| Wave 7 | Entry 与宿主 MVP | CLI / SwiftUI 最小可用壳 |

## 4. 详细 target 顺序

下面是建议顺序。顺序编号表示推荐执行顺序，不代表每个 target 必须单独提交。

### 4.1 Wave 1: Foundation 纯模型层

#### 1. `PraxisCoreTypes`

为什么先做：

- 它是全系统公共基座。
- 如果这里不先稳定，后面所有 target 都会反复改类型。

本波目标：

- ID、边界描述、基础错误、版本、最小共享协议稳定
- 不引入任何高层业务语义

完成标志：

- 其它 Foundation target 不再自己定义重复基础类型

建议：

- 这个 target 宁可小，也不要“好心”塞共享工具。

#### 2. `PraxisGoal`

本波目标：

- 目标来源、目标归一化、目标编译

完成标志：

- 输入目标可以被统一编译成稳定的内部 goal 表示

建议：

- 不要在这里提前定义命令行参数模型或 UI 表单模型。

#### 3. `PraxisState`

本波目标：

- 状态快照、状态投影、状态校验、delta

完成标志：

- 状态可以脱离 live runtime 被独立测试

建议：

- 这里优先追求“状态真相清晰”，不要急着追求 projection 性能。

#### 4. `PraxisTransition`

本波目标：

- transition table
- guard
- next action 决策

完成标志：

- 核心状态机不依赖宿主实现即可跑通

建议：

- 所有 guard 要坚持纯函数化，不要偷读 workspace 或 provider 状态。

#### 5. `PraxisRun`

本波目标：

- run 生命周期
- tick 协调
- fail / pause / resume / complete 纯规则

完成标志：

- 单次运行生命周期可在纯内存测试里演进

建议：

- 不要把 session/checkpoint 持久化操作直接写进这里。

#### 6. `PraxisSession`

本波目标：

- session header
- run attachment
- hot/cold 生命周期

完成标志：

- session 与 run 的长期关系被清楚建模

建议：

- 只表达关系，不写 store。

#### 7. `PraxisJournal`

本波目标：

- append-only event
- cursor
- read model input

完成标志：

- 事件流真相与 session/run 真相不再混用

建议：

- 先用内存模型表达 append-only 语义，不急着接磁盘或 DB。

#### 8. `PraxisCheckpoint`

本波目标：

- snapshot
- recovery envelope
- checkpoint pointer 语义

完成标志：

- 恢复边界与 session/run/journal 的关系清楚

建议：

- 只定义恢复真相，不做真正的外部存储落地。

### 4.2 Wave 2: Capability 子域

#### 9. `PraxisCapabilityContracts`

本波目标：

- capability manifest
- invocation contract
- identity / binding 语义

完成标志：

- capability 成为 TAP/CMP 可引用的统一基础

建议：

- 先定义 capability 语义，不要提前绑定 OpenAI/Anthropic 形状。

#### 10. `PraxisCapabilityResults`

本波目标：

- result envelope
- normalized output
- failure taxonomy

完成标志：

- 上层不再直接依赖 provider 原始回包

建议：

- 这里应尽早冻结，因为后续 TAP review 很依赖它。

#### 11. `PraxisCapabilityPlanning`

本波目标：

- selector
- invocation plan
- routing / lease / dispatch 纯规划

完成标志：

- capability 从“声明”走到“可计划执行”

建议：

- planning 要保持纯规则，不要直接长成 executor。

#### 12. `PraxisCapabilityCatalog`

本波目标：

- capability family registry
- baseline set
- discoverability

完成标志：

- 系统能说明“当前有哪些能力、哪些可用”

建议：

- catalog 优先服务于可见性和策略，不要变成运行时总装配置中心。

### 4.3 Wave 3: TAP 子域

#### 13. `PraxisTapTypes`

本波目标：

- TAP 共用类型先稳定

建议：

- 这个 target 完成之前，不要急着写 review/runtime 细节。

#### 14. `PraxisTapGovernance`

本波目标：

- 风险分级
- 模式策略
- governance object

完成标志：

- “该不该做”有稳定规则模型

#### 15. `PraxisTapReview`

本波目标：

- reviewer route
- review request / decision
- tool review / human review 统一审查面

完成标志：

- 审查逻辑可以独立测试，不依赖真正工具执行

#### 16. `PraxisTapProvision`

本波目标：

- provision request
- asset index
- provision planner

完成标志：

- TAP 可以表达“需要什么能力/资源”，但不落执行器

建议：

- 这是容易重新混回宿主实现的点，要特别克制。

#### 17. `PraxisTapRuntime`

本波目标：

- control plane
- activation lifecycle
- replay policy

完成标志：

- TAP 运行时语义稳定，但仍不直接碰外部 I/O

建议：

- 只有前四个 TAP target 稳定后，才开始写这里。

#### 18. `PraxisTapAvailability`

本波目标：

- availability report
- gate rule
- failure taxonomy

完成标志：

- 系统能判断“某类能力在当前上下文是否可用”

建议：

- 这是治理收口层，建议放在 TAP 最后做。

### 4.4 Wave 4: CMP 子域

#### 19. `PraxisCmpTypes`

本波目标：

- CMP 共用模型先稳定

建议：

- 先把 section/package/projection/lineage 的名词表定住。

#### 20. `PraxisCmpSections`

本波目标：

- ingest
- section creation
- lowering
- ownership / visibility rules

完成标志：

- 上下文切片规则可独立推演

#### 21. `PraxisCmpProjection`

本波目标：

- projection record
- materialization
- recovery / visibility

完成标志：

- 上下文如何投影和恢复被稳定表达

#### 22. `PraxisCmpDelivery`

本波目标：

- package
- dispatch instruction
- active/passive delivery

完成标志：

- CMP 能表达“上下文如何投递”

建议：

- delivery 先做 plan，不要先接 MQ。

#### 23. `PraxisCmpGitModel`

本波目标：

- branch family
- refs lifecycle
- lineage governance

完成标志：

- Git 相关规则脱离 Git CLI 仍可成立

#### 24. `PraxisCmpDbModel`

本波目标：

- storage topology
- projection/package persistence plan

完成标志：

- DB 落库方案先成为 model/planner，而不是 SQL 直接实现

#### 25. `PraxisCmpMqModel`

本波目标：

- topic topology
- routing
- escalation

完成标志：

- MQ 路由规则脱离 Redis 也能成立

#### 26. `PraxisCmpFiveAgent`

本波目标：

- five-agent role protocol
- hand-off
- context partition

完成标志：

- 五角色的纯职责模型稳定

建议：

- 这是高复杂子域，放在 CMP 最后做是为了减少返工。

### 4.5 Wave 5: HostContracts

这一波不是做实现，而是做“系统向外界要什么”。

#### 27. `PraxisWorkspaceContracts`

建议先做原因：

- 几乎所有 live 路径都会依赖 workspace 能力。

#### 28. `PraxisToolingContracts`

建议：

- shell / browser / git / process supervision 分开定义，不要一个万能 executor。

#### 29. `PraxisUserIOContracts`

建议：

- 先冻结 prompt / permission / presentation 边界，后面 CLI/UI 才不会乱长。

#### 30. `PraxisProviderContracts`

建议：

- 这是最容易被 SDK 反向污染的 target，先做协议，不做 adapter。

#### 31. `PraxisInfraContracts`

建议：

- 放在 HostContracts 最后做，因为它要吸收前面 CMP/checkpoint/journal 的存储边界。

完成标志：

- 五类宿主协议都有 fake/mock 版本可以驱动测试

### 4.6 Wave 6: HostRuntime

这一波开始才是真正把系统“接起来”。

#### 32. `PraxisRuntimeComposition`

本波目标：

- composition root
- dependency graph
- adapter registry

建议：

- 只装配，不表达产品动作。

#### 33. `PraxisRuntimeUseCases`

本波目标：

- runGoal
- resumeRun
- inspectTap
- inspectCmp
- buildCapabilityCatalog

建议：

- 这里是整个重构成败的关键层。
- 如果这里重新长成 `runtime.ts`，前面所有拆分都会失效。

#### 34. `PraxisRuntimeFacades`

本波目标：

- 面向宿主的稳定 DTO
- façade 级调用表面

建议：

- facade 只负责压平 use case，不要二次实现业务规则。

#### 35. `PraxisRuntimePresentationBridge`

本波目标：

- CLI / SwiftUI / FFI 共用桥接模型
- 命令结果、展示状态、事件桥

完成标志：

- Entry 层不再需要知道 runtime 内部 target

建议：

- 这个 target 要特别克制，不要把 ViewModel 或 CLI renderer 直接塞进来。

### 4.7 Wave 7: Entry

#### 36. `PraxisCLI`

建议顺序：

- 先做非交互命令
- 再做交互会话
- 最后做高级终端体验

原因：

- 非交互命令最容易验证 HostRuntime 是否正确。

#### 37. `PraxisAppleUI`

建议顺序：

1. 只做 app shell / navigation
2. 再做只读 inspection 视图
3. 最后才做可交互 run/session 页面

原因：

- 先把 SwiftUI 当成宿主壳，而不是先做漂亮页面。

#### 38. 未来的 `PraxisFFI`

建议：

- 必须在 `PraxisRuntimePresentationBridge` 稳定后再建
- 不要提前进入当前波次

## 5. 推荐的 PR / 工单切法

建议不要按“每个 target 一个 PR”切，那样会非常碎。

推荐切法：

### PR 1

- `PraxisCoreTypes`
- `PraxisGoal`
- `PraxisState`
- `PraxisTransition`

### PR 2

- `PraxisRun`
- `PraxisSession`
- `PraxisJournal`
- `PraxisCheckpoint`

### PR 3

- `PraxisCapabilityContracts`
- `PraxisCapabilityResults`
- `PraxisCapabilityPlanning`
- `PraxisCapabilityCatalog`

### PR 4

- 全部 TAP targets

### PR 5

- `PraxisCmpTypes`
- `PraxisCmpSections`
- `PraxisCmpProjection`
- `PraxisCmpDelivery`

### PR 6

- `PraxisCmpGitModel`
- `PraxisCmpDbModel`
- `PraxisCmpMqModel`
- `PraxisCmpFiveAgent`

### PR 7

- 全部 HostContracts targets

### PR 8

- `PraxisRuntimeComposition`
- `PraxisRuntimeUseCases`

### PR 9

- `PraxisRuntimeFacades`
- `PraxisRuntimePresentationBridge`

### PR 10

- `PraxisCLI`
- `PraxisAppleUI`

## 6. 明确不建议的顺序

不要这样做：

1. 先写 `PraxisAppleUI`
2. 先写 provider adapter
3. 先接 Git / DB / MQ live 实现
4. 先把 `runtime.ts` 整体翻译成 Swift
5. 先做 `CmpFiveAgent` live 版

原因很简单：

- 这些路径都太靠近现有“屎山”的表面形态，最容易把旧问题原样搬过去。

## 7. 风险最高的 target

下面几个 target 最值得设 review gate：

### `PraxisCapabilityPlanning`

风险：

- 容易偷偷长成 executor。

### `PraxisTapProvision`

风险：

- 容易把 provisioning 的宿主副作用直接塞进去。

### `PraxisCmpDelivery`

风险：

- 容易提前和 MQ / DB / provider 绑定。

### `PraxisRuntimeUseCases`

风险：

- 最容易重新长回单体总编排器。

### `PraxisRuntimePresentationBridge`

风险：

- 最容易把 CLI / SwiftUI 特定模型反灌回来。

## 8. 最后建议

如果你接下来要真正开做，我建议采用下面的节奏：

1. 先完成 Wave 1 和 Wave 2，建立最小可演算核心。
2. 再完成 Wave 3 和 Wave 4，补齐 TAP/CMP 的纯规则层。
3. 然后完成 Wave 5 和 Wave 6，建立可装配运行时。
4. 最后才做 Wave 7 的 CLI / SwiftUI。

更直接一点说：

- 第一阶段先证明“Swift 可以承接纯核心”
- 第二阶段再证明“Swift 可以装配整个系统”
- 第三阶段才证明“Swift 宿主真的好用”
