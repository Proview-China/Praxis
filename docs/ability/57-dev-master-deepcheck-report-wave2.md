# Dev-Master Deepcheck Report Wave 2

状态：细查报告 / 第二波高风险前置检查。

更新时间：2026-04-02

## 这份文档回答什么

这份文档专门回答：

- 第二波细查到底查出了什么。
- 哪些高风险面已经清楚，哪些还只能继续后置。
- 当前最安全、最合理的下一步到底是什么。

一句白话：

- 这份文档不是再开新任务。
- 它是把这轮“仔细检查”的结论收成一个统一判断。

## 当前检查范围

这轮重点看了 4 组面：

1. `runtime assembly`
2. `rax` 表面统一
3. `package.json` / 脚本入口
4. 项目叙事与记忆入口

## 当前已确认结论

### 1. `runtime assembly` 仍然是最大风险口

当前 `origin/dev..origin/cmp/mp` 的差异量级大致为：

- `src/agent_core/runtime.ts`
  - `3754 insertions`
  - `2602 deletions`
- `src/agent_core/runtime.test.ts`
  - `1645 insertions`
  - `3141 deletions`

当前判断：

- 这一块仍然只能由主线程主导
- 不能让多个 worker 并行改
- 在 `rax` 表面和入口脚本没有进一步整理前，不应提前动手

### 2. `rax` 表面是中风险，而不是最高风险

当前 `src/rax/index.ts` 的差异量级明显小一档，主要新增的是：

- `cmp-types`
- `cmp-config`
- `cmp-domain`
- `cmp-connectors`
- `cmp-runtime`
- `cmp-status-panel`
- `cmp-facade`

当前判断：

- 这里更像分层与出口整理问题
- 危险，但还没有到 runtime 那样必须最后处理的程度
- 未来最合理的顺序是：
  1. 先接 `cmp-types / cmp-config / cmp-domain / cmp-connectors`
  2. 再处理 `cmp-runtime / cmp-status-panel`
  3. 最后才是 `cmp-facade`

### 3. `package.json` 低风险脚本入口已经在位

当前已确认主线上已经存在：

- `cmp:infra:up`
- `cmp:infra:down`
- `cmp:infra:ps`
- `cmp:infra:status`
- `cmp:status:serve`

当前判断：

- 这一步已经不再是阻塞点
- 后面无需再为 `CMP infra` 触达路径单独补脚本

### 4. 项目叙事入口已经基本成型

当前项目级入口已经具备：

- `docs/master.md`
- `docs/ability/52-56`
- `memory/current-context.md`

当前判断：

- `docs/master.md` 继续承担长期总入口
- `memory/current-context.md` 已经完成从 reboot 快照到总装现状的升级
- `memory/compaction-handoff-prompt*.md` 继续留在阶段性交接旁路，不抬升为主入口

## 当前仍然不该做的事

- 不要提前让多个 worker 同时改 `src/agent_core/runtime.ts`
- 不要把 `cmp-five-agent` 和 `runtime assembly` 一起推进
- 不要把 `rax.cmp` facade 提前到 `cmp-domain/connectors` 之前
- 不要因为入口脚本已经就位，就误判高风险总装也已可以直接开始

## 当前最安全的下一步

如果继续往前走，当前最安全的顺序应是：

1. 先做 `rax` 的低风险 `CMP` 表面接回
2. 再决定 `cmp-runtime` / `cmp-status-panel` 的接法
3. 然后评估 `cmp-five-agent` 的 Batch 2 准入
4. 最后才进入 `runtime assembly`

## 一句话结论

- Batch 1 已站稳
- `package.json` 已不是问题
- `rax` 可以作为下一个受控施工面
- `runtime assembly` 仍然必须最后处理
