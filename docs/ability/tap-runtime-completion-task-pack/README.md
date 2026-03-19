# TAP Runtime Completion Task Pack

状态：第三阶段并行编码任务包。

更新时间：2026-03-19

## 这包任务是干什么的

这一包不是继续做 `TAP` 的第一版控制面，也不是继续补第二阶段“可用控制面”。

这包任务的目标是：

- 把 `TAP` 从“可用 runtime 控制面”
- 推进到“可持续使用的真闭环控制面”

这轮重点只有三件事：

1. `activation driver`
2. `real builder / TMA`
3. durable `human gate / replay`

一句白话：

- 这次不是继续讨论谁能审批
- 而是让系统真的能造、真的能装、真的能从中断里恢复

## 开工前必须先读

所有执行本包的 Codex 都必须先读：

- [20-ta-pool-control-plane-outline.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/20-ta-pool-control-plane-outline.md)
- [21-ta-pool-implementation-status.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/21-ta-pool-implementation-status.md)
- [23-ta-pool-stage-wrap-up.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/23-ta-pool-stage-wrap-up.md)
- [24-tap-mode-matrix-and-worker-contracts.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/24-tap-mode-matrix-and-worker-contracts.md)
- [25-tap-capability-package-template.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/25-tap-capability-package-template.md)
- [26-tap-runtime-migration-and-enforcement-outline.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/26-tap-runtime-migration-and-enforcement-outline.md)
- [27-tap-runtime-completion-blueprint.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/27-tap-runtime-completion-blueprint.md)
- [docs/master.md](/home/proview/Desktop/Praxis_series/Praxis/docs/master.md)
- `memory/current-context.md`

## 本轮冻结共识

- reviewer 继续只审、只读、只投票
- `TMA` 只造 capability，不完成原始用户任务
- `activation driver` 只做机械装配，不做 LLM 决策
- durable 第一版先走 checkpoint-first
- 当前先不提前抽 shared framework
- 当前所有改动都继续落在 `reboot/blank-slate`

## 推荐分波顺序

### Wave 0

- `00-runtime-completion-protocol-freeze.md`

### Wave 1

- `01-activation-driver-contract.md`
- `02-tma-runtime-contract.md`
- `03-durable-pool-runtime-snapshot.md`

### Wave 2

- `04-activation-driver-runtime.md`
- `05-package-materializer-and-factory-resolver.md`
- `06-tma-planner-lane.md`
- `07-tma-executor-lane.md`

### Wave 3

- `08-durable-human-gate.md`
- `09-durable-replay-and-activation-attempts.md`
- `10-runtime-recovery-assembly.md`

### Wave 4

- `11-first-class-tooling-baseline-for-reviewer-and-tma.md`
- `12-end-to-end-runtime-closure-and-smoke.md`

## 推荐并发量

- Wave 0：`1`
- Wave 1：`3`
- Wave 2：`4`
- Wave 3：`3`
- Wave 4：`2`

建议总并发控制在 `4-6` 个真正会写共享协议的 worker。

可以额外挂更多只读 explorer，但不要让太多 worker 同时改：

- `src/agent_core/runtime.ts`
- `src/agent_core/ta-pool-runtime/**`
- `src/agent_core/ta-pool-types/**`

## 强依赖提醒

- `00` 没完成前，不要并行写 `01/02/03`
- `01` 和 `05` 没冻结前，不要真正开写 `04`
- `02` 没冻结前，不要真正开写 `06/07`
- `03` 没冻结前，不要真正开写 `08/09/10`
- `12` 必须最后做

## 任务列表

- `00-runtime-completion-protocol-freeze.md`
- `01-activation-driver-contract.md`
- `02-tma-runtime-contract.md`
- `03-durable-pool-runtime-snapshot.md`
- `04-activation-driver-runtime.md`
- `05-package-materializer-and-factory-resolver.md`
- `06-tma-planner-lane.md`
- `07-tma-executor-lane.md`
- `08-durable-human-gate.md`
- `09-durable-replay-and-activation-attempts.md`
- `10-runtime-recovery-assembly.md`
- `11-first-class-tooling-baseline-for-reviewer-and-tma.md`
- `12-end-to-end-runtime-closure-and-smoke.md`

## 一句话收口

这一包任务不是再证明 `TAP` 存不存在，而是把它补成一套真的能造能力、装能力、恢复能力状态的第三阶段 runtime 闭环。
