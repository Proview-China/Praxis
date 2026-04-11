# 2026-04-11 Swift Runtime Next-Step Reassessment

## 当前真实进度

- `Wave 0` 到 `Wave 6` 的最小闭环已经真实成立，不再只是 target 骨架。
- 本地验证结果已重新确认：
  - `swift test` 通过
  - 当前快照为 `128` tests / `39` suites
- 旧 TS 侧当前仍可作为行为参考，但不是完全健康的静态基线：
  - `npm run typecheck` 失败
  - 失败点：`src/agent_core/live-agent-chat.ts:1690`
  - 原因是 `applyCliDefaultsToCapabilityRequest(...)` 当前签名只接收 `3` 个参数，但 live chat 侧仍按 `4` 个参数调用

一句白话：

- Swift 侧现在已经是“可运行、可回放、可测”的新主路径雏形
- 旧 TS 侧仍然是重要参考，但不能把“TS 当前能否 typecheck”当作 Swift 下一步拆分的唯一依据

## 现有 Swift 落地状态

### 已经进入真实实现的层

- `PraxisRuntimeComposition`
  - 默认 profile 已切到 `localDefaults(rootDirectory:)`
  - 真实本地 adapter 已覆盖：
    - checkpoint / journal / projection / delivery truth
    - semantic memory / embedding metadata / semantic search
    - workspace reader / searcher / writer
    - system shell executor
    - system git probe / git executor
    - lineage store
    - in-process message bus
- `PraxisRuntimeUseCases`
  - `runGoal` / `resumeRun` 已真实消费 checkpoint / journal / recovery / local persistence
  - 会把最小 CMP local runtime truth 写入 projection / delivery truth / lineage / message bus
  - `inspectTap` / `inspectCmp` / `inspectMp` 已真实读取 host adapters
- `PraxisRuntimeFacades`
  - 当前已具备：
    - `runFacade`
    - `inspectionFacade`
- `PraxisRuntimeInterface`
  - 当前已具备 neutral request / response / event / codec / registry
  - 当前 command 面包括：
    - `inspectArchitecture`
    - `runGoal`
    - `resumeRun`
    - `inspectTap`
    - `inspectCmp`
    - `inspectMp`
    - `buildCapabilityCatalog`
- `PraxisRuntimeGateway`
  - CLI / 导出路径已改成优先走 `RuntimeGateway -> RuntimeInterface`
- `PraxisCLI`
  - 已经是最小可用 debug / smoke shell
  - 但仍然只应视为薄宿主，不应反向塑造 runtime contract

### 仍然明显是 scaffold 的宿主面

- `providerInferenceExecutor`
- `browserExecutor`
- `browserGroundingCollector`
- `userInputDriver`
- `permissionDriver`
- `terminalPresenter`
- `conversationPresenter`
- `audioTranscriptionDriver`
- `speechSynthesisDriver`
- `imageGenerationDriver`

这意味着：

- 当前真正做实的是 local runtime persistence / workspace / git / lineage
- provider / browser / multimodal / conversation surface 还没有进入真实 host-backed lane

## Swift 与旧 TS 的对应关系

### 已经完成第一轮承接的对应面

- Foundation
  - Swift:
    - `PraxisGoal`
    - `PraxisState`
    - `PraxisTransition`
    - `PraxisRun`
    - `PraxisSession`
    - `PraxisJournal`
    - `PraxisCheckpoint`
  - TS:
    - `src/agent_core/goal/*`
    - `src/agent_core/state/*`
    - `src/agent_core/run/*`
    - `src/agent_core/session/*`
    - `src/agent_core/journal/*`
    - `src/agent_core/checkpoint/*`

- Capability
  - Swift:
    - `PraxisCapabilityContracts`
    - `PraxisCapabilityPlanning`
    - `PraxisCapabilityResults`
    - `PraxisCapabilityCatalog`
  - TS:
    - `src/agent_core/capability-model/*`
    - `src/agent_core/capability-result/*`
    - `src/agent_core/capability-package/*`

