# T/A Pool Stage Wrap-Up

状态：阶段性收尾文档。

更新时间：2026-03-19

## 当前一句话结论

Praxis 已经把 `TAP` 从第一版控制面推进到“可用 runtime 控制面”：默认 capability_call 已接管到 `TAP`，reviewer/provisioner bootstrap worker bridge 已成立，最小 enforcement / human gate / replay skeleton 已成立；下一阶段重点转向真实 activation driver、真实 builder 和 durable 恢复链。

## 当前仓库状态

- 仓库：`/home/proview/Desktop/Praxis_series/Praxis`
- 分支：`reboot/blank-slate`
- 工作树：当前为本轮实现中的未提交状态
- 上一里程碑提交：`dd01fb5`
- 当前里程碑已推到：
  - `origin/reboot/blank-slate`

## 这一阶段真正完成了什么

- `TAP` 第二阶段 shared protocol 已冻结
- 五模式与三档风险已正式进入代码
- reviewer bootstrap worker bridge 已接入
- provisioner bootstrap worker bridge 已接入
- capability package template SDK 已落地
- default capability_call -> TAP 已切换
- 最小 enforcement token / execution guard 已落地
- `restricted -> waiting_human -> approve / reject` 已成立
- replay policy 与 activation handoff skeleton 已落地

## 当前已经验证成立的链路

- default capability_call -> TAP
- baseline fast path
- review -> reviewer worker bridge -> dispatch
- review -> provisioning
- provisioning -> asset index -> replay handoff
- `restricted -> waiting_human -> approve / reject`
- safety -> interrupt

## 当前验证状态

- `npm run typecheck` 通过
- `npm run build` 通过
- `npx tsx --test src/agent_core/**/*.test.ts` 通过
- 当前 `agent_core` 定向测试：`159 pass / 0 fail`
- `npm run smoke:websearch:live -- --provider=openai` 通过
- `gmn + gpt-5.4` 的 `native_plain / native_search / rax_websearch` 都是 `ok`

## 当前还没有做完的事

- reviewer 还没有接真实项目状态、记忆池、包装机
- 还没有真实 builder
- activation 还只是 handoff skeleton
- replay 还只是 pending skeleton
- human gate / replay 还没有 durable 恢复链

## 压缩后应优先阅读

- [21-ta-pool-implementation-status.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/21-ta-pool-implementation-status.md)
- [22-ta-pool-handoff-prompt.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/22-ta-pool-handoff-prompt.md)
- [24-tap-mode-matrix-and-worker-contracts.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/24-tap-mode-matrix-and-worker-contracts.md)
- [25-tap-capability-package-template.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/25-tap-capability-package-template.md)
- [26-tap-runtime-migration-and-enforcement-outline.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/26-tap-runtime-migration-and-enforcement-outline.md)
- [tap-usable-task-pack/README.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/tap-usable-task-pack/README.md)

## 给压缩后新上下文的最短提示

可直接复制下面这段：

```text
你现在在仓库 /home/proview/Desktop/Praxis_series/Praxis 工作。

当前唯一目标：
继续推进 TAP 与 raw_agent_core 的 activation driver、真实 builder、durable human gate / replay 恢复链，不要串到别的任务。

当前事实：
- 分支：reboot/blank-slate
- 上一里程碑提交：dd01fb5
- TAP 已经是默认 capability_call 控制面
- AgentCoreRuntime 已具备：
  - resolveTaCapabilityAccess(...)
  - dispatchTaCapabilityGrant(...)
  - dispatchCapabilityIntentViaTaPool(...)
  - submitTaHumanGateDecision(...)
- 当前已打通：
  - default capability_call -> TAP
  - baseline fast path
  - review -> reviewer worker bridge -> dispatch
  - review -> provisioning
  - provisioning -> asset index -> replay handoff
  - restricted -> waiting_human -> approve / reject
  - safety -> interrupt
- 当前未完成：
  - reviewer 真实项目态 / 记忆池 / 包装机接入
  - 真实 builder
  - 真实 activation driver
  - durable human gate / replay 恢复链
- 验证基线：
  - npm run typecheck
  - npm run build
  - npx tsx --test src/agent_core/**/*.test.ts
  - 当前 agent_core 定向测试：159 pass / 0 fail
  - npm run smoke:websearch:live -- --provider=openai

先读：
- docs/ability/21-ta-pool-implementation-status.md
- docs/ability/22-ta-pool-handoff-prompt.md
- docs/ability/24-tap-mode-matrix-and-worker-contracts.md
- docs/ability/25-tap-capability-package-template.md
- docs/ability/26-tap-runtime-migration-and-enforcement-outline.md
- docs/ability/tap-usable-task-pack/README.md
```
