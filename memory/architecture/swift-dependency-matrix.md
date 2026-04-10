# Swift Dependency Matrix

## 目标

这份矩阵不是实现文档，而是“谁可以依赖谁”的硬边界。

后续任何 Swift target 的继续细化、拆分、合并，都不能突破这张矩阵的方向。

## 总规则

- 依赖只能单向向下收敛，不能反向抬升。
- `Core` 是逻辑层，不是单一 target。
- `HostContracts` 只定义协议，不承载业务规则。
- `HostRuntime` 负责装配与对外用例，不重新吸收 Core 规则。
- `Entry` 只能通过 `PraxisRuntimePresentationBridge` 进入系统。

## 层级矩阵

| From | To | 是否允许 | 说明 |
| --- | --- | --- | --- |
| `Core` | `Core` | 允许 | 但必须按子域规则受限 |
| `Core` | `HostContracts` | 不允许 | Core 不能反向知道宿主协议层 |
| `Core` | `HostRuntime` | 不允许 | 禁止依赖装配层 |
| `Core` | `Entry` | 不允许 | 禁止依赖 UI / CLI / FFI |
| `HostContracts` | `Core` | 允许 | 用 Core 类型描述协议输入输出 |
| `HostContracts` | `HostRuntime` | 不允许 | 协议层不能依赖装配层 |
| `HostRuntime` | `Core` | 允许 | 装配层绑定核心能力 |
| `HostRuntime` | `HostContracts` | 允许 | 装配层消费协议族 |
| `HostRuntime` | `Entry` | 不允许 | 装配层不反向知道入口 |
| `Entry` | `Core` | 不允许 | 不允许越层直连 Core |
| `Entry` | `HostContracts` | 不允许 | 入口层不直接持有宿主协议 |
| `Entry` | `PraxisRuntimePresentationBridge` | 允许 | 唯一正式入口 |

## Product 与 target 的关系

下面两个名字只表示聚合 product，不表示可随意塞逻辑的单体 target：

- `PraxisHostContracts`
- `PraxisHostRuntime`

真正受边界约束的是它们下面的 phase-1 target。

## 当前 target 依赖矩阵

### Foundation

#### `PraxisCoreTypes`

- 可依赖：
  - 无
- 可被依赖：
  - 所有 Core / Host / Entry target

#### `PraxisGoal`

- 可依赖：
  - `PraxisCoreTypes`
- 禁止依赖：
  - 任何 Capability / TAP / CMP / Host target

#### `PraxisState`

- 可依赖：
  - `PraxisCoreTypes`
- 禁止依赖：
  - `PraxisRun`
  - 任何 Capability / TAP / CMP / Host target

#### `PraxisTransition`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisState`
- 禁止依赖：
  - `PraxisRun`
  - 任何 Capability / TAP / CMP / Host target

#### `PraxisRun`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisGoal`
  - `PraxisState`
  - `PraxisTransition`
- 禁止依赖：
  - 任何 Capability / TAP / CMP / Host target

#### `PraxisSession`

- 可依赖：
  - `PraxisCoreTypes`
- 禁止依赖：
  - `PraxisRun`
  - 任何 Capability / TAP / CMP / Host target

#### `PraxisJournal`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisSession`
- 禁止依赖：
  - 任何 Capability / TAP / CMP / Host target

#### `PraxisCheckpoint`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisSession`
  - `PraxisJournal`
- 禁止依赖：
  - 任何 Capability / TAP / CMP / Host target

### Capability 子域

#### `PraxisCapabilityContracts`

- 可依赖：
  - `PraxisCoreTypes`
- 禁止依赖：
  - TAP / CMP / Host targets

#### `PraxisCapabilityPlanning`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisGoal`
  - `PraxisRun`
  - `PraxisCapabilityContracts`
- 禁止依赖：
  - TAP / CMP / Host targets

#### `PraxisCapabilityResults`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisCapabilityContracts`
- 禁止依赖：
  - TAP / CMP / Host targets

#### `PraxisCapabilityCatalog`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisCapabilityContracts`
  - `PraxisCapabilityPlanning`
- 禁止依赖：
  - TAP / CMP / Host targets

说明：

- Capability 是横向基础能力，不允许反向知道 TAP / CMP。

### TAP 子域

#### `PraxisTapTypes`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisCapabilityContracts`

#### `PraxisTapGovernance`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisCapabilityContracts`
  - `PraxisTapTypes`

#### `PraxisTapReview`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisCapabilityContracts`
  - `PraxisCapabilityResults`
  - `PraxisTapTypes`
  - `PraxisTapGovernance`

#### `PraxisTapProvision`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisCapabilityContracts`
  - `PraxisCapabilityPlanning`
  - `PraxisTapTypes`
  - `PraxisTapGovernance`

#### `PraxisTapRuntime`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisSession`
  - `PraxisCheckpoint`
  - `PraxisCapabilityPlanning`
  - `PraxisTapTypes`
  - `PraxisTapGovernance`
  - `PraxisTapReview`
  - `PraxisTapProvision`

#### `PraxisTapAvailability`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisCapabilityCatalog`
  - `PraxisTapTypes`
  - `PraxisTapGovernance`

说明：

- TAP 可以依赖 Capability，但不应绑定任何宿主实现。

### CMP 子域

#### `PraxisCmpTypes`

- 可依赖：
  - `PraxisCoreTypes`

#### `PraxisCmpSections`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisCmpTypes`

