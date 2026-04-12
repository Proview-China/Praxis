# 2026-04-12 CMP Smoke Typed Surface Hardening

## 本次落地内容

- 第 2 包继续留在 `CMP neutral surface hardening` 范围内，这次先把 `CMP smoke` 的宿主无关外显 contract 收紧成 typed surface，然后又补了一条 follow-up 修复，纠正 smoke façade 把 `.missing` 压扁成 `.failed` 的回退。
- 这次最终收口的是 `cmp smoke` 这条完整链路：
  - use case smoke record
  - façade/result surface
  - smoke snapshot roundtrip
  - runtime surface smoke assertions

一句白话：

- smoke 现在不再靠“门名字符串 + 状态字符串”传真相，而且 `missing` 也不会再被错误伪装成 `failed`。

## 语义收紧

- 新增最小 typed 模型：
  - `PraxisCmpSmokeGate`
- `PraxisCmpProjectSmokeCheck` / `PraxisCmpSmokeCheckRecord` 现在都以 typed `gate` 表达 smoke 检查门位，而不是自由字符串。
- smoke `status` 现在保留现有 typed 语义：
  - `PraxisCmpProjectComponentStatus.ready`
  - `PraxisCmpProjectComponentStatus.degraded`
  - `PraxisCmpProjectComponentStatus.missing`
- 这次 follow-up 删除了 smoke façade 上的压缩逻辑：
  - 不再把 `PraxisCmpProjectComponentStatus.missing` 折叠成 `PraxisTruthLayerStatus.failed`
- 未知 typed raw value 不再靠默认回退掩盖：
  - smoke snapshot 对未知 `gate/status` 会显式解码失败
  - runtime interface codec 现在也能拒绝未知 `nextAction` raw value

## 测试

- 本次补齐和更新的验证覆盖：
  - smoke snapshot `gate/status` raw-value roundtrip
  - 非法 smoke `gate/status` decode failure
  - runtime surface 对 smoke `missing` 保真断言
  - `cmpProjectSmoke` 的 typed smoke status/gate 正向断言
  - 全量回归确认 smoke typed 化没有把其它 surface 打坏
- 本地最终验收：
  - `swift test --filter PraxisRuntimeFacadesTests`
  - `swift test --filter HostRuntimeSurfaceTests`
  - `swift test`
- 结果：
  - `268 tests / 52 suites` 通过
- 复审结果：
  - smoke typed surface follow-up：`无 findings`

## 残余限制

- `CMP smoke` 这次只收紧了 gate/status，不包含 `nextAction`、MP、RuntimeInterface 生产面或其它 project/readback backlog。
- smoke 真实路径里的 `.missing` 目前主要通过 façade snapshot roundtrip 和 runtime surface 的直接断言来钉住；如果后续还想更稳，可以再补一个非 `git` gate 的真实生成样本。
- generic runtime smoke (`PraxisRuntimeSmokeCheck`) 仍保留自己的既有 contract，这次没有越界改造那条通用路径。

## 下一包入口

- 第 2 包还可以继续收口剩余的 CMP stringly / weakly-typed 外显 contract。
- 当前更自然的下一个切口：
  - `CMP flow ingest nextAction` 的 typed surface
  - 其它仍依赖弱映射/默认回退的 façade contract
- 继续优先规则不变：先修宿主无关中间层仍在泄漏的 contract，再做更大层级整理。
