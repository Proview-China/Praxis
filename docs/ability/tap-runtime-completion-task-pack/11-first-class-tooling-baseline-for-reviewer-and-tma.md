# 11 First-Class Tooling Baseline For Reviewer And TMA

## 任务目标

把 reviewer 与 `TMA` 真正需要的第一批基础能力接入 `TAP` 主链，避免两个 worker 继续空壳化。

## 必须完成

- reviewer 最小信息能力基线
- `bootstrap TMA` 最小施工能力基线
- `extended TMA` 高外部性能力基线
- 模式矩阵下的审批边界：
  - reviewer 能看什么
  - `TMA` 能做什么
  - 哪些必须升人工
- 第一批真实 capability package 的接入模板

## 推荐第一批能力

- `code.read`
- `docs.read`
- `repo.write`
- `shell.restricted`
- `test.run`
- `skill.doc.generate`
- `dependency.install`
- `network.download`
- `mcp.configure`

## 允许修改范围

- `src/agent_core/ta-pool-model/**`
- `src/agent_core/ta-pool-review/**`
- `src/agent_core/ta-pool-provision/**`
- `src/agent_core/capability-package/**`

## 依赖前置

- `02`
- `06`
- `07`

## 不要做的事

- 不要一口气接入所有厚能力
- 不要把 reviewer 的能力放宽到能执行

## 验收标准

- reviewer 与 `TMA` 不再只是逻辑空壳
- 第一批基础 capability 能按新 contract 被消费
- 后续接更多工具时有统一模板可套
