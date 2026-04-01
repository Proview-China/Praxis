# Dev-Master Integration Outline

状态：总装总纲 / 分支治理与架构同步稿。

更新时间：2026-04-01

## 这份文档回答什么

这份文档专门回答：

- 为什么现在需要新开一条总装线来承接 `reboot` 之后的现状。
- 为什么总装基座优先选择 `reboot/blank-slate`，而不是旧 `main/dev`。
- `cmp/mp` 这条线到底应该怎样并入总装，而不是被误判成另一套替代主线。
- 旧世界分支该怎么归档保留，哪些东西还值得迁移。
- 后续从总装线推进到新 `main` 时，最稳妥的阶段顺序是什么。

一句白话：

- 这份文档不是再讨论原则。
- 它是给后续实际合并、整理、同步方向用的施工总图。

## 分支命名说明

用户原始意图是建立一条逻辑上的 `dev/master` 总装线。

但当前仓库已经存在顶级分支 `dev`，Git 不能同时再创建 `dev/master` 这种子路径分支。

因此当前实际落地分支命名为：

- `dev-master`

它在语义上等价于：

- 总装开发主线
- 新世界的集成分支
- 后续准备提升到 `main` 的 staging 主线

除非未来先重命名或清理旧 `dev`，否则不要继续尝试真实创建 `dev/master`。

## 当前总判断

当前仓库里同时存在两类历史：

### 1. legacy 世界

- `main`
- `dev`
- `deploy`

这组分支承载的是旧实现与旧流程。

它们对今天的价值主要是：

- 历史参考
- 旧 deploy 流程参考
- 回滚抓手

它们不应继续被当成 reboot 之后的新实现基座。

### 2. reboot 世界

- `reboot/blank-slate`
- `cmp/mp`

这组分支承载的是当前仍有生命力的新架构。

但它们不是简单的前后替代关系，而是：

- `reboot/blank-slate` 更偏基座、`agent_core`、`CapabilityPool`、`TAP`
- `cmp/mp` 更偏 `CMP`、`rax.cmp`、shared infra lowering、five-agent closure

一句白话：

- `reboot` 在补工具池和底盘
- `cmp/mp` 在补上下文治理池
- 总装的目标不是二选一
- 而是把两边重新装回同一套系统

## 与架构图的对齐结论

按当前图与文档一起回读，必须先把下面几条看成硬约束：

1. `CMP`、`MP`、`TAP` 是并列池，不是互相替代的历史版本。
2. `git_infra` 是共享协作底座，不是 `CMP` 私有子系统。
3. `TAP` 管能力供给与治理，不负责替代 `CMP` 的历史主干。
4. `CMP` 的 canonical source 仍然是 `git`，不是 RAG/vector。
5. `CMP DB` 是结构化投影层，不是第二真相源。
6. `MP` 仍然是未来方向，当前不要把它和这轮 `CMP` 总装混成一团。

## 为什么 `reboot/blank-slate` 是总装基座

当前选择 `reboot/blank-slate` 作为 `dev-master` 基座，理由有 4 个：

1. 它代表 reboot 后的新世界根历史。
2. 它已经承载：
   - `agent_core`
   - capability interface / pool
   - `T/A Pool`
   - `TAP` runtime completion
   - three-agent real usage
3. 它比 legacy `main/dev` 更接近当前真实架构方向。
4. 它已经是仓库级 `memory/`、`docs/ability/`、TypeScript/Node 基座的自然起点。

## `cmp/mp` 的正确定位

`cmp/mp` 这个名字本身容易误导。

按当前仓库记忆与文档，它当前承载的真实重点不是“已经开始做 `MP`”，而是：

- `CMP` 主线继续收口
- `CMP infra` 真实 backend 骨架
- `CMP runtime` 接入与 lowering
- `rax.cmp`
- non-five-agent closure
- five-agent runtime / configuration / final closure

因此，当前总装时要把它理解为：

- `CMP integration line`

而不是：

- `MP completed line`

## 三类分支资产的处置原则

## A. `reboot/blank-slate`

默认整线继承。

它是 `dev-master` 的基座，不作为被合并对象看待。

重点保留：

- `src/agent_core/**`
- `src/rax/**`
- `memory/**`
- `docs/ability/20-28`
- `docs/ability/43-51`
- `tap-* task pack`

## B. `cmp/mp`

按主题并回总装。

默认需要吸收的资产：

