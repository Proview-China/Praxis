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

## Wave 1 初步结论

当前第一轮研究已经先把几处真正高风险的口子摸出来了。

### Group 1. 入口与装配层

当前事实：

- `src/agent_core/runtime.ts` 在 `cmp/mp` 相对新 `dev` 的 diff 量级约为：
  - `3754 insertions`
  - `2602 deletions`
- `src/agent_core/runtime.test.ts` 的 diff 量级约为：
  - `1645 insertions`
  - `3141 deletions`
- `package.json` 在 `cmp/mp` 只多了少量 `CMP infra` 和 status 相关脚本

当前结论：

- `runtime.ts` / `runtime.test.ts` 是总装最后处理的高风险入口
- `package.json` 是相对容易先吸收的低成本入口

建议顺序：

1. 先补 `package.json` 的 `CMP` 脚本
2. 再做 `rax` 表面
3. 最后才碰 runtime assembly

### Group 2. `CMP` 主体层

当前事实：

- `cmp/mp` 已经有完整的：
  - `cmp-git`
  - `cmp-db`
  - `cmp-mq`
  - `cmp-runtime`
  - `cmp-five-agent`
  - `infra/cmp`
  - `scripts/cmp-status-panel-server.mjs`
- 其中支撑层与 infra 层的成熟度明显高于五角色与 live LLM 化层

当前结论：

- `cmp-git / cmp-db / cmp-mq / cmp-runtime / infra/cmp` 适合作为第一批吸收对象
- `cmp-five-agent`、`model-inference`、`rax.cmp` 应后置到第二批或第三批

### Group 3. reboot/TAP 基座层

当前事实：

- 新 `dev` 基座已经完整承接 `docs/ability/20-28` 与 `43-51`
- 这些文档表达的是当前 reboot/TAP 主线
- `cmp/mp` 虽然也带了 `43-51` 的副本，但不代表应该回覆盖新 `dev`

当前结论：

- `docs/ability/20-28` 与 `43-51` 应视为 reboot/TAP 基座保护区
- `CMP` 并入时不应反向覆盖这批基座文档
- `CMP <-> TAP` 的主要问题更像 wiring / assembly，而不是 reboot 文档方向错误

### Group 4. 文档与记忆层

当前事实：

- 新 `dev` 的 `docs/master.md` 仍是项目级长期主叙事入口
- 新 `dev` 的 `memory/current-context.md` 仍停在 `2026-03-18` 的 reboot 阶段
- `cmp/mp` 的 `memory/current-context.md` 则已经完全变成 `CMP` 收口快照

当前结论：

- `docs/master.md` 目前继续承担项目级长期主叙事入口
- `memory/current-context.md` 必须重写成“总装后的项目级现状”，不能直接用任一分支版本覆盖
- `memory/compaction-handoff-prompt*.md` 继续保留为阶段性交接材料，不升级为项目主叙事

### Group 5. legacy 资产层

当前事实：

- legacy 线目前仍保留：
  - `main`
  - `deploy`
  - `archive/dev-legacy-2026-04-01`
- 当前总装阶段还没有必要让新 `dev` 立即接触 `main`

当前结论：

- legacy 资产这一轮继续只做参考
- 真正处理 `dev -> main` 之前，先把新 `dev` 的 `CMP + TAP` 总装做实

## 下一轮研究建议

下一轮不再泛泛扩代理，建议按下面这个顺序继续：

1. 先对 Group 2 做更细的模块级并入排序
2. 再对 Group 1 做 runtime assembly 桥位盘点
3. 然后用 Group 4 的结论重写项目级 `memory/current-context.md`
4. 最后再决定第一批实际代码并入是否从 `infra/cmp + cmp-runtime` 开始

一句收口：

- 先研究清楚冲突面
- 再让多智能体去并行爆破
