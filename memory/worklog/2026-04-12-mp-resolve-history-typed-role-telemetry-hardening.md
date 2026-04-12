# 2026-04-12 MP Resolve/History Typed Role Telemetry Hardening

## 本次落地内容

- 这次只处理 MP `resolve/history` 这条链上的 role telemetry 外显，不扩 `RuntimeInterface` surface，也不顺手改 MP 其它路径。
- `roleCounts` / `roleStages` 现在已经从自由字符串 map 收紧成 host-neutral typed contract：
  - `PraxisMpRoleCountMap`
  - `PraxisMpRoleStageMap`
  - `PraxisMpRoleTelemetryStage`
- role key 统一复用 `PraxisMpFiveAgentRole`，stage 外显面则用最小统一 enum 承接各角色 stage raw value。
- `PraxisMpHostRetrievalService.dispatcherTelemetry()`、`PraxisMpResolveResult` / `PraxisMpHistoryResult`、`PraxisMpResolveSnapshot` / `PraxisMpHistorySnapshot` 都已切到 typed telemetry。
- `HostRuntimeInterface` 没有新增字段；只同步了 interface test stub 的入参类型，保持 interface 继续是 summary-only MP surface。

一句白话：

- MP `resolve/history` 现在不再把角色和阶段当普通字符串乱传，而是有了明确、可校验、可稳定编码的 typed 合同。

## Codable 与边界约束

- `PraxisMpRoleCountMap` decode 时会显式校验 role key；未知 role raw value 会直接抛 `DecodingError`。
- `PraxisMpRoleStageMap` decode 时不会把 stage 当自由字符串直接接受，而是先按 role 分流，再要求 stage 必须属于该 role 的 stage 集合。
- 未知 stage raw value 或“raw value 合法但不属于该 role”的情况，都会显式 decode failure，不会静默 fallback。
- 第一轮 review 之后又补了一刀 contract sealing：
  - `PraxisMpRoleTelemetryStage` 现在显式暴露所属 `role`
  - `PraxisMpRoleStageMap` 新增统一校验逻辑
  - throwing `init(validating:)`、非 throwing `init(stages:)` 与 `encode(to:)` 都会复用同一套 role/stage 兼容性检查
- 这意味着非法 `role -> stage` 组合不再只是“decode 时才会炸”；现在在构造期和编码期也会被封死，不会再出现“对象能造出来、能编码、但解码失败”的假 typed 状态。
- typed telemetry 类型放在 `PraxisMpFiveAgent`，避免在 facade 层临时包一层伪 typed map，继续保持宿主无关边界。

## 测试

- 本次补的验证覆盖：
  - use case 层 typed assertion
  - facade 层 typed assertion
  - resolve/history result roundtrip
  - resolve/history snapshot roundtrip
  - 未知 role raw value decode failure
  - 非法 stage raw value decode failure
- 本地验收：
  - `swift test --filter PraxisMpFiveAgentTests`
  - `swift test --filter PraxisRuntimeUseCasesTests`
  - `swift test --filter PraxisRuntimeFacadesTests`
  - `swift test --filter HostRuntimeInterfaceTests`
- 复审结果：
  - 第一轮发现 `PraxisMpRoleStageMap` 仍允许代码内构造非法 `role -> stage` 组合
  - follow-up 修复后复审 `无 findings`

## 残余限制

- 这次只收紧了 `resolve/history` 的 telemetry 外显；`PraxisMpFiveAgentRuntimeState` / `PraxisMpFiveAgentSummary` 里的 `latestStages: [Role: String]` 仍然是 stringly，按范围没有继续扩。
- 当前 host retrieval 仍只产出 `dispatcher` 单角色 telemetry；typed contract 已经能承载多角色，但上游 runtime state 还没真正提供多角色产出。
- 测试已经覆盖：
  - 未知 role
  - 非法 raw stage
  - 手工构造非法 `role -> stage` 组合
- 但还没有单独钉住：
  - 非 throwing `init(stages:)` 的 `precondition` 分支
  - `encode(to:)` 在对象被异常伪造成非法状态时的防御分支

## 下一包入口

- 继续留在 MP neutral surface hardening 范围内时，下一步更合理的是收口剩余 stringly MP telemetry / stage surface，而不是回退去扩 interface 或把 facade 再做成聚合真相层。
