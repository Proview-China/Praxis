# 2026-04-10 Wave6 Review Fixes

## 背景

- 针对一轮外部 review 指出的 HostRuntime 问题进行了逐条核对和修复：
  - `resumeRun` 跳过完整 lifecycle advance
  - 旧 `run.<session>.<goal>` 形式 run ID 解析错误
  - 默认 bridge factory 每次重建一套 scaffold host adapters
  - replay checkpoint 之后的 journal events 时，没有先据此更新 run，再决定是否继续 resume
  - checkpoint recovery 把 “read everything after checkpoint” 静默截断为 50 条
  - 新 runtime interface 的 raw `sessionID` 进入 run ID 后，恢复解析不是完全可逆
  - 历史 `run:` ID 中字面量包含 `%3A` 的 session，会被新的通用 percent decode 误解码

## 核对结果

- 上述问题都属实。

### 1. resume 不该绕开 lifecycle advance

- 之前的实现直接对 checkpoint 恢复出的 run 调用了 `applyEventToState`，绕过了 `PraxisRunLifecycleService.advance(...)`。
- 结果是恢复后的 run/checkpoint 会被持久化为 `queued`，而不是 transition table 定义的 `acting + recovery`。
- 这会让依赖 `phase` 或 checkpoint 内 run aggregate 的调用方误判恢复态。

### 2. 旧 run ID 解析确实会截断 dotted session

- 之前 legacy `run.<session>.<goal>` 解析逻辑按第一个 `.` 截断，像 `run.session.host-runtime.goal.host-runtime` 会把 session 误解析成 `session`。
- 这会直接导致 checkpoint pointer 错误，从而无法恢复历史 run。

### 3. 默认 factory 确实会生成新的内存 store

- 之前 `PraxisRuntimeBridgeFactory` 的无参入口每次都会重新执行 `.scaffoldDefaults()`。
- 这意味着跨 bridge/controller/store 实例时，默认 checkpoint/journal store 并不共享，恢复能力只在单个 bridge 生命周期内有效。

### 4. replay 后的 journal events 确实需要先决定当前 run 真相

- 之前恢复流程虽然会通过 `PraxisCheckpointRecoveryService` 读出 checkpoint 之后的 `replayedEvents`，但后续仍直接拿 checkpoint 里的 `restoredRun` 生成新的 `run.resumed`。
- 这意味着如果 checkpoint 之后已经落过终态事件，例如 `run.completed`，恢复路径仍会把 run 当成“待恢复的旧状态”处理。
- 结果就是已完成 run 会被错误地再次 resume，终态真相被 checkpoint 旧快照覆盖。

### 5. checkpoint replay 确实被 50 条硬截断

- `PraxisCheckpointRecoveryService.recover(...)` 调 `PraxisJournalReading` 时传入 `limit: nil`，语义本来是“把 checkpoint 之后的 journal 全部 replay 回来”。
- 但 HostRuntime 的 contract-backed reader 之前把这个 `nil` 改写成了 `50`。
- 结果是只要 checkpoint 之后事件数超过 50，恢复聚合就会停在半路，后续的失败/完成事件根本不会进入 replay 结果。

### 6. 新 run ID 里的 session 组件之前不是可逆编码

- 新的 `runID(for:)` 直接拼出 `run:<sessionID>:<goalID>`，而 `sessionID(from:)` 又按 `:` 切分。
- 这对包含 `:` 的有效 sessionID 是有损的，例如 `team:alpha` 会在恢复时被错误解成 `team`。
- 结果就是 `runGoal` 刚创建完的 run，在后续 `resumeRun` 或统一接口 `resumeRun` 时会找不到 checkpoint。

### 7. 历史 percent-literal session 也确实会被误解码

- 更早的 `run:` ID 会把 session 原样写进 `run:<session>:<goal>`，所以历史上完全可能存在 `run:team%3Aalpha:goal` 这种 ID，其中 `%3A` 只是 session 字面量的一部分。
- 上一轮修复如果对所有 `run:` session 组件都无条件执行 `removingPercentEncoding`，就会把它错误地还原成 `team:alpha`。
- 这样恢复时就会去错误的 session 下找 checkpoint，导致历史 run 无法 resume。

## 修复内容

- `resumeRun`
  - 改为先把不可直接恢复的旧 checkpoint 状态归一化为可恢复种子 run，再走完整 `lifecycle.advance(...)`
  - 恢复后把 follow-up intent 稳定写回 persisted run aggregate，避免 checkpoint 中丢失恢复中的 intent
- legacy run ID
  - `run.<session>.<goal>` 现在优先按 `.goal.` 边界解析 session；缺少该标记时退化为按最后一个 `.` 切分
- 默认 factory
  - `PraxisRuntimeBridgeFactory` 现在复用同一组共享 scaffold host adapters
  - 这样默认 CLI / Apple bridge / facade 在同一进程内可以共享 checkpoint/journal 内存态
- replay-aware resume
  - 恢复流程现在会先把 checkpoint 之后的 journal events 重放回 `PraxisRunAggregate`
  - 只有当 replay 后的 run 仍然不是终态时，才继续生成新的 `run.resumed`
  - 如果 replay 已经证明 run 进入 `.completed` 或 `.cancelled`，则直接持久化 replay 后的快照，不再发新的 resume 事件
- checkpoint replay pagination
  - HostRuntime 的 contract-backed journal reader 现在对 `limit: nil` 采用分页读取直到耗尽，而不是把它静默替换成固定的 `50`
  - 现有实现使用 `50` 作为单页大小，但不再把它当成总 replay 上限
- lossless session component encoding
  - 新的 colon-style run ID 现在会对 session 组件做可逆转义，再写入 `run:<session>:<goal>` 结构
  - 恢复解析时会反向解码 session 组件，因此 raw `sessionID` 可以跨 `runGoal -> resumeRun` 无损往返
  - 进一步补上了显式编码前缀：只有带前缀的新 session 组件才会执行反向解码
  - 不带前缀的历史 `run:` ID 继续按字面量解释，从而保住诸如 `team%3Aalpha` 这类旧 session 值
  - `resumeRun` 对 `run:` ID 还会按候选 session 做兼容查找，兼顾新前缀格式与过渡期的未标记编码

## 新增验证

- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeSurfaceTests.swift`
  - 恢复后的 run 和 checkpoint aggregate 现在验证为 `running`
  - 增加 legacy dotted session run ID 恢复测试
  - 增加默认 factory 跨 bridge 实例复用 shared scaffold adapters 的测试
  - 增加 checkpoint 后 replay 到 `run.completed` 时不再错误 resume 的回归测试
  - 增加 checkpoint 后有 60 条 replay 事件时仍然会完整重放直到 terminal event 的回归测试
- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeInterfaceTests.swift`
  - 增加 raw `sessionID = "team:alpha"` 时，统一接口的 `runGoal -> resumeRun` 仍然无损往返的回归测试
 - `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeSurfaceTests.swift`
  - 增加历史 `run:team%3Aalpha:goal...` 仍按字面量 session 恢复的回归测试

## 当前结论

- Wave6 当前的默认 HostRuntime scaffold 已经具备跨 bridge 实例的最小恢复一致性。
- 恢复路径现在遵守一个更清晰的语义：checkpoint 只是基线，resume 前必须先吸收 checkpoint 之后已经落盘的 journal 真相；只有非终态 run 才允许再进入恢复生命周期。
- 如果后续要做导出给其他语言的 lib，这些修复也让 runtime façade / bridge 的状态语义更稳定，不会因为恢复相位或默认 store 生命周期错误而暴露出不一致行为。
