# 2026-04-12 Host-Neutral Boundary Freeze

## 本次落地内容

- `PraxisRuntimeFacades` 新增 `PraxisHostNeutralRuntimeBoundary`，把 HostRuntime 的宿主无关边界规则集中成一处真相：
  - gateway 入口只允许 `PraxisCLI`、`PraxisFFI`
  - presentation bridge 入口只允许 `PraxisAppleUI`
  - middle layer 明确禁止把 CLI / SwiftUI / terminal / platform / provider raw payload 语义带进 `RuntimeInterface / RuntimeGateway / RuntimeFacades / RuntimeUseCases`
- `PraxisRuntimeGatewayModule.bootstrap` 不再把 `PraxisAppleUI` 视为 portal-agnostic 入口，entrypoint truth 已收紧成只服务 CLI / exported host。
- `PraxisRuntimePresentationBridgeModule.bootstrap` 不再把 `PraxisCLI` / `PraxisFFI` 当成 bridge 直接入口，明确只代表 native presentation host。
- `PraxisRuntimeInterface` 与 `PraxisRuntimePresentationBridge` 的边界注释已改成当前事实，不再保留误导性的 TODO 文案。

一句白话：

- CLI 和未来导出层走 `RuntimeGateway -> RuntimeInterface`。
- Apple UI 只走 `RuntimePresentationBridge`。
- 这三条现在不仅写在计划里，也写进了代码真相和守卫测试。

## 守卫测试

- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeTopologyTests.swift`
  - 独立钉死 gateway / presentation bridge 的 allowed entrypoints
  - 独立钉死两侧 blueprint 必须包含的 boundary rules
  - 不再只是拿生产常量互相比对
- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeBoundaryGuardTests.swift`
  - 新增源码级 import guard
  - `PraxisCLI` 不能直接 import `PraxisRuntimeComposition / PraxisRuntimeUseCases / PraxisRuntimeFacades / PraxisRuntimePresentationBridge`
  - `PraxisAppleUI` 采用 allowlist guard，当前只允许直接 import：
    - `PraxisRuntimePresentationBridge`
    - `SwiftUI`
    - `Foundation`
  - host-neutral middle layer 当前明确禁止引入：
    - `SwiftUI`
    - `AppKit`
    - `UIKit`
    - `PraxisAppleUI`
  - import parser 已避免把注释里的 `import Foo` 当成真实 import

## 验证

- 已通过：
  - `swift test --filter PraxisHostRuntimeArchitectureTests`
  - `swift test --filter PraxisCLITests`
  - `swift test --filter PraxisRuntimeFacadesTests`
- 最终复审结果：
  - 无 findings

## 残余限制

- 这次守的是模块边界，不是语义污损的全部形态。
- 当前 guard 主要防 import 越层，防不住有人在允许模块里把 CLI / UI / platform 语义重新包装进 DTO 或命名后再渗入 middle layer。
- `PraxisAppleUI` 的 allowlist 目前是严格模式；后续如果原生展示壳合理引入新的基础框架，需要同步更新 guard。

## 下一包入口

- 下一包继续做 `CMP neutral surface hardening`。
- 主战场仍是：
  - `PraxisRuntimeFacades`
  - `PraxisRuntimeInterface`
  - `PraxisRuntimeUseCases`
  - `PraxisRuntimeGateway`
- 重点不是扩 CLI/UI，而是继续把 `session / project / flow / roles / control / readback` 六个分面钉成稳定的 host-neutral surface。
