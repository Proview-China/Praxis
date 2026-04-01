# 2026-03-24 CMP Wave 3 Code Landing

## 当前阶段结论

`CMP` 的第三波代码已经在 `cmp/mp` 分支真实落地，并且主线程已经把第三波的 hooks、runtime assembly 和 snapshot/recovery 主链接了起来。

## 当前第三波已补的模块

- `src/agent_core/cmp-git/**`
  - `lineage-guard.ts`
  - `integration-hooks.ts`
  - `lineage-governance-smoke.test.ts`
- `src/agent_core/cmp-db/**`
  - `integration-hooks.ts`
  - `integration-hooks.test.ts`
- `src/agent_core/cmp-mq/**`
  - `integration-hooks.ts`
  - `integration-e2e.test.ts`
- `src/agent_core/cmp-runtime/**`
  - `runtime-snapshot.ts`
  - `runtime-recovery.ts`

## 当前主线程已完成的第三波接线

- `runtime.ts` 当前已不只是 wave 2 的 governance / delivery / enforcement 接线。
- 现在额外具备：
  - `CMP` runtime snapshot serialization
  - `CMP` runtime snapshot hydration
  - `CMP` durable checkpoint write
  - `CMP` checkpoint-level recovery load
  - `cmp-git/cmp-db/cmp-mq/cmp-runtime` 第三波 hooks 的消费与桥接

## 当前第三波已验证的行为

- active mode e2e
- passive mode e2e
- parent-child reseed
- sibling exchange
- non-skipping enforcement
- interrupted/recovered lineage snapshot

## 当前验证基线

- `npm run typecheck` 通过
- `npx tsx --test src/agent_core/cmp-git/*.test.ts src/agent_core/cmp-db/*.test.ts src/agent_core/cmp-mq/*.test.ts src/agent_core/cmp-runtime/*.test.ts src/agent_core/runtime.test.ts` 通过
  - `96 pass / 0 fail`
- `npm run build` 通过

## 当前还没做完的事

从任务包视角看，第三波剩余量已经很少，当前主要未完成或未明确收口的是：

- Part 3:
  - `12-part3-end-to-end-and-cross-part-tests` 的更多场景扩展仍可继续丰富
- Part 4:
  - `08-end-to-end-runtime-smoke-and-multi-agent-tests` 之外更厚的产品级 smoke / recovery 扩展
- 更后续的波次：
  - 真正更厚的 multi-agent runtime closure
  - 更完整的 checkpoint/replay/handoff 收口

## 当前一句话收口

第三波已经把 `CMP` 从“第二波的 governance + delivery + enforcement”推进到了“cross-part hooks + runtime snapshot/recovery + e2e runtime tests 已成立”的状态。
