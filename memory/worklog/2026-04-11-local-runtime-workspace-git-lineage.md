# 2026-04-11 Local Runtime Workspace Git Lineage

## 做了什么

- 继续沿 `PraxisRuntimeComposition` 收口 concrete local adapters，没有新增 target。
- 在 `PraxisLocalHostAdapters.swift` 落下了第一批真实本地宿主能力补齐：
  - `PraxisLocalWorkspaceReader`
  - `PraxisLocalWorkspaceSearcher`
  - `PraxisLocalWorkspaceWriter`
  - `PraxisSystemGitExecutor`
  - `PraxisLocalLineageStore`
- `PraxisHostAdapterRegistry.localDefaults(rootDirectory:)` 现在默认不再把 workspace / git executor / lineage store 回落到 scaffold doubles。

## 当前边界

- 这轮仍然只把 HostRuntime 的本地闭环往前推进，没有把 provider、browser、multimodal user-io 做真。
- `WorkspaceWriter` 当前真实支持：
  - `createFile`
  - `updateFile`
  - `deleteFile`
- `applyPatch` 仍保持显式未实现，避免伪装成已经支持统一 patch 执行。
- `GitExecutor` 当前优先承接最小 structured git plan：
  - `verifyRepository`
  - `fetch`
  - `checkout`
  - `commit`
  - `push`
  - `merge`
  - `inspectRef`
  - `updateRef`

## Inspection 变化

- `PraxisInspectCmpUseCase` 不再只看“有没有 adapter 接线”，而是开始读取真实本地状态：
  - workspace reader/searcher/writer 是否可用
  - git executor 是否能做安全的 repo verify
  - lineage store 是否能解析 projection 引用到的 lineage
- 这次没有扩 public DTO / request surface，只更新现有 summary 文案和 issue 聚合。

## 验证

- `swift test` 通过
- 当前测试快照：
  - `125` tests
  - `39` suites

## 后续建议

- 下一步优先把 local workspace / git / lineage adapter 接到更真实的 use case 输入，而不只是 inspection。
- 如果后面要继续推进本地 runtime，优先顺序保持：
  - workspace read/search/write hardening
  - git executor / lineage persistence richer receipts
  - SQLite-backed persistence 升级
  - provider live lane
