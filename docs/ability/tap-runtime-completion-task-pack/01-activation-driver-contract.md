# 01 Activation Driver Contract

## 任务目标

冻结 activation driver 的输入、输出、状态流转和失败语义。

## 必须完成

- 定义 activation driver 的最小输入
- 定义 activation receipt / failure 输出
- 定义激活前校验项：
  - `targetPool`
  - `adapterFactoryRef`
  - `manifestPayload`
  - `bindingPayload`
  - generation / registration / drain 策略
- 定义 asset lifecycle 推进规则
- 定义回滚句柄和失败重试边界

## 允许修改范围

- `src/agent_core/ta-pool-types/**`
- `src/agent_core/ta-pool-runtime/**`
- 必要时少量改 `src/agent_core/capability-package/**`

## 不要做的事

- 不要在 contract 里塞 reviewer 逻辑
- 不要让 activation driver 自己决定 replay
- 不要让 activation driver 直接完成用户任务

## 验收标准

- contract 能表达成功、失败、重试、回滚
- 后续 worker 可以按 contract 直接写 runtime
- 文档和代码里的 activation 术语一致
