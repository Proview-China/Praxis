# 2026-04-09 Host Layer Phase-1 Split

## 背景

在 Core 逻辑层完成按功能子域拆分后，Host 层如果仍保留单体接口包或单体 runtime 包，会重新变成新的“大总装器”。

因此本轮把 Host 层也冻结成 phase-1 的 target 拓扑。

## 本次冻结的结论

### HostContracts 五分

固定拆成：

- `PraxisProviderContracts`
- `PraxisWorkspaceContracts`
- `PraxisToolingContracts`
- `PraxisInfraContracts`
- `PraxisUserIOContracts`

目标：

- 不再让所有宿主协议混在一个接口层里。
- 后续每一类外部能力都能单独演进、单独补 contract tests。

### HostRuntime 四分

固定拆成：

- `PraxisRuntimeComposition`
- `PraxisRuntimeUseCases`
- `PraxisRuntimeFacades`
- `PraxisRuntimePresentationBridge`

目标：

- 不再让 runtime 层把装配、用例、对外 facade、入口桥都塞进一个 target。
- 入口层只能消费展示桥，不直接碰内部运行时零件。

### Entry 规则同步收紧

固定为：

- `PraxisCLI` 只能依赖 `PraxisRuntimePresentationBridge`
- `PraxisAppleUI` 只能依赖 `PraxisRuntimePresentationBridge`
- 未来 `PraxisFFI` 也应遵守同一规则

这条规则的意义是：

- 入口层不直接拿 Core target
- 入口层不直接拿 HostContracts
- 所有宿主入口都通过同一个 presentation-facing 边界进入系统

### Host 测试拓扑同步拆分

原本单一的 Host 架构测试，冻结为两个 target：

- `PraxisHostContractsArchitectureTests`
- `PraxisHostRuntimeArchitectureTests`

这样后续既能单独守卫协议层拆分，也能单独守卫 runtime 四分结构。

## 对后续重构的直接影响

- “Host 层”以后只能作为逻辑层总称出现，不能再作为兜底 target 出现。
- 任何新功能如果涉及宿主能力，必须先决定它属于哪个 contracts family。
- 任何新入口如果要接入 Swift 核心，都必须先过 `PraxisRuntimePresentationBridge`。
