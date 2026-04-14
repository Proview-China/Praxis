# Praxis

Praxis 现在按纯 framework 方向继续收口。

仓库内被跟踪的旧 TypeScript / Node.js 实现已经移除；当前活代码主线以 SwiftPM targets、runtime contracts、FFI 导出边界和本地 runtime 组合为准。

## 当前状态

- 项目当前主工具链是 Swift + SwiftPM。
- 仓库定位是可嵌入、可导出的 runtime/framework，而不是产品 CLI、TUI 或 GUI 仓库。
- `memory/` 目录继续承担仓库内长期记忆层，用来沉淀当前阶段的事实、约束和工作脉络。
- 根目录主计划以 [SWIFT_REFACTOR_PLAN.md](/Users/shiyu/Documents/Project/Praxis/SWIFT_REFACTOR_PLAN.md) 为准。

## 当前基线

- 当前仓库级主验证是 `swift test`
- 旧 TS 运行时与 Node 构建物已经从仓库剔除：
  - `src/`
  - `dist/`
  - `package.json`
  - `package-lock.json`
  - `tsconfig.json`
  - `scripts/`
- Swift runtime 主线当前保留：
  - domain targets
  - host contracts
  - runtime composition / use cases / facades / interface / gateway
  - `PraxisRuntimeKit` 高层 Swift framework API（收敛为 `runs` / `tap` / `cmp` / `mp` 四个稳定入口，参数面继续用 RuntimeKit 自己的 typed input / options model，并把 `project` / `run` / `session` / `agent` / `capability` / `memory` 这些标识符收成轻量 ref 类型）
  - FFI 导出边界
- 旧 TS 文件路径若仍出现在部分 boundary metadata 或 archive 文档中，应视为历史谱系引用，不代表仓库中仍存在可执行实现。

## 当前方向

- 优先继续收口纯 framework 公开面，不再恢复 TS 运行时。
- `PraxisCLI`、`PraxisAppleUI`、TUI、GUI 都不再作为长期产品方向。
- 调用者友好性应通过更清晰的 Swift public API 和导出边界来解决，而不是通过 CLI 壳补齐。

## 接下来怎么用

1. 新功能默认直接落在 Swift targets，不再往仓库里恢复 TS/Node runtime。
2. 先从 runtime contracts、use cases、facades、gateway、FFI 这些 framework 面扩展。
3. 如需追溯旧实现来源，优先看 boundary metadata 的 `legacyReferences` 和 `memory/` 下的历史记录，而不是假设仓库里仍有旧 TS 代码。
4. 任何涉及方向调整的长期结论，都同步写回 `memory/`。
