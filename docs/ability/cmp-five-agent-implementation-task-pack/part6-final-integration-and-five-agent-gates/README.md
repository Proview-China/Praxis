# Part 6 / Final Integration And Five-Agent Gates

状态：实施分包。

## 当前目标

完成五个 agent 的 runtime assembly 和最终联调。

## 当前重点

- 混合代理接口
- 五个角色 capability matrix
- 与现有 `CMP` 总接口的兼容
- end-to-end smoke
- five-agent-ready gate

## 建议拆分子任务

### P6-1 / Role Capability Matrix

- 落五个角色最小权限面
- 落角色到 `TAP` 的能力申请边界
- 明确默认高外部性动作禁区

### P6-2 / Runtime Assembly

- 把五个 `Agent_Loop_Runtime` 正式装进 `cmp-runtime`
- 接上现有：
  - `core_agent -> rax.cmp -> cmp-runtime`
- 守住主线程独占文件

### P6-3 / Facade And Admin Surface

- 把新的五-agent runtime 组装进 `rax.cmp`
- 保持现有总接口兼容
- 保持 debug/admin 只暴露管理动作

### P6-4 / Integration Tests And Gates

- 补主动链联调
- 补被动链联调
- 补父子播种链联调
- 补 five-agent-ready gate

## 建议多智能体编组

- `Part6 Lead`
  - 模型：`gpt-5.4-high`
- `P6-Capability Worker`
  - 模型：`gpt-5.4-high`
- `P6-Assembly Worker`
  - 模型：`gpt-5.4-xhigh`
- `P6-Integration Worker`
  - 模型：`gpt-5.4-high`

## 串并行建议

- `P6-1` 可先于总装并行准备
- `P6-2` 依赖 Part 1-5 主路径稳定
- `P6-3` 与 `P6-2` 紧密联动，由主线程收冲突
- `P6-4` 在 `P6-2`、`P6-3` 收口后统一执行

## 本部分最低完成定义

- 五个 `Agent_Loop_Runtime` 能被正式装配
- 主动链 / 被动链 / 父子播种链都能联调
- 角色差异化能力矩阵成立
- five-agent-ready smoke gate 成立

## 本部分验收检查

- 五个 runtime 真被正式装配，而不是只写了空壳
- `rax.cmp` 没有失去现有总控制台语义
- 三条链都能跑通最小 smoke
