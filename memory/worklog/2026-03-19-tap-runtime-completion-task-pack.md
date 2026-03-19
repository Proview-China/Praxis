# 2026-03-19 TAP Runtime Completion Task Pack

## 当前阶段结论

本轮已经把 `TAP` 第三阶段实现拆成可直接发包的并行任务清单。

对应目录：

- `docs/ability/tap-runtime-completion-task-pack/`

## 当前任务包结构

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

## 当前推荐分波

1. `00`
2. `01 / 02 / 03`
3. `04 / 05 / 06 / 07`
4. `08 / 09 / 10`
5. `11 / 12`

## 当前最重要的调度建议

- 总并发建议控制在 `4-6`
- 不要让太多 worker 同时改：
  - `src/agent_core/runtime.ts`
  - `src/agent_core/ta-pool-runtime/**`
  - `src/agent_core/ta-pool-types/**`
- `12` 必须最后做