#### `PraxisCmpProjection`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisCheckpoint`
  - `PraxisCmpTypes`
  - `PraxisCmpSections`

#### `PraxisCmpDelivery`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisCapabilityPlanning`
  - `PraxisTapTypes`
  - `PraxisCmpTypes`
  - `PraxisCmpProjection`

#### `PraxisCmpGitModel`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisCmpTypes`
  - `PraxisCmpProjection`

#### `PraxisCmpDbModel`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisCmpTypes`
  - `PraxisCmpProjection`

#### `PraxisCmpMqModel`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisCmpTypes`
  - `PraxisCmpDelivery`

#### `PraxisCmpFiveAgent`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisCapabilityPlanning`
  - `PraxisTapReview`
  - `PraxisTapRuntime`
  - `PraxisCmpTypes`
  - `PraxisCmpSections`
  - `PraxisCmpProjection`
  - `PraxisCmpDelivery`

说明：

- CMP 是高层业务子域，可以依赖 Capability 与 TAP。
- Git / DB / MQ 在 CMP 内只允许以 model / planner 形式存在。

### HostContracts 子域

#### `PraxisProviderContracts`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisCapabilityContracts`
  - `PraxisCapabilityResults`
- 禁止依赖：
  - 其它 HostContracts target
  - 任何 HostRuntime / Entry target

#### `PraxisWorkspaceContracts`

- 可依赖：
  - `PraxisCoreTypes`
- 禁止依赖：
  - 其它 HostContracts target
  - 任何 HostRuntime / Entry target

#### `PraxisToolingContracts`

- 可依赖：
  - `PraxisCoreTypes`
- 禁止依赖：
  - 其它 HostContracts target
  - 任何 HostRuntime / Entry target

#### `PraxisInfraContracts`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisCmpTypes`
  - `PraxisCmpDelivery`
- 禁止依赖：
  - 其它 HostContracts target
  - 任何 HostRuntime / Entry target

#### `PraxisUserIOContracts`

- 可依赖：
  - `PraxisCoreTypes`
- 禁止依赖：
  - 其它 HostContracts target
  - 任何 HostRuntime / Entry target

说明：

- HostContracts 只负责描述能力，不提供实现。

### HostRuntime 子域

#### `PraxisRuntimeComposition`

- 可依赖：
  - 所有 Foundation / Capability / TAP / CMP targets
  - 所有五个 HostContracts targets
- 禁止依赖：
  - `PraxisCLI`
  - `PraxisAppleUI`

#### `PraxisRuntimeUseCases`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisRuntimeComposition`
- 禁止依赖：
  - Entry targets

#### `PraxisRuntimeFacades`

- 可依赖：
  - `PraxisCoreTypes`
  - `PraxisRuntimeUseCases`
- 禁止依赖：
  - Entry targets

#### `PraxisRuntimeInterface`

- 可依赖：
  - `PraxisGoal`
  - `PraxisRun`
  - `PraxisSession`
  - `PraxisRuntimeFacades`
- 禁止依赖：
  - Entry targets
  - `PraxisRuntimeComposition`
  - `PraxisRuntimePresentationBridge`

说明：

- `PraxisRuntimeInterface` 负责宿主无关的统一 request/response/event/coding surface。
- 它可以被未来的导出层或跨语言绑定复用，但不能吸收 CLI、SwiftUI、ABI 细节。

#### `PraxisRuntimePresentationBridge`

- 可依赖：
  - `PraxisRuntimeComposition`
  - `PraxisRuntimeUseCases`
  - `PraxisRuntimeFacades`
  - `PraxisRuntimeInterface`
  - 为 blueprint 与边界描述读取必要的 Core / HostContracts target
- 禁止依赖：
  - Entry targets

说明：

- `PraxisRuntimePresentationBridge` 是 Entry 的唯一正式入口。

### Entry

#### `PraxisCLI`

- 可依赖：
  - `PraxisRuntimePresentationBridge`
- 禁止依赖：
  - 其它所有 Core target
  - 所有 HostContracts target
  - `PraxisRuntimeComposition`
  - `PraxisRuntimeUseCases`
  - `PraxisRuntimeFacades`

#### `PraxisAppleUI`

- 可依赖：
  - `PraxisRuntimePresentationBridge`
- 禁止依赖：
  - 其它所有 Core target
  - 所有 HostContracts target
  - `PraxisRuntimeComposition`
  - `PraxisRuntimeUseCases`
  - `PraxisRuntimeFacades`

## 继续细分时的硬规则

如果后续继续细分 target，必须保持下面方向不变：

- Foundation 只能继续按对象所有权细化，不能重新长回公共大杂烩。
- Capability 只能继续细分 contracts / planning / results / catalog 内部子模块，不能反向依赖 TAP / CMP。
- TAP 只能继续细分 governance / review / provision / runtime / availability，不能偷带宿主实现。
- CMP 只能继续细分 model / planner / package / delivery 内部语义，不能把执行器塞进来。
- HostContracts 只能继续按协议族下钻，不能回并成“大接口层”。
- HostRuntime 只能继续按 composition / use case / facade / presentation bridge 的职责演进。

## 违反矩阵时的处理

如果一个 target 需要引用矩阵中被禁止的模块，只能做三件事之一：

1. 抽公共类型到更低层
2. 把规则从高层下沉为协议或 planner
3. 把副作用实现上提到宿主层

不允许的处理方式：

- 临时放开依赖
- 用 util / shared / basics 之类大杂烩模块兜底
- 把 Host 逻辑偷偷塞回 Core
