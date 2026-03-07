## 为什么

当前 `better-agent/core` 只完整实现了 `function/custom tool` 的注册、执行、provider 适配与 runtime event 归一化，但 `/Users/shiyu/Documents/Project/better-agent/docs/ability/01-basic-implementation.md` 定义的 M0 目标要求统一覆盖 `function/web/code/computer/shell/hooks/skills/mcp` 的执行语义、审计证据与失败诊断。尤其是 Hooks 已被文档定义为治理层能力，虽然未来会逐步让位于 skills，但现在仍需要完整的前向兼容语义，避免后续接入 client 侧提示词注入或运行时治理时出现契约断层。

现在推进这项变更，是为了把项目从“只支持单一函数调用垂直切片”提升到“具备统一工具运行时骨架”的阶段，并明确沙盒能力当前只支持 macOS 与 Linux，不在本轮兼容 Windows。

## 变更内容

- 扩展已注册工具的运行时模型，使执行记录能够稳定表达 `tool_kind`，而不是把所有执行都记录为 `function`。
- 为 `web/code/computer/shell/skills/mcp/hooks` 增加最小可复现的 builtin 执行路径；其中 `shell` 与 `code` 提供 macOS/Linux 的 POSIX 沙盒执行版本，Windows 明确返回结构化不支持错误。
- 为 `web/computer/skills/mcp` 提供可测试、可回放的确定性适配路径；当没有配置 live adapter 时，运行时必须返回结构化 `blocked/failed` 结果，而不是静默失败。
- 增加 Hooks 生命周期支持：在工具执行前后可调度 hook 工具，记录审计证据，并允许 hook 对主执行流做继续或阻断决策。
- 补充 C++ 单元测试，验证不同 tool kind、POSIX 沙盒路径、hook 链路与错误契约。

## 功能 (Capabilities)

### 新增功能
- `unified-tool-runtime`: 为多类工具提供统一执行契约、tool_kind 追踪、结构化错误与证据输出。
- `hook-lifecycle-compat`: 为前向兼容保留完整的 before/after hook 生命周期、控制语义与审计记录。

### 修改功能
- 无

## 影响

- 受影响代码主要位于 `better-agent/core/header/agent_core.h`、`better-agent/core/cpp/internal/`、`better-agent/core/cpp/agent_core.cpp`、`better-agent/core/bindings/node/agent_core_napi.cpp` 与 `better-agent/core/tests/`。
- `shell` 与 `code` 沙盒能力在本轮仅保证 macOS / Linux；Windows 不在范围内，必须显式返回结构化不支持结果。
- 本轮不实现完整的 live 浏览器自动化、真实图形界面 computer-use backend、Memory Module 或 Windows 沙盒。
