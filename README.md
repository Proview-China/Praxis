# Praxis

Praxis 当前可继续开发的总装基线是 `integrate/dev-master-cmp`。

这条线已经不是单纯的 reboot 起步线，而是把 `dev-master`、`reboot/blank-slate`、`cmp/mp` 以及后续 TAP / CMP 收口补丁真正装到一起后的可验证工作线。

## 当前状态

- 项目主工具链是 TypeScript + Node.js。
- `core_agent_runtime`、`TAP`、`CMP`、`rax.cmp` 当前都已进入同一条可继续开发的主线。
- `memory/` 目录继续承担仓库内长期记忆层，用来沉淀当前阶段的事实、约束和工作脉络。
- macOS 不默认走 Electron；Windows / Linux 后续仍可再评估 Electron。

## 当前基线

- 当前总装工作线：`integrate/dev-master-cmp`
- 当前仓库级验证已经通过：
  - `npm run typecheck`
  - `npm run build`
  - `npm test`
- `runtime.continue-followups` 已拆成 focused 测试文件，以绕开 Node 25 + `tsx` 下的单文件 OOM。

## 这条线已经承接住什么

- `reboot/blank-slate` 带回来的 `agent_core` / `TAP` / capability 基座
- `cmp/mp` 带回来的 `CMP` runtime、`rax.cmp`、五角色 runtime 与 live wrapper
- 后续总装阶段对 `runtime.ts`、`runtime.test.ts`、TAP replay / human-gate / provisioning 主链做的收口修正

## 接下来怎么用

1. 默认直接在这条线继续开发新功能。
2. 新功能优先复用已经接好的 `core_agent_runtime + TAP + CMP + rax.cmp` 总装面。
3. 如需回溯重启期设计背景，再读 [docs/master.md](/home/proview/Desktop/Praxis_series/Praxis/docs/master.md) 和 [memory/current-context.md](/home/proview/Desktop/Praxis_series/Praxis/memory/current-context.md)。
