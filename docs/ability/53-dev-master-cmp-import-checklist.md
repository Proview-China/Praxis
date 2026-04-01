# Dev-Master CMP Import Checklist

状态：总装执行清单 / `CMP` 资产并入计划。

更新时间：2026-04-02

## 这份文档回答什么

这份文档专门回答：

- `cmp/mp` 的哪些资产应该并入新的 `dev` 主线。
- 这些资产应该按什么顺序并入，而不是一把乱 merge。
- 哪些内容属于长期主线资产，哪些只属于阶段性证据或临时状态。
- 多智能体并行时，怎样切 lane 才不会互相踩写域。

一句白话：

- 这份文档不是“再讲一遍原则”。
- 它是给后续真正开始搬运 `CMP` 资产时使用的施工清单。

## 当前基线

当前新的 `dev` 主线已经切到 reboot 世界，和 `dev-master` 同头。

当前 `cmp/mp` 相对新的 `dev` 仍多出 12 个主题提交：

1. `d8b5146`
   - Start CMP wave 1 with task packs and runtime skeleton
2. `98c68ef`
   - Advance CMP wave 2 governance delivery and enforcement
3. `bdd678b`
   - Finish CMP wave 3 hooks snapshot recovery and e2e
4. `73ea587`
   - Close CMP wave 4 and mark the current design complete
5. `a073959`
   - 完成 CMP infra 第一波总纲与真实 backend 骨架落地
6. `32456dd`
   - 完成 CMP 正式接入第一波落地与 infra helper 下沉
7. `05b2ecc`
   - 完成 CMP 非五-agent 主链收口并接入 section-first 与历史回退
8. `2233b65`
   - 完成 CMP 非五-agent 最后收口并更新项目级状态
9. `de4391b`
   - 完成 CMP 五-agent 首轮代码落地与控制面可见性接线
10. `e38c2fe`
   - 完成 CMP 五-agent 配置收口并接通角色级 TAP 控制面
11. `14c8041`
   - 推进 CMP final closure：接通五角色 TAP 执行桥并补最小 live infra
12. `5abf0fd`
   - 收口 CMP final closure 的 recovery 与 acceptance gate

这 12 个提交不应被理解为“逐个 cherry-pick 就完成”，而应被拆成几个主题批次。

## 总体导入原则

1. 先导入长期主叙事，再导入代码。
2. 先导入低耦合目录，再导入总装入口。
3. `memory/live-reports/**` 这类瞬时证据默认不直接进主线。
4. 当前 `cmp/mp` 工作区里的未提交试验改动，不纳入第一轮总装。
5. 每一批导入后都要回读 `git diff --stat` 与关键测试，而不是堆到最后再看。

## Batch 0. 基座保护

目标：

- 明确这一轮只“吸收 `CMP` 资产”，不覆盖 reboot 基座。

不得覆盖的基座重点：

- `docs/ability/20-28`
- `docs/ability/43-51`
- `memory/worklog/2026-03-18-*`
- `memory/worklog/2026-03-19-*`
- `src/agent_core/ta-pool*/**`
- `tap-* task pack`

## Batch 1. 文档与记忆先行

目标：

- 先把 `CMP` 的长期叙事和阶段收口材料导入，形成后续编码的共同语境。

默认导入：

- `docs/ability/29-40`
- `docs/ability/44-46`
- `docs/ability/cmp-*`
- `docs/ability/rax-cmp-workflow-task-pack/**`
- `memory/current-context.md`
- `memory/compaction-handoff-prompt.md`
- `memory/compaction-handoff-prompt-cmp-final-closure.md`
- `memory/compaction-handoff-prompt-five-agent.md`
- `memory/worklog/2026-03-20-*`
- `memory/worklog/2026-03-24-*`
- `memory/worklog/2026-03-25-cmp-*`

默认不导入：

- `memory/live-reports/cmp-*`

## Batch 2. `infra/cmp` 与脚本

目标：

- 把 `CMP` 的真实 backend 骨架和辅助脚本接回总装线。

默认导入：

- `infra/cmp/**`
- `scripts/cmp-status-panel-server.mjs`

重点检查：

- 路径是否仍符合 reboot 当前目录约束。
- 是否引入和 `TAP` 基座重复的 runtime helper。
- `package.json` 是否需要补脚本、依赖或 workspace 映射。

## Batch 3. `agent_core` 的 `CMP` 主体

目标：

- 导入 `CMP` 在 `agent_core` 里的对象模型、runtime、five-agent 相关代码。

默认导入：

- `src/agent_core/cmp-*/**`
- `src/agent_core/cmp-types/**`
- `src/agent_core/integrations/*cmp*`

重点检查：

- `CMP` runtime 与 reboot 当前 `agent_core` 的 assembly 方式是否已经漂移。
- `Checkpoint`、`recovery`、`queue/port` 相关接口是否有签名变化。
- five-agent 代码是否还依赖只存在于 `cmp/mp` 的临时假设。

## Batch 4. `rax.cmp` 表面与工作流入口

目标：

- 导入 `CMP` 在 `rax` 表面的对外出口。

默认导入：

- `src/rax/cmp-*/**`
- `src/rax/cmp-types.ts`
- `src/rax/cmp-domain.ts`
- `src/rax/cmp-connectors*.ts`

重点检查：

- `src/rax/index.ts` 的 export 面是否与 reboot 当前 `TAP`/capability 表面冲突。
- facade/runtime shell 是否会误覆盖已有 reboot 出口。
- status panel / smoke 入口是否应该作为主线能力保留。

## Batch 5. 总装入口与验收

目标：

- 处理真正的高耦合总装点，让 `CMP + TAP` 能作为一条新主线成立。

重点文件：

- `src/agent_core/runtime.ts`
- `src/agent_core/runtime.test.ts`
- `src/rax/index.ts`
- `package.json`
- `docs/master.md`
- `memory/current-context.md`

这一批不再按目录导入，而要按“问题”导入：

1. runtime assembly 先后顺序
2. `CMP <-> TAP` 最小供给接缝
3. 统一 check/build/test 脚本
4. 项目级当前叙事与入口同步

## 不直接视为主线资产的内容

下面这些内容默认不在第一轮导入：

- `memory/live-reports/cmp-*`
- 只为一次 live smoke 存在的 JSON 证据
- 明显只服务某轮 handoff 的临时说明
- 当前 `cmp/mp` 工作区里的未提交试验性改动

## 多智能体并行 lane 建议

Lane 1：文档与记忆

- 写域：
  - `docs/ability/cmp-*`
  - `memory/**`

Lane 2：`infra/cmp`

- 写域：
  - `infra/cmp/**`
  - `scripts/cmp-status-panel-server.mjs`

Lane 3：`agent_core` 的 `CMP`

- 写域：
  - `src/agent_core/cmp-*/**`

Lane 4：`rax.cmp`

- 写域：
  - `src/rax/cmp-*/**`

Lane 5：总装入口

- 写域：
  - `src/agent_core/runtime.ts`
  - `src/rax/index.ts`
  - `package.json`
  - `docs/master.md`
  - `memory/current-context.md`

## 每一批的完成信号

每完成一批，至少回读：

- `git status --short`
- `git diff --stat`
- 与该批直接相关的测试或类型检查结果

一句收口：

- `CMP` 并入不是一次 merge
- 它是一轮分批总装

