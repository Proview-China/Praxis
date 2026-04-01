# Dev-Master Batch 2 Preflight

状态：高风险总装前置清单 / 第一版。

更新时间：2026-04-02

## 这份文档回答什么

这份文档专门回答：

- Batch 1 完成后，Batch 2 开工前最该先查实的高风险桥位是什么。
- `runtime assembly`、`rax` 表面、`package/scripts` 应该按什么顺序进入总装。
- 哪些东西可以先动，哪些仍必须最后处理。

一句白话：

- Batch 1 解决的是“先把 `CMP` 支撑层接回来”。
- 这份文档开始回答“接下来怎么碰真正危险的总装入口”。

## 当前事实

### 1. `runtime assembly` 仍是最大冲突口

当前 `origin/dev..origin/cmp/mp` 的 diff 量级大致是：

- `src/agent_core/runtime.ts`
  - `3754 insertions`
  - `2602 deletions`
- `src/agent_core/runtime.test.ts`
  - `1645 insertions`
  - `3141 deletions`

当前结论：

- 这一块不能交给多个 worker 同时写
- 主线程必须先做桥位盘点，再决定怎么引入

### 2. `rax` 表面冲突明显小一档

当前 `src/rax/index.ts` 的 diff 量级大致是：

- `92 insertions`
- `5 deletions`

当前 `cmp/mp` 主要想接回的是：

- `cmp-types`
- `cmp-config`
- `cmp-domain`
- `cmp-connectors`
- `cmp-runtime`
- `cmp-status-panel`
- `cmp-facade`

当前结论：

- `rax` 表面问题存在，但更像分层和出口整理问题
- 它危险，但还没有到 `runtime.ts` 那种不能碰的程度

### 3. `package.json` 是最低风险的入口补点

当前 `cmp/mp` 相对新 `dev` 只额外多了这些脚本：

- `cmp:infra:up`
- `cmp:infra:down`
- `cmp:infra:ps`
- `cmp:infra:status`
- `cmp:status:serve`

当前结论：

- `package.json` 可以作为 Batch 2 里最先处理的低风险入口
- 它能帮后面研究和联调更方便地触达 `CMP infra`

## Batch 2 的建议拆法

## Phase A. 低风险入口补点

范围：

- `package.json`

目标：

- 先把 `CMP` 基础脚本接回主线
- 不牵扯 runtime assembly

最小验收：

- `npm run typecheck`
- 相关 script 能正常显示帮助或进入预期入口

## Phase B. `rax` 表面预接线

范围：

- `src/rax/index.ts`
- `src/rax/cmp-types.ts`
- `src/rax/cmp-config.ts`
- `src/rax/cmp-domain.ts`
- `src/rax/cmp-connectors.ts`
- `src/rax/cmp-status-panel.ts`

目标：

- 先把 `CMP` 的类型、配置、domain、connectors、status panel 接进 `rax`
- 暂不强求一上来把所有 runtime/assembly 都接完

最小验收：

- `npm run typecheck`
- `src/rax/cmp-*.test.ts` 相关测试

## Phase C. `rax.cmp` runtime/facade

范围：

- `src/rax/cmp-runtime.ts`
- `src/rax/cmp-facade.ts`

目标：

- 在不碰 `agent_core/runtime.ts` 的前提下，先把 `rax.cmp` 本身接回主线
- 让上层逐渐具备 `CMP` 的外层表面

最小验收：

- `npm run typecheck`
- `src/rax/cmp-facade.test.ts`
- `src/rax/cmp-status-panel.test.ts`

## Phase D. runtime assembly

范围：

- `src/agent_core/runtime.ts`
- `src/agent_core/runtime.test.ts`

目标：

- 把 reboot/TAP 基座与 `CMP` 主体真正接到同一条 runtime 主链里

当前规则：

- 只能最后处理
- 只能由主线程主导
- 不能与其他写域并行修改

## 当前仍应继续后置的内容

即使进入 Batch 2，下面这些仍不建议一上来就碰：

- `src/agent_core/cmp-five-agent/**`
- `src/agent_core/integrations/model-inference*.ts`
- 更深的 live LLM 化
- `main` 分支切换

## 当前最推荐顺序

1. 先补 `package.json`
2. 再接 `rax` 的低风险 `CMP` 表面
3. 然后接 `rax.cmp` runtime/facade
4. 最后才做 `agent_core/runtime.ts` 的总装

一句收口：

- Batch 2 不是一口气碰所有高风险口
- 它应该从最小、最可控、最能提供联调价值的入口开始