- TAP
  - Swift:
    - `PraxisTapTypes`
    - `PraxisTapGovernance`
    - `PraxisTapReview`
    - `PraxisTapProvision`
    - `PraxisTapRuntime`
    - `PraxisTapAvailability`
  - TS:
    - `src/agent_core/ta-pool-types/*`
    - `src/agent_core/ta-pool-review/*`
    - `src/agent_core/ta-pool-provision/*`
    - `src/agent_core/ta-pool-runtime/*`
    - `src/agent_core/tap-availability/*`

- CMP Core
  - Swift:
    - `PraxisCmpTypes`
    - `PraxisCmpSections`
    - `PraxisCmpProjection`
    - `PraxisCmpDelivery`
    - `PraxisCmpGitModel`
    - `PraxisCmpDbModel`
    - `PraxisCmpMqModel`
    - `PraxisCmpFiveAgent`
  - TS:
    - `src/agent_core/cmp-runtime/*`
    - `src/agent_core/cmp-git/*`
    - `src/agent_core/cmp-db/*`
    - `src/agent_core/cmp-mq/*`
    - `src/agent_core/cmp-five-agent/*`

- HostRuntime neutral bootstrap
  - Swift:
    - `PraxisRuntimeComposition`
    - `PraxisRuntimeUseCases`
    - `PraxisRuntimeFacades`
    - `PraxisRuntimeInterface`
    - `PraxisRuntimeGateway`
  - TS:
    - `src/agent_core/runtime.ts`
    - `src/rax/runtime.ts`
    - `src/rax/facade.ts`

### 下一步最该对齐的旧 TS 表面

- `src/rax/cmp/session.ts`
- `src/rax/cmp/project.ts`
- `src/rax/cmp/flow.ts`
- `src/rax/cmp/readback.ts`
- `src/rax/cmp/roles.ts`
- `src/agent_core/cmp-service/project-service.ts`
- `src/agent_core/cmp-service/active-flow-service.ts`
- `src/agent_core/cmp-service/tap-bridge-service.ts`
- `src/agent_core/cmp-service/package-flow-service.ts`

原因：

- TS 侧已经把 CMP runtime 表面拆成了 `session / project / flow / roles / readback`
- Swift 侧目前还主要停在 `run + inspection` 两组 facade
- 如果下一步继续只补 inspection 文案或 CLI 命令，而不补 neutral runtime surface，就会错过最重要的宿主无关接口收口窗口

## 当前明确缺口

### 1. 宿主无关对外接口还不够宽

当前 `PraxisRuntimeInterface` 虽然已经是 neutral surface，但它还主要覆盖：

- run
- resume
- inspection
- catalog

它还没有把下面这些 TS 中已经显式存在的宿主表面收进 Swift 的 neutral contract：

- CMP session open / bootstrap payload normalize
- CMP project bootstrap / readback / smoke
- CMP flow ingest / commit / resolve / materialize / dispatch / history
- CMP role capability access / dispatch / peer approval

### 2. `PraxisRuntimeFacades` 还没长出真正的分面 facade

当前 facade 只有：

- `runFacade`
- `inspectionFacade`

还没有按 TS 当前已验证的分面趋势，形成下面这些更稳定的中立 facade：

- session facade
- project facade
- flow facade
- roles facade
- readback facade

### 3. provider / browser / multimodal host lanes 仍然是假实现

这块现在不适合直接推进到 CLI / GUI 交互层。

原因：

- 一旦先往 CLI / Apple UI 做厚，runtime contract 会被壳层需求反向拖拽
- 当前更应该先稳定 neutral request/response/event surface

## 下一步建议

### Priority 1: 扩 runtime neutral contract，而不是扩 CLI / GUI

首要目标应定义为：

