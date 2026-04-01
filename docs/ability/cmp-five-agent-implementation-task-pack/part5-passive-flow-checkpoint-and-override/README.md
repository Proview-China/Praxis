# Part 5 / Passive Flow Checkpoint And Override

状态：实施分包。

## 当前目标

把五个 agent 的被动查询、角色 checkpoint 和人工 override 收成第一版。

## 当前方向

- active/passive 混合常开
- 被动请求默认由 `DBAgent` 直接接单
- 每个角色都允许 checkpoint / recovery
- 每个角色都允许人工 override
- override 必须强审计
- checkpoint 第一版按事件级设计
- override 只允许改运行控制与裁决状态
- 不允许直接改 raw truth

## debug/admin 允许动作

- pause
- resume
- retry
- rebuild

## 建议拆分子任务

### P5-1 / Passive Query Path

- 固定 passive 请求对象
- 固定 `DBAgent` 直收、`Dispatcher` 回送
- 固定默认主载荷是 `ContextPackage`

### P5-2 / Event-Level Checkpoint

- 为五个角色补事件级 checkpoint
- 明确 checkpoint record 格式
- 明确角色级恢复入口

### P5-3 / Override Audit

- 固定审计最小五元组：
  - actor
  - reason
  - scope
  - timestamp
  - before / after
- 再加关键差异摘要
- 明确 override 不得改 raw truth

### P5-4 / Debug Admin Management Surface

- 固定只开放：
  - `pause`
  - `resume`
  - `retry`
  - `rebuild`
- 不开放真相写口
- 不开放完整角色控制台

## 建议多智能体编组

- `Part5 Lead`
  - 模型：`gpt-5.4-high`
- `P5-Passive Worker`
  - 模型：`gpt-5.4-high`
- `P5-Checkpoint Worker`
  - 模型：`gpt-5.4-xhigh`
- `P5-Audit Worker`
  - 模型：`gpt-5.4-high`

## 串并行建议

- `P5-1` 与 `P5-2` 可并行
- `P5-3` 依赖 `P5-2`
- `P5-4` 可与 `P5-3` 并行收口

## 本部分最低完成定义

- 五个角色都有 checkpoint / recovery 入口
- 被动查询链成立
- override audit 成立
- debug/admin 管理动作边界成立

## 本部分验收检查

- checkpoint 真的是事件级，不是伪装成事件级的粗粒度快照
- override 没有直接碰 raw truth
- debug/admin 没有被偷偷扩成角色完整内部接口
