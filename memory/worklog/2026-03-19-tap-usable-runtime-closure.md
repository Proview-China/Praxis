# 2026-03-19 TAP Usable Runtime Closure

## 当前阶段结论

Praxis 已经把 `TAP` 从第一版控制面推进到“可用 runtime 控制面”。

当前真实成立的内容：

- default `capability_call -> TAP`
- reviewer bootstrap worker bridge
- provisioner bootstrap worker bridge
- capability package template SDK
- 最小 enforcement token / execution guard
- `restricted -> waiting_human -> approve / reject`
- replay skeleton / activation handoff skeleton

## 当前验证基线

- `npm run typecheck` 通过
- `npm run build` 通过
- `npx tsx --test src/agent_core/**/*.test.ts` 通过
  - `159 pass / 0 fail`
- `npm run smoke:websearch:live -- --provider=openai` 通过
  - `gmn + gpt-5.4` 的 `native_plain / native_search / rax_websearch` 都是 `ok`

## 当前还没做的事

- 真实 builder
- 真实 activation driver
- durable human gate / replay 恢复链
- reviewer 真实项目状态 / 记忆池 / 包装机接入

## 当前最重要的边界

- reviewer 只回 vote，不直接 dispatch grant
- provisioner 只造包，不直接替主 agent 完成原任务
- `TAP` 继续做 control plane
- `CapabilityPool` 继续做 execution plane
- 当前 `waiting_human` 仍主要是 runtime handoff 语义，不是完整产品级审批 UI
