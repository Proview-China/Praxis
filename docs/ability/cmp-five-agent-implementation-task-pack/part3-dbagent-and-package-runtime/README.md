# Part 3 / DBAgent And Package Runtime

状态：实施分包。

## 当前目标

实现 `DBAgent` 的第一版 package / snapshot 物化链。

## 当前主产物

- `ContextPackage`

## 当前附产物

- `Task` 级 `Skill Snapshot`

## 当前实现纪律

- package 为主
- snapshot 为附属引用
- active / passive 双轨并行
- snapshot 随 checked / promoted 增量更新
- `CMP DB` 结构化写权限只给 `DBAgent`
- 包族关系固定为：
  - 现场主包
  - 时间线附包
  - 多个 task snapshot

## 建议拆分子任务

### P3-1 / Package Family Schema

- 定义现场主包
- 定义时间线附包
- 定义多 snapshot 挂接方式
- 明确三者引用关系

### P3-2 / DBAgent Projection Path

- 落 `DBAgent` 状态机：
  - `accept-checked -> project -> materialize-package -> attach-snapshots -> serve-passive`
- 固定 checked truth 到 DB projection 的写入纪律

### P3-3 / Passive Serve Path

- 固定 passive request 直达 `DBAgent`
- 固定默认返回 `ContextPackage`
- 明确时间线附包何时随包返回

### P3-4 / Parent Promote Review Intake

- 落父 `DBAgent` 主审 promote 的入口
- 明确父 `Checker` 的协助取证接口
- 不把 promote 主审写回父 `Checker`

### P3-5 / Tests And Readback

- 补 package family 契约测试
- 补 active / passive 双轨测试
- 补 promote review intake 测试

## 建议多智能体编组

- `Part3 Lead`
  - 模型：`gpt-5.4-high`
- `P3-Schema Worker`
  - 模型：`gpt-5.4-high`
- `P3-Projection Worker`
  - 模型：`gpt-5.4-xhigh`
- `P3-Passive Worker`
  - 模型：`gpt-5.4-high`

## 串并行建议

- `P3-1` 与 `P3-2` 可先并行推进
- `P3-3` 依赖 `P3-1`、`P3-2`
- `P3-4` 依赖 `P2-3`
- `P3-5` 在前三者收口后统一补齐

## 本部分最低完成定义

- `DBAgent Agent_Loop_Runtime` 成立
- checked truth -> package materialization 成立
- checked/promoted -> skill snapshot 增量更新成立
- passive request 直达 `DBAgent` 的入口成立

## 本部分验收检查

- `DBAgent` 保持 `CMP DB` 主写单点
- 现场主包与时间线附包没有被糊成一个无限膨胀大包
- promote 主审角色仍是父 `DBAgent`
