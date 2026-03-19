# 07 TMA Executor Lane

## 任务目标

把当前 provisioner 的“交 capability package 样板”推进成真正的 executor lane。

## 必须完成

- executor 输入使用批准后的 `BuildPlan`
- 真实产出：
  - tool artifact
  - binding artifact
  - verification artifact
  - usage artifact
- 产出 `BuildExecutionReport`
- 产出 `VerificationEvidence`
- 产出 `RollbackHandle`
- executor 不得完成原始用户任务

## 允许修改范围

- `src/agent_core/ta-pool-provision/**`
- `src/agent_core/capability-package/**`
- 必要时少量改 `src/agent_core/runtime.ts`

## 依赖前置

- `00`
- `02`
- `06`

## 不要做的事

- 不要让 executor 越权扩大 build scope
- 不要让 executor 自己批准 activation

## 验收标准

- provisioner runtime 不再只是 bridge 样板输出
- executor 的产出足够驱动 activation driver
- executor 失败时能留下完整 report 和失败证据
