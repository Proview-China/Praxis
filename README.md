# Praxis

`reboot/blank-slate` 是 Praxis 的空白重启线。

这条分支的目标不是修补旧实现，而是从一个干净、可讨论、可验证的起点重新建立项目骨架。

## 当前状态

- 旧实现没有被带入这条分支。
- `dev`、`main`、`deploy` 保持原样，作为历史参考与回滚抓手。
- 当前仓库先以 TypeScript + Node.js 作为新的主工具链。
- `memory/` 目录用于沉淀架构思路、约束和阶段性结论，不再把所有长期记忆都挤进 `AGENTS.md`。
- macOS 不默认使用 Electron；Windows / Linux 未来可以再评估 Electron。

## 当前基线

- 根目录 Node/TypeScript 工具链已经就位。
- 仓库级协作说明见 [AGENTS.md](/home/proview/Desktop/Praxis_series/Praxis/AGENTS.md)。
- 项目记忆层说明见 [memory/README.md](/home/proview/Desktop/Praxis_series/Praxis/memory/README.md)。
- 重启约束文档见 [docs/reboot-charter.md](/home/proview/Desktop/Praxis_series/Praxis/docs/reboot-charter.md)。

## 接下来先做什么

1. 继续把新的系统边界和模块职责写实。
2. 把第一批核心接口和事件模型稳定下来。
3. 然后再围绕最小闭环能力持续往里写代码。
