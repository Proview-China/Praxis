# TAP Wave4-Wave5 Durable Lanes And Hydration

状态：已落地 durable lane / hydration 基线，并继续推进了后半段 runtime resume 与 tool_reviewer 主链接缝。

更新时间：2026-03-25

## 这一步真正做成了什么

这一步没有一次性把 `Wave 4-5` 全部终结，而是先把最关键的一段打通了：

- reviewer durable lane
- tool_reviewer 最小真 agent 壳
- TMA/provision 资产台账 durability
- TMA planner / executor 最小可恢复过程态
- runtime snapshot / checkpoint / recovery / hydration 的共享接缝

一句白话：

- 现在 TAP 不只是能恢复通用 human gate / replay / activation
- reviewer、tool_reviewer、provision、TMA 也已经开始有自己的 durable lane，并且能被 TAP snapshot 带走再 hydrate 回来

## 当前代码入口

### reviewer durable

- [reviewer-durable-state.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-review/reviewer-durable-state.ts)
- [reviewer-runtime.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-review/reviewer-runtime.ts)

### tool_reviewer 最小真 agent 壳

- [tool-review-session.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-tool-review/tool-review-session.ts)
- [tool-review-runtime.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-tool-review/tool-review-runtime.ts)

### TMA / provision durable

- [provision-durable-snapshot.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-provision/provision-durable-snapshot.ts)
- [provision-registry.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-provision/provision-registry.ts)
- [provision-asset-index.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-provision/provision-asset-index.ts)
- [provisioner-runtime.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-provision/provisioner-runtime.ts)
- [tma-session-state.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-provision/tma-session-state.ts)
- [tma-planner.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-provision/tma-planner.ts)
- [tma-executor.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-provision/tma-executor.ts)

### runtime hydration / recovery 接缝

- [runtime-snapshot.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-runtime/runtime-snapshot.ts)
- [runtime-checkpoint.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-runtime/runtime-checkpoint.ts)
- [runtime-recovery.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-runtime/runtime-recovery.ts)
- [runtime.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/runtime.ts)

## 这一步已经成立的能力

### reviewer

- 已有最小 durable state
- 已能 export / hydrate durable snapshot
- 仍保持 vote-only，不持久化 inline grant

### tool_reviewer

- 已有 session
- 已有 action ledger
- 已有 snapshot / restore
- 仍保持 `governance_only` 边界，不执行原任务

### TMA / provision

- registry 已能 serialize / restore
- asset index 已能 serialize / restore
- bundle history 已能 serialize / restore
- planner / executor 已有最小 resumable session state

### runtime

- `TapPoolRuntimeSnapshot` 已开始承载 reviewer/tool_reviewer/provision/TMA 的 durable 子状态
- `AgentCoreRuntime` 已能把这些状态 hydrate 回来
- 已有 runtime 级集成测试证明这件事不是纸面设计

## 当前验证结果

这步已验证通过：

- `npm run typecheck`
- `npx tsx --test src/agent_core/runtime.test.ts src/agent_core/ta-pool-review/*.test.ts src/agent_core/ta-pool-tool-review/*.test.ts src/agent_core/ta-pool-provision/*.test.ts src/agent_core/ta-pool-runtime/runtime-*.test.ts`
- `npx tsx --test src/agent_core/**/*.test.ts`
- `npm test`

## 这一步还没有完全做完的部分

这一步还没把 `Wave 4-5` 全部终结，剩下的真实缺口主要是：

- `tool_reviewer` 已经开始进入 human_gate / replay / activation 主链，但 lifecycle 等更完整治理编排还可以继续加深
- reviewer / tool_reviewer / TMA 的 resume 驱动已经有第一版公开恢复入口，但更细的 durable orchestration 还可以继续加强
- `three-agent negative boundary tests` 已经开始进入 runtime 级测试，但还没有作为独立波次完全铺满
- 更重的 activation / replay / human gate “自动续跑”仍可继续细化，当前仍以显式恢复调用为主

所以它当前更准确的定位是：

- `Wave 4-5 durable lane baseline is code-backed`
- `Wave 4-5 late-half resume/runtime hookup is partially code-backed`
- 但还不是 `Wave 4-5 final closure`

## 本轮继续推进的后半段收口

这一轮在 baseline 之上，又补了 4 件很关键的事：

- `tool_reviewer` 不再只是能 hydrate 回来的壳子，而是开始从 runtime 主链自动记录：
  - `human_gate`
  - `replay`
  - `activation`
- `resume envelope` 不再只是静态记录，runtime 现在已有显式恢复入口，可以按 envelope 继续：
  - 保持 human gate 待批准
  - 重试 activation
  - 从 pending replay 重新进入 review / dispatch
- `recover + hydrate` 现在不只恢复 reviewer / tool_reviewer / provision / TMA 子状态，也会把必要的 session / control-plane request 一起补回 runtime
- run recovery 的主链也补了一刀，恢复后的 `resumeRun(...)` 不再过早依赖内存态 run 记录，能更真实地接住 checkpoint 恢复场景

一句白话：

- 现在 TAP 已经不只是“把状态存下来”
- 而是开始真的具备“恢复以后继续把事往下跑”的能力了

## 本轮新增验证重点

这轮新增并跑通的重点验证包括：

- recover 之后继续批准 waiting human gate，主链还能重新 dispatch
- recover 之后按 replay envelope 继续进入 review / dispatch
- hydrate 之后 human gate envelope 不会偷偷自动放行
- runtime 主链会自动把 `tool_reviewer` 的 governance session / action ledger 补出来，而不是只能手工 submit

## 一句话收口

这次已经把 TAP 从“只有通用控制面可恢复”推进到了“reviewer / tool_reviewer / TMA / provision 这些角色与资产层开始拥有自己的 durable lane，并能跟着 TAP snapshot 一起 hydrate 回 runtime”的阶段。
