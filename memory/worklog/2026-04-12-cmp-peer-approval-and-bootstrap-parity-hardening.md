# 2026-04-12 CMP Peer Approval And Bootstrap Parity Hardening

## 本次落地内容

- 第 2 包继续留在 `CMP neutral surface hardening` 范围内，这次连续收口了两条紧邻的小段：
  - `CMP peer-approval / tap status typed surface hardening`
  - `CMP bootstrap componentStatuses parity`
- 由于两段都落在同一组未提交文件上，且第二刀是为恢复全量 `swift test` 绿色而补的极小 parity 修复，因此这次以一批代码状态统一收尾。

一句白话：

- peer approval / tap status 现在不再靠字符串传关键流程状态；同时 bootstrap project surface 补上了之前掉掉的 `.gitProbe` component status。

## 语义收紧

- `requestedTier / route / outcome / tapMode / riskLevel / humanGateState` 已从 use case 真相层贯通到 façade DTO / façade surface，不再只在 façade 外层换皮。
- 本次新增最小 typed 模型：
  - `PraxisCmpPeerApprovalOutcome`
- 本次复用的既有 typed 模型：
  - `PraxisTapCapabilityTier`
  - `PraxisTapMode`
  - `PraxisTapRiskLevel`
  - `PraxisHumanGateState`
  - `PraxisReviewerRoute`
- `PraxisTapStatusReadback`、`PraxisTapHistoryEntry`、`PraxisCmpPeerApproval`、`PraxisCmpPeerApprovalReadback` 现在都使用宿主无关 typed contract。
- 非法 raw value 不再静默吞掉：
  - persisted peer approval descriptor 会经由 `cmpPeerApprovalSurfaceFields(...)` 强解码
  - façade snapshot `Codable` 对未知 `route / outcome / tapMode / riskLevel / humanGateState` 会直接失败
- `summary / readinessSummary / decisionSummary` 仍只是展示文本，没有被抬成业务真相字段。
- bootstrap project surface 现在补上：
  - `componentStatuses[.gitProbe]`
- 当前 bootstrap 真相源只有合并后的 `gitAvailable` 语义，因此 `.gitProbe` 与 `.gitExecutor` 暂时共用同一条最小映射：
  - `.bootstrapped / .alreadyExists -> .ready`
  - `.conflicted -> .degraded`

## 测试

- 本次补齐和更新的验证覆盖：
  - peer approval / tap status façade snapshot 正向 typed assertions
  - façade snapshot JSON raw-value roundtrip
  - 非法 `route / outcome / tapMode / riskLevel / humanGateState` decode failure
  - use case 层 persisted corrupted peer-approval raw value failure
  - TAP history/status 对 typed route/outcome/human-gate 的正向断言
  - bootstrap façade / runtime surface 对 `.gitProbe` parity 的正向断言
- 本地验收：
  - `swift test --filter PraxisRuntimeUseCasesTests`
  - `swift test --filter PraxisRuntimeFacadesTests`
  - `swift test --filter HostRuntimeSurfaceTests`
  - `swift test --filter runtimeInterfaceCmpApprovalEventDetailsFollowDecisionSummaryContract`
  - `swift test`
- 结果：
  - `263 tests / 52 suites` 通过
- 复审结果：
  - peer-approval / tap-status 小段：`无 findings`
  - bootstrap parity 小段：`无 findings`

## 残余限制

- `PraxisCmpPeerApprovalOutcome` 目前定义在 `PraxisUseCaseCommands.swift`；如果后续还要把同一 typed contract 上提到更共享的位置，这里会是下一步 seam，但当前不构成 bug。
- façade 级 decode 负向覆盖目前没有单独钉住坏 `requestedTier` raw value；已有代表性覆盖集中在 `route / outcome / tapMode / riskLevel / humanGateState`。
- bootstrap 侧目前还不能区分“git probe 坏了”还是“git executor 坏了”；这轮只做了最小 parity，没有扩建更细粒度的 bootstrap 真相模型。
- TAP history 里为了统一 typed contract，对若干 dispatch/tap 事件使用了 host-neutral route/outcome 映射；如果后续需要把“peer approval”与“dispatch gate”事件彻底拆成不同 typed event family，需要单独设计新的 neutral history surface，而不是回退成字符串。

## 下一包入口

- 第 2 包还剩的优先收口点，应继续瞄准 CMP 外显 contract 里仍然 stringly/weakly-typed 的部分，而不是回头重做已经 typed 化的 peer approval / tap status。
- 下一段更合理的方向：
  - `peer-approval` 邻接的其它弱类型字段是否需要继续 typed 化
  - `CMP project / readback / status` 里剩余的 stringly contract
  - 在不破坏宿主无关边界的前提下，把 façade / interface / presentation 的职责继续拆清