- 在 `PraxisRuntimeUseCases + PraxisRuntimeFacades + PraxisRuntimeInterface` 内，补出宿主无关的 `session / project / flow / roles / readback` 表面

推荐新增的中立 command / DTO 面：

- `openCmpSession`
- `bootstrapCmpProject`
- `readbackCmpProject`
- `smokeCmpProject`
- `ingestCmpFlow`
- `commitCmpFlow`
- `resolveCmpFlow`
- `materializeCmpFlow`
- `dispatchCmpFlow`
- `requestCmpHistory`
- `resolveCmpRoleCapabilityAccess`
- `dispatchCmpRoleCapability`
- `approveCmpPeerExchange`

边界要求：

- CLI 只负责参数解析和文本渲染
- Apple UI 只负责展示态映射
- 不允许把这些流程先做成 CLI command-specific API

### Priority 2: 先接 CMP neutral surface，再碰 provider live lane

推荐顺序：

1. `session / project / flow / roles / readback` neutral runtime surface
2. 这批 surface 所需的本地 persistence / lineage / git receipt 丰富化
3. MP workflow neutral surface
4. provider inference / browser grounding / multimodal host-backed lane

原因：

- 当前 Core + local runtime truth 已足够支撑 CMP neutral surface 下沉
- 但 provider / browser / multimodal 仍缺真实默认 adapter，不适合现在作为主推进方向

### Priority 3: MP 先从 neutral workflow surface 进入，不要直接复制 LanceDB runtime 壳

对照旧 TS 时优先看：

- `src/rax/mp-runtime.ts`
- `src/rax/mp-facade.ts`
- `src/agent_core/mp-runtime/*`

但 Swift 侧下一步应该先做：

- MP workflow request/response contract
- memory/search/readback neutral surface

不应该先照搬：

- TS 的 LanceDB runtime 组织方式
- provider-specific payload 或 CLI-specific 展示结构

## 影响边界

### 本轮下一步应主要影响的 Swift 模块

- `PraxisRuntimeUseCases`
- `PraxisRuntimeFacades`
- `PraxisRuntimeInterface`
- `PraxisRuntimeGateway`

按需小幅补充：

- `PraxisRuntimeComposition`
- `PraxisInfraContracts`
- `PraxisToolingContracts`

### 本轮下一步不应成为主战场的模块

- `PraxisCLI`
- `PraxisAppleUI`
- 正式 `PraxisFFI`

原则：

- 可以跟着 neutral surface 做最小路由补充
- 但不应让入口壳层重新变成需求来源

## 测试要求

下一步落代码时，至少同步补下面几类验证：

- HostRuntime interface tests
  - 新的 neutral command 编解码
  - success / failure envelope
  - event buffering / drain
- HostRuntime facade / use-case tests
  - `session / project / flow / roles / readback` 的 DTO 压平与错误路径
- Local adapter integration tests
  - project bootstrap / readback / history / dispatch 对本地 persistence 的真实写读
- Architecture guard tests
  - 继续确保 CLI / AppleUI 不越层直连 Core / HostContracts

建议新增测试 target：

- `PraxisRuntimeUseCasesTests`
- `PraxisRuntimeFacadesTests`

原因：

- 当前 HostRuntime 的行为验证已经不少，但很多还聚在 architecture/surface 测试里
- 下一步 neutral surface 变宽后，应该把行为测试按 target 拓扑继续下钻

## 最终判断

截至今天，Swift 重构的下一步不应定义为：

- 做更厚的 CLI
- 做 Apple UI
- 做 provider live lane
- 做完整 FFI

而应定义为：

- 把 `RuntimeGateway -> RuntimeInterface -> RuntimeFacades -> UseCases` 这条中立运行表面，从“run + inspection”推进到“session / project / flow / roles / readback”
- 对齐的旧 TS 参考应优先看 `rax.cmp.*` 与 `cmp-service/*` 的已拆分表面，而不是重新回到 `runtime.ts` 大总装器
