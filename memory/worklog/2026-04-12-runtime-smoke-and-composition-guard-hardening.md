# 2026-04-12 Runtime Smoke And Composition Guard Hardening

## 本次落地内容

- 这次接管并整合了一批遗留在主工作区里的未提交改动，并按当前代码事实收口成一个单一意图包：
  - `runtime smoke` 的宿主无关 gate/status typed surface
  - `HostRuntime composition` 的最小守卫测试
  - `CMP peer approval` 对显式人工结论的行为回归测试
- 这一包没有扩 CLI、UI 或 platform 侧行为，仍然只收紧 host-neutral middle layer 及其验证。

一句白话：

- runtime smoke 现在不再把 gate/status 当自由字符串透传；同时 composition root 和 peer-approval 的几条关键回归路径也被补上了测试钉子。

## 语义收紧

- 新增 `PraxisRuntimeSmokeGate`，把 runtime smoke 的门位真相收紧为稳定 typed enum：
  - `host`
  - `memory-store`
  - `semantic-search`
  - `provider-inference`
  - `browser-grounding`
- 新增 `PraxisRuntimeTruthLayerStatus`，把 runtime smoke 当前外显状态收紧为最小 typed enum：
  - `ready`
  - `degraded`
  - `missing`
- `PraxisRuntimeSmokeCheckRecord` 与 façade `PraxisRuntimeSmokeCheck` 现在统一使用这两类 host-neutral typed contract，不再依赖自由字符串。
- `PraxisMpHostInspectionService.smoke(...)` 现在直接生成 typed `gate/status`，不再在 use case 层拼接自由字符串状态。
- façade `mapSmokeResult(...)` 不再做字符串桥接，而是直接保留 typed smoke 真相。

## 测试

- 本次补齐和更新的验证覆盖：
  - runtime smoke use case record 的 JSON roundtrip
  - façade/runtime surface smoke snapshot 的 JSON roundtrip
  - runtime smoke 对未知 `gate/status` raw value 的 decode failure
  - MP smoke façade 对 typed `gate/status` 的正向断言
  - composition bootstrap validator 的空 boundary / 重名 boundary 失败断言
  - composition root 对 registry 输入和 dependency graph 透传的守卫断言
  - scaffold/local host adapter factory 的最小 provision guard
  - CMP peer approval 在 `approve / reject / release` 三种显式人工决策下，对：
    - decision result
    - approval readback
    - TAP status
    - TAP history
    的一致性回归断言
- 本地验收：
  - `swift test --filter PraxisRuntimeUseCasesTests`
  - `swift test --filter PraxisRuntimeFacadesTests`
  - `swift test --filter HostRuntimeInterfaceTests`
  - `swift test`
- 结果：
  - `289 tests / 53 suites` 通过
- 复审结果：
  - `无 findings`

## 残余限制

- `RuntimeInterface` 当前对 MP smoke 仍然主要暴露 summary-oriented snapshot，没有把 runtime smoke 的 typed gate/status 直接扩成一组独立 interface surface。
- façade 层旧的 `PraxisTruthLayerStatus` 仍然存在；这次新增的 `PraxisRuntimeTruthLayerStatus` 只用于 runtime smoke 这条链路，没有顺手做全局合并。
- `HostRuntimeCompositionGuardTests` 当前把 `scaffoldDefaults().terminalPresenter != nil` 当成默认守卫；如果后续引入真正的 headless scaffold profile，需要重新审视这个断言是否仍然成立。

## 下一包入口

- 第 2 包 `CMP neutral surface hardening` 还没有结束，下一段应继续收紧剩余的 stringly / weakly-typed CMP contract，而不是回头扩 UI 或 provider 细节。
- 当前更自然的下一个切口仍是：
  - `roles latestStage / roleStages`
  - 以及与其邻接的 readback / interface surface typed 化
