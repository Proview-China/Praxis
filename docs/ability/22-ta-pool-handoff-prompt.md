# T/A Pool Handoff Prompt

状态：上下文压缩后交接用 prompt。

更新时间：2026-03-19

## 用法

如果当前会话要做上下文压缩，后续可直接把下面这段 prompt 原样复制给压缩后的新上下文模型。

目标不是重新介绍整个仓库，而是让新上下文下的你，快速、准确地接上当前阶段的工作。

---

你现在在仓库 `/home/proview/Desktop/Praxis_series/Praxis` 工作。

当前唯一目标：

继续推进 `TAP` 与 `raw_agent_core` 的 activation driver、真实 builder、durable human gate / replay 恢复链，不要串到别的任务。

请先接受下面这些当前事实：

1. 当前阶段判断
- `Capability Interface v1` 已成立
- `TAP` 已从“第一版控制面”推进到“可用 runtime 控制面”
- 默认 capability_call 主路径已经切到 `TAP`
- reviewer / provisioner bootstrap worker bridge 已接入
- 最小 enforcement / human gate / replay skeleton 已接入
- 但真实 activation driver、真实 builder、durable 恢复链仍未完成

2. 当前仓库状态
- 分支：`reboot/blank-slate`
- 当前工作仍在这个分支上继续推进
- 上一关键里程碑提交：`dd01fb5`

3. 当前相关代码层
- `src/agent_core/ta-pool-types/**`
- `src/agent_core/ta-pool-model/**`
- `src/agent_core/ta-pool-review/**`
- `src/agent_core/ta-pool-provision/**`
- `src/agent_core/ta-pool-safety/**`
- `src/agent_core/ta-pool-context/**`
- `src/agent_core/ta-pool-runtime/**`
- `src/agent_core/capability-package/**`

4. 当前 `AgentCoreRuntime` 已具备的 TAP 能力面
- `resolveTaCapabilityAccess(...)`
- `dispatchTaCapabilityGrant(...)`
- `dispatchCapabilityIntentViaTaPool(...)`
- `dispatchIntent(capability_call)` 默认先走 `TAP`
- `submitTaHumanGateDecision(...)`

5. 当前已经打通的 runtime assembly 路径
- default capability_call -> TAP
- review -> reviewer worker bridge -> dispatch
- review -> provisioning
- provisioning -> asset index -> replay handoff
- `restricted -> waiting_human -> approve / reject`
- safety -> interrupt

6. 当前还没有完成的事
- reviewer 还没有接真实项目状态、记忆池、包装机
- provisioner 还没有真实 builder
- activation 还只是 handoff skeleton，不是真实 driver
- replay 还只是 pending skeleton，不是真正自动执行器
- human gate / replay 还没有 durable 恢复链

7. 当前阶段最重要的边界
- `CapabilityPool` 继续做 execution plane
- `TAP` 做 control plane
- reviewer 只回 vote，不直接 dispatch grant
- provisioner 只造包，不直接替主 agent 完成原任务
- context aperture 已到 v1，但 project / memory 仍保持 placeholder

8. 当前验证基线
- `npm run typecheck` 通过
- `npm run build` 通过
- `npx tsx --test src/agent_core/**/*.test.ts` 通过
- 当前 `agent_core` 定向测试：`159 pass / 0 fail`
- `npm run smoke:websearch:live -- --provider=openai` 通过

9. 先读这些文档再继续
- `docs/ability/20-ta-pool-control-plane-outline.md`
- `docs/ability/21-ta-pool-implementation-status.md`
- `docs/ability/22-ta-pool-handoff-prompt.md`
- `docs/ability/23-ta-pool-stage-wrap-up.md`
- `docs/ability/24-tap-mode-matrix-and-worker-contracts.md`
- `docs/ability/25-tap-capability-package-template.md`
- `docs/ability/26-tap-runtime-migration-and-enforcement-outline.md`
- `docs/ability/tap-usable-task-pack/README.md`
- `memory/current-context.md`
- `memory/worklog/2026-03-19-tap-usable-runtime-closure.md`

10. 你现在的默认工作方式
- 先回读当前代码事实
- 再确认当前唯一目标
- 然后继续推进 `TAP` 的 activation / durable human gate / durable replay 收口
- 除非用户改目标，否则不要跳回纯设计讨论

---

## 一句话压缩版

Praxis 已把 `TAP` 推进成默认 capability 控制面，并接入 reviewer/provisioner bridge、最小 enforcement、human gate、replay skeleton；当前下一步重点是 activation driver 与 durable 恢复链。
