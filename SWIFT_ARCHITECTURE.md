# Praxis Swift 架构蓝图

## 1. 目标

这份蓝图只回答一件事：

- Swift 重构后，系统应该按什么边界拆模块，模块之间怎么依赖，哪些东西可以复用到 Apple UI / CLI / FFI，哪些东西必须留在宿主层。

当前阶段不回答：

- 具体算法怎么写
- 具体 provider SDK 怎么接
- SwiftUI 页面怎么长
- 单个模块的函数级实现

当前架构目标只有四个：

1. 让领域核心可以独立演进，不再被 UI、SDK、CLI、数据库、消息队列绑死。
2. 让 Apple 端能用 SwiftUI 做原生宿主。
3. 让未来 Windows / Linux 或其它语言宿主可以复用 Swift 核心库。
4. 让从 TypeScript 迁移到 Swift 时有清晰的模块落点，而不是再造一个 Swift 版“大总装器”。

## 2. 非目标

当前阶段明确不做：

- 不追求一次性替换整个 TypeScript 系统
- 不追求先完成 UI
- 不追求先接全量 provider 能力
- 不追求先做性能优化
- 不追求先做跨平台 UI 统一

一句白话：

- 现在先把房屋结构设计对，再谈装修。

## 3. 总体分层

Praxis Swift 版本固定为四层。

一个硬约束：

- `Core` 只能是逻辑层名字，不能是兜底 target，也不能是兜底 product。

### L1. Core 逻辑层

职责：

- 领域模型
- 状态机
- 编排协议
- planner / governance / projection / delivery 的纯规则
- snapshot / checkpoint / replay 模型

禁止进入：

- provider SDK
- shell / `Process`
- 文件系统副作用
- 网络请求
- SQL / Redis / MQ client
- SwiftUI / AppKit / UIKit
- ANSI 终端输出

### L2. HostContracts 逻辑层

这是宿主协议层，不是实现层。

当前 phase-1 固定拆成五个 target：

- `PraxisProviderContracts`
- `PraxisWorkspaceContracts`
- `PraxisToolingContracts`
- `PraxisInfraContracts`
- `PraxisUserIOContracts`

职责：

- 定义 Core 运行时需要的外部能力协议
- 约束宿主必须提供什么能力
- 统一宿主能力输入输出的语义边界

### L3. HostRuntime 逻辑层

这是装配与应用用例层，不是“第二个核心”。

当前 phase-1 固定拆成四个 target：

- `PraxisRuntimeComposition`
- `PraxisRuntimeUseCases`
- `PraxisRuntimeFacades`
- `PraxisRuntimePresentationBridge`

职责：

- 组装 Core 功能域和 HostContracts
- 暴露稳定应用用例
- 把内部用例映射成 CLI / SwiftUI / FFI 能消费的展示桥

### L4. 宿主入口层

当前或未来的入口：

- `PraxisCLI`
- `PraxisAppleUI`
- `PraxisFFI`

职责：

- 输入输出
- 生命周期
- 用户交互
- 视图渲染
- 进程集成

硬规则：

- 所有入口只能通过 `PraxisRuntimePresentationBridge` 进入系统。

## 4. 模块切分原则

所有模块都必须遵守这四条：

1. 按功能语义切，不按技术手段切。
2. 按纯度切，不按当前文件位置切。
3. 先切所有权，再切目录。
4. 如果一个模块同时拥有规则和副作用实现，必须继续拆。

### 4.1 什么应进 Core

满足以下任一项，通常应进 Core：

- 描述对象模型
- 描述状态转移
- 描述编排规则
- 描述治理 / 授权 / 风控逻辑
- 描述协议、planner、delivery plan
- 可以在没有网络、文件系统、数据库的情况下测试

满足以下任一项，通常不能进 Core：

- 直接 import 具体 SDK
- 直接调用 shell
- 依赖本地目录结构
- 执行网络请求
- 执行数据库读写
- 直接渲染 UI
- 直接处理终端输入

## 5. 当前 phase-1 target 蓝图

这里的 “Core” 指逻辑层，不指具体 target。
当前 phase-1 target 已经按功能语义展开，后续不允许回并成 Capability / TAP / CMP / HostContracts 这种粗模块。

