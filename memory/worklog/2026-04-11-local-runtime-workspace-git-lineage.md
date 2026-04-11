# 2026-04-11 Local Runtime SQLite Closure

## 做了什么

- 继续沿 `PraxisRuntimeComposition` 收口 concrete local adapters，没有新增 target。
- 在 `PraxisLocalHostAdapters.swift` 落下了真实本地宿主能力补齐：
  - `PraxisLocalWorkspaceReader`
  - `PraxisLocalWorkspaceSearcher`
  - `PraxisLocalWorkspaceWriter`
  - `PraxisSystemGitExecutor`
  - `PraxisLocalLineageStore`
- `PraxisHostAdapterRegistry.localDefaults(rootDirectory:)` 现在默认不再把 workspace / git executor / lineage store 回落到 scaffold doubles。
- 本地 structured persistence 已从多份 JSON 文件切换到单一 `runtime.sqlite3`：
  - checkpoint
  - journal
  - projection
  - delivery truth
  - embedding metadata
  - semantic memory
  - lineage
- `PraxisRunGoalUseCase` / `PraxisResumeRunUseCase` 现在除了 checkpoint + journal 之外，还会把最小 CMP 宿主真相写入本地 runtime：
  - projection descriptor
  - lineage descriptor
  - delivery truth
  - message bus publication

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
- SQLite 这一轮是 local-first baseline，不包含：
  - schema versioning
  - migration policy
  - backward compatibility bridge for old JSON files
  - richer cross-process locking policy beyond SQLite default file lock + busy timeout

## Inspection 变化

- `PraxisInspectCmpUseCase` 不再只看“有没有 adapter 接线”，而是开始读取真实本地状态：
  - workspace reader/searcher/writer 是否可用
  - git executor 是否能做安全的 repo verify
  - lineage store 是否能解析 projection 引用到的 lineage
- 现在 `runGoal` / `resumeRun` 也会把 inspection 需要的最小宿主真相写回本地 store，所以 inspection 看到的不再只是测试种子数据。
- 这次没有扩 public DTO / request surface，只更新现有 summary 文案和 issue 聚合。

## 验证

- `swift test` 通过
- 当前测试快照：
  - `128` tests
  - `39` suites
- 新增验证覆盖：
  - localDefaults 基于单一 SQLite 文件跨 registry 持久化 checkpoint / journal
  - local runtime run + resume 会写 projection / delivery truth / lineage
  - inspection 能读回这些 runtime-written facts

## 后续建议

- 如果后面要继续推进本地 runtime，优先顺序保持：
  - workspace read/search/write hardening
  - git executor / lineage persistence richer receipts
  - SQLite schema hardening
  - semantic memory / embedding write-path richer facts
  - provider live lane
