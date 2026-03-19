# 06 TMA Planner Lane

## 任务目标

把当前 provisioner 的“会描述要造什么”部分正式收成 planner lane。

## 必须完成

- planner lane 输入封装
- planner prompt pack / envelope
- `BuildPlan` 结构化输出
- sibling capability / reuse 检查
- verification / rollback plan 输出
- 严格禁止 planner 直接做执行副作用

## 允许修改范围

- `src/agent_core/ta-pool-provision/**`
- `src/agent_core/ta-pool-context/**`
- `src/agent_core/ta-pool-types/**`

## 依赖前置

- `00`
- `02`

## 不要做的事

- 不要让 planner 直接跑 shell
- 不要让 planner 直接交 ready bundle

## 验收标准

- planner 只产出 plan，不产出 execution side effect
- planner 输出能被 executor 直接消费
- planner 可以明确说明“复用已有能力”还是“需要新建能力”
