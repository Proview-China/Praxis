# Dev-Master CMP Import Checklist

状态：总装并入清单 / 可并行施工版本。

更新时间：2026-04-02

## 这份文档回答什么

这份文档专门回答：

- `cmp/mp` 这条线应该按什么顺序并入新的 `dev`
- 哪些内容属于必须吸收的主线资产
- 哪些内容只适合作为阶段性证据或交接材料保留
- 多智能体并行时，应怎样分波次、分写域、分冲突责任

一句白话：

- 它不是 branch diff 备忘录
- 它是给总装施工直接派工的清单

## 当前总原则

1. 总装基座始终以当前 `dev` 为准。
2. `cmp/mp` 不是整包覆盖对象，而是按主题吸收的资产源。
3. 先吸收长期主线资产，再处理高冲突装配口。
4. `memory/live-reports/**` 这类瞬时产物默认不先进入主线。
5. 每一波并入后都要回读：
   - `git status`
   - 差异范围
   - 最小验证结果

## 并入范围分级

### A 级：应优先并入的长期资产

- `docs/ability/29-40`
- `docs/ability/44-47`
- `docs/ability/cmp-*`
- `memory/current-context.md`
- `memory/compaction-handoff-prompt*.md`
- `memory/worklog/2026-03-20*`
- `memory/worklog/2026-03-24*`
- `memory/worklog/2026-03-25-cmp-*`
- `infra/cmp/**`
- `scripts/cmp-status-panel-server.mjs`
- `src/agent_core/cmp-*/**`
- `src/rax/cmp-*/**`

### B 级：需要边研究边并入的装配资产

- `src/agent_core/runtime.ts`
- `src/agent_core/runtime.test.ts`
- `src/rax/index.ts`
- `package.json`
- `docs/master.md`

### C 级：默认不先进入主线的阶段性材料

- `memory/live-reports/cmp-*`
- 单次 live smoke JSON
- 只服务某次上下文压缩的临时备注
- 当前 `cmp/mp` 工作区尚未提交的实验性改动

## 推荐波次

## Wave 0. 文档与记忆对齐

目标：

- 先让新 `dev` 的主叙事完整
- 避免后续代码合并时没有统一方向

建议吸收：

- `docs/ability/29-40`
- `docs/ability/44-47`
- `memory/current-context.md`
- `memory/compaction-handoff-prompt*.md`
- `memory/worklog/2026-03-20*`
- `memory/worklog/2026-03-24*`
- `memory/worklog/2026-03-25-cmp-*`

验证：

- `git diff --stat`
- 回读 `docs/master.md`
- 回读 `memory/current-context.md`

## Wave 1. `CMP` 基础设施与脚本

目标：

- 先把 `CMP` 的共享施工面接回主线

建议吸收：

- `infra/cmp/**`
- `scripts/cmp-status-panel-server.mjs`

验证：

- 目录差异回读
- 脚本入口回读
- 与 `package.json` 的依赖关系核对

## Wave 2. `CMP` 主体模块

目标：

- 让 `CMP` 主体代码回到总装线

建议吸收：

- `src/agent_core/cmp-*/**`
- `src/rax/cmp-*/**`

验证：

- `git diff --stat`
- 相关测试文件范围核对
- 与 `TAP`/`agent_core` 入口的引用关系核对

## Wave 3. 总装入口修复

目标：

- 处理 `CMP` 与 reboot/TAP 基座在入口层的接缝

建议处理：

- `src/agent_core/runtime.ts`
- `src/agent_core/runtime.test.ts`
- `src/rax/index.ts`
- `package.json`

验证：

- `npm run typecheck`
- 相关测试组合
- `git status --short`

## Wave 4. 项目级同步

目标：

- 让后续协作者看到的是统一主线，而不是两套并行叙事

建议处理：

- `docs/master.md`
- 项目级同步总纲
- 必要的 memory 入口升级

验证：

- 文档入口回读
- 当前状态文档回读

## 多智能体分工建议

### Worker A：文档与记忆

负责：

- `docs/ability/29-40`
- `docs/ability/44-47`
- `memory/**`

不负责：

- runtime 入口代码

### Worker B：`CMP` 基础设施

负责：

- `infra/cmp/**`
- `scripts/cmp-status-panel-server.mjs`

不负责：

- `src/agent_core/runtime.ts`

### Worker C：`CMP` 主体代码

负责：

- `src/agent_core/cmp-*/**`
- `src/rax/cmp-*/**`

不负责：

- `package.json`
- `docs/master.md`

### 主线程：总装入口

负责：

- `src/agent_core/runtime.ts`
- `src/rax/index.ts`
- `package.json`
- 最终文档入口与验证

## 当前不要做错的事

- 不要一上来直接整体 merge `cmp/mp`
- 不要先动 `main`
- 不要把 live smoke 结果当长期主线资产
- 不要让多个 worker 同时改 runtime 入口
- 不要在文档叙事还没统一前就开始大批量代码搬运

一句收口：

- 先把主叙事和 `CMP` 资产接回新 `dev`
- 再碰总装入口
