# 2026-04-11 Next Swift Refactor Target Assessment

## 当前结论

> 2026-04-11 later update:
> 这份评估里原先把 `minimal CLI runtime entry` 放在了较高优先级。
> 当前已调整策略为：
> 优先保持 `RuntimeInterface / FFIBridge / PraxisFFI` 的中立导出边界，
> 暂时尽量不深入 CLI / GUI 产品实现。

- Swift 重构到今天为止，`Wave 0` 到 `Wave 6` 的“最小可验证闭环”已经基本成立。
- 现在最大的缺口已经不是 target 拆分，也不是 Core 规则缺名词，而是：
  - 默认 HostRuntime 仍依赖 `scaffoldDefaults()`
  - `PraxisCLI` 仍是 print scaffold
  - `PraxisAppleUI` 仍是 blueprint list 壳
- 因此下一步最值得做的，不是继续扩桥层文案，也不是提前做完整 FFI，而是把 Swift/macOS 主路径推进到：
  - real local-runtime adapters
  - minimal usable CLI session surface

一句白话：

- Core、Contracts、Runtime surface 已经“有骨架且能测”
- 现在要开始把“假的宿主”换成“真的本地宿主”

## 为什么是这个顺序

### 1. Core / Contracts / Runtime interface 已经足够稳定

- `SWIFT_REFACTOR_PLAN.md` 已明确：
  - Wave 1 Foundation 完成
  - Wave 2 Capability 完成
  - Wave 4 CMP 完成
  - Wave 5 HostContracts 完成
  - Wave 6 HostRuntime 已基本覆盖到当前阶段所需接口可用性
- 本地 `swift test` 已再次确认通过，当前是 `113` 个测试通过。

这意味着：

- 继续补 target 骨架的收益已经明显下降
- 现在更缺的是“真实承接宿主能力”的增量

### 2. 当前 Swift 最大的真实空洞在 host adapters，而不是 Core

- `PraxisRuntimeComposition` 仍默认走 `PraxisHostAdapterRegistry.scaffoldDefaults()`
- 这些 scaffold adapter 会返回 placeholder inference、fake checkpoint/journal/projection/message bus、stub semantic search
- `PraxisInspectCmpUseCase`、`PraxisInspectMpUseCase` 现在虽然已经是 host-backed inspection，但读到的仍主要是 fake/stub adapter 状态

这意味着：

- 现在 inspection 已经能看“有没有接线”
- 但接上的大多还是假的本地实现

### 3. Entry 还不值得先做重 UI

- `PraxisCLI/main.swift` 仍只是 bootstrap print
- `PraxisAppleUI` 仍主要展示 blueprint list
- 如果现在先做更复杂的 CLI / Apple UI 页面，而底层仍是 scaffold adapters，会上演“桥层越来越厚、宿主仍不真实”的问题

所以：

- Entry 应该跟在“最小真实本地 runtime”之后推进
- 先让 CLI 能吃到真实 local runtime，再谈更丰富的交互壳

## 建议的下一目标

建议把下一轮主目标定义为：

- `Wave 6.5: macOS local runtime adapters + minimal CLI runtime entry`

注意：

- 这不是新增 wave 编号到主计划里
- 只是为了表达“仍属于 Wave 6 -> Wave 7 的过渡段”

## 目标拆解

### A. 先把 `scaffoldDefaults()` 替换成真实的本地默认装配

优先落点：

- `PraxisRuntimeComposition`

建议新增的子模块面：

- `LocalPersistence`
- `LocalMessageBus`
- `LocalGitProbe`
- `LocalSemanticIndex`
- `LocalProviderBridge`

这些子模块面默认不新增 target，而是落在既有 `PraxisRuntimeComposition` 内部。

原因：

- 只有 `PraxisRuntimeComposition` 可以知道具体 adapter 实现类
- 当前也不建议再为了 adapter 新增一层“大 host adapter target”

### B. 先打通最小真实链路，而不是一次做满

推荐第一批真实接入顺序：

1. checkpoint / journal / projection / delivery truth
2. message bus
3. git readiness probe
4. semantic memory + semantic search baseline
5. provider inference baseline

推荐原因：

