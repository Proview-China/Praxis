## 上下文

当前 `better-agent/core` 的执行主路径围绕 `agent_core_execute_function_call()` 与 `agent_core_register_tool()` 展开：运行时可以归一化 OpenAI / Claude / custom payload，做参数校验、策略校验、幂等处理，并最终通过 `mock / builtin / native` 执行器返回标准化执行记录。这个模型已经足以支撑 `function/custom tool` 的 M0 垂直切片，但仍有三个明显缺口：

- 执行记录始终把 `tool_kind` 写成 `function`，无法表达 shell/web/code/computer 等类别。
- builtin 执行器目前只有 `builtin.echo`，没有覆盖目标文档中要求的核心与扩展工具语义。
- Hooks 仅在 runtime normalizer 中作为外部事件分类的一部分出现，并没有真正接入实际执行链。

同时，用户明确要求本轮沙盒只支持 macOS / Linux。由于 Windows 上实现一致、可控的轻量沙盒成本较高，本轮应把平台范围收紧到 POSIX。

## 目标 / 非目标

**目标：**
- 让注册工具在执行时能够稳定携带并返回真实 `tool_kind`。
- 为 `shell`、`code`、`web`、`computer`、`skills`、`mcp`、`hooks` 增加最小可复现 builtin 路径。
- 为 `shell` 与 `code` 提供 POSIX-only 的沙盒执行实现，并在不支持平台返回结构化错误。
- 在工具执行链中引入前向兼容的 `before_tool` / `after_tool` hook 生命周期。
- 补齐单元测试，验证审计证据、策略拦截、hook 递归保护与平台限制。

**非目标：**
- 不实现完整的 live browser automation / GUI computer-use backend。
- 不实现真实远程 MCP 协议栈或完整 skills 运行时编排器；M0 只提供确定性接入路径与审计契约。
- 不实现 Windows 沙盒或 Windows 平台兼容层。
- 不实现 Memory Module、本轮也不扩展多智能体拓扑。

## 决策

### 1. 用注册元数据显式声明 `tool_kind`

在 `ToolRegistration` 中新增 `tool_kind` 字段，并通过 `constraints.tool_kind` 读取。允许的类别值限定为 `function/web/code/computer/shell/hooks/skills/mcp`，默认值仍为 `function`。这样可以在 `register_tool -> execute_tool_registration -> build_execution_record -> provider wrapper` 的完整链路中稳定保留工具类别，而不是在执行阶段做脆弱推断。

### 2. 继续复用统一执行入口，而不是为每类工具创建割裂 API

本轮仍复用现有的注册工具与统一执行入口，不拆出八套彼此独立的 C API。执行入口继续接受已归一化的 custom/tool payload，实际差异下沉到 `tool_kind + executor_target + policy`。如有必要，只新增轻量别名 API 或更明确的包装函数，避免破坏现有 `function_call` 垂直切片。

### 3. builtin 执行器按“两类能力”拆分

- **POSIX sandbox executors**：`builtin.shell.posix`、`builtin.code.posix`
  - 仅在 macOS / Linux 可执行。
  - 统一通过 POSIX 进程执行辅助层运行命令，收集 `stdout/stderr/exit_code`。
  - 策略最小集包括：允许工作目录、允许命令 / 运行时、可选超时。
- **deterministic adapter executors**：`builtin.web.fixture`、`builtin.computer.fixture`、`builtin.skills.fixture`、`builtin.mcp.fixture`、`builtin.hook.echo`
  - 不依赖 live 外部环境，优先服务统一契约、测试与回放。
  - 若未提供 fixture / adapter 配置，返回结构化 `blocked` 或 `failed`。

这样可以先建立统一运行时骨架，后续再逐步替换为真实 provider / connector。

### 4. Hooks 通过“注册工具 + 生命周期调度”实现

Hooks 不再被视为完全独立于工具系统之外的黑盒。运行时从策略中读取 `before_tool_hooks` 与 `after_tool_hooks`（名称列表），这些 hook 名称必须对应已注册工具，并且其 `tool_kind` 必须是 `hooks`。执行流程如下：

`target request`
→ `before_tool hooks`
→ `main executor`
→ `after_tool hooks`
→ `store execution record`

hook 输入是标准化事件载荷，至少包含：
- `phase`
- `target_tool`
- `target_tool_kind`
- `request`
- `result`（仅 after hook）

hook 输出约定最小字段：
- `decision`: `continue | block`
- `reason`: 可选说明
- 其他字段保留给未来扩展

### 5. 默认启用 hook 递归保护

如果当前目标工具本身已经是 `hooks` 类型，则默认跳过自动注入的 before/after hook 链，并在证据中记录 `hook_recursion_guard`。这样可以避免 hook 触发 hook 导致无限递归，同时保留未来通过显式策略开启递归的空间。

## 风险 / 权衡

- fixture 型 `web/computer/skills/mcp` 适配器不等同于完整 live 能力，但它们可以先保证统一协议、测试稳定性与回放能力。
- POSIX 轻量沙盒主要依赖目录/命令/运行时策略与子进程隔离，不是完整容器级安全边界；但对当前 M0 足够，并且比直接无约束执行更符合文档要求。
- 若继续完全复用现有 `execute_function_call` 命名，语义上会显得偏向旧路径；如果新增别名 API，则需要同步 Node binding 与测试。
