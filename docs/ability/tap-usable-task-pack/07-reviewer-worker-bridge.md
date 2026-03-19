# 07 Reviewer Worker Bridge

## 任务目标

把 `llmReviewerHook` 升级成真正的 reviewer worker bridge，但仍保持 reviewer 只审不执行。

## 必须完成

- 定义 reviewer worker prompt pack
- 定义 reviewer 输入封包
- 定义 reviewer 输出 schema
- bridge 只收结构化 vote
- reviewer 不直接拿 runtime / shell / write capability
- reviewer 运行在 bootstrap reviewer lane

## 允许修改范围

- `src/agent_core/ta-pool-review/**`
- 必要时新建 `src/agent_core/ta-pool-workers/**`
- 测试与 fixture

## 不要做

- 不要让 reviewer 直接 dispatch
- 不要给 reviewer 文件写或系统写能力

## 验收标准

- reviewer worker bridge 可替换现有 hook
- reviewer 只能回 vote
- 负向测试能证明 reviewer 无法越权成执行器
