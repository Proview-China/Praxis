# 2026-03-25 TAP Wave4-Wave5 Late-Half Runtime Resume

## 当前阶段结论

`TAP` 在 `Wave 4-5 durable lane baseline` 之后，又继续推进了一小波真正的 runtime 主链接缝。

这一轮不是再扩 family，也不是再补前置蓝图，而是直接补：

- `tool_reviewer` 主链自动接入
- `resume envelope` 显式恢复入口
- recover + hydrate 后继续跑的人类批准 / replay 主链
- run/session/control-plane 的恢复辅助接缝

一句白话：

- 现在 TAP 不只是“能把状态存下来”
- 也开始真的能“恢复后把事情继续往下推”

## 这轮真实做成的东西

### 1. tool_reviewer 开始接入 runtime 主链

runtime 现在会在真实链路里自动给 `tool_reviewer` 记录 governance action：

- `human_gate`
- `replay`
- `activation`

也就是说，`tool_reviewer` 不再只是手工测试用壳，而是开始成为 TAP 的真实第三角色之一。

### 2. resume envelope 有了显式恢复入口

`AgentCoreRuntime` 新增：

- `getTaResumeEnvelope(...)`
- `resumeTaEnvelope(...)`

当前第一版支持：

- `human_gate`
  - 保持待人工批准
  - 不会自动放行
- `replay`
  - 能从恢复后的 pending replay 重新进入 `review / dispatch`
- `activation`
  - 有第一版 retry 入口

### 3. recover + hydrate 会补回更多 runtime 前置状态

这轮不再只是 hydrate 子状态 map，还会补：

- session header
- control-plane access request
- control-plane review decision

这样恢复之后，后续审批与 dispatch 主链才能继续走下去。

### 4. run-coordinator 的恢复入口更真实了

`resumeRun(...)` 现在不再过早要求 run 必须已经在内存 map 里。

它会先尝试：

- checkpoint 恢复
- journal 恢复

然后再把 run 放回 runtime。

## 这轮新增验证

这轮新增并跑通的重点包括：

- recover 之后继续批准 `waiting_human` 还能 dispatch
- recover 之后按 replay envelope 重新进入 `review / dispatch`
- hydrate 后 `human_gate` envelope 不会偷偷 auto-approve
- runtime 主链会自动产出 `tool_reviewer` governance session / action ledger

## 当前验证基线

- `npm run typecheck` 通过
- `npx tsx --test src/agent_core/runtime.test.ts` 通过
- `npx tsx --test src/agent_core/**/*.test.ts` 通过
- 当前 `agent_core` 定向测试：`306 pass / 0 fail`
- `npm test` 通过
- 当前仓库级测试：`190 pass / 0 fail / 1 skipped`

## 这轮涉及的主文件

- `src/agent_core/runtime.ts`
- `src/agent_core/runtime.test.ts`
- `src/agent_core/run/run-coordinator.ts`
- `src/agent_core/ta-pool-runtime/control-plane-gateway.ts`
- `docs/ability/46-tap-wave4-wave5-durable-lanes-and-hydration.md`

## 当前还没做完的事

- `18-three-agent-negative-boundary-tests` 还没有完整铺满
- `tool_reviewer` 的 lifecycle / full orchestration 还可以继续加深
- `TMA` 的 durable resume 还没有真正接成 executor/planner 可继续执行的主链
- 更完整的 activation / replay / human gate durable orchestration 仍待后续继续收口
