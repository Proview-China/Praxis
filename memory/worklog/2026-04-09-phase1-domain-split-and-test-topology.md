# 2026-04-09: phase-1 领域拆分与测试拓扑落地

## 做了什么

- 把 phase-0 粗模块正式拆成 phase-1 target：
  - Capability: 4 个
  - TAP: 6 个
  - CMP: 8 个
- 更新 `Package.swift`
- 更新 Runtime blueprint
- 新增 `Tests/` 下的架构守卫测试 target
- 新增 `memory/architecture/swift-test-topology.md`

## 这次拆分的重点

- 不是实现迁移
- 是把“Core 不是一个模块”落实到 target 图和测试图

## 当前测试拓扑

- `PraxisFoundationArchitectureTests`
- `PraxisCapabilityArchitectureTests`
- `PraxisTapArchitectureTests`
- `PraxisCmpArchitectureTests`
- `PraxisHostContractsArchitectureTests`
- `PraxisHostRuntimeArchitectureTests`

## 为什么先做这些测试

- 当前最容易回退的不是算法，而是边界。
- 先把边界写成测试，后续再细化实现时，才不容易无意间把 target 重新糊回去。
