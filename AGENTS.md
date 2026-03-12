# Praxis Reboot Agent Guide

## Scope

- 当前仓库处于 blank-slate 重启阶段，默认不要把旧 `dev` 分支的实现整包搬回来。
- 与用户或代码现状冲突时，以当前事实为准；长期有效的结论再同步进 `memory/`。

## Communication

- 默认使用简体中文。
- 专业术语尽量配白话解释。
- 如果问题开始变得含混或风险不清楚，要先停下来对齐，不要硬编答案。

## Working Defaults

- TypeScript + Node.js 是当前新实现的主语言和主工具链。
- `docs/` 可能会被另一个 Codex 实例持续更新；不要回滚或覆盖与你当前任务无关的文档改动。
- `memory/` 是项目级记忆层，不要只依赖这个 `AGENTS.md`；做完重要架构决策、约束调整或阶段性结论后，要把可复用的信息写回 `memory/`。
- 保持仓库干净、最小化，除非用户明确要求，否则不要提前铺大型目录树或旧时代兼容层。

## Platform Direction

- macOS 不默认走 Electron，Apple 端优先保留原生应用方向。
- Windows 和 Linux 后续可以考虑 Electron，但在明确需求前不要提前搭 UI 壳子。

## Verification

- 新增脚手架后，至少回读一次 `git status` 和相关构建/类型检查结果。
- 提交保持单一意图，便于回滚和 review。
