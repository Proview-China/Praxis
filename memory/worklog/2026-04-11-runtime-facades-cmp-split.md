# 2026-04-11 Runtime Facades CMP Split

## 本次落地内容

- `PraxisRuntimeFacades` 已把 CMP host-facing surface 从单一 `cmpFacade` 继续拆成明确子分面：
  - `PraxisCmpSessionFacade`
  - `PraxisCmpProjectFacade`
  - `PraxisCmpFlowFacade`
  - `PraxisCmpRolesFacade`
  - `PraxisCmpControlFacade`
  - `PraxisCmpReadbackFacade`
- `PraxisRuntimeFacade` 现在对外同时暴露：
  - `cmpSessionFacade`
  - `cmpProjectFacade`
  - `cmpFlowFacade`
  - `cmpRolesFacade`
  - `cmpControlFacade`
  - `cmpReadbackFacade`
- 原有 `PraxisCmpFacade` 已降为兼容聚合层：
  - 持有上述子分面引用
  - 仅做向后兼容转发
  - 不再是新增 host-facing CMP surface 的首选落点

一句白话：

- 以后继续扩 HostRuntime 时，优先加到明确分面里，不要继续把所有 CMP 对外能力堆回一个大 facade。

## Interface 对齐

- `PraxisRuntimeInterfaceSession` 已改为优先直接调用 split facades：
  - session command 走 `cmpSessionFacade`
  - project command 走 `cmpProjectFacade`
  - flow command 走 `cmpFlowFacade`
  - roles command 走 `cmpRolesFacade`
  - control command 走 `cmpControlFacade`
  - status / peer-approval readback 走 `cmpReadbackFacade`

这意味着：

- RuntimeInterface 已经不再把 `cmpFacade` 当作唯一 CMP neutral surface。
- CLI / Gateway 仍经由 RuntimeInterface 进系统，没有反向把入口壳做厚。

## 验证

- 新增 `Tests/PraxisRuntimeFacadesTests/PraxisRuntimeFacadesTests.swift`
- 新增 SwiftPM test target：
  - `PraxisRuntimeFacadesTests`
- 已验证：
  - `swift test` 全绿
  - 当前快照：`175` tests / `46` suites

## 后续建议

- 如果继续推进 HostRuntime neutral surface，下一步优先补：
  - 各 split facade 的 DTO / summary 稳定性测试
  - `PraxisRuntimeUseCasesTests`
  - Interface response snapshot 的分面级 contract 测试
- 避免把新增 CMP 行为直接先做成 CLI command-specific 分支逻辑。
