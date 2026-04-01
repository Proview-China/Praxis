# Dev-Master Batch 1 Task Pack

状态：第一批并入任务包 / 文档先行后的首个实施面。

更新时间：2026-04-02

## 这份文档回答什么

这份文档专门回答：

- 在新 `dev` 总装线上，第一批真正应该开始施工的范围是什么。
- 多智能体并行时，应该怎样切写域，避免互相踩踏。
- 第一批施工完成后，最小验收口径是什么。

一句白话：

- 前面的文档已经回答了“为什么”和“先研究什么”。
- 这份文档开始回答“现在第一批到底做哪几块”。

## Batch 1 的目标

只做 `CMP` 的文档/记忆与支撑层并入，不碰总装入口。

也就是说：

- 先把 `CMP` 的方向、叙事、主体支撑层接回新 `dev`
- 暂不处理：
  - `src/agent_core/runtime.ts`
  - `src/agent_core/runtime.test.ts`
  - `src/rax/index.ts`
  - `memory/current-context.md`

## Batch 1 的施工范围

### Part A. 文档与记忆并入

默认范围：

- `docs/ability/29-40`
- `docs/ability/44-46`
- `docs/ability/cmp-*`
- `memory/compaction-handoff-prompt*.md`
- `memory/worklog/2026-03-20*`
- `memory/worklog/2026-03-24*`
- `memory/worklog/2026-03-25-cmp-*`

目标：

- 让新 `dev` 正式具备 `CMP` 的主文档和阶段记录
- 但不改项目级总入口和当前状态入口

### Part B. `CMP` 基础设施并入

默认范围：

- `infra/cmp/**`
- `scripts/cmp-status-panel-server.mjs`

目标：

- 把 `CMP` 的外部依赖与状态面板基础设施装回新主线
- 先形成可读、可查、可启动的本地 infra 面

### Part C. `CMP` 支撑层并入

默认范围：

- `src/agent_core/cmp-types/**`
- `src/agent_core/cmp-git/**`
- `src/agent_core/cmp-db/**`
- `src/agent_core/cmp-mq/**`
- `src/agent_core/cmp-runtime/**`

目标：

- 把 `CMP` 的主体支撑层装回新 `dev`
- 但暂不处理五角色、`rax.cmp` 和 runtime assembly

## 当前明确不在 Batch 1 的范围

- `src/agent_core/cmp-five-agent/**`
- `src/agent_core/integrations/model-inference*.ts`
- `src/rax/cmp-*/**`
- `src/agent_core/runtime.ts`
- `src/agent_core/runtime.test.ts`
- `src/rax/index.ts`
- `docs/master.md`
- `memory/current-context.md`
- `memory/live-reports/cmp-*`

## 多智能体写域划分

### Worker A. 文档与记忆

只负责：

- Part A

不负责：

- `docs/master.md`
- `memory/current-context.md`
- 任何 `src/**` 代码

### Worker B. `CMP` 基础设施

只负责：

- Part B

不负责：

- `package.json`
- `src/agent_core/runtime.ts`

### Worker C. `CMP` 支撑层

只负责：

- Part C

不负责：

- `src/agent_core/runtime.ts`
- `src/rax/index.ts`
- `src/agent_core/cmp-five-agent/**`

### 主线程

负责：

- 仲裁冲突
- 保护 reboot/TAP 基座
- 决定是否允许进入 Batch 2

## 最小验收

Batch 1 完成后，至少要回读下面这些信号：

- `git status --short`
- `npm run typecheck`
- `npx tsx --test src/agent_core/cmp-git/*.test.ts`
- `npx tsx --test src/agent_core/cmp-db/*.test.ts`
- `npx tsx --test src/agent_core/cmp-mq/*.test.ts`
- `npx tsx --test src/agent_core/cmp-runtime/*.test.ts`

## Batch 1 完成后才能做什么

只有当 Batch 1 站稳后，才进入下一批：

- `cmp-five-agent`
- `rax.cmp`
- `package.json` 的更深入口调整
- runtime assembly
- 项目级 `memory/current-context.md` 重写

一句收口：

- Batch 1 不求一口气总装完成
- 它只求把 `CMP` 支撑层安全接回新 `dev`