- `docs/ability/29-40`
- `docs/ability/44-46`
- `cmp-* task pack`
- `memory/current-context.md`
- `memory/compaction-handoff-prompt*.md`
- `memory/worklog/2026-03-20*`
- `memory/worklog/2026-03-24*`
- `memory/worklog/2026-03-25-cmp-*`
- `infra/cmp/**`
- `scripts/cmp-status-panel-server.mjs`
- `src/agent_core/cmp-*/**`
- `src/rax/cmp-*/**`

需要谨慎对待的内容：

- `memory/live-reports/cmp-*`
- 只服务某次 live smoke 的瞬时 JSON
- 当前 `cmp/mp` 工作区里的未提交实验性改动

## C. legacy `main/dev/deploy`

默认归档保留，不直接混入总装。

仍值得逐项复核的资产：

- `deploy` 线上的部署经验与 workflow 语义
- 旧 `main/dev` 中少量仍有长期价值的说明或流程约束

默认不回搬的内容：

- 旧 `better-agent/` 目录结构
- 旧 UI 壳子与其技术栈包袱
- 与 reboot 方向相冲突的旧时实现假设

## 当前已知冲突热点

总装时最可能冲突的装配口，不是全仓，而是下面这些高耦合文件：

- `src/agent_core/runtime.ts`
- `src/agent_core/runtime.test.ts`
- `src/rax/index.ts`
- `src/rax/facade.ts`
- `src/rax/runtime.test.ts`
- `package.json`
- `docs/master.md`
- `memory/current-context.md`

白话：

- 真正难的不是文件数量
- 而是几处总装入口要同时接住 `TAP` 和 `CMP`

## 这轮总装的应有变动

这次不是简单把 `cmp/mp` 的文件整包覆盖到 `reboot` 上。

真正应该发生的变动，至少包括下面 6 类：

### 1. 主线身份变更

- `dev` 不再继续代表 legacy 世界的旧开发线
- `dev-master` 所代表的新世界总装状态，应直接接管新的 `dev`
- `dev` 之后的语义应变成：
  - reboot 之后的新开发主线
  - `CMP + TAP` 的统一集成线

### 2. 文档入口统一

- `docs/master.md` 必须能同时解释：
  - reboot 基座
  - `TAP`
  - `CMP`
  - 后续 `MP`
- 不再让后续协作者靠零散 handoff prompt 才知道当前主方向

### 3. 记忆入口统一

- `memory/current-context.md` 需要从“某一轮 `CMP` 收口快照”
  升级成“总装后的项目级当前状态”
- `memory/compaction-handoff-prompt*.md` 仍保留，但不再代替项目主叙事

### 4. runtime 总装

- `agent_core` 的 runtime assembly 需要同时接住：
  - reboot 线已经成立的 `TAP`
  - `cmp/mp` 线带来的 `CMP`
- 目标不是二选一保留，而是让两条链在总装入口上共存

### 5. `rax` 表面统一

- `src/rax/**` 需要从“分别承载 `TAP` 或 `CMP` 的局部出口”
  收成对外统一表面
- 后续外层应该能从一个清楚的 `rax` 出口理解：
  - 哪些是 capability/tap 面
  - 哪些是 cmp/context 面

### 6. 验收口径升级

- 旧的阶段性 “某条线已收口” 结论，要升级成总装口径
- 后续验收不再只问：
  - `CMP` 自己能不能跑
  - `TAP` 自己能不能跑
- 而要问：
  - 总装后的主线是不是已经形成统一施工基线

## 冲突研究矩阵

后续细查时，不要按“分支 vs 分支”粗看，而要按下面 5 组装配面逐组研究：

### A. 入口与装配层

主要文件：

- `src/agent_core/runtime.ts`
- `src/agent_core/runtime.test.ts`
- `src/rax/index.ts`
- `package.json`

要回答的问题：

- `CMP` 入口和 `TAP` 入口谁在主链上先发生
- runtime assembly 当前缺少哪些桥位
- 新主线的 check/build/test 脚本是否足以覆盖两侧

### B. `CMP` 主体层

主要目录：

- `src/agent_core/cmp-*/**`
- `src/rax/cmp-*/**`
- `infra/cmp/**`

要回答的问题：

- 哪些实现已经到“应并入总装”的成熟度
- 哪些 still 属于阶段性试验或 live smoke 辅助
- `CMP` 当前最小可保真主链到底是哪一段

