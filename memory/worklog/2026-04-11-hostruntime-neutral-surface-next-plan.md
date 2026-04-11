# 2026-04-11 HostRuntime Neutral Surface Next Plan

## 当前结论

- 截至今天，Swift 重构主线已经不再停留在 target scaffold。
- `Wave 0` 到 `Wave 6` 的最小闭环已经真实成立：
  - Foundation / Capability / TAP / CMP Core 已有最小可验证实现
  - HostContracts 已冻结结构化宿主协议
  - HostRuntime 已经具备 `Composition -> UseCases -> Facades -> Interface -> Gateway` 的闭环
- 当前真正的下一步，不是继续做 CLI 或 Apple UI 壳，而是把 HostRuntime 的“宿主无关对外接口”继续收紧和补齐。

一句白话：

- 核心规则层已经站住了。
- 现在最需要做的是把中立 runtime surface 做稳，不要让 CLI / GUI 重新变成系统入口和需求来源。

## 这次核对到的真实事实

### 1. Swift HostRuntime 已经超过“只有 run + inspection”

当前 Swift 侧已经存在：

- `PraxisRuntimeUseCases`
  - `openCmpSession`
  - `readbackCmpProject`
  - `bootstrapCmpProject`
  - `recoverCmpProject`
  - `ingestCmpFlow`
  - `commitCmpFlow`
  - `resolveCmpFlow`
  - `materializeCmpFlow`
  - `dispatchCmpFlow`
  - `retryCmpDispatch`
  - `requestCmpHistory`
  - `readbackCmpRoles`
  - `readbackCmpControl`
  - `updateCmpControl`
  - `requestCmpPeerApproval`
  - `decideCmpPeerApproval`
  - `readbackCmpPeerApproval`
  - `readbackCmpStatus`
  - `smokeCmpProject`
- `PraxisRuntimeFacades`
  - `runFacade`
  - `inspectionFacade`
  - `cmpFacade`
- `PraxisRuntimeInterface`
  - 已有对应的 typed command kind 和 request payload

这意味着：

- 之前“Swift 还只有 run / inspection neutral surface”这个判断已经部分过时。
- 现在更准确的说法是：
  - CMP neutral commands 已经进入 Interface / Facade / UseCase
  - 但分面仍偏“大 cmpFacade + architecture tests”
  - 行为测试和长期稳定 facade 形状还不够独立、不够成体系

### 2. TS 侧已经把 CMP 宿主表面拆得很清楚

当前旧 TS 应优先对照的分面，不再是 `runtime.ts` 平铺方法，而是：

- `src/rax/cmp/session.ts`
  - session open
  - bootstrap payload normalize
- `src/rax/cmp/project.ts`
  - bootstrap
  - readback
  - smoke
- `src/rax/cmp/flow.ts`
  - ingest
  - commit
  - resolve
  - materialize
  - dispatch
  - requestHistory
- `src/rax/cmp/roles.ts`
  - capability access
  - capability dispatch
  - peer approval
- `src/rax/cmp/control.ts`
  - manual control surface
  - automation gate
  - dispatch scope
  - truth preference
- `src/rax/cmp/readback.ts`
  - readback summary
  - readiness / smoke synthesis

这说明：

- Swift 下一步应该继续顺着 `session / project / flow / roles / control / readback` 这些分面做稳定表面。
- 不应该再回到“补一个更大的 runtime facade”或者“直接贴 CLI command API”的路线。

### 3. TS runtime service 下沉现状也已经给出了优先级

优先作为 Swift 行为对照的 service：

- `src/agent_core/cmp-service/project-service.ts`
  - bootstrap receipt
  - recovery summary
  - delivery truth
  - timeout sweep
- `src/agent_core/cmp-service/active-flow-service.ts`
  - ingest / resolve 纯主链已明显下沉
- `src/agent_core/cmp-service/tap-bridge-service.ts`
  - role capability access
  - capability dispatch
  - peer approval

暂时不要过早固化为“稳定 Swift facade 真相”的部分：

- `src/agent_core/cmp-service/package-flow-service.ts`
  - 仍主要是 runtime 转发壳
- `active-flow-service.ts` 的 `commit`
  - 还存在继续下沉空间

这意味着：

- Swift 应优先对齐已经稳定拆开的 TS 表面。
- 不要对齐 TS 里还明显在迁移中的 runtime forwarding shape。

## 当前 Swift 与旧 TS 的模块对应

### 已完成第一轮承接

- Foundation
  - Swift: `PraxisGoal` / `PraxisState` / `PraxisTransition` / `PraxisRun` / `PraxisSession` / `PraxisJournal` / `PraxisCheckpoint`
  - TS: `src/agent_core/goal/*` / `state/*` / `transition/*` / `run/*` / `session/*` / `journal/*` / `checkpoint/*`
- Capability
  - Swift: `PraxisCapabilityContracts` / `PraxisCapabilityPlanning` / `PraxisCapabilityResults` / `PraxisCapabilityCatalog`
  - TS: `src/agent_core/capability-model/*` / `capability-result/*` / `capability-package/*`
- TAP
  - Swift: `PraxisTapTypes` / `PraxisTapGovernance` / `PraxisTapReview` / `PraxisTapProvision` / `PraxisTapRuntime` / `PraxisTapAvailability`
  - TS: `src/agent_core/ta-pool-types/*` / `ta-pool-review/*` / `ta-pool-provision/*` / `ta-pool-runtime/*` / `tap-availability/*`
