# 02 Review Vote And Grant Compiler

## 任务目标

把 reviewer 从“可直接给 grant”改成“只投票”，并由 kernel/compiler 机械生成真正 grant。

## 必须完成

- 新增 `ReviewVote` 或同义结构
- reviewer runtime 输出 vote，而不是最终可执行 grant
- 新增 `GrantCompiler`
- 在 grant 编译时强制校验：
  - request 兼容性
  - capability key 一致性
  - tier 不放宽
  - scope 不放宽
  - mode 不改写

## 允许修改范围

- `src/agent_core/ta-pool-review/**`
- `src/agent_core/ta-pool-runtime/**`
- 必要时少量改 `src/agent_core/runtime.ts`

## 不要做

- 不要切默认主路径
- 不要接真正 LLM worker

## 验收标准

- 兼容性校验进入主链
- 伪造宽 grant 的负向测试失败
- reviewer 不再直接控制 execution grant
