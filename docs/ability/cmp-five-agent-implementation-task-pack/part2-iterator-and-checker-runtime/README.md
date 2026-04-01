# Part 2 / Iterator And Checker Runtime

状态：实施分包。

## 当前目标

实现 `Iterator` 与 `Checker` 的第一版主动治理链。

## Iterator 当前边界

- 推 git 工作流
- 推到可审查状态
- 不负责最终 truth 拍板
- 以 `commit` 为最小可审查单元
- 是 `cmp/*` 线 git 主写角色

## Checker 当前边界

- 增删拆合
- checked 裁决
- suggest-promote
- promote 默认由直属父层拍板
- `checked` 与 `suggest-promote` 第一版硬分离
- 父层内部默认由父 `DBAgent` 主审 promote

## 建议拆分子任务

### P2-1 / Iterator Candidate Commit Path

- 落 `Iterator` 状态机：
  - `accept-material -> write-candidate-commit -> update-review-ref`
- 固定 candidate commit 产物
- 固定 review ref 推进规则

### P2-2 / Checker Restructure And Checked

- 落 `Checker` 状态机：
  - `accept-candidate -> restructure -> checked -> suggest-promote`
- 固定增删拆合语义
- 固定 checked 判定结果

### P2-3 / Suggest-Promote Request Path

- 固定 `suggest-promote` 请求对象
- 固定父层 promote 提请接缝
- 明确父 `DBAgent` 主审入口与父 `Checker` 协助位

### P2-4 / Runtime Checkpoint And Tests

- 为 `Iterator`、`Checker` 都补事件级 checkpoint
- 补主链单元测试与契约测试

## 建议多智能体编组

- `Part2 Lead`
  - 模型：`gpt-5.4-high`
- `P2-Iterator Worker`
  - 模型：`gpt-5.4-high`
- `P2-Checker Worker`
  - 模型：`gpt-5.4-xhigh`
- `P2-Promote Contract Worker`
  - 模型：`gpt-5.4-high`

## 串并行建议

- `P2-1` 与 `P2-2` 可先并行
- `P2-3` 依赖 `P2-2`
- `P2-4` 依赖前三项收口

## 本部分最低完成定义

- `Iterator Agent_Loop_Runtime` 成立
- `Checker Agent_Loop_Runtime` 成立
- candidate -> checked-ready -> checked 形成正式链路
- 父层 promote request 接缝明确

## 本部分验收检查

- `Iterator` 没有把 `PR` 当成最小推进单元
- `Checker` 没有把 `checked` 和 `suggest-promote` 写成联判
- 父层 promote 接缝明确指向父 `DBAgent`
