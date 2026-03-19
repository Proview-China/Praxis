# 09 Capability Package Template SDK

## 任务目标

把 capability package template 下沉成代码层可复用的 helper / schema / builder sdk。

## 必须完成

- 为 capability package 的七部分补 schema/helper
- 为 activation spec 和 replay policy 补 helper
- 提供 package validation
- 提供最小 package fixture

## 允许修改范围

- `src/agent_core/capability-types/**`
- `src/agent_core/ta-pool-types/**`
- 必要时新建 `src/agent_core/capability-package/**`

## 验收标准

- 新 capability package 能通过统一校验
- provisioner 输出能直接落到这个模板上
