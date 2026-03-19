# 06 Provision Activation Spec And Asset Index

## 任务目标

补齐从“造出来”到“正式上架”的桥。

## 必须完成

- 新增 `PoolActivationSpec`
- 新增 `ProvisionAssetIndex`
- 将工单账本与资产目录分开
- 支持最少状态：
  - pending
  - building
  - verifying
  - ready_for_review
  - activating
  - active
  - failed
  - superseded
- 明确 `bindingArtifact` 如何映射到 activation spec

## 允许修改范围

- `src/agent_core/ta-pool-types/**`
- `src/agent_core/ta-pool-provision/**`
- 必要时少量改 `src/agent_core/ta-pool-runtime/**`

## 验收标准

- 资产索引能表达“已激活”和“仅 ready bundle”
- reviewer inventory 不再只看 capabilityPool 当前清单
