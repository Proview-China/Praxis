# 2026-04-06 Integrate Dev-Master CMP Baseline Established

## 这轮工作的结论

这轮不是继续做“总装试算”，而是把总装线真正收成了一条可继续开发的工作线。

当前最重要的结论是：

- `integrate/dev-master-cmp` 现在已经能承接 `core_agent_runtime + TAP + CMP + rax.cmp`
- 并且已经过了仓库级验证

一句白话：

- 现在不是“还在拼分支”
- 而是已经有一条可以直接继续写新功能的线

## 这轮真正收进来的内容

### 一、先把 `cmp/mp` 主体并入总装线

当前已经吸收：

- `CMP` workflow 正式接入 `agent_core/runtime.ts`
- `rax.cmp` 的 facade / runtime / status panel / types
- `cmp-five-agent/**`
- `CMP` five-agent live LLM 相关实现：
  - `live-llm.ts`
  - `live-llm-model-executor.ts`
  - `cmp-five-agent-live-smoke.ts`

### 二、再把 TAP runtime 主链回补到总装线

当前已经收回：

- tool reviewer / replay / human-gate / provisioning / recovery 主链
- three-agent ledger 与治理记录链
- split runtime tests 对应的运行时行为
- `runtime.continue-followups` 的 focused 测试拆分

### 三、`runtime.ts` 最终形成总装态

这轮之后，`src/agent_core/runtime.ts` 已同时承接：

- reboot/TAP 的 control plane、replay、recovery、governance、three-agent ledger
- `CMP` 的 workflow 主链
- `CMP` five-agent live wrapper

白话：

- 现在 `runtime.ts` 不再只偏向某一边
- 它已经变成当前项目最关键的正式总装入口

## 这轮最终通过的验证

当前已经真实通过：

- `npm run typecheck`
- `npm run build`
- `npm test`

额外重点回读：

- `src/agent_core/runtime.test.ts`
- `src/agent_core/runtime.cmp-live.test.ts`
- `src/agent_core/runtime.cmp-five-agent.test.ts`
- `src/agent_core/runtime.recovery.test.ts`
- `src/agent_core/runtime.replay.test.ts`
- `src/agent_core/runtime.replay-continue.test.ts`
- `src/agent_core/runtime.continue-followups.test.ts`
- `src/agent_core/runtime.continue-followups.*.test.ts`
- `src/rax/cmp-facade.test.ts`
- `src/rax/cmp-runtime.test.ts`

## 这轮最重要的新判断

当前最重要的新判断不是某个单独模块终于通过，而是：

- 这条线现在已经足够承托后续新开发

也就是说：

- 后续如果继续联调 `CMP + TAP + core_agent_runtime`
- 默认直接在 `integrate/dev-master-cmp` 上写

## 当前最推荐的下一步

后续默认顺序应改成：

1. 以 `integrate/dev-master-cmp` 为当前开发主线
2. 从新的功能目标出发继续推进
3. 只在必要时再回看历史分支做对照

一句收口：

- 总装阶段到这里已经基本完成
- 下面进入的是“基于总装主线继续开发”的阶段
