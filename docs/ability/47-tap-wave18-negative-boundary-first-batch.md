# TAP Wave18 Negative Boundary First Batch

状态：已落地第一批三角色负向边界测试，并补了一处真实 runtime 短路。

更新时间：2026-03-25

## 这一步真正做成了什么

这一步不是继续补正向 happy path，而是开始收口 `18-three-agent-negative-boundary-tests`。

这一批重点只有一句话：

- 失败时不要偷偷继续跑

## 本轮真实落地的边界

### runtime / replay / activation

- `resumeTaEnvelope(...)` 现在在 replay 恢复时会先看 activation 结果
- 如果 activation 失败，就直接短路返回
- 不再继续偷偷进入 review / dispatch

同时补了这些 runtime 级负例：

- unknown envelope -> `resume_envelope_not_found`
- malformed replay envelope -> `resume_not_supported`
- malformed activation envelope -> `resume_not_supported`
- manual replay policy 只停在 handoff，不自动开真实 human gate，不自动 dispatch
- hydrate 后 human gate envelope 不会自动批准

### tool_reviewer

- runtime 主链产出的 tool reviewer action 现在有断言：
  - 全程保持 `boundaryMode === "governance_only"`
- tool reviewer hydration 只恢复治理记录
- 不会自己多产 action，不会偷偷往下执行

### reviewer

- reviewer 非法 bridge 输出失败后，不会污染 durable state
- reviewer worker bridge 新增负例：
  - 非 `allow` 票型不能夹带 compiler directives

### TMA / provision

- provision/TMA restore 对被篡改的 boundary 会重新钳回：
  - `mayExecuteOriginalTask: false`
  - `scope: capability_build_only`
- restore 后只恢复 resumable/completed state
- 不会因为 restore 就自动重新提交新工作

## 当前验证结果

本轮已验证通过：

- `npm run typecheck`
- `npx tsx --test src/agent_core/runtime.test.ts src/agent_core/ta-pool-review/reviewer-runtime.test.ts src/agent_core/ta-pool-review/reviewer-worker-bridge.test.ts src/agent_core/ta-pool-tool-review/tool-review-runtime.test.ts src/agent_core/ta-pool-provision/provisioner-runtime.test.ts`
- `npx tsx --test src/agent_core/**/*.test.ts`
- `npm test`

## 涉及文件

- [runtime.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/runtime.ts)
- [runtime.test.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/runtime.test.ts)
- [reviewer-runtime.test.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-review/reviewer-runtime.test.ts)
- [reviewer-worker-bridge.test.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-review/reviewer-worker-bridge.test.ts)
- [tool-review-runtime.test.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-tool-review/tool-review-runtime.test.ts)
- [provisioner-runtime.test.ts](/home/proview/Desktop/Praxis_series/Praxis/.parallel-worktrees/reboot-merge/src/agent_core/ta-pool-provision/provisioner-runtime.test.ts)

## 还没有完全做完的部分

这一批还不是 `18` 的最终收口，后面仍可以继续补：

- reviewer / human-gate recovery 的幂等边界
- tool_reviewer lifecycle runtime-level negative tests
- TMA 真正 resumable orchestration
- 更细的 activation / replay durable failure taxonomy

## 一句话收口

这批已经把 `18` 从“只有想法”推进到了“失败分支和越权分支开始被真实测试钉住”的阶段。
