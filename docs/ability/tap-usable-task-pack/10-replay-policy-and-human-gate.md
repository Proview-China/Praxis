# 10 Replay Policy And Human Gate

## 任务目标

补齐 provision 之后的后续决策和 restricted 模式的人类审批链。

## 必须完成

- 冻结 `ReplayPolicy`
- 支持：
  - none
  - manual
  - auto_after_verify
  - re_review_then_dispatch
- 第一版默认策略：
  - `re_review_then_dispatch`
- 新增 human gate 状态与事件语义
- 为用户输出白话风险说明和可点击动作

## 允许修改范围

- `src/agent_core/ta-pool-types/**`
- `src/agent_core/ta-pool-runtime/**`
- `src/agent_core/runtime.ts`
- 必要时少量改 journal/state 协议

## 验收标准

- `restricted` 模式可以等待人工批准
- loop 不被异常打断
- approval/reject 事件可回注继续运行
