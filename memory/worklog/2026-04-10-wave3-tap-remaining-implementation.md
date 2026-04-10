# 2026-04-10 Wave 3 TAP Remaining Implementation

## 这轮补了什么

在 `PraxisTapTypes` 和 `PraxisTapGovernance` 之后，本轮把 wave3 剩余四块也推进到了“有真实规则”的阶段：

- `PraxisTapReview`
- `PraxisTapProvision`
- `PraxisTapRuntime`
- `PraxisTapAvailability`

目标不是一步做到完整 live runtime，而是先把 review / provision / runtime / availability 的 Core 规则面补齐，方便统一 review。

## Review

`PraxisTapReview` 现在新增了：

- `PraxisReviewRoutingOutcome`
- `PraxisReviewInventory`
- richer `PraxisReviewDecision`
- `PraxisReviewRoutingResult`
- `PraxisReviewDecisionEngine.route(...)`
- `PraxisReviewerCoordinator.record(...)`

当前已经能表达的纯规则：

- baseline approved
- review required
- redirected to provisioning
- escalated to human
- denied

当前仍然刻意没有实现的内容：

- reviewer worker bridge
- model hook
- tool execution/runtime handoff

## Provision

`PraxisTapProvision` 现在新增了：

- `PraxisProvisionReplayPolicy`
- `PraxisProvisionAssetStatus`
- richer `PraxisProvisionRequest`
- richer `PraxisProvisionAsset`
- richer `PraxisProvisionPlan`
- `PraxisProvisionRegistry`
- `PraxisProvisionPlanner.plan(...)`

当前规则层已经能做：

- capability + mode 过滤资产
- 只选择 `ready_for_review / active` 资产
- 生成 verification plan
- 生成 rollback plan
- 根据 replay policy / 是否命中资产给出 `requiresApproval`

当前仍然刻意没有实现的内容：

- provision worker bridge
- model-backed provisioner
- install / repo write / MCP config / network 副作用

## Runtime

`PraxisTapRuntime` 现在新增了：

- richer `PraxisReplayPolicy`
- richer `PraxisTapRuntimeSnapshot`
- `PraxisReplayStatus`
- `PraxisReplayNextAction`
- richer `PraxisPendingReplay`
- `PraxisActivationLifecycleService`
- `PraxisTapRuntimeCoordinator.store/record/stageReplay`

当前规则层已经能做：

- `ProvisionReplayPolicy -> ReplayPolicy`
- 创建 pending replay
- human gate 事件写回 runtime snapshot
- replay 与 human gate event 的最小 runtime 协调

当前仍然刻意没有实现的内容：

- activation factory live assembly
- provider/tool runtime activation
- checkpoint/recovery 与真实 host persistence 的联动

## Availability

`PraxisTapAvailability` 现在新增了：

- `PraxisAvailabilityGateDecision`
- `PraxisTapCapabilityAvailabilityRecord`
- richer `PraxisAvailabilityReport`
- `PraxisAvailabilityAuditor.audit(...)`

当前规则层已经能做：

- baseline
- review_only
- blocked
- pending_backlog

并且已经把这些因素纳入判定：

- required mode 是否匹配
- blocked capability set
- degraded capability set
- backlog capability set
- reviewRequired flag

当前仍然刻意没有实现的内容：

- family audit live evidence
- registration/binding/health observation host injection
- full formal family availability matrix

## 新增测试

本轮新增：

- `TapOperationalRuleTests`

当前 wave3 相关 targeted 测试已确认通过：

- `TapGovernanceRuleTests`
- `TapOperationalRuleTests`
- `TapGovernanceSupportTests`
- `TapTopologyTests`

## 当前已知问题

- 整包 `swift test` 在当前环境下仍然会遇到 `swiftpm-testing-helper` 的 `signal 11`。
- 该问题出现在测试 runner 层，而不是新增 TAP 模块编译失败。
- 当前已确认：
  - 编译完成
  - targeted TAP suites 通过
  - 但 full-suite runner 仍偶发/稳定在 helper 层崩溃，需要后续单独排查 Swift Testing 运行器问题

## 当前结论

到这一轮为止，wave3 的六个 Swift target 已经不再只是架构名词：

- `PraxisTapTypes`
- `PraxisTapGovernance`
- `PraxisTapReview`
- `PraxisTapProvision`
- `PraxisTapRuntime`
- `PraxisTapAvailability`

都已经有最小可运行的 Core 规则面，接下来可以进入统一 review，再决定下一轮是：

1. 继续把规则做深
2. 开始把 review/provision/runtime 之间的 DTO 和 façade 接口接入 HostRuntime
3. 或先停下来清一次命名和模型边界
