# 2026-04-10 Swift Skeleton Split Complete

## 做了什么

- 完成所有 Swift target 的多文件拆分。
- 为各 target 补齐基础类型声明，包括 `struct`、`final class`、`actor`、`protocol`、DTO 和 service/coordinator/facade 骨架。
- 修复拆分后遗漏的模块导入，使类型可见性恢复正常。

## 当前结论

- Swift 架构脚手架已经从“文档规划”进入“源码骨架已落地”阶段。
- 现在的 Swift 包可作为后续实现期的正式重构底盘使用。
- 入口层、运行时层、领域层、宿主契约层的边界都已经通过 target 和源码目录体现出来。

## 验证结果

- `swift build` 通过。
- `swift test` 通过。
- 当前架构测试覆盖 foundation、capability、tap、cmp、host contracts、host runtime 六组拓扑约束。

## 后续建议

- 下一阶段不要再扩 target 数量，优先把 `PraxisRuntimeComposition -> PraxisRuntimeUseCases -> PraxisRuntimeFacades -> PraxisCLI` 这一条链路从声明补到最小可运行。
- Apple UI 继续保持 presentation bridge 之后再接，不要越过 bridge 直接依赖底层实现。
