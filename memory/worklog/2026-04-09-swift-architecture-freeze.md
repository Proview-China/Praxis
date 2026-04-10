# 2026-04-09: Swift 架构分层冻结

## 做了什么

- 当时新增根目录架构蓝图，后续已并入：
  - `SWIFT_REFACTOR_PLAN.md`
- 新增 ADR：
  - `memory/decisions/ADR-0002-swift-rearchitecture-layering.md`
- 更新已有工单与架构边界说明：
  - 现已统一收敛到 `SWIFT_REFACTOR_PLAN.md`
  - `memory/architecture/swift-refactor-boundaries.md`

## 这次冻结了什么

- Swift 重构必须采用四层结构：
  - `PraxisCore`
  - `PraxisHostContracts`
  - `PraxisHostRuntime`
  - `PraxisCLI / PraxisAppleUI / PraxisFFI`
- Core 不得依赖 provider SDK、Git/DB/MQ 客户端、SwiftUI、终端 I/O。
- Git / DB / MQ / provider 必须拆成“Core model/planner + Host executor”两层。
- CLI 和 SwiftUI 只能通过 `PraxisRuntimePresentationBridge` 调用系统能力。

## 为什么现在冻结

- 当前已经开始建立 SwiftPM target 骨架，如果这时不把架构规则写死，后面 target 会很快重新长成一个新的总装器。
- 先冻结层次，比先写实现更关键；否则迁移速度越快，偏航也越快。

## 对后续工作的影响

- 后续所有 Swift 模块细化都需要先检查是否违反这次冻结的边界。
- 如果未来某个模块同时出现规则与副作用实现，默认继续拆，而不是接受混合状态。
