## 上下文

当前 `better-agent/core` 已实现 `builtin.shell.posix` 与 `builtin.code.posix`，并提供了基本的目录 allowlist、命令/runtime allowlist 与最小审计输出。但根据 `docs/ability/01-basic-implementation.md`，M0 沙盒还需要补齐：超时、中断、网络边界、输出/产物限制、资源限制语义以及更完整的审计面。

同时，本项目的架构边界已经明确：core 是内核，向 UI 暴露稳定接口；UI 不能承担实际的安全逻辑。因此 sandbox policy 的解释、限制生效、错误分类和审计组装，都必须在 `better-agent/core` 内完成。

## 目标 / 非目标

**目标：**
- 为 `shell` 与 `code` 执行器建立统一 sandbox policy 合约
- 补齐 timeout / interrupt / output limits / artifact limits / network gate 等控制项
- 输出完整审计结果，供 UI 直接展示
- 对未启用或未支持的限制返回结构化说明
- 保持 Node binding 为薄封装

**非目标：**
- 不实现容器级或虚拟机级隔离
- 不实现 Windows 版本
- 不把 `computer use` live sandbox 纳入本轮
- 不让 UI 层承担 sandbox 决策逻辑

## 决策

### 1. 继续复用现有 POSIX 执行器，而不是另起一套外部 sandbox 服务

本轮在现有 `builtin.shell.posix` / `builtin.code.posix` 上增强控制项，而不是直接引入远程 executor。这样可以最大化复用当前测试与 API 形态，保持 core 接口稳定。

### 2. 定义统一 sandbox policy JSON

新增或完善的 policy 字段至少包括：
- `allowed_cwds`
- `allowed_commands`
- `allowed_runtimes`
- `timeout_ms`
- `network_access`
- `max_stdout_bytes`
- `max_stderr_bytes`
- `max_artifacts`
- `cpu_limit`
- `memory_limit`

其中 CPU / memory 在 M0 可以先以“显式未启用”方式返回，确保 contract 先稳定。

### 3. timeout 与 interrupt 优先级最高

先实现 timeout 与 interrupt，因为这是最直接影响安全性和 UI 可控性的能力。执行器需要保存可终止的进程上下文，并把结果状态明确区分为：
- `success`
- `failed`
- `blocked`
- `timeout`
- `interrupted`

### 4. network_access 在 M0 采用“默认拒绝，显式说明”

在当前阶段，如果没有真正可靠的细粒度网络隔离能力，就不能假装实现了“允许网络”。因此策略应默认：
- `network_access: false` 时严格拒绝带网络需求的执行
- `network_access: true` 但当前实现未支持时返回结构化“未启用/未支持”

### 5. 输出与产物限制必须在 core 内裁剪

stdout/stderr 的大小限制和 artifact 数量限制由 core 内核执行并记录元数据。UI 只展示“裁剪后的结果 + 裁剪说明”，不在 UI 层做二次裁剪。

### 6. 审计结果作为一等输出

每次 sandbox 执行都必须在结果中暴露：
- 生效的 policy snapshot
- executor target
- cwd
- 命令或 runtime
- timeout / interrupt / blocked 原因
- 裁剪信息
- artifact manifest

这既服务 UI 展示，也服务后续 memory / context manager 接入。

## 风险 / 权衡

- 轻量 POSIX 路径比容器级隔离更容易实现，但安全边界更弱；因此必须通过明确 contract 避免“看起来安全，实际未限制”的假象。
- 引入真正的 interrupt 需要额外执行上下文管理，复杂度会上升，但这是后续所有高风险执行能力的共用能力，值得先做。
- 若 network/cpu/memory 现在无法完全启用，就应先把“未支持”说清楚，而不是留给 UI 猜测。
