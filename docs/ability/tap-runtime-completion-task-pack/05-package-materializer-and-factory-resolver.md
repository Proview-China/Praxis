# 05 Package Materializer And Factory Resolver

## 任务目标

补齐从 `ready bundle / capability package` 到“真正可注册 execution object”的转换桥。

## 必须完成

- 新增 capability package materializer
- 新增 adapter factory resolver
- 支持从 `manifestPayload / bindingPayload` 还原：
  - `CapabilityManifest`
  - `CapabilityAdapter`
  - 必要的 binding metadata
- 明确 `adapterFactoryRef` 的解析规则

## 允许修改范围

- `src/agent_core/capability-package/**`
- `src/agent_core/ta-pool-runtime/**`
- 必要时少量改 `src/agent_core/capability-types/**`

## 不要做的事

- 不要在这里接 runtime 审批逻辑
- 不要把 materializer 写死成只服务一个 capability

## 验收标准

- activation driver 不需要自己手搓 manifest/adapter
- package -> execution object 的转换可以独立测试
- 未来新的 capability package 可以复用同一条 materialize 链
