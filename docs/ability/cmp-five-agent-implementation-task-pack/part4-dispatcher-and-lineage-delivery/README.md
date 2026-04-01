# Part 4 / Dispatcher And Lineage Delivery

状态：实施分包。

## 当前目标

实现 `Dispatcher` 的第一版交付链。

## 当前职责

- 主 agent 回填
- 子 agent 播种
- 同父平级受控交换
- delivery / ack 回执

## 当前纪律

- 同父平级可交换，但必须先有直属父节点批准
- 不同父节点子树默认硬隔离
- dispatcher 不负责下游再裁剪
- 子节点播种默认只进子节点 `ICMA`
- 同父平级交换默认走瘦交换包

## 建议拆分子任务

### P4-1 / Delivery Route Baseline

- 落 `Dispatcher` 状态机：
  - `route -> deliver -> collect-receipt -> timeout-handle`
- 固定 delivered / acknowledged 语义
- 固定 timeout 后续行为

### P4-2 / Parent-Child Reseed

- 固定父节点如何给子节点播种
- 固定高密度但任务定向的播种策略
- 明确只进子 `ICMA`

### P4-3 / Same-Parent Peer Package

- 定义瘦交换包
- 定义直属父节点显式一次性批准记录
- 定义交换后的交付与回执

### P4-4 / Cross-Parent Isolation

- 固定异父子树硬隔离规则
- 补隔离回归测试

## 建议多智能体编组

- `Part4 Lead`
  - 模型：`gpt-5.4-high`
- `P4-Route Worker`
  - 模型：`gpt-5.4-high`
- `P4-Lineage Worker`
  - 模型：`gpt-5.4-xhigh`
- `P4-Isolation Worker`
  - 模型：`gpt-5.4-high`

## 串并行建议

- `P4-1` 可先单独起
- `P4-2` 与 `P4-3` 依赖 `P4-1`
- `P4-4` 可与 `P4-3` 并行推进

## 本部分最低完成定义

- `Dispatcher Agent_Loop_Runtime` 成立
- delivered / acknowledged 回执成立
- parent-child reseed 成立
- same-parent peer exchange 成立
- cross-parent isolation 成立

## 本部分验收检查

- 子代播种没有绕过子 `ICMA`
- 同父交换都有显式批准记录
- peer exchange 默认交换的是瘦交换包而不是完整主包
