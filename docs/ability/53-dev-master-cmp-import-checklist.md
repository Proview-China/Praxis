# Dev-Master CMP Import Checklist

状态：总装并入清单 / 可并行施工版本。

更新时间：2026-04-02

## 这份文档回答什么

这份文档专门回答：

- `cmp/mp` 这条线应该按什么顺序并入新的 `dev`
- 哪些内容属于必须吸收的主线资产
- 哪些内容只适合作为阶段性证据或交接材料保留
- 多智能体并行时，应怎样分波次、分写域、分冲突责任

一句白话：

- 它不是 branch diff 备忘录
- 它是给总装施工直接派工的清单

## 当前总原则

1. 总装基座始终以当前 `dev` 为准。
2. `cmp/mp` 不是整包覆盖对象，而是按主题吸收的资产源。
3. 先吸收长期主线资产，再处理高冲突装配口。
4. `memory/live-reports/**` 这类瞬时产物默认不先进入主线。
5. 每一波并入后都要回读：
   - `git status`
   - 差异范围
   - 最小验证结果

## 并入范围分级

### A 级：应优先并入的长期资产

- `docs/ability/29-40`
- `docs/ability/44-47`
- `docs/ability/cmp-*`
- `memory/current-context.md`
- `memory/compaction-handoff-prompt*.md`
- `memory/worklog/2026-03-20*`
- `memory/worklog/2026-03-24*`
- `memory/worklog/2026-03-25-cmp-*`
- `infra/cmp/**`
- `scripts/cmp-status-panel-server.mjs`
- `src/agent_core/cmp-*/**`
- `src/rax/cmp-*/**`

### B 级：需要边研究边并入的装配资产

- `src/agent_core/runtime.ts`
- `src/agent_core/runtime.test.ts`
- `src/rax/index.ts`
- `package.json`
- `docs/master.md`

### C 级：默认不先进入主线的阶段性材料

- `memory/live-reports/cmp-*`
- 单次 live smoke JSON
- 只服务某次上下文压缩的临时备注
- 当前 `cmp/mp` 工作区尚未提交的实验性改动

## 推荐波次

## Wave 0. 文档与记忆对齐

目标：

- 先让新 `dev` 的主叙事完整
- 避免后续代码合并时没有统一方向

建议吸收：

- `docs/ability/29-40`
- `docs/ability/44-47`
- `memory/current-context.md`
- `memory/compaction-handoff-prompt*.md`
- `memory/worklog/2026-03-20*`
- `memory/worklog/2026-03-24*`
- `memory/worklog/2026-03-25-cmp-*`

验证：

- `git diff --stat`
- 回读 `docs/master.md`
- 回读 `memory/current-context.md`

## Wave 1. `CMP` 基础设施与脚本

目标：

- 先把 `CMP` 的共享施工面接回主线

建议吸收：

- `infra/cmp/**`
- `scripts/cmp-status-panel-server.mjs`

验证：

- 目录差异回读
- 脚本入口回读
- 与 `package.json` 的依赖关系核对

## Wave 2. `CMP` 主体模块

目标：

- 让 `CMP` 主体代码回到总装线

建议吸收：

- `src/agent_core/cmp-*/**`
- `src/rax/cmp-*/**`

验证：

- `git diff --stat`
- 相关测试文件范围核对
- 与 `TAP`/`agent_core` 入口的引用关系核对

## Wave 3. 总装入口修复

目标：

- 处理 `CMP` 与 reboot/TAP 基座在入口层的接缝

建议处理：

- `src/agent_core/runtime.ts`
- `src/agent_core/runtime.test.ts`
- `src/rax/index.ts`
- `package.json`

验证：

- `npm run typecheck`
- 相关测试组合
- `git status --short`

## Wave 4. 项目级同步

目标：

- 让后续协作者看到的是统一主线，而不是两套并行叙事

建议处理：

- `docs/master.md`
- 项目级同步总纲
- 必要的 memory 入口升级

验证：

- 文档入口回读
- 当前状态文档回读

## 多智能体分工建议

### Worker A：文档与记忆

负责：

- `docs/ability/29-40`
- `docs/ability/44-47`
- `memory/**`

不负责：

- runtime 入口代码

### Worker B：`CMP` 基础设施

负责：

- `infra/cmp/**`
- `scripts/cmp-status-panel-server.mjs`

不负责：

- `src/agent_core/runtime.ts`

### Worker C：`CMP` 主体代码

负责：

- `src/agent_core/cmp-*/**`
- `src/rax/cmp-*/**`

