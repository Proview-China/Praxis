# Swift Host Interface Catalog

## 目标

这份目录用于冻结“Core 未来会向宿主要什么能力”。

重点不是先写 Swift 代码签名，而是先固定协议族和责任边界，避免后面宿主接口无限生长。

当前 phase-1 已决定：

- HostContracts 不是单一大接口 target。
- 它固定拆成五个协议族 target。

## 设计原则

- 一个接口族只负责一种外部能力。
- 接口命名按能力语义，不按现有 SDK 命名。
- Core 只依赖协议语义，不依赖具体实现细节。
- 协议输入输出尽量使用 Core 模型，而不是 provider 原始 payload。
- Apple 专属或 FFI 专属能力，默认不先进入通用 HostContracts。

## 1. `PraxisProviderContracts`

这个 target 负责所有 provider 相关外部能力协议。

### `ProviderInferenceExecutor`

职责：

- 文本生成
- 结构化输出
- 流式 / 非流式推理

不负责：

- skill 注册
- MCP 会话
- 文件上传

### `ProviderEmbeddingExecutor`

职责：

- embedding / vectorize 请求

### `ProviderFileStore`

职责：

- provider 侧文件上传、读取、删除

### `ProviderBatchExecutor`

职责：

- provider 侧 batch / async job

### `ProviderSkillRegistry`

职责：

- 托管 skill 的 list / read / publish / remove / version 管理

### `ProviderSkillActivator`

职责：

- 把统一 skill 描述转换为 provider 可执行载体

### `ProviderMCPExecutor`

职责：

- MCP connect / use / list / call / read / serve 相关宿主能力

## 2. `PraxisWorkspaceContracts`

这个 target 负责所有 workspace 读写与检索协议。

### `WorkspaceReader`

职责：

- 文件读取
- 多文件读取
- 文档读取

### `WorkspaceSearcher`

职责：

- glob
- grep
- symbol search
- references / definitions

### `WorkspaceWriter`

职责：

- 受控写入
- patch 应用
- 文件创建

说明：

- Core 不直接写文件，只生成计划；宿主决定怎么安全执行。

## 3. `PraxisToolingContracts`

这个 target 负责工具执行与过程控制协议。

### `ShellExecutor`

职责：

- shell 命令执行
- stdout / stderr / result 采集

### `ProcessSupervisor`

职责：

- 长任务追踪
- cancel / poll / timeout

### `BrowserExecutor`

职责：

- 浏览器自动化
- 页面导航
- DOM snapshot
- 点击 / 填充 / 截图

### `GitExecutor`

职责：

- repo bootstrap
- branch / worktree / commit / merge / ref readback

说明：

- Git 规则不在这里。
- 这里只负责执行 Git 计划。

## 4. `PraxisInfraContracts`

这个 target 负责持久化、投影、消息与谱系等基础设施协议。

### `JournalStore`

职责：

- 持久化 journal 事件
- cursor readback

### `CheckpointStore`

职责：

- checkpoint 存储与读取

### `ProjectionStore`

职责：

- CMP projection / package / delivery 记录写入与读取

### `MessageBus`

职责：

- CMP delivery publish / ack / escalation

### `LineageStore`

职责：

- branch family / checked ref / promoted ref / lineage truth

说明：

- 如果后续证明 `LineageStore` 与 `GitExecutor` 永远一起变更，可以再收敛；当前先独立。

## 5. `PraxisUserIOContracts`

这个 target 负责用户输入、权限与展示协议。

### `UserInputDriver`

职责：

- 请求用户输入
- 提供 structured prompt 结果

### `PermissionDriver`

职责：

- 请求权限
- 反馈授权结果

### `TerminalPresenter`

职责：

- 终端输出
- 状态渲染
- 日志 / 事件回放展示

### `ConversationPresenter`

职责：

- 把 HostRuntime 用例结果映射为 UI / CLI 可展示状态

说明：

- Presenter 属于宿主展示协议，不进入 Core。

## 6. 暂不独立建通用 target 的接口族

以下接口族当前先保留为“概念预留”，不在 phase-1 升格为通用 HostContracts target。

### Apple 宿主专属能力

例如：

- `AppShellCoordinator`
- `SystemIntegrationDriver`

原因：

- 它们属于 Apple 宿主的边界，不应先污染通用跨平台宿主协议层。

### FFI 导出能力

例如：

- `FFIBridgeExporter`
- `FFICodec`

原因：

- FFI 应该建立在稳定的 `PraxisRuntimeInterface` 与 `PraxisRuntimePresentationBridge` 之上，而不是提前扩张 HostContracts。

### Observability / Telemetry / Metrics

原因：

- 这些能力以后大概率存在，但当前项目的核心问题不是缺观测，而是边界混乱。
- 过早接口化，只会继续膨胀架构表面积。
