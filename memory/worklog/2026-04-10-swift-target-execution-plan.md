# 2026-04-10 Swift Target Execution Plan

## 做了什么

- 新增根目录执行计划书：
  - `SWIFT_TARGET_EXECUTION_PLAN.md`

## 这次固定了什么

- Swift 重构不按“看到什么先写什么”推进。
- 正式执行顺序固定为：
  - Foundation
  - Capability
  - TAP
  - CMP
  - HostContracts
  - HostRuntime
  - Entry

## 为什么这样排

- 先低层纯模型，可以降低后续类型返工。
- 先纯规则和 planner，可以避免一开始就被宿主实现绑死。
- HostContracts 必须晚于 Core 子域，否则协议边界会一直漂。
- HostRuntime 必须晚于 HostContracts，否则 runtime 会重新吞掉系统边界。
- CLI / SwiftUI 必须最后做，否则入口层会倒逼核心结构回退。

## 对后续的直接约束

- 真正开始编码时，优先按 `SWIFT_TARGET_EXECUTION_PLAN.md` 的 wave 和 target 顺序推进。
- `PraxisRuntimeUseCases` 与 `PraxisRuntimePresentationBridge` 需要额外 review gate。
- 任何想提前接 live provider / git / db / mq 的需求，都应默认视为越过当前推荐顺序。