不负责：

- `package.json`
- `docs/master.md`

### 主线程：总装入口

负责：

- `src/agent_core/runtime.ts`
- `src/rax/index.ts`
- `package.json`
- 最终文档入口与验证

## 当前不要做错的事

- 不要一上来直接整体 merge `cmp/mp`
- 不要先动 `main`
- 不要把 live smoke 结果当长期主线资产
- 不要让多个 worker 同时改 runtime 入口
- 不要在文档叙事还没统一前就开始大批量代码搬运

## Wave 1 初步结论

这一轮已经先把高风险面摸清了一遍，当前可以先钉死下面这些事实。

### 1. `cmp/mp` 相对新 `dev` 仍有 12 个主题提交

当前 `origin/dev...origin/cmp/mp` 为：

- `36/12`

白话：

- 新 `dev` 基座在 reboot/TAP 一侧继续往前走了
- `cmp/mp` 仍有 12 个 `CMP` 主题提交需要被系统吸收

这 12 个主题提交大体可分成 4 段：

1. `CMP wave1-wave4`
   - 从协议/任务包进入第一波代码落地
2. `CMP infra / non-five-agent closure`
   - shared infra lowering
   - `section-first`
   - history fallback
   - delivery truth
3. `CMP five-agent 第一轮结构化接线`
   - 五角色 runtime
   - `rax.cmp`
   - role-level `TAP` bridge
4. `CMP final closure`
   - recovery
   - acceptance gate
   - 最小 live infra

### 2. 可以最先并入的第一批资产

当前最适合优先并入的是：

- `docs/ability/29-40`
- `docs/ability/44-46`
- `docs/ability/cmp-*`
- `memory/compaction-handoff-prompt*.md`
- `memory/worklog/2026-03-20*`
- `memory/worklog/2026-03-24*`
- `memory/worklog/2026-03-25-cmp-*`
- `infra/cmp/**`
- `scripts/cmp-status-panel-server.mjs`
- `src/agent_core/cmp-types/**`
- `src/agent_core/cmp-git/**`
- `src/agent_core/cmp-db/**`
- `src/agent_core/cmp-mq/**`
- `src/agent_core/cmp-runtime/**`

理由很简单：

- 这些资产大多是 `CMP` 自身的主体或支撑层
- 它们与 reboot 基座的 `TAP` runtime 不是同一块写域
- 即使有冲突，也更容易在局部解决，而不会一上来就打爆总装入口

### 3. 当前应暂缓的资产

下面这些内容不适合在第一批直接并入：

- `src/agent_core/runtime.ts`
- `src/agent_core/runtime.test.ts`
- `memory/current-context.md`
- `docs/master.md`
- `src/agent_core/cmp-five-agent/**`
- `src/agent_core/integrations/model-inference*.ts`
- `src/rax/cmp-*/**`
- `memory/live-reports/cmp-*`
- 当前 `cmp/mp` 工作区里的未提交实验性文件

原因：

- `runtime.ts` 与 `runtime.test.ts` 是当前最大冲突口
- `memory/current-context.md` 在两条线上代表的是两种完全不同阶段，不应互相覆盖
- 五角色与 `rax.cmp` 已开始碰总装入口，不适合在第一批直接压上来
- `memory/live-reports` 只服务阶段性 smoke，不应被当长期主线事实

### 4. 第一批并入后的建议验证

Wave 1 后如果开始做 Batch 1 + Batch 2，建议最小验证收成下面这组：

- `npm run typecheck`
- `npx tsx --test src/agent_core/cmp-git/*.test.ts`
- `npx tsx --test src/agent_core/cmp-db/*.test.ts`
- `npx tsx --test src/agent_core/cmp-mq/*.test.ts`
- `npx tsx --test src/agent_core/cmp-runtime/*.test.ts`

白话：

- 先验证 `CMP` 支撑层自己能在新 `dev` 上站住
- 不要在第一批就把五角色和总装入口一起拖进来

### 5. 第一批并入时最该防的错误

- 不要把 `docs/ability/43-51` 这批 reboot/TAP 文档当成 `cmp/mp` 的可覆盖区域。
- 不要把 `memory/current-context.md` 直接从 `cmp/mp` 覆盖到新 `dev`。
- 不要把 `CMP` 主体和 `runtime assembly` 在同一波一起处理。
- 不要把 `cmp/mp` 的 live smoke JSON 当成长期真相。

一句收口：

- 先把主叙事和 `CMP` 资产接回新 `dev`
- 再碰总装入口
