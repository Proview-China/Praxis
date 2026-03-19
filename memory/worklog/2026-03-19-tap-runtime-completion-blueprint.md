# 2026-03-19 TAP Runtime Completion Blueprint

## 当前阶段结论

本轮没有继续写 `TAP` 代码，而是把后续三段真实可用化链路的详细设计冻结成文档：

- `activation driver`
- `real builder / toolmakeragent (TMA)`
- durable `human gate / replay`

对应文档：

- `docs/ability/27-tap-runtime-completion-blueprint.md`

## 这轮冻结的核心思路

### 1. activation driver

- 它是 `TAP control plane -> CapabilityPool execution plane` 的机械装配层
- 只负责把 provision 产物接回 pool
- 不负责审核、不负责造工具、不负责替主 agent 完成原任务

### 2. TMA

- provisioner 后续将继续收口成 `toolmakeragent`
- `TMA` 分两层：
  - `planner`
  - `executor`
- `planner` 负责想清楚怎么造
- `executor` 负责按批准过的 plan 机械执行

### 3. durable 恢复链

- 第一版不重构整个 kernel event 系统
- 先走 checkpoint-first 路线
- 先把下面这些对象 durable 化：
  - `TaHumanGateState`
  - `TaHumanGateEvent[]`
  - `TaPendingReplay`
  - `TaActivationAttemptRecord`

## 当前最重要的边界

- reviewer 继续只审、只读、只投票
- `TMA` 只造 capability，不完成原始用户任务
- activation driver 只做机械装配
- 当前先不提前抽 shared framework
- 先把 `TAP` 做成第一套完整样板

## 当前建议的实现顺序

1. `activation driver`
2. `real builder / TMA`
3. durable `human gate / replay`
