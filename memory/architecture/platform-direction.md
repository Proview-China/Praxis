# Platform Direction

## 已确认方向

- 新实现优先围绕 TypeScript + Node.js 建立。
- macOS 方向保持原生优先，不默认引入 Electron。
- Windows / Linux 可以在未来评估 Electron，但只有在桌面壳需求被明确后再搭。

## 暂时不做的事

- 不提前恢复旧 `better-agent/` 目录结构。
- 不为了“看起来完整”而先铺多套桌面端技术栈。
- 不把平台层决策写死到无法调整的程度。

## 现阶段含义

现阶段更重要的是把核心逻辑、接口和运行时边界建立好，而不是先做多端 UI 表面工程。