### C. `TAP` 基座层

主要目录：

- `src/agent_core/ta-pool*/**`
- `docs/ability/20-28`
- `docs/ability/43-51`

要回答的问题：

- reboot 线后续 `TAP` 演进对总装入口提出了什么新要求
- 哪些 `TAP` 文档已经过时，哪些仍是当前真实口径
- `CMP <-> TAP` 最小供给接缝现在缺的是 wiring 还是 contract

### D. 文档与记忆层

主要文件：

- `docs/master.md`
- `memory/current-context.md`
- `memory/worklog/**`
- `memory/compaction-handoff-prompt*.md`

要回答的问题：

- 哪些文档代表长期主叙事
- 哪些只是阶段性交接材料
- 总装后项目级“唯一入口”应由哪些文件承担

### E. legacy 资产层

主要分支：

- `main`
- `dev`
- `deploy`

要回答的问题：

- 哪些旧内容只保留为参考
- 哪些 deploy 语义仍要迁移到新主线
- 何时正式让新 `dev` 再去接管 `main`

## `dev-master` 总装阶段

## Phase 0. 现场保护

目标：

- 保住当前 `cmp/mp` 脏工作区
- 不在现有工作目录硬切分支
- 用独立 worktree 作为总装现场

当前已执行：

- 已建立本地与远端 `dev-master`
- 已从 `origin/reboot/blank-slate` 拉出独立 worktree

## Phase 1. reboot 基座冻结

目标：

- 以 `reboot/blank-slate` 当前状态作为总装起点
- 不在总装第一步就把 legacy 或 `cmp` 混进来

完成标志：

- `dev-master` 能清楚代表“当前新世界底板”

## Phase 2. `CMP` 资产并入

目标：

- 把 `cmp/mp` 中真正属于 `CMP` 主线的代码、文档、记忆和 infra 并入总装

推荐顺序：

1. 文档与记忆先行
2. `infra/cmp` 与脚本并入
3. `src/agent_core/cmp-*`
4. `src/rax/cmp-*`
5. 总装入口与测试修正

## Phase 3. 总装接缝修复

目标：

- 解决 `CMP` 与 reboot 后续 `TAP` 演进在总装入口上的冲突

重点处理：

- runtime assembly
- `rax` export surface
- acceptance gate
- `CMP <-> TAP` 最小供给接缝

## Phase 4. 项目级方向同步

目标：

- 形成一份新的项目级总纲
- 让后续 agent 不再需要靠猜测理解“当前应该先做什么”

至少要同步：

- 当前架构图口径
- 三类分支的地位
- `CMP/TAP/MP` 的边界
- 当前优先级
- 下一阶段验收口径

## Phase 5. 准备提升到 `main`

目标：

- 在总装完成并验证后，让 `dev-master` 成为进入新 `main` 的唯一候选线

这一阶段再决定：

- 是通过 PR 进入 `main`
- 还是先归档旧 `main`，再做主线切换

在这之前，不要提前讨论 deploy。

## 总装阶段的禁止事项

- 不要把 legacy `main/dev` 当成本轮基座。
- 不要把 `CMP`、`MP`、`TAP` 混成一个大而空的“memory system”。
- 不要把图里的 `DB(RAG)` 旧标记重新带回 `CMP` 的 DB 设计。
- 不要把 `memory/live-reports` 的瞬时结果当成长期真相。
- 不要在总装第一轮就试图同时解决 deploy、UI、旧 runtime 兼容。

## 当前最小完成定义

只有同时满足下面这些条件，才算 `dev-master` 第一阶段总装成立：

1. `dev-master` 已清楚代表 reboot 世界的新主装线。
2. `CMP` 资产已按主题并入，而不是零散复制。
3. `TAP` 基座与 `CMP` 装配口没有互相覆盖。
4. 项目级总纲、方向同步文档、记忆入口都已更新。
5. `git status`、类型检查、关键测试的结果可以作为下一轮施工基线。

## 建议的后续文档

在这份总纲之后，建议继续补两类文档：

1. `dev-master` 合并清单
   - 逐项列出 `cmp/mp` 需要并入的提交主题、目录、冲突口
2. 项目级同步总纲
   - 把架构图、当前方向、分阶段目标统一成后续协作入口

一句收口：

- `dev-master` 不是新名字而已
- 它是 reboot 之后第一次正式把 `TAP` 基座和 `CMP` 主体重新装到一起的总装线