- 前三项先把 `inspectCmp` 和 `run/resume` 的“本地真相底座”做实
- 后两项再让 `inspectMp` 与最小 provider-backed orchestration 变得真实

### C. CLI 先承接最小命令式 runtime，不先复制旧 TS live chat

`PraxisCLI` 下一步应先支持：

- `inspect-architecture`
- `inspect-tap`
- `inspect-cmp`
- `inspect-mp`
- `run-goal`
- `resume-run`
- `events`

暂时不建议先搬：

- `src/agent_core/live-agent-chat.ts`
- `src/agent_core/live-agent-chat/ui.ts`

原因：

- 旧 TS live chat 是成熟度更高的宿主壳
- 但它耦合了 OpenAI live 请求、终端渲染、direct/full UI mode、日志、browser grounding 展示
- 现在直接搬，会把 CLI 宿主先做成第二个大总装器

## 需要对照的旧 TS 代码

下一轮不需要整包搬旧 TS，但以下代码必须作为对照来源：

### 一类：Runtime composition / host-backed workflow

- `src/agent_core/runtime.ts`
- `src/rax/runtime.ts`
- `src/rax/facade.ts`

用途：

- 只读“系统是怎么装起来的、宿主入口要什么稳定表面”
- 不按文件结构翻译

### 二类：CMP 已拆开的宿主表面

- `src/rax/cmp/session.ts`
- `src/rax/cmp/project.ts`
- `src/rax/cmp/flow.ts`
- `src/rax/cmp/control.ts`
- `src/rax/cmp/readback.ts`
- `src/rax/cmp/roles.ts`

用途：

- 作为 Swift `RuntimeFacades` / `RuntimeUseCases` 的宿主接口对照
- 特别是 session / project / flow / readback 的分面，不要重新糊回一个 facade

### 三类：CMP service 下沉现状

- `src/agent_core/cmp-service/project-service.ts`
- `src/agent_core/cmp-service/active-flow-service.ts`
- `src/agent_core/cmp-service/package-flow-service.ts`
- `src/agent_core/cmp-service/tap-bridge-service.ts`

用途：

- 判断哪些 runtime 逻辑已经在 TS 侧下沉成 service
- Swift 下一步优先对齐 project / flow / tap bridge 这些分面，而不是回头对齐大 runtime 方法

特别注意：

- `package-flow-service.ts` 仍主要是 runtime 转发壳
- `active-flow-service.ts` 的 `commit` 仍有继续下沉空间
- 这意味着 Swift 侧不应该急着把这块固定成又一个大 runtime facade

### 四类：MP / provider / multimodal 对照面

- `src/agent_core/mp-runtime/*`
- `src/agent_core/mp-lancedb/*`
- `src/rax/mp-runtime.ts`
- `src/rax/mp-facade.ts`
- `src/agent_core/integrations/*`
- `src/integrations/*`

用途：

- 只对照 MP workflow、semantic memory/search、provider bridge 语义
- 不把 LanceDB / 线上 provider payload 原样投到 Swift 主路径

### 五类：CLI / live shell 参考，但不直接迁移

- `src/agent_core/live-agent-chat.ts`
- `src/agent_core/live-agent-chat/ui.ts`
- `src/agent_core/live-agent-chat/shared.ts`

用途：

- 仅作为 CLI session、event replay、terminal presentation 的体验参考
- 不作为 Swift CLI 第一阶段的实现蓝本

## 将要补实现的 Swift 模块

建议下一轮主要落在以下模块。

### 第一优先级

- `PraxisRuntimeComposition`
  - 增加真实本地 adapter 组装入口
  - 让默认 macOS profile 不再只返回 scaffold fake/stub
- `PraxisRuntimeUseCases`
  - 先消费真实 checkpoint/journal/projection/message bus/git probe
  - 把 inspection 和 run/resume 的 receipt 建立在真实 local runtime adapter 上
- `PraxisCLI`
  - 若保留，只承担 debug / smoke / 开发验证用的薄适配层
  - 不作为当前阶段必须优先深化的主路径

### 第二优先级

- `PraxisRuntimeFacades`
  - 对外提供更稳的 session / project / flow facade 压平面
