# Dev-Master Conflict Research Plan

状态：总装冲突研究计划 / 并行分析稿。

更新时间：2026-04-02

## 这份文档回答什么

这份文档专门回答：

- 新 `dev` 的总装冲突应该从哪里查起
- 为什么不能只看 `git diff`
- 多智能体并行时，哪些冲突面适合拆开研究
- 每组冲突研究完成后，需要产出什么结论

一句白话：

- 它不是修复文档
- 它是修复前的研究地图

## 总体方法

这轮不要按“文件越多越危险”的方式看冲突。

应该按装配面拆成下面 5 组：

1. 入口与装配层
2. `CMP` 主体层
3. `TAP` 基座层
4. 文档与记忆层
5. legacy 资产层

## Group 1. 入口与装配层

主要对象：

- `src/agent_core/runtime.ts`
- `src/agent_core/runtime.test.ts`
- `src/rax/index.ts`
- `package.json`

研究问题：

- 当前 runtime assembly 是怎么接 `TAP` 的
- `CMP` 并入后最少需要补哪些桥位
- 哪些导出面会发生重名、重复或语义冲突
- `check/build/test` 的当前脚本是否覆盖总装后主线

产出物：

- 入口冲突清单
- 最小接缝方案
- 需要主线程统一拍板的点

## Group 2. `CMP` 主体层

主要对象：

- `src/agent_core/cmp-*/**`
- `src/rax/cmp-*/**`
- `infra/cmp/**`

研究问题：

- 哪些 `CMP` 模块已经形成最小可保真主链
- 哪些仍属于阶段性尝试
- 哪些模块对 runtime 入口有硬依赖
- 哪些模块可先独立并入而不碰总装入口

产出物：

- 可直接并入清单
- 需要延后并入清单
- `CMP` 主链最小闭环图

## Group 3. `TAP` 基座层

主要对象：

- `docs/ability/20-28`
- `docs/ability/43-51`
- `src/agent_core/ta-pool*/**`

研究问题：

- reboot 后续 `TAP` 演进对新 `dev` 的硬约束是什么
- 哪些 `TAP` 文档仍是当前主口径
- `CMP <-> TAP` 的当前接缝缺的是 wiring、contract，还是验收口径
- 哪些 `CMP` 并入动作可能会误伤 `TAP` 基座

产出物：

- reboot 基座保护清单
- `TAP` 不可覆盖区域清单
- `CMP <-> TAP` 最小供给接缝问题单

## Group 4. 文档与记忆层

主要对象：

- `docs/master.md`
- `memory/current-context.md`
- `memory/worklog/**`
- `memory/compaction-handoff-prompt*.md`

研究问题：

- 哪些内容应该升级成长期主叙事
- 哪些只应保留为阶段性交接材料
- 总装后新的“唯一入口”应该由哪些文件承担
- 哪些 worklog 需要在总装后改写为面向主线的摘要

产出物：

- 项目级同步总纲章节表
- 长期入口文件清单
- 阶段性交接材料保留清单

## Group 5. legacy 资产层

主要对象：

- `main`
- `deploy`
- `archive/dev-legacy-2026-04-01`

研究问题：

- 哪些旧资产只保留为历史参考
- 哪些 deploy 语义仍应迁移到新主线
- 什么时候再考虑 `dev -> main`
- 当前绝对不应回搬的 legacy 包袱有哪些

产出物：

- legacy 归档与复用边界说明
- deploy 语义迁移清单

## 并行研究顺序

最稳妥的顺序：

1. Group 4 文档与记忆层
2. Group 3 `TAP` 基座层
3. Group 2 `CMP` 主体层
4. Group 1 入口与装配层
5. Group 5 legacy 资产层

原因：

- 先统一口径
- 再保护基座
- 再判断哪些 `CMP` 资产能安全接回
- 最后才碰高冲突入口和 legacy 切线

## 多智能体建议

### Explorer 1

负责：

- Group 4

### Explorer 2

负责：

- Group 3

### Explorer 3

负责：

- Group 2

### 主线程

负责：

- Group 1
- Group 5
- 最终汇总

## 完成标志

只有同时满足下面这些条件，才算冲突研究完成：

1. 每组都有“关键问题 -> 结论 -> 后续动作”
2. 每组都能落到具体文件或目录
3. 总装入口冲突已被缩成有限清单
4. 后续并行施工时，worker 已有明确写域

一句收口：

- 先研究清楚冲突面
- 再让多智能体去并行爆破
