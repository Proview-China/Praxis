# 00 Protocol Freeze And Shared Types

## 任务目标

冻结第二阶段会共用的协议，避免后面 reviewer、provisioner、runtime assembly 互相打架。

## 必须完成

- 扩展 `ta-pool-types/**` 以支持：
  - 五种模式
  - 三档风险等级
  - reviewer vote 语义
  - `DecisionToken`
  - `PoolActivationSpec`
  - `ReplayPolicy`
- 冻结与 `GrantCompiler` 相关的共享类型
- 冻结 plain-language risk payload 的类型

## 允许修改范围

- `src/agent_core/ta-pool-types/**`
- 必要时少量更新 `src/agent_core/ta-pool-model/**`

## 不要做

- 不要接 runtime
- 不要接 reviewer agent
- 不要接 provisioner agent
- 不要写具体 builder

## 验收标准

- 类型检查通过
- 新增协议测试
- 所有后续任务都能直接依赖这些类型

## 交付说明

- 提交时明确列出新增类型
- 标注哪些是后续任务的前置协议