### 5.1 Foundation 子域

#### `PraxisCoreTypes`

职责：

- 共享 ID、枚举、边界描述、共用协议
- 为其它子域提供最小公共基座

#### `PraxisGoal`

职责：

- goal source
- goal normalize
- goal compile

#### `PraxisState`

职责：

- state projection
- state validation
- state delta 语义

#### `PraxisTransition`

职责：

- transition table
- transition guards
- next action evaluation

#### `PraxisRun`

职责：

- run lifecycle
- tick coordinator
- resume / fail / complete 流程

#### `PraxisSession`

职责：

- session header
- session hot/cold lifecycle
- run attachment
- checkpoint pointer

#### `PraxisJournal`

职责：

- append-only events
- cursor
- read-model input stream

#### `PraxisCheckpoint`

职责：

- checkpoint snapshot
- recovery envelope
- runtime snapshot serialization boundary

### 5.2 Capability 子域

#### `PraxisCapabilityContracts`

职责：

- capability 协议
- manifest
- invocation request / result envelope 的统一边界

#### `PraxisCapabilityPlanning`

职责：

- capability invocation planning
- plan compile
- capability selection / routing 的纯规则

#### `PraxisCapabilityResults`

职责：

- normalized capability output
- result mapping / status envelope

#### `PraxisCapabilityCatalog`

职责：

- capability catalog
- capability discoverability
- capability pool 语义

### 5.3 TAP 子域

#### `PraxisTapTypes`

职责：

- TAP 共享对象模型
- gate / reviewer / provision / availability 的公共类型

#### `PraxisTapGovernance`

职责：

- governance object
- policy / risk classifier
- permission / audit 规则

#### `PraxisTapReview`

职责：

- reviewer 流程语义
- tool-review / human-review 决策模型

#### `PraxisTapProvision`

职责：

- provision request
- capability/tool 供应语义

#### `PraxisTapRuntime`

职责：

- TAP 运行期编排规则
- review / provision / checkpoint 协调

#### `PraxisTapAvailability`

职责：

- capability availability
- gating / exposure / runtime ready 状态

### 5.4 CMP 子域

#### `PraxisCmpTypes`

职责：

- CMP 共用对象模型
- package / section / projection / delivery 的公共类型

#### `PraxisCmpSections`

职责：

- context section 结构
- section ownership / visibility

#### `PraxisCmpProjection`

职责：

- projection record
- lower / rebuild / materialize 的纯规则

#### `PraxisCmpDelivery`

职责：

- context package delivery
- publish / fanout / receipt planner

#### `PraxisCmpGitModel`

职责：

- Git 相关 CMP plan / model

#### `PraxisCmpDbModel`

职责：

- DB projection / persistence 相关 CMP plan / model

#### `PraxisCmpMqModel`

职责：

- MQ publish / ack / escalation 相关 CMP plan / model

#### `PraxisCmpFiveAgent`

职责：

- five-agent role protocol
- multi-agent context contract

### 5.5 HostContracts 子域

#### `PraxisProviderContracts`

职责：

- provider inference / embedding / skill / MCP 等协议

#### `PraxisWorkspaceContracts`

职责：

- workspace read / search / write 等协议

#### `PraxisToolingContracts`

职责：

- shell / browser / git / process supervision 等协议

#### `PraxisInfraContracts`

职责：

- checkpoint / journal / projection / message bus / lineage 等协议

#### `PraxisUserIOContracts`

职责：

- user input / permission / terminal presentation / conversation presentation 等协议

### 5.6 HostRuntime 子域

#### `PraxisRuntimeComposition`

职责：

- composition root
- 跨子域装配关系

#### `PraxisRuntimeUseCases`

职责：

- 高层应用用例
- run / resume / inspect / build 等编排入口

#### `PraxisRuntimeFacades`

职责：

- 对外稳定 facade
- 为不同宿主压平内部 use case 复杂度

#### `PraxisRuntimePresentationBridge`

职责：

- 把 facade / use case 映射为 CLI / UI / FFI 可消费的数据与交互边界
- 成为唯一正式入口桥

## 6. 模块依赖规则

### 6.1 单向依赖

只允许：