- `PraxisRuntimePresentationBridge`
  - 仅补 state/event mapping
  - 不反向吸收 CLI 解析与终端渲染
- `PraxisRuntimeInterface`
  - 维持 neutral contract
  - 为 CLI/FFI 提供统一 request/response/event 面

### 暂缓

- `PraxisAppleUI`
- 正式 `PraxisFFI`

原因：

- 两者现在都建立在 HostRuntime 已经足够真实的前提上
- 当前先做会把宿主壳推进得比本地 runtime 更快

## 建议的实现步骤

### Step 1. 固化 local runtime profile builder

在 `PraxisRuntimeComposition` 内新增：

- 本地 SQLite-backed store builder
- actor/AsyncStream message bus builder
- system git probe builder
- semantic memory/search baseline builder

验收：

- 无参默认 factory 不再只是 scaffold fake/stub
- `HostRuntimeSurfaceTests` 仍通过
- 新增 adapter-level tests

### Step 2. 让 `inspectCmp` 和 `run/resume` 优先吃真实本地底座

重点：

- checkpoint / journal recovery
- projection / delivery truth describe
- message bus availability
- git readiness

验收：

- inspection 摘要不再主要描述 fake adapter
- run / resume 的 checkpoint/journal 行为不再只停留在 fake store

### Step 3. 接通最小 provider inference lane

目标：

- 让 `runGoal` 的 follow-up 不只停留在 rule receipt
- 给后续 CLI session 接一条最小 provider-backed lane

边界：

- 不在这一步接完整 TAP/CMP 五角色 live
- 先接单 lane、单 capability、单 receipt

### Step 4. CLI 若继续存在，只保持最小验证态

目标：

- 命令路由
- state summary
- event replay/snapshot
- resume by run id

边界：

- 不先做 full-screen TUI
- 不先搬 direct/full 双 UI mode
- 不先搬 browser grounding 呈现细节
- 不让 CLI 成为其它语言 UI 的上游依赖

## 影响范围

### 会直接受影响的 Swift 目录

- `Sources/PraxisRuntimeComposition/`
- `Sources/PraxisRuntimeUseCases/`
- `Sources/PraxisRuntimeFacades/`
- `Sources/PraxisRuntimePresentationBridge/`
- `Sources/PraxisRuntimeInterface/`
- `Sources/PraxisCLI/`

### 会同步受影响的测试

- `Tests/PraxisHostRuntimeArchitectureTests/`
- 可能新增 local runtime adapter 测试
- 可能新增 CLI surface 测试

### 当前不建议直接动的区域

- `Sources/PraxisAppleUI/`
- `SWIFT_REFACTOR_PLAN.md`
- 大量 `docs/ability/*`

原因：

- 当前问题不是再写更多计划
- 而是把既有 plan 真正推进到真实本地 runtime

## 风险与 guard rail

### 风险 1

- `PraxisRuntimeComposition` 容易变成“大 adapter 垃圾桶”

防线：

- 只允许它知道 concrete types
- 但 adapter 仍按 local persistence / bus / git / semantic / provider 子面分文件

### 风险 2

- `PraxisRuntimeUseCases` 容易长回第二个 `runtime.ts`

防线：

- use case 只做 orchestration
- Core 决策继续留在对应 domain target
- host effect 继续收在 contracts + adapter 层

### 风险 3

- CLI 容易过早复制旧 TS live chat

防线：

- 第一阶段只做命令式 surface
- 不做完整交互 shell
- 不把 provider streaming、terminal decoration、browser grounding UI 一起搬进来

## 最终判断

- 下一步最合理的重构目标，不是继续扩 Swift target，也不是恢复旧 TS 宿主壳。
- 最值得做的是：
  - 以 `PraxisRuntimeComposition` 为中心，把 macOS local runtime 的真实默认 adapter 接进来
  - 以 `PraxisRuntimeUseCases` 为核心，把 inspection / run / resume 建立在真实本地底座上
  - 再让 `PraxisCLI` 承接最小可用宿主入口

一句白话收尾：

- 下一轮要证明的，不再是“Swift 架构拆得对”
- 而是“Swift 这套拆法，已经能支撑一个真实可跑的本地 runtime”
