# Part 1 / ICMA And Ingress Runtime

状态：实施分包。

## 当前目标

实现 `ICMA` 的第一版 runtime。

## 当前职责

- 接住 `core_agent` 输入和运行历史
- 整形成中等语义块
- 生成下一步可推进的 ingress materials
- 挂受控 `system fragment`

## 当前冻结口子

- 默认按任务意图切块
- 默认状态机：
  - `capture -> chunk-by-intent -> attach-fragment -> emit`
- `system fragment` 只允许：
  - 约束
  - 风险
  - 流程
- `system fragment` 默认按任务阶段持续生效
- `ICMA` 不直接写 git

## 当前明确不做

- 不做最终 history truth 裁决
- 不做最终 projection/package 物化
- 不做 promote 拍板

## 建议拆分子任务

### P1-1 / Ingress Event Shape

- 定义 `ICMA` 的输入对象
- 定义 intent chunk 结果
- 定义发给 `Iterator` 的出口对象
- 交付：
  - 明确字段
  - 明确生命周期
  - 明确谁能写谁能读

### P1-2 / Intent Chunking

- 落任务意图切块规则
- 区分：
  - 新任务意图
  - 延续任务意图
  - 附属运行材料
- 保证 `ICMA` 不变成大而全重整器

### P1-3 / Controlled System Fragment

- 落 fragment 模板与白名单
- 明确允许注入的三类内容
- 明确撤销条件
- 明确不可注入模板

### P1-4 / ICMA Runtime And Checkpoint

- 落 `ICMA Agent_Loop_Runtime`
- 落事件级 checkpoint
- 落最小恢复入口
- 补测试

## 建议多智能体编组

- `Part1 Lead`
  - 模型：`gpt-5.4-high`
- `P1-Event Worker`
  - 模型：`gpt-5.4-high`
- `P1-Fragment Worker`
  - 模型：`gpt-5.4-high`
- `P1-Runtime Worker`
  - 模型：`gpt-5.4-xhigh`
  - 负责状态机和 checkpoint

## 串并行建议

- `P1-1` 与 `P1-3` 可并行
- `P1-2` 依赖 `P1-1`
- `P1-4` 依赖 `P1-1`、`P1-2`、`P1-3`

## 本部分最低完成定义

- `ICMA Agent_Loop_Runtime` 成立
- ingress 输入输出对象明确
- controlled system fragment 有白名单 / 规则生成边界
- `ICMA` 可把输入推进到 `Iterator` 可接状态

## 本部分验收检查

- `ICMA` 没有偷偷拿 git 主写能力
- `system fragment` 不能自由改写根 `system`
- 出口对象能被 `Iterator` 直接消费
