## 为什么

当前 `better-agent/core` 已经具备 `builtin.shell.posix` 与 `builtin.code.posix` 的最小执行路径，但距离 `/Users/shiyu/Documents/Project/better-agent/docs/ability/01-basic-implementation.md` 中对沙盒的要求还有明显差距：文档要求限制目录、网络、时长、CPU/内存，并且强调可审计、可复盘、可中断，而当前实现仍主要停留在“可执行 + 基本 allowlist”的阶段。

现在推进这项变更，是为了把现有的执行器提升为真正可控的 M0 沙盒内核，并继续遵守本项目的内核边界：所有沙盒决策逻辑都必须留在 `better-agent/core`，供 UI 层直接调用；UI 不负责自行组合安全策略、资源限制或执行审计逻辑。

## 变更内容

- 为 `shell` 与 `code` POSIX 执行器补齐统一 sandbox policy：目录、命令/运行时、超时、网络开关、输出大小、产物数量等控制项。
- 引入执行中断与超时语义，明确区分 `failed / blocked / timeout / interrupted`。
- 强化审计与回放信息，确保每次沙盒执行都能返回 policy snapshot、执行器元数据、产物清单与失败原因。
- 对不支持的平台或当前无法启用的资源限制，返回结构化结果而不是静默忽略。
- 扩展单元测试与 binding 验证，证明 core 内核已经承担沙盒逻辑，UI 只需调用接口。

## 功能 (Capabilities)

### 新增功能
- `sandbox-policy-enforcement`: 为 shell/code 执行定义统一的 sandbox policy 合约与强制执行规则。
- `sandbox-runtime-control`: 为 sandbox 执行提供超时、中断、输出与产物治理。
- `sandbox-audit-surface`: 为 UI 暴露稳定的审计与状态结果，而不把安全逻辑下放给 UI。

### 修改功能
- 无

## 影响

- 受影响代码主要位于 `better-agent/core/header/agent_core.h`、`better-agent/core/cpp/internal/core_execution.cpp`、相关内部模型与 `better-agent/core/tests/`。
- 本轮继续只支持 macOS / Linux 的 POSIX 路径，不扩展 Windows。
- 本轮不实现容器级隔离、虚拟机隔离或真实 GUI `computer use` 沙盒，只主攻 `shell` 与 `code`。