- `Core` -> `Core`
- `HostContracts` -> `Core`
- `HostRuntime` -> `Core`
- `HostRuntime` -> `HostContracts`
- `Entry` -> `PraxisRuntimePresentationBridge`

绝不允许：

- `Core` -> `HostContracts`
- `Core` -> `HostRuntime`
- `Core` -> `CLI/UI/FFI`
- `Core` -> provider SDK / Git / DB / MQ client / SwiftUI
- `Entry` -> 任何 Core 子模块
- `Entry` -> 任何 HostContracts target

### 6.2 Core 内部依赖方向

Foundation 层：

- `PraxisCoreTypes` 不依赖其它 Core target
- `PraxisGoal` / `PraxisState` / `PraxisSession` 尽量只依赖 `PraxisCoreTypes`
- `PraxisJournal` 只依赖 `PraxisCoreTypes` 和 `PraxisSession`
- `PraxisCheckpoint` 只依赖 `PraxisCoreTypes`、`PraxisSession`、`PraxisJournal`
- `PraxisTransition` 只依赖 `PraxisState` 和 `PraxisCoreTypes`
- `PraxisRun` 只依赖 `PraxisGoal` / `PraxisState` / `PraxisTransition` / `PraxisCoreTypes`

Capability 子域：

- `PraxisCapabilityContracts` 是 Capability 最低层
- `PraxisCapabilityPlanning` 可以依赖 `Contracts`
- `PraxisCapabilityResults` 可以依赖 `Contracts`
- `PraxisCapabilityCatalog` 可以依赖 `Contracts` 和 `Planning`
- Capability 子域不能反向依赖 TAP / CMP

TAP 子域：

- `PraxisTapTypes` 是 TAP 最低层
- `Governance` / `Review` / `Provision` / `Runtime` / `Availability` 只能在明确语义上依赖 `TapTypes`
- TAP 可以依赖 Capability 子域
- TAP 不应依赖 CMP 的宿主实现

CMP 子域：

- `PraxisCmpTypes` 是 CMP 最低层
- `Sections` / `Projection` / `Delivery` / `GitModel` / `DbModel` / `MqModel` / `FiveAgent` 只能按语义向上拼装
- CMP 可以依赖 Capability 与 TAP
- Git / DB / MQ 在这里仍是 model / planner，不是执行器

HostContracts 子域：

- 只定义协议语义
- 不承载业务规则
- 不反向依赖 HostRuntime

HostRuntime 子域：

- `PraxisRuntimeComposition` 负责知道“系统有什么”
- `PraxisRuntimeUseCases` 负责知道“系统怎么用”
- `PraxisRuntimeFacades` 负责知道“对宿主暴露什么”
- `PraxisRuntimePresentationBridge` 负责知道“入口层如何调用”

## 7. 数据所有权

这部分必须定死，否则后面又会混成一团。

### 7.1 Run / Session / Journal / Checkpoint

- `Run` 拥有单次运行生命周期状态
- `Session` 拥有长期会话挂载关系
- `Journal` 拥有事件流真相
- `Checkpoint` 拥有恢复快照真相

规则：

- `Session` 不能自己变成事件日志
- `Checkpoint` 不承担业务判断
- `Run` 不直接操作存储后端

### 7.2 Capability

- `CapabilityManifest` 拥有能力声明
- `InvocationPlan` 拥有调用计划
- `CapabilityResultEnvelope` 拥有能力输出的统一包装

规则：

- provider 原始返回体不进入 Core 真相
- 只允许 normalized result 进入 Core

### 7.3 TAP

- `TapGovernanceObject` 拥有治理上下文
- `ReviewDecision` 拥有审核结果
- `ProvisionRequest` 拥有供应意图
- `HumanGateState` 拥有人工闸门状态

规则：

- TAP 不拥有工具执行实现
- TAP 只拥有决策与授权，不拥有工具细节

### 7.4 CMP

- `CmpSection` / `StoredSection` 拥有上下文切片真相
- `ProjectionRecord` 拥有投影状态
- `ContextPackage` 拥有派送包真相
- `DeliveryRecord` 拥有投递真相

规则：

- Git / DB / MQ 是真相载体，不是领域本体
- CMP 先表达“应该发生什么”，再由宿主执行“怎么发生”

## 8. 宿主适配器策略

