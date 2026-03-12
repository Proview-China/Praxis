# 2026-03-12 Bootstrap

## 本次建立的基线

- 仓库正式切到 `reboot/blank-slate`。
- 旧的 `AGENTS.md` 已移除，并换成新的重启阶段协作说明。
- 根目录建立了 TypeScript + Node.js 最小工具链。
- `memory/` 目录被正式引入，作为项目级长期记忆层。

## 当前明确方向

- TypeScript 是新的核心语言。
- macOS 不默认走 Electron。
- Windows / Linux 是否使用 Electron，留待后续明确需求再定。
- `docs/` 可能由另一个 Codex 实例并行推进。

## 接下来

1. 写清核心模块和事件模型。
2. 再围绕最小闭环能力持续落代码。
