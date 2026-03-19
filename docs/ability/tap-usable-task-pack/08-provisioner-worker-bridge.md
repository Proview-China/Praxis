# 08 Provisioner Worker Bridge

## 任务目标

把 provisioner 从 mock builder 提升为真正的 builder worker bridge。

## 必须完成

- 定义 provisioner worker prompt pack
- 定义 provisioner 输入封包
- 定义 provisioner 输出 schema
- 区分：
  - bootstrap provisioner
  - extended provisioner
- 输出必须包含：
  - tool artifact
  - binding artifact
  - verification artifact
  - usage artifact
  - activation payload
  - replay recommendation

## 允许修改范围

- `src/agent_core/ta-pool-provision/**`
- 必要时新建 `src/agent_core/ta-pool-workers/**`

## 不要做

- 不要让 provisioner 自己批准执行
- 不要让 provisioner 直接替主 agent 完成原任务

## 验收标准

- provisioner worker bridge 可替换 mock builder
- builder 输出符合 package template
- bootstrap / extended 权限层有清晰边界
