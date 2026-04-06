# Current Context

更新时间：2026-04-06

## 当前主线一句话

Praxis 当前可继续开发的总装主线已经形成，工作分支是：

- branch: `integrate/dev-master-cmp`
- worktree: `.parallel-worktrees/integrate-dev-master-cmp`

一句白话：

- 这条线已经不是“合并试算线”
- 它现在就是后续继续联调与开发的实际工作线

## 当前最重要的项目事实

### 1. 这条线已经承接住 `core_agent_runtime + TAP + CMP + rax.cmp`

当前 `integrate/dev-master-cmp` 已经真实吸收：

- `dev-master`
- `reboot/blank-slate`
- `cmp/mp`
- 后续为 `runtime.ts`、`runtime.test.ts`、TAP replay / human-gate / provisioning 主链、CMP five-agent live wrapper 做的一批收口补丁

白话：

- 当前最重要的三块不再分散在多条主要实现线上
- 已经进入同一条可继续开发的总装基线

### 2. `core_agent_runtime` 当前已经是总装后的正式运行底座

当前这条线里的 `src/agent_core/runtime.ts` 已经同时承接：

- reboot/TAP 基座上的 reviewer / tool-reviewer / provisioner / replay / recovery 主链
- `CMP` 的 readback / recover / dispatch / requestHistory / five-agent TAP bridge
- `CMP` five-agent live wrapper：
  - `captureCmpIcmaWithLlm(...)`
  - `advanceCmpIteratorWithLlm(...)`
  - `evaluateCmpCheckerWithLlm(...)`
  - `materializeCmpDbAgentWithLlm(...)`
  - `servePassiveCmpDbAgentWithLlm(...)`
  - `dispatchCmpDispatcherWithLlm(...)`
  - `deliverPassiveCmpDispatcherWithLlm(...)`
  - `runCmpFiveAgentActiveLiveLoop(...)`
  - `runCmpFiveAgentPassiveLiveLoop(...)`

### 3. `rax.cmp` 当前已经是可继续使用的统一入口

当前这条线已经真实接好并验证：

- `src/rax/cmp-types.ts`
- `src/rax/cmp-runtime.ts`
- `src/rax/cmp-facade.ts`
- `src/rax/cmp-five-agent-live-smoke.ts`

白话：

- `rax.cmp` 不再只是低风险表面层
- 它已经能对接当前总装后的 `agent_core` runtime

## 当前已验证通过的基线

这条线当前已经真实通过：

- `npm run typecheck`
- `npm run build`
- `npm test`

额外已单独回读过的重点验证：

- `npx tsx --test src/agent_core/runtime.test.ts`
- `npx tsx --test src/agent_core/runtime.cmp-live.test.ts src/agent_core/runtime.cmp-five-agent.test.ts`
- `npx tsx --test src/agent_core/runtime.recovery.test.ts src/agent_core/runtime.replay.test.ts src/agent_core/runtime.replay-continue.test.ts`
- `npx tsx --test src/agent_core/runtime.continue-followups.test.ts src/agent_core/runtime.continue-followups.*.test.ts`
- `npx tsx --test src/rax/cmp-facade.test.ts src/rax/cmp-runtime.test.ts`

### 关于 `runtime.continue-followups`

当前已经不再使用原来的超大单文件直跑方式。

当前状态是：

- `src/agent_core/runtime.continue-followups.test.ts`
  - 改成轻量 skip 入口
- focused tests:
  - `runtime.continue-followups.pickup-targeted.test.ts`
  - `runtime.continue-followups.auto-after-verify.test.ts`
  - `runtime.continue-followups.blocked.test.ts`
  - `runtime.continue-followups.waiting-human.test.ts`

原因：

- 在 Node 25 + `tsx` 下，旧的单文件入口会 OOM
- 拆分后已可以稳定验证同一批主链场景

## 当前对“下面能不能继续开发”的判断

当前最诚实的判断是：

- 如果目标是继续做 `CMP + TAP + core_agent_runtime` 的联调、收口与新功能开发
- `integrate/dev-master-cmp` 已经足够承托

也就是说：

- 后面默认直接在这条线继续写
- 不需要再回到 `reboot/blank-slate`
- 也不需要再回到 `cmp/mp`

## 当前还需要记住的边界

### 1. 这条线是“当前主线”，不是“删掉所有历史分支也绝对没风险的唯一归档”

白话：

- 当前继续开发，直接用这条线没问题
- 但仓库里其他历史分支是否全部可删，不是当前这份文档要做的承诺

### 2. 后续新功能默认直接贴当前总装线写

后续新需求默认优先复用：

- `agent_core/runtime.ts`
- `TAP` control plane / replay / recovery 主链
- `CMP` workflow / five-agent live wrapper / `rax.cmp`

不要再做错的事：

- 不要把 `reboot/blank-slate` 重新当成主要继续线
- 不要把 `cmp/mp` 重新当成主要继续线
- 不要再为“总装”另起新的长期工作分支

## 给后续 Codex 的一句提示

如果后续 Codex 读到这份文件，默认把当前对象理解为：

- “总装主线已经形成，当前在 `integrate/dev-master-cmp` 上继续开发”

而不是：

- 仍在大规模分支整合阶段
- 或仍在等待 `CMP` / `TAP` 的主线接回
