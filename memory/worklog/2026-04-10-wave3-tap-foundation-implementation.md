# 2026-04-10 Wave 3 TAP Foundation Implementation

## 本轮实现了什么

- 正式开始 `Wave 3` 的 Swift 实现，不再只停留在 TAP skeleton。
- 首批落地范围集中在：
  - `PraxisTapTypes`
  - `PraxisTapGovernance`
- 目标是先把后续 `review / provision / runtime / availability` 都要依赖的 TAP 共用语义和治理规则做实。

## 已落地的 TAP 基础语义

`PraxisTapTypes` 现在已经不再只是几组 placeholder enum，而是开始对齐旧 TS 的实际 TAP 语义：

- mode：
  - canonical mode：`bapr / yolo / permissive / standard / restricted`
  - legacy alias：`strict / balanced`
  - 支持 `canonicalMode` 归一化
- capability tier：
  - `B0 / B1 / B2 / B3`
- risk level：
  - `normal / risky / dangerous`
- review vote：
  - `allow / allow_with_constraints / deny / defer / escalate_to_human / redirect_to_provisioning`
- review decision kind：
  - `approved / partially_approved / denied / deferred / escalated_to_human / redirected_to_provisioning`
- capability profile：
  - baseline capability
  - allowed/review-only/denied patterns
  - capability wildcard match helper

## 已落地的治理规则

`PraxisTapGovernance` 这一轮开始具备真实规则，而不是只有模型名字：

- risk classifier：
  - 支持 risky / dangerous capability pattern
  - 支持 `B3` tier 自动升为高风险
  - 返回结构化 `risk classification`
- mode policy provider：
  - 支持 mode+tier -> request path / execution path / reviewer strategy / review requirement
  - 支持 mode+tier -> policy entry
  - 支持 mode+risk -> risk policy entry
- safety interceptor：
  - 支持把 risk policy 映射成 `allow / downgrade / interrupt / block / escalate_to_human`

## 这轮明确下来的边界

- `ta-pool-context`、`ta-pool-safety` 继续归 `PraxisTapGovernance`
- `ta-pool-tool-review` 继续归 `PraxisTapReview`
- 当前这一轮没有把以下内容搬进 Core：
  - worker bridge
  - model hook
  - tooling adapter
  - provider execution
  - runtime assembly

一句话：

- 当前实现的是 “TAP 该怎么判断”，不是 “TAP 现在怎么去执行宿主副作用”。

## 新增验证

- 新增 `TapGovernanceRuleTests`
- 当前验证覆盖：
  - legacy mode canonicalization
  - capability wildcard matching
  - risk classifier
  - mode policy matrix
  - safety interception boundary

## 当前状态

- `swift test` 通过
- 当前测试总数已提升到 `54`

## 下一步建议

按当前顺序继续推进：

1. `PraxisTapReview`
   先落 `review decision / route / trail / tool-review pure decision`
2. `PraxisTapProvision`
   先落 `registry / asset index / plan`
3. `PraxisTapRuntime`
   再承接 `control plane / replay / recovery`

这样能保证后续实现继续建立在已固定的 TAP 基础语义之上，而不是重新发明 mode/risk 解释。