所有外部能力都必须通过 HostContracts 注入。

### 8.1 Provider

Core 不再直接知道：

- OpenAI `responses`
- Anthropic `messages`
- Gemini / DeepMind 原始 payload

Core 只知道：

- inference request
- structured-output request
- embedding request
- skill / MCP / search 请求

### 8.2 Git / DB / MQ

必须拆成两层：

1. Core 中的 model / planner
2. Host 中的 executor / store / bus

例如：

- `CmpGitPlan` 属于 Core
- `GitExecutor` 属于 HostContracts，具体实现属于宿主

- `CmpProjectionUpsertPlan` 属于 Core
- `ProjectionStore` 属于 HostContracts，具体实现属于宿主

- `CmpDeliveryPublishPlan` 属于 Core
- `MessageBus` 属于 HostContracts，具体实现属于宿主

### 8.3 CLI / UI / FFI

CLI / SwiftUI / FFI 都只能调用 `PraxisRuntimePresentationBridge`。

禁止：

- UI 直接 import Core 子域后拼业务状态
- UI 直接调用 provider
- CLI 直接操作 Git / DB / MQ
- FFI 直接暴露内部 target 细节

## 9. 跨平台导出策略

跨平台可复用的对象只能是：

- Core 功能子域的稳定数据与规则
- HostRuntime 暴露的稳定用例边界

推荐顺序：

1. 先稳定 Foundation + Capability + TAP + CMP 的功能子域
2. 再稳定 `PraxisRuntimeUseCases` / `PraxisRuntimeFacades`
3. 最后稳定 `PraxisRuntimePresentationBridge`
4. 最后才定义 C ABI / FFI facade

FFI 层应导出：

- 纯数据结构
- 明确错误码
- 稳定版本号
- 不含 SwiftUI / Apple 平台对象

不应导出：

- Swift 内部实现细节
- 闭包泛滥接口
- provider SDK 原始对象

## 10. Apple 端架构

Apple 端建议固定成：

- `PraxisAppleUI`
  - SwiftUI scene / view / view state
- `PraxisRuntimePresentationBridge`
  - 宿主可消费展示桥
- `PraxisRuntimeFacades` / `PraxisRuntimeUseCases`
  - 应用服务
- Core 功能子域
  - 领域核心

### 10.1 SwiftUI 层原则

- 用 ViewState / StateSnapshot 驱动
- 不直接渲染 Core 内部对象树
- 不在 View 内执行业务判断
- 不在 View 层做 provider routing

### 10.2 多系统复用原则

可以共享：

- Core 功能子域
- `PraxisRuntimeUseCases`
- `PraxisRuntimeFacades`
- 必要时一部分 presentation-facing state

不强求共享：

- 终端交互体验
- 桌面和移动端布局
- 调试视图

## 11. 迁移规则

### 11.1 迁移顺序

只能按下面顺序推进：

1. 先迁纯模型和状态机
2. 再迁 planner / governance / protocol
3. 再接 HostContracts
4. 再接宿主执行器
5. 最后才接 CLI / SwiftUI / FFI live 路径

### 11.2 迁移禁区

在 Core 还没稳定前，不要做：

- 把 `live-agent-chat` 直接翻译成 Swift
- 把 `runtime.ts` 原样翻成 Swift 版大总装器
- 把 provider payload builder 原样照搬
- 让 SwiftUI 直接吞 Core 内部对象

## 12. 架构验收清单

满足以下条件，才算架构设计达标：

- Core 不依赖任何具体宿主技术
- 模块依赖严格单向
- Core 不存在兜底 target
- Capability / TAP / CMP 都已按功能子模块拆开
- HostContracts 已按五个协议族拆开
- HostRuntime 已按四个运行期职责拆开
- Entry 只经由 `PraxisRuntimePresentationBridge` 进入
- run/session/journal/checkpoint 所有权明确
- FFI 路径被预留，但没有提前污染 Core

## 13. 当前阶段一句话原则

先把 Praxis 设计成“可导出的功能核心 + 可替换的宿主协议层 + 可重组的运行时装配层 + 可重建的 UI 层”，再考虑任何实现细节。

最后再强调一次：

- 不允许出现一个叫 `Core` 的万能模块去兜底所有领域逻辑。
