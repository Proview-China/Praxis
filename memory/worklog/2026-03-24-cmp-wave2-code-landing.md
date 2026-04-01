# 2026-03-24 CMP Wave 2 Code Landing

## 当前阶段结论

`CMP` 的第二波代码已经在 `cmp/mp` 分支真实落地，并且主线程已完成第二波的 runtime 接线与联调验证。

## 当前第二波已补的模块

- `src/agent_core/cmp-git/**`
  - `governance.ts`
  - `refs-lifecycle.ts`
  - `orchestrator.ts`
- `src/agent_core/cmp-db/**`
  - `delivery-registry.ts`
  - `dbagent-sync.ts`
- `src/agent_core/cmp-mq/**`
  - `subscription-guards.ts`
  - `critical-escalation.ts`
- `src/agent_core/cmp-runtime/**`
  - `delivery-routing.ts`
  - `passive-delivery.ts`
  - `visibility-enforcement.ts`

## 当前主线程已完成的第二波接线

- `runtime.ts` 不再只靠第一波的最小占位逻辑。
- 当前已经改成：
  - `commitContextDelta(...)`
    - 使用 `CmpGitSyncRuntimeOrchestrator`
    - 生成 checked ref / PR / merge / promotion
    - 同步 `cmp-db` projection
  - `materializeContextPackage(...)`
    - 同步 DB package record
  - `dispatchContextPackage(...)`
    - 使用 `cmp-runtime` delivery routing
    - 强制 non-skipping / visibility 检查
    - 同步 DB delivery record
  - `requestHistoricalContext(...)`
    - 使用 `cmp-runtime` passive delivery helper
  - `ingestRuntimeContext(...)`
    - 使用 `cmp-mq` subscription guard 约束邻接广播

## 当前第二波已验证的行为

- `submit_to_parent` 现在会真实走到 `cmp-git` promotion 治理
- `dispatch_to_children` 现在会真实推进 DB package / delivery record
- 非越级 lineage dispatch 现在会在 runtime 层被阻断

## 当前验证基线

- `npm run typecheck` 通过
- `npx tsx --test src/agent_core/cmp-git/*.test.ts src/agent_core/cmp-db/*.test.ts src/agent_core/cmp-mq/*.test.ts src/agent_core/cmp-runtime/*.test.ts src/agent_core/runtime.test.ts` 通过
  - `74 pass / 0 fail`
- `npm run build` 通过

## 当前还没做完的事

- Part 2:
  - `08-non-skipping-policy-and-escalation-guard`
  - `10-cross-part-integration-hooks`
  - `11-end-to-end-lineage-sync-and-governance-smoke`
- Part 3:
  - `12-part3-end-to-end-and-cross-part-tests`
- Part 4:
  - `07-runtime-assembly-and-core-agent-integration`
  - `08-end-to-end-runtime-smoke-and-multi-agent-tests`

## 当前一句话收口

第二波已经把 `CMP` 从“第一波 typed skeleton + minimal runtime bridge”推进到了“git governance / DB delivery / MQ guard / runtime enforcement 全部有真实二段式骨架并完成主线程联调”的阶段。
