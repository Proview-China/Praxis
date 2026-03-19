# 01 Mode Matrix And Risk Policy Upgrade

## 任务目标

把当前 `strict / balanced / yolo` 升级成第二阶段冻结的五模式体系，并接入三档风险等级。

## 必须完成

- 扩展 mode policy：
  - `bapr`
  - `yolo`
  - `permissive`
  - `standard`
  - `restricted`
- 接入风险等级：
  - `normal`
  - `risky`
  - `dangerous`
- 定义 capability risk classifier 的纯函数层
- 明确不同模式下：
  - baseline 是否直放
  - reviewer 是否自动批准
  - 是否默认转人工
  - 是否中断

## 允许修改范围

- `src/agent_core/ta-pool-model/**`
- `src/agent_core/ta-pool-safety/**`
- 配套测试

## 不要做

- 不要改 runtime 主路径
- 不要接 LLM reviewer

## 验收标准

- 模式矩阵单测齐全
- 风险等级单测齐全
- `bapr` / `restricted` 行为语义明确
