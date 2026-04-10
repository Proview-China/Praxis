# 2026-04-10 Swift Object Architecture Plan

## 做了什么

- 新增根目录类级架构计划书：
  - `SWIFT_OBJECT_ARCHITECTURE_PLAN.md`
- 新增长期对象设计规则：
  - `memory/architecture/swift-object-design-rules.md`

## 这次冻结了什么

- 重构粒度从 target 进一步下压到类型级。
- 明确了 `struct / final class / actor / protocol / extension` 的适用边界。
- 明确了依赖注入只能以 composition root 为核心展开。

## 最关键的约束

- 不接受“万物 class”。
- 纯领域真相必须优先保留值语义。
- 只有协调流程和承载外部依赖的对象，才进入引用语义。
- `PraxisRuntimeUseCases` 与 `PraxisRuntimePresentationBridge` 仍然是最高风险区。
