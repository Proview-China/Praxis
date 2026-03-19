# TAP Capability Package Template

状态：冻结设计草案 v1。

更新时间：2026-03-19

## 这份文档解决什么问题

如果没有统一的 capability package 模板，后面 reviewer、provisioner、execution plane 会很快各说各话。

我们需要先承认一件事：

- 一个 capability 不是“一个函数”
- 一个 capability 是一套可注册、可审批、可执行、可验证、可复用的资产包

## 第一版 capability package 最小结构

每个 capability package 至少包含下面七部分：

1. `manifest`
2. `adapter`
3. `policy`
4. `builder`
5. `verification`
6. `usage`
7. `lifecycle`

第一版要求：

- 这七部分全部存在
- 不允许只交一个“工具本体”就算完成

## 1. `manifest`

描述“这是什么能力”。

最少字段：

- `capability_key`
- `capability_kind`
- `tier`
- `version`
- `generation`
- `description`
- `dependencies`
- `tags`
- `route_hints`
- `supported_platforms`

一句白话：

- `manifest` 是 capability 的身份证

## 2. `adapter`

描述“怎么接到 execution plane”。

最少字段：

- `adapter_id`
- `runtime_kind`
- `supports`
- `prepare`
- `execute`
- `cancel`
- `result_mapping`

一句白话：

- `adapter` 是 capability 真正跑起来的插头

## 3. `policy`

描述“默认怎么放权、怎么审核”。

最少字段：

- `default_baseline`
- `recommended_mode`
- `risk_level`
- `default_scope`
- `review_requirements`
- `safety_flags`
- `human_gate_requirements`

一句白话：

- `policy` 是 capability 的使用规则

## 4. `builder`

描述“如果缺失，怎么被 provisioner 构建出来”。

最少字段：

- `builder_id`
- `build_strategy`
- `requires_network`
- `requires_install`
- `requires_system_write`
- `allowed_workdir_scope`
- `activation_spec_ref`
- `replay_capability`

一句白话：

- `builder` 是 capability 的制造说明书

## 5. `verification`

描述“怎么证明它真的能用”。

最少字段：

- `smoke_entry`
- `health_entry`
- `success_criteria`
- `failure_signals`
- `evidence_output`

一句白话：

- `verification` 是 capability 的验收标准

## 6. `usage`

描述“agent 怎么正确使用它”。

最少字段：

- `usage_doc_ref`
- `skill_ref`
- `best_practices`
- `known_limits`
- `example_invocations`

一句白话：

- `usage` 是 capability 的说明书

## 7. `lifecycle`

描述“它怎么安装、升级、替换、退役”。

最少字段：

- `install_strategy`
- `replace_strategy`
- `rollback_strategy`
- `deprecate_strategy`
- `cleanup_strategy`
- `generation_policy`

一句白话：

- `lifecycle` 是 capability 的生命周期管理规则

## 第一版必须补的两个桥

### 1. `PoolActivationSpec`

当前 `binding artifact` 还只是 ref，不足以说明“怎么把 capability 正式接回池里”。

所以第一版新增冻结抽象：

- `PoolActivationSpec`

最少表达：

- `target_pool`
- `activation_mode`
- `manifest_payload`
- `binding_payload`
- `adapter_factory_ref`
- `register_or_replace`
- `generation_strategy`
- `drain_strategy`
- `rollback_handle`

### 2. `ReplayPolicy`

当前 provision 完成后，还没有正式规定“原 intent 要不要重放”。

所以第一版新增冻结抽象：

- `ReplayPolicy`

第一版枚举：

- `none`
- `manual`
- `auto_after_verify`
- `re_review_then_dispatch`

默认策略：

- `re_review_then_dispatch`

## 第一版 package artifact bundle 结构

provisioner 最终至少交回下面四类 artifact：

- `tool artifact`
- `binding artifact`
- `verification artifact`
- `usage artifact`

其中：

- `tool artifact` 对应 capability 本体
- `binding artifact` 必须能落到 `PoolActivationSpec`
- `verification artifact` 必须带 smoke/health 证据
- `usage artifact` 必须能被 agent 和开发者直接读懂

## 复用约束

这套 package template 不是只给 `tap` 用的。

后续如果出现：

- memory pool
- packaging pool
- governance pool

它们都应该优先复用下面这些抽象：

- `Request`
- `ReviewDecision`
- `Grant`
- `ProvisionRequest`
- `ArtifactBundle`
- `ContextAperture`
- `WorkerPromptPack`
- `PoolActivationSpec`
- `ReplayPolicy`

注意：

- 当前不要把 `TAP` 过早抽象成一个全通用框架
- 先把 `TAP` 做成第一套样板
- 等第二个池真的出现，再抽 shared control-plane primitives

## 当前冻结结论

第一版 capability package 强制要求：

- 必须带 `builder`
- 必须带 `verification`
- 必须带 `usage`

不满足这三项，不算可接入 `TAP` 的正式 capability package。