- CMP Core
  - Swift: `PraxisCmpTypes` / `PraxisCmpSections` / `PraxisCmpProjection` / `PraxisCmpDelivery` / `PraxisCmpGitModel` / `PraxisCmpDbModel` / `PraxisCmpMqModel` / `PraxisCmpFiveAgent`
  - TS: `src/agent_core/cmp-runtime/*` / `cmp-git/*` / `cmp-db/*` / `cmp-mq/*` / `cmp-five-agent/*`
- HostRuntime neutral bootstrap
  - Swift: `PraxisRuntimeComposition` / `PraxisRuntimeUseCases` / `PraxisRuntimeFacades` / `PraxisRuntimeInterface` / `PraxisRuntimeGateway`
  - TS: `src/agent_core/runtime.ts` / `src/rax/runtime.ts` / `src/rax/facade.ts`

### 下一轮最重要的对照面

- Swift `PraxisRuntimeFacades.cmpFacade`
- Swift `PraxisRuntimeInterface` CMP command/request/response surface
- Swift `PraxisRuntimeUseCases` 中 CMP session / project / flow / roles / readback 行为
- TS `src/rax/cmp/*`
- TS `src/agent_core/cmp-service/project-service.ts`
- TS `src/agent_core/cmp-service/active-flow-service.ts`
- TS `src/agent_core/cmp-service/tap-bridge-service.ts`

## 下一步的主目标

下一轮建议定义为：

- `HostRuntime neutral surface hardening`

而不是：

- CLI 功能扩张
- Apple UI 扩张
- provider live lane 扩张
- 把 `runtime.ts` 剩余部分继续直接翻 Swift

### 目标 A: 把 `cmpFacade` 继续收敛成更稳定的分面

建议在 `PraxisRuntimeFacades` 内显式形成下列子面：

- `sessionFacade`
- `projectFacade`
- `flowFacade`
- `rolesFacade`
- `readbackFacade`

是否保留总的 `cmpFacade` 容器都可以，但要求是：

- 外部稳定语义来自这些分面
- 不要再让所有 CMP 对外能力都堆成一个继续膨胀的 `cmpFacade`

### 目标 B: 把 Interface contract 与 facade 分面一一对齐

`PraxisRuntimeInterface` 下一轮要重点确认并固定：

- command kind 与 payload 的对应关系
- 每个 CMP command 对应的 snapshot / error envelope
- event emission 是否保持宿主无关

原则：

- interface 只暴露 neutral request / response / event
- CLI 只解析参数和渲染文本
- Apple UI 只消费 bridge / presentation mapping
- 不允许为了 CLI 使用方便而把 runtime command 设计成 CLI-specific API

### 目标 C: UseCase 继续对齐 TS 中已经稳定下沉的 service 行为

优先对齐：

- project bootstrap / recovery / delivery truth / timeout advance
- flow ingest / resolve / history request
- roles capability access / capability dispatch / peer approval

暂缓过度定型：

- package-flow forwarding shape
- TS 中仍明显未收稳的 commit/service 拆分细节

## 明确影响边界

### 本轮应该成为主战场的 Swift 模块

- `PraxisRuntimeFacades`
- `PraxisRuntimeInterface`
- `PraxisRuntimeUseCases`
- `PraxisRuntimeGateway`

按需补充：

- `PraxisRuntimeComposition`
- `PraxisInfraContracts`
- `PraxisToolingContracts`

### 本轮不应成为主战场的模块

- `PraxisCLI`
- `PraxisAppleUI`
- `PraxisRuntimePresentationBridge`
- 未来正式 `PraxisFFI`

这些入口层当前可以做的只有：

- 最小路由补充
- 最小 smoke 验证补充
- 最小展示映射补充

不应该做的包括：

- 直接绕过 `RuntimeGateway -> RuntimeInterface`
- 直接依赖 Core 或 HostContracts
- 因为入口层体验诉求，反向改写 neutral runtime contract

## 测试策略

下一轮如果继续补 HostRuntime neutral surface，测试不能只靠 architecture tests 兜底。

至少要同步补：

### 1. Runtime interface 行为测试

- 新 command 的 JSON 编解码
- success / failure envelope
- event snapshot / drain 语义
- session registry handle 行为

### 2. Runtime facade 行为测试

- `session / project / flow / roles / readback` DTO 压平
- facade summary / snapshot 稳定性
- 错误路径不泄漏底层实现细节

### 3. UseCase 行为测试

- bootstrap / readback / history / dispatch 对本地持久化的真实读写
- peer approval / control update / retry dispatch 的状态变化
- recovery / smoke / timeout advance 的 receipt 与 summary

### 4. 架构守卫测试

- CLI / AppleUI 仍只能经由 `RuntimeGateway -> RuntimeInterface`
- PresentationBridge 不回灌成跨宿主总入口
- HostRuntime 不直接吸收 CLI / UI 细节

## 建议新增的测试 target

- `PraxisRuntimeUseCasesTests`
- `PraxisRuntimeFacadesTests`

原因：

- 现在很多 HostRuntime 验证还混在 architecture / surface tests 里。
- 如果 neutral surface 继续变宽，不把行为测试按 target 拆出来，后面会越来越难看出是哪一层坏了。

## 最终判断

从当前代码事实看，下一步最合理的推进顺序是：

1. 收紧 `PraxisRuntimeFacades` 的 CMP 分面结构
2. 校准 `PraxisRuntimeInterface` 对这些分面的 neutral contract
3. 用独立的 use-case / facade tests 承接行为验证
4. 只给 CLI / AppleUI 做最小接线，不让它们重新成为中心

一句白话：

- 先把“系统能被任何宿主稳定调用”这件事做扎实。
- 不要先把“某个宿主更好看、更好用”做厚。
