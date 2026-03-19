# 02 TMA Runtime Contract

## 任务目标

把当前 provisioner 正式收口成 `toolmakeragent (TMA)` 的运行时契约。

## 必须完成

- 明确 `TMA planner` 与 `TMA executor` 的职责边界
- 定义 `BuildPlan`
- 定义 `BuildExecutionReport`
- 定义 `VerificationEvidence`
- 定义 `RollbackHandle`
- 明确 `bootstrap / extended` 两条 lane 的输入输出

## 允许修改范围

- `src/agent_core/ta-pool-provision/**`
- `src/agent_core/ta-pool-types/**`
- `src/agent_core/capability-package/**`

## 不要做的事

- 不要在这一任务里真正安装依赖
- 不要把 TMA 做成万能主 agent
- 不要允许 TMA 自己批准 activation

## 验收标准

- planner 与 executor 的边界在类型和测试层都明确
- 后续任务不需要再争论“plan 和 execution report 分不分开”
- 旧 provisioner worker bridge 能平滑映射到新 contract
