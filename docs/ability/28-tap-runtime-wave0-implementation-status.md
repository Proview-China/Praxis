# TAP Runtime Wave 0 Implementation Status

状态：阶段性实现总结，已进入第三阶段第一波真实落地。

更新时间：2026-03-20

## 先说结论

`TAP` 现在已经不只是“可用 runtime 控制面”。

这一轮之后，它已经进入下面这个阶段：

- 第三阶段 `Wave 0` 协议冻结已进代码
- activation contracts / resolver / materializer / driver 已进代码
- `AgentCoreRuntime` 已接入 activation runtime 能力
- `TMA planner` helper 已进代码
- `TMA executor` helper 已进代码
- checkpoint `pool-runtime-checkpoint` helper 已进代码
- `runtime-snapshot / runtime-recovery` helper 已进代码

更准确地说：

- `TAP` 现在已经开始从“可用控制面”推进到“真闭环 runtime”
- 但 durable 自动写入点，以及 `TMA -> provisioner runtime` 的更深主链还没有完全收口

一句白话：

- 我们现在不只是会审批和说“去造一个工具”
- 我们已经有了第一批真正能装能力、记能力状态、并把这些状态带回 runtime 的骨架

## 这次到底真正完成了什么

### 1. 第三阶段协议冻结

当前已落地：

- `src/agent_core/ta-pool-types/ta-pool-tma.ts`
- `src/agent_core/ta-pool-runtime/activation-types.ts`
- `src/agent_core/ta-pool-runtime/runtime-snapshot.ts`

这里已经新增并冻结：

- `TmaBuildPlan`
- `TmaExecutionReport`
- `TmaVerificationEvidence`
- `TmaRollbackHandle`
- `TaActivationReceipt`
- `TaActivationFailure`
- `TaActivationAttemptRecord`
- `TaResumeEnvelope`
- `PoolRuntimeSnapshots`
- `TapPoolRuntimeSnapshot`

这意味着：

- activation / TMA / durable recovery 三条线，已经有同一套可测试的数据契约

### 2. Activation Line

当前已落地：

- `src/agent_core/ta-pool-runtime/activation-factory-resolver.ts`
- `src/agent_core/ta-pool-runtime/activation-materializer.ts`
- `src/agent_core/ta-pool-runtime/activation-driver.ts`

并且已经接入：

- `src/agent_core/runtime.ts`

当前 runtime 已新增：

- `registerTaActivationFactory(...)`
- `activateTaProvisionAsset(...)`
- activation attempt 索引读取

这意味着：

- provision 出来的 capability 已经不再只是 handoff 概念
- 现在已经有一条可运行的 activation runtime 路径

### 3. TMA Line

当前已落地：

- `src/agent_core/ta-pool-provision/tma-planner.ts`
- `src/agent_core/ta-pool-provision/tma-executor.ts`

这里已经做成了两段 helper：

- planner 负责把缺失 capability 收成结构化 `BuildPlan`
- executor 负责消费 `BuildPlan` 产出：
  - `TmaExecutionReport`
  - `TmaVerificationEvidence[]`
  - `TmaRollbackHandle`

这意味着：

- `TMA planner / executor` 两层已经不只是设计稿
- 但它们目前还是 helper contract，还没有完全并进 `provisioner runtime` 主链

### 4. Durable Snapshot / Recovery Line

当前已落地：

- `src/agent_core/checkpoint/pool-runtime-checkpoint.ts`
- `src/agent_core/ta-pool-runtime/runtime-recovery.ts`

并且 runtime 当前已新增：

- `createTapRuntimeSnapshot()`
- `createPoolRuntimeSnapshots()`
- `createTapCheckpointSnapshot(...)`
- `writeTapDurableCheckpoint(...)`
- `recoverTapRuntimeSnapshot(...)`

这意味着：

- `human gate / replay / activation attempt` 相关状态已经不再只能活在内存里
- 现在已经有 checkpoint 级别的 TAP control-plane snapshot 入口

## 当前已经验证成立的链路

当前已经通过测试证明成立的能力包括：

- provision asset activation materialize
- activation factory resolve
- activation driver register / replace / fail path
- runtime activation handoff -> activation -> replay/re-review
- `TMA planner` helper
- `TMA executor` helper
- pool runtime snapshot serialize / hydrate
- runtime 写 durable checkpoint 并恢复 TAP snapshot

## 当前验证状态

当前已回读通过：

- `npm run typecheck`
- `npx tsx --test src/agent_core/**/*.test.ts`
- 当前 `agent_core` 定向测试：`183 pass / 0 fail`

## 当前还没有做完的事

### 1. durable 自动写入点还没完全接主链

当前已经有：

- snapshot helper
- checkpoint helper
- runtime 级手动 checkpoint API

但还没有做到：

- human gate 状态变化自动写 durable checkpoint
- replay 状态变化自动写 durable checkpoint
- activation 状态变化自动写 durable checkpoint

### 2. `TMA executor` 还没正式接进 `provisioner runtime`

当前已经有：

- planner helper
- executor helper

但还没有做到：

- `provisioner runtime` 真正改为 `planner -> executor -> bundle` 的主链

### 3. reviewer 的高层上下文仍然是 placeholder

这条事实没有变化：

- reviewer 还没有接真实项目状态、记忆池、包装机

### 4. end-to-end live smoke 还没有补第三阶段专用入口

当前 `agent_core` 单测已经覆盖很多链路。

但还没有做到：

- 针对第三阶段 activation / durable checkpoint / TMA 的独立 live smoke 命令

## 当前最准确的阶段判断

现在最准确的说法是：

- `TAP` 第三阶段第一波代码已经真实落地
- activation runtime integration 已成立
- `TMA planner / executor` helper 已成立
- durable checkpoint helper 与 runtime 级 snapshot API 已成立
- 但真正的 durable 自动写入主链，以及 `TMA -> provisioner runtime` 主链，还要继续推进

一句收口：

- 我们现在已经从“有控制面”走到了“有第一批真实闭环骨架”
- 但离完整 industrial-grade 的 `TAP runtime` 还差最后几段自动化主链收口
