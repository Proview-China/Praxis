# 2026-04-09: Core 只能是逻辑层，不能是模块

## 做了什么

- 明确冻结一条新规则：
  - `Core` 只能是逻辑层概念，不能是兜底模块或兜底产品名
- 新增：
  - `memory/architecture/swift-core-decomposition.md`
- 更新：
  - 当前统一主计划：`SWIFT_REFACTOR_PLAN.md`
  - `Package.swift`
  - `memory/architecture/swift-refactor-boundaries.md`
  - 现已统一收敛到 `SWIFT_REFACTOR_PLAN.md`

## 为什么要这么做

- 如果保留一个名义上的大 `Core` 模块，后续真实迁移时很容易把剩下所有“不知道放哪”的逻辑都继续塞进去。
- 现在必须提前把这个逃生口堵死，否则架构会在实现阶段迅速回退。

## 当前结论

- Foundation 层已经足够细，可以先稳定。
- 真正还要继续拆的是：
  - `PraxisCapability`
  - `PraxisTAP`
  - `PraxisCMP`
