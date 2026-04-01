# Dev-Master Conflict Research Plan

状态：总装冲突研究计划 / 并行爆破入口。

更新时间：2026-04-02

## 这份文档回答什么

这份文档专门回答：

- 新 `dev` 主线里真正要研究的冲突面有哪些。
- 这些冲突面应该按什么顺序研究，而不是全仓盲看。
- 多智能体并行时，怎样把问题拆成几个稳定 lane。

一句白话：

- 这份文档不是实现文档。
- 它是后续“广泛爆破”之前的作战地图。

## 研究总原则

1. 先研究总装入口，再研究局部实现。
2. 先研究长期主叙事，再研究阶段性证据。
3. 先分清“应该保留什么”，再讨论“怎么改”。
4. 任何 lane 都不要越权覆盖别的 lane 的写域。

## 冲突面 A. 入口与装配层

主要文件：

- `src/agent_core/runtime.ts`
- `src/agent_core/runtime.test.ts`
- `src/rax/index.ts`
- `package.json`

先回答什么：

1. reboot 当前 runtime assembly 的主链入口是什么。
2. `CMP` 应该从哪里接入，而不是旁路接入。
3. `package.json` 的 check/build/test 脚本是否已足以覆盖 `CMP + TAP`。

## 冲突面 B. `CMP` 主体层

主要目录：

- `src/agent_core/cmp-*/**`
- `src/agent_core/cmp-types/**`
- `src/rax/cmp-*/**`

先回答什么：

1. `CMP` 当前最小可保真主链是哪一段。
2. five-agent 相关实现里，哪些已经足够进入主线。
3. 哪些 live LLM 或 smoke 入口仍属阶段性试验。

## 冲突面 C. `TAP` 基座层

主要目录：

- `docs/ability/20-28`
- `docs/ability/43-51`
- `src/agent_core/ta-pool*/**`

先回答什么：

1. reboot 后续 `TAP` 演进对总装入口提出了哪些硬要求。
2. `CMP <-> TAP` 最小供给接缝当前缺的是 contract 还是 wiring。
3. 哪些 reboot 文档是主口径，哪些只是过渡态。

## 冲突面 D. 文档与记忆层

主要文件：

- `docs/master.md`
- `memory/current-context.md`
- `memory/worklog/**`
- `memory/compaction-handoff-prompt*.md`

先回答什么：

1. 总装后哪些文件承担项目级唯一入口。
2. 哪些 handoff prompt 仍应留在阶段性交接层。
3. 哪些 worklog 要保留为证据而不是主叙事。

## 冲突面 E. legacy 资产层

主要分支：

- `main`
- `deploy`
- `archive/dev-legacy-2026-04-01`

先回答什么：

1. deploy 语义里哪些仍值得迁移。
2. legacy `main` 在何时被新 `dev` 接管。
3. 哪些旧实现假设必须明确丢弃。

## 建议的研究顺序

### Wave 1

- 冲突面 A
- 冲突面 D

目标：

- 先把总装入口和项目级叙事定住。

### Wave 2

- 冲突面 B
- 冲突面 C

目标：

- 在入口稳定后，再研究 `CMP` 主体与 `TAP` 基座的真正接缝。

### Wave 3

- 冲突面 E

目标：

- 最后再处理 legacy 资产的迁移、归档与主线切换。

## 多智能体 lane 建议

Lane A：runtime / package / export 入口研究

- 聚焦：
  - `src/agent_core/runtime.ts`
  - `src/rax/index.ts`
  - `package.json`

Lane B：`CMP` 主体成熟度研究

- 聚焦：
  - `src/agent_core/cmp-*/**`
  - `src/rax/cmp-*/**`

Lane C：`TAP` 基座保护研究

- 聚焦：
  - `docs/ability/20-28`
  - `docs/ability/43-51`
  - `src/agent_core/ta-pool*/**`

Lane D：项目级叙事与记忆入口研究

- 聚焦：
  - `docs/master.md`
  - `memory/current-context.md`
  - `memory/worklog/**`

Lane E：legacy 处置研究

- 聚焦：
  - `main`
  - `deploy`
  - `archive/dev-legacy-2026-04-01`

## 每个 lane 的统一产出格式

每条 lane 都建议输出 3 段：

1. 当前事实
2. 应有变动
3. 不应误动的保护项

这样主线程回收时，不会变成一堆不可拼装的零散结论。

一句收口：

- 广泛爆破可以很猛
- 但必须先有同一张作战地图

