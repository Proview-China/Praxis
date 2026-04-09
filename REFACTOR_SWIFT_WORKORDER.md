# Praxis Swift 重构工单

## 1. 目标与结论

这份工单的目的不是把当前 TypeScript 代码逐文件翻译成 Swift，而是先把当前仓库的真实模块职责、实现方式和宿主依赖拆清楚，再为后续的 Swift Core + Swift UI/TUI 重构提供对照表。

配套架构蓝图见：

- [SWIFT_ARCHITECTURE.md](/Users/shiyu/Documents/Project/Praxis/SWIFT_ARCHITECTURE.md)
- [ADR-0002-swift-rearchitecture-layering.md](/Users/shiyu/Documents/Project/Praxis/memory/decisions/ADR-0002-swift-rearchitecture-layering.md)
- [swift-core-decomposition.md](/Users/shiyu/Documents/Project/Praxis/memory/architecture/swift-core-decomposition.md)

当前最重要的三个结论：

- 当前仓库真正的“核心”主要在 `src/agent_core/`，但它被一个超大总编排器 `src/agent_core/runtime.ts` 串成了一团。
- 当前仓库并没有成熟独立的 TUI 子系统；所谓界面层，实质上是 `src/agent_core/live-agent-chat.ts` + `src/agent_core/live-agent-chat/ui.ts` 这套 CLI harness。
- `src/rax/` 更像统一能力外观层、兼容层和 provider 接缝层，不应原样视为未来 Swift Core 的领域核心。

对后续 Swift 重构的直接含义：

- Swift Core 应优先承接“纯领域模型 + 规则 + 状态机 + 编排协议”。
- Git / Postgres / Redis / OpenAI / Anthropic / DeepMind / CLI / readline 这些都应该降为宿主适配器，不应混进核心库。
- Apple 端 UI 可以用 SwiftUI；跨平台复用应优先通过 Swift Package + C ABI / FFI 边界导出 Core，而不是继续把 UI 和 Core 缠在一起。

## 2. 当前项目现状总览

### 2.1 真实入口与运行基线

- 根入口：`src/index.ts`
  - 对外同时导出 `rax` 和 `agent_core`。
  - 当前更像“总装入口”，不是干净的产品入口。
- 主工具链：TypeScript + Node.js 22+
- 编译输出：`dist/`
- 当前脚本里暴露出的主要运行面：
  - `npm run dev`
  - `npm run build`
  - `npm run typecheck`
  - `npm test`
  - 多个 smoke / live / cmp infra 脚本
- 当前 README 明确说明：
  - 现在的主线已经是 `integrate/dev-master-cmp` 吸收后的大总装线
  - `core + TAP + CMP + rax.cmp` 已经被并入同一实现面

### 2.2 当前架构的真实层次

按“代码真实作用”而不是“命名理想状态”来看，当前仓库大致分为六层：

1. `agent_core`
   - 真正的核心业务层
   - 包含 kernel runtime、capability 执行面、TAP、CMP、五 agent 编排、状态与恢复
2. `rax`
   - 统一 facade、provider 兼容层、MCP/skill/websearch/runtime 接缝层
3. `integrations/*`
   - OpenAI / Anthropic / DeepMind 的 API 与 agent 侧 payload/adapter 实现
4. `infra/cmp`
   - CMP live 所需基础设施与 docker compose
5. `scripts`
   - refactor gate、status panel server 等仓库维护脚本
6. `docs/` 与 `memory/`
   - 大量设计资料、任务包、工作日志、长期记忆

### 2.3 当前“UI / TUI”真实情况

当前仓库没有独立的 `tui/`、`app/`、`frontend/` 或桌面 UI 模块。

现在最接近 UI 的只有：

- `src/agent_core/live-agent-chat.ts`
  - CLI 主循环
  - 直连 OpenAI-compatible 路由
  - 串起 core / TAP / CMP live 路径
- `src/agent_core/live-agent-chat/ui.ts`
  - 终端打印
  - direct composer 输入框
  - 状态、事件、历史记录渲染

这意味着未来你想做的 Swift “core + tui” 并不是迁移一个成熟界面子系统，而是：

- 把现有 CLI harness 当成行为参考
- 重新设计真正的 Swift 宿主层

## 3. 当前模块地图

下面的模块地图按“值得作为重构单元”的粒度来写，主要以一级目录和关键文件为单位。

### 3.1 根层与总装入口

| 模块 | 当前职责 | 主要实现 | 重构判断 |
| --- | --- | --- | --- |
| `src/index.ts` | 总装导出入口，向外暴露 `rax` 与 `agent_core` | 统一 export + bootstrap 描述 | 不应成为 Swift Core 结构模板，只保留为兼容层参考 |
| `package.json` | 当前 Node 脚本、验证基线、smoke/life 脚本入口 | `build/typecheck/test/smoke/cmp:infra:*` | 用来提取行为基线，不迁移到 Swift Core |
| `tsconfig.json` | TS 编译配置 | NodeNext / ES2022 / declaration | 仅作现状参考 |

### 3.2 `src/agent_core/` 模块地图

#### A. Kernel 基础层

| 模块 | 当前职责 | 主要文件 | 实现判断 | Swift 去向 |
| --- | --- | --- | --- | --- |
| `types` | Kernel 事件、状态、intent、result、session、checkpoint 基础类型 | `kernel-*.ts` | 纯模型，迁移价值高 | `PraxisCore/KernelTypes` |
| `goal` | 目标源、goal 归一化、goal 编译 | `goal-source.ts`, `goal-normalizer.ts`, `goal-compiler.ts` | 纯规则，适合先迁 | `PraxisCore/Goal` |
| `state` | 从事件投影当前状态、状态校验、delta | `state-projector.ts`, `state-validator.ts` | 纯投影逻辑 | `PraxisCore/State` |
| `transition` | 状态转移表、guard、transition evaluator | `transition-table.ts`, `transition-guards.ts`, `transition-evaluator.ts` | 纯状态机 | `PraxisCore/Transition` |
| `run` | run 生命周期、排队、恢复、调度协同 | `run-coordinator.ts`, `run-lifecycle.ts`, `run-dispatch.ts`, `run-resume.ts` | 纯编排为主 | `PraxisCore/Run` |
| `session` | session header、冷热会话、checkpoint 指针、run 绑定 | `session-manager.ts`, `session-header-store.ts`, `session-eviction.ts` | 逻辑清晰，可独立迁移 | `PraxisCore/Session` |
| `journal` | append-only 事件日志、cursor、flush trigger | `append-only-log.ts`, `journal-cursor.ts` | 目前以内存/简单存储为主 | `PraxisCore/Journal` |
| `checkpoint` | checkpoint 存储、恢复、pool runtime snapshot 合并 | `checkpoint-store.ts`, `checkpoint-recovery.ts`, `pool-runtime-checkpoint.ts` | 核心但和 TAP/CMP 息息相关 | `PraxisCore/Checkpoint` |

#### B. Capability 执行基础设施

| 模块 | 当前职责 | 主要文件 | 实现判断 | Swift 去向 |
| --- | --- | --- | --- | --- |
| `capability-types` | capability 相关协议与类型 | `capability-*.ts` | 纯契约 | `PraxisCore/CapabilityTypes` |
| `capability-model` | manifest / binding / model | `capability-model.ts`, `capability-manifest.ts`, `capability-binding.ts` | 纯契约+装配 | `PraxisCore/CapabilityModel` |
| `capability-invocation` | invocation、lease、execution plan | `capability-invocation.ts`, `capability-plan.ts`, `capability-lease.ts` | 核心执行抽象 | `PraxisCore/CapabilityExecution` |
| `capability-gateway` | capability 获取/准备统一入口 | `kernel-capability-gateway.ts` | 内核到执行面接缝 | `PraxisCore/CapabilityGateway` |
| `capability-pool` | adapter 注册、调度、背压、drain、health | `pool-registry.ts`, `pool-dispatch.ts`, `pool-backpressure.ts` | 重要，但应和宿主实现隔离 | `PraxisCore/CapabilityPool` |
| `capability-result` | result envelope、事件桥 | `result-envelope.ts`, `result-event-bridge.ts` | 纯领域桥接逻辑 | `PraxisCore/CapabilityResult` |
| `port` | capability port broker、queue、idempotency | `port-broker.ts`, `port-queue.ts`, `port-backpressure.ts` | 当前 runtime 内部消息桥 | `PraxisCore/ExecutionPort` |
| `capability-package` | capability package / baseline / family catalog | `capability-package.ts`, `first-wave-capability-package.ts`, `first-class-tooling-baseline.ts` 等 | 是“能力目录与装配描述层” | `PraxisCore/CapabilityCatalog` |

#### C. TAP / 三 agent 治理层

| 模块 | 当前职责 | 主要文件 | 实现判断 | Swift 去向 |
| --- | --- | --- | --- | --- |
| `ta-pool-types` | TAP 领域类型：profile / review / provision / TMA | `ta-pool-*.ts` | 纯模型，优先迁移 | `PraxisCore/TapTypes` |
| `ta-pool-model` | 风险分类、模式策略、治理对象、用户视图、baseline | `risk-classifier.ts`, `mode-policy.ts`, `governance-object.ts`, `user-surface.ts` | TAP 规则核心 | `PraxisCore/TapGovernance` |
| `ta-pool-context` | 审查/供应上下文 aperture 与 plain language risk | `context-aperture.ts`, `plain-language-risk.ts` | 纯规则与格式化 | `PraxisCore/TapContext` |
| `ta-pool-review` | reviewer 逻辑、评审决策、路由、durable state | `review-decision-engine.ts`, `reviewer-runtime.ts` | 业务规则强，适合核心化 | `PraxisCore/TapReview` |
| `ta-pool-tool-review` | tool reviewer 合同、session、runtime | `tool-review-contract.ts`, `tool-review-runtime.ts` | TAP 子域 | `PraxisCore/TapToolReview` |
| `ta-pool-provision` | provision registry、asset index、planner、executor、worker bridge | `tma-planner.ts`, `tma-executor.ts`, `provisioner-runtime.ts` | 业务规则和宿主桥混在一起 | 拆为 `PraxisCore/TapProvision` + Host adapters |
| `ta-pool-runtime` | activation driver、control plane gateway、human gate、replay、runtime snapshot | `activation-driver.ts`, `control-plane-gateway.ts`, `human-gate.ts`, `runtime-snapshot.ts` | TAP 编排核心 | `PraxisCore/TapRuntime` |
| `ta-pool-safety` | 安全拦截器 | `safety-interceptor.ts` | 小而独立 | `PraxisCore/TapSafety` |
| `tap-availability` | capability family availability audit、gate、failure taxonomy | `availability-audit.ts`, `availability-gating.ts`, `failure-taxonomy.ts` | 偏治理/运维审计层 | `PraxisCore/TapAvailability`，但可后迁 |

#### D. CMP 子系统

| 模块 | 当前职责 | 主要文件 | 实现判断 | Swift 去向 |
| --- | --- | --- | --- | --- |
| `cmp-types` | CMP canonical object model、section、lineage、delivery、interface | `cmp-object-model.ts`, `cmp-section.ts`, `cmp-lineage.ts`, `cmp-delivery.ts` | 纯领域模型，优先抽离 | `PraxisCore/CmpTypes` |
| `cmp-runtime` | ingress、section lowering、projection、delivery routing、infra bootstrap、恢复对账 | `section-ingress.ts`, `section-rules.ts`, `materialization.ts`, `delivery-routing.ts`, `runtime-recovery.ts`, `infra-bootstrap.ts` | CMP 领域中枢，但和 infra 边界缠得很深 | 拆为 `PraxisCore/CmpDomain` + `PraxisHost/CmpInfra` |
| `cmp-git` | branch family、lineage registry、commit sync、refs lifecycle、git backend、worktree bootstrap | `cmp-git-types.ts`, `orchestrator.ts`, `git-cli-backend.ts` | 规则 + Git CLI 执行器混在一起 | 拆为 `PraxisCore/CmpGitModel` + `PraxisHost/GitExecutor` |
| `cmp-db` | project topology、local hot tables、projection state、delivery registry、Postgres adapter/live executor | `project-db-topology.ts`, `agent-local-hot-tables.ts`, `postgresql-adapter.ts` | SQL 构建与模型定义已经比较清楚 | 拆为 `PraxisCore/CmpDbModel` + `PraxisHost/PostgresExecutor` |
| `cmp-mq` | topic topology、neighborhood routing、subscription guards、critical escalation、Redis adapter/bootstrap | `topic-topology.ts`, `redis-routing.ts`, `redis-adapter.ts` | 规则 + MQ adapter 混合 | 拆为 `PraxisCore/CmpMqModel` + `PraxisHost/RedisExecutor` |
| `cmp-five-agent` | ICMA / Iterator / Checker / DbAgent / Dispatcher 五角色 runtime + live llm + tap bridge | `icma-runtime.ts`, `iterator-checker-runtime.ts`, `dbagent-runtime.ts`, `dispatcher-runtime.ts`, `five-agent-runtime.ts`, `live-llm.ts` | 当前最像“多 agent 产品逻辑”的模块 | `PraxisCore/CmpFiveAgent` |
| `cmp-service` | 供外部宿主调用的 CMP 服务包装层 | `project-service.ts`, `active-flow-service.ts`, `tap-bridge-service.ts`, `live-service.ts` | API surface，不是核心规则 | `PraxisHost/CmpService` |
| `cmp-api` | AgentCore 暴露的 CMP API 类型 | `index.ts` | 薄接口层 | `PraxisHost/CmpApi` |

#### E. Integrations 与宿主桥

| 模块 | 当前职责 | 主要文件 | 实现判断 | Swift 去向 |
| --- | --- | --- | --- | --- |
| `integrations/model-inference*` | 统一模型推理桥，底层依赖 `rax.generate` 与 OpenAI SDK | `model-inference.ts`, `model-inference-adapter.ts` | 当前直接泄露 provider / SDK 细节到 runtime | 只保留协议，执行器单独做 |
| `integrations/rax-*` | 把 rax 的 websearch / mcp / skill 接到 agent_core capability 家族 | `rax-websearch-adapter.ts`, `rax-mcp-adapter.ts`, `rax-skill-adapter.ts` | 这是接缝层，不是 Core 领域 | `PraxisHost/RaxBridge` 或直接重做 |
| `integrations/tap-capability-family-assembly.ts` | 组装 foundation/websearch/skill/mcp/userio 五大家族 | `tap-capability-family-assembly.ts` | 运行时装配器 | `PraxisHost/CapabilityAssembly` |
| `integrations/tap-tooling*` | shell/git/browser/playwright 等工具能力适配 | `tap-tooling-adapter.ts` + `tap-tooling/` | 明显是宿主执行器 | `PraxisHost/ToolingAdapters` |
| `integrations/workspace-read-adapter.ts` | 代码读取、glob、grep、workspace symbol 等工作区读取能力 | `workspace-read-adapter.ts` | 适配器，不应进 Core | `PraxisHost/WorkspaceRead` |
| `integrations/tap-vendor-network-adapter.ts` | vendor websearch/network family | adapter 文件本身 | 宿主接入层 | `PraxisHost/NetworkAdapters` |
| `integrations/tap-vendor-user-io-adapter.ts` | request_user_input / request_permissions | adapter 文件本身 | 宿主接入层 | `PraxisHost/UserIoAdapters` |
| `integrations/tap-agent-model.ts` | reviewer/tool-review/provisioner 的模型 route | `tap-agent-model.ts` | 配置/路由策略 | Core 可保留策略，具体 SDK 不保留 |

#### F. 临时 UI / CLI 宿主层

| 模块 | 当前职责 | 主要文件 | 实现判断 | Swift 去向 |
| --- | --- | --- | --- | --- |
| `live-agent-chat.ts` | CLI 主程序，输入循环，直接调用 core/TAP/CMP live | `src/agent_core/live-agent-chat.ts` | 不是稳定 UI 架构，只是临时操作壳 | 重写为 Swift CLI/TUI |
| `live-agent-chat/shared.ts` | CLI 共享类型、日志、文本提取、配置拼装 | `shared.ts` | 多数逻辑是宿主层 helper | 部分行为可参考，不直接迁移 |
| `live-agent-chat/ui.ts` | 终端渲染、composer 输入、状态输出 | `ui.ts` | 纯 Node 终端实现 | 用 Swift 重写，不沿用 |

### 3.3 `src/rax/` 模块地图

`rax` 不是简单的 provider SDK wrapper，它已经承接了统一 capability router、compatibility profile、MCP runtime、skill runtime、websearch runtime，以及 `rax.cmp` facade。

| 模块 | 当前职责 | 主要文件 | 重构判断 |
| --- | --- | --- | --- |
| `runtime.ts` | 默认 `rax` 实例装配，绑定 router / mcp / skill / cmp runtime | `runtime.ts` | 是装配入口，不是纯核心 |
| `facade.ts` | `generate/embed/file/batch/websearch/mcp/skill/cmp` 的统一外观 | `facade.ts` | 更像“公共 SDK 外观层”，不应混入 Swift Core |
| `registry.ts` | capability registry 与 provider support 描述 | `registry.ts` | 可保留为能力目录思想，但不必按 TS 结构迁移 |
| `router.ts` / `adapters.ts` | capability request 路由与 thin adapters | `router.ts`, `adapters.ts` | 可转化为 Swift Host routing 层 |
| `mcp-*` | shared/native MCP runtime 与 compose | `mcp-runtime.ts`, `mcp-native-runtime.ts`, `mcp-native-compose.ts` | Host integration |
| `skill-*` | skill runtime / types / reports | `skill-runtime.ts`, `skill-types.ts`, `skill-capability-report.ts` | Host integration |
| `websearch-*` | websearch runtime/result/types | `websearch-runtime.ts`, `websearch-result.ts` | Host integration |
| `cmp-*` + `cmp/` | `rax.cmp` facade、config、status panel、project/roles/session/flow API | `cmp-facade.ts`, `cmp-runtime.ts`, `cmp-status-panel.ts`, `cmp/*.ts` | 应作为对外 API surface 参考，不应压进核心库 |

结论：

- `rax` 更像未来 Swift 重构中的 `PraxisSDK` / `PraxisHostFacade`
- 不像 `PraxisCore`

### 3.4 `src/integrations/` provider 模块地图

当前每个 provider 都分成：

- `api/`
  - 直接对接平台 API / payload builder
- `agent/`
  - 对接 agent runtime / orchestration 层

已存在的 provider：

- `src/integrations/openai`
- `src/integrations/anthropic`
- `src/integrations/deepmind`

当前职责：

- 生成 payload
- skill carrier / lifecycle
- MCP native payload
- embeddings / files / batches / search 等 provider 侧映射

重构判断：

- 这些模块应重写成“Provider Adapter 层”
- 不应再让 Core 直接依赖 provider 的 JSON shape 或 SDK 类

### 3.5 Infra、脚本、记忆层

| 模块 | 当前职责 | 主要文件 | 重构判断 |
| --- | --- | --- | --- |
| `infra/cmp` | CMP live infra：Postgres / Redis / Git infra / status panel | `infra/cmp/compose.yaml`, `README.md`, `postgres/init/*.sql` | 保留为宿主环境，不属于 Swift Core |
| `scripts/refactor-test-gates.mjs` | 大文件拆分 gate 与 focused suites 管理 | 脚本本身 | 重构时继续使用行为基线思想 |
| `scripts/cmp-status-panel-server.mjs` | status panel server | 脚本本身 | 宿主工具 |
| `docs/` | 设计文档、task pack、路线图 | 大量 markdown | 是需求/历史资料，不是迁移对象 |
| `memory/` | 长期记忆与工作日志 | `architecture/`, `decisions/`, `worklog/` | 继续保留，用于沉淀 Swift 重构结论 |

## 4. 当前实现的关键问题

### 4.1 总编排器过大

`src/agent_core/runtime.ts` 超过 7000 行，当前同时承担：

- runtime 装配
- capability dispatch
- model inference 分发
- TAP 控制平面
- CMP runtime/infra/five-agent 逻辑
- recovery / checkpoint / session 协作

这意味着：

- 任何一处改动都可能影响全链
- 模块边界主要存在于目录里，不存在于运行时真实依赖里
- Swift 重构必须先拆职责，再搬实现

### 4.2 领域规则与宿主执行器混在一起

典型例子：

- `cmp-git`
  - 既有 branch/lineage/governance 规则
  - 又有 `GitCliCmpGitBackend` 这种直接 `execFile("git")` 的执行器
- `cmp-db`
  - 既有 topology / projection state
  - 又有 PostgreSQL SQL 构建与 live executor
- `cmp-mq`
  - 既有 topic / routing / guard
  - 又有 Redis adapter
- `model-inference.ts`
  - 内核直接知道 OpenAI SDK 和 provider metadata

### 4.3 `rax` 与 `agent_core` 边界重叠

当前同时存在：

- `agent_core` 自己的 capability/inference/runtime 体系
- `rax` 自己的 facade/router/runtime 体系

这两个层级不是严格上下分离，更像并行生长后在总装线硬接起来。

### 4.4 UI 只是 harness，不是产品级界面层

当前 CLI/TUI 行为可参考，但不应作为未来 UI 架构基础：

- 直接耦合 OpenAI-compatible live route
- 直接读取终端输入
- 直接渲染 CMP/TAP/core 内部细节

### 4.5 文档驱动很强，但代码边界没有同步收口

当前项目有大量 outline / task pack / closure 文档，但代码里仍然保留大量历史并行概念，导致：

- 文档边界比代码边界清晰
- 运行时的真实依赖更混杂

## 5. Swift 重构目标架构

建议不要以“TS 目录 = Swift 模块”迁移，而是以“纯度”和“宿主依赖”切层。

### 5.1 建议的新模块分层

#### 第一层：`PraxisCore`

纯 Swift Package，尽量不依赖具体平台 SDK。

建议包含：

- `KernelTypes`
- `Goal`
- `State`
- `Transition`
- `Run`
- `Session`
- `Journal`
- `Checkpoint`
- `CapabilityTypes`
- `CapabilityModel`
- `CapabilityInvocation`
- `CapabilityGateway`
- `CapabilityPool`
- `CapabilityCatalog`
- `TapTypes`
- `TapGovernance`
- `TapReview`
- `TapProvision`
- `TapRuntime`
- `CmpTypes`
- `CmpDomain`
- `CmpGitModel`
- `CmpDbModel`
- `CmpMqModel`
- `CmpFiveAgent`

原则：

- 只保留纯模型、状态机、策略、规划、规则
- 任何 `Process` / shell / Git CLI / SQL driver / Redis client / provider SDK 都不要直接进这层

#### 第二层：`PraxisHost` / `PraxisAdapters`

负责把 Core 接到真实世界。

建议包含：

- `WorkspaceReadAdapter`
- `ShellToolingAdapter`
- `GitExecutor`
- `PostgresExecutor`
- `RedisExecutor`
- `ProviderAdapter.OpenAI`
- `ProviderAdapter.Anthropic`
- `ProviderAdapter.DeepMind`
- `McpAdapter`
- `SkillAdapter`
- `UserIoAdapter`

#### 第三层：Apple 端宿主

建议至少拆成：

- `PraxisApp`
  - SwiftUI 宿主
  - macOS / iPadOS / iOS 共用界面层
- `PraxisCLI` 或 `PraxisTUI`
  - 命令行 / 终端交互层
  - 接管现有 `live-agent-chat` 的职责

#### 第四层：跨平台导出层

为了满足“其它平台 UI 复用核心库”的目标，建议预留：

- C ABI 导出层
- 或 Swift -> static/dynamic lib + 统一 FFI façade

不要把跨平台复用建立在直接复用 SwiftUI 上，而要建立在 `PraxisCore` 的稳定 ABI / API 上。

## 6. 重构执行工单

下面的工单按推荐顺序排列。每个工单都尽量避免“一上来重写全系统”。

### W0. 冻结现状基线与行为对照

目标：

- 先把当前 TS 系统的可验证行为固定住，避免 Swift 重构时失去对照

任务：

- 记录当前有效验证命令
  - `npm run typecheck`
  - `npm run build`
  - `npm test`
  - `npm run test:refactor:list`
- 盘点当前 live / smoke 入口
  - `src/agent_core/single-agent-live-smoke.ts`
  - `src/rax/cmp-five-agent-live-smoke.ts`
  - `src/agent_core/live-agent-chat.ts`
- 为未来 Swift Core 抽取最小行为黄金样本
  - goal 编译
  - run transition
  - capability invocation plan
  - TAP 风险分类
  - CMP section lowering / routing

完成标准：

- 有一份最小行为样本列表
- 明确哪些行为必须在 Swift 中 1:1 保持

### W1. 先抽纯领域模型，不动宿主

目标：

- 优先迁移“纯度最高、收益最高”的类型系统与状态机

任务：

- 从以下模块抽 Swift 对应数据模型与纯函数：
  - `types`
  - `goal`
  - `state`
  - `transition`
  - `run`
  - `session`
  - `journal`
  - `checkpoint` 中的纯模型部分
  - `cmp-types`
  - `ta-pool-types`
- 明确所有模型的序列化格式
  - ID
  - 时间戳
  - 枚举值
  - payload schema

完成标准：

- `PraxisCore` 中已具备纯模型和状态机
- 可以不依赖 Node 跑核心单元测试

### W2. 拆 Capability 执行内核

目标：

- 把当前 capability 体系从 TS runtime 总线里剥出来

任务：

- 迁移：
  - `capability-types`
  - `capability-model`
  - `capability-invocation`
  - `capability-gateway`
  - `capability-pool`
  - `capability-result`
  - `port`
- 重新定义 Swift 协议：
  - capability manifest
  - adapter lifecycle
  - prepare / execute / cancel / healthCheck
  - queue / backpressure / lease

完成标准：

- Swift Core 能表示和调度 capability invocation
- 但暂时不要求接通真实外部工具

### W3. 拆 TAP 规则核

目标：

- 让 reviewer / tool reviewer / provisioner / human gate 成为独立的 Core 子域

任务：

- 迁移：
  - `ta-pool-model`
  - `ta-pool-context`
  - `ta-pool-review`
  - `ta-pool-tool-review`
  - `ta-pool-provision` 的纯规划部分
  - `ta-pool-runtime`
  - `ta-pool-safety`
  - `tap-availability`
- 明确 TAP 里哪些是纯规则，哪些是宿主实现：
  - 纯规则：风险分类、授权、审批状态、replay policy、治理快照
  - 宿主实现：真正执行 shell / browser / network / mcp / skill

完成标准：

- Swift Core 可以独立做 TAP 决策
- 审查与供应流程不再依赖 Node 特定实现

### W4. 拆 CMP 领域核

目标：

- 把 CMP 从“文档驱动的大体系”落成可复用的 Swift 领域模型与 planner

任务：

- 优先迁移纯规则：
  - `cmp-types`
  - `cmp-runtime` 中的 ingress、section、rules、materialization、delivery-routing、visibility、runtime-snapshot、runtime-recovery 的纯规则部分
  - `cmp-git` 中的 lineage / governance / refs lifecycle 规则
  - `cmp-db` 中的 topology / projection state / registry model
  - `cmp-mq` 中的 topic / neighborhood / guard / escalation model
  - `cmp-five-agent` 中的五角色输入输出协议与角色职责

完成标准：

- Swift Core 能在不接真实 Git/PG/Redis 的情况下跑 CMP 规划与状态推进

### W5. 宿主适配器化 Git / DB / MQ

目标：

- 把 CMP 的现实基础设施改成明确的 Host adapter

任务：

- 用协议替代当前 Node 直接实现：
  - `CmpGitBackend`
  - Postgres query executor
  - Redis publish/ack executor
- 先定义接口，再分别做实现：
  - Swift 本地实现
  - 兼容 Node 过渡实现
- 明确同步/异步边界、错误模型、重试策略

完成标准：

- Core 不再 import / 依赖 shell、SQL 驱动、Redis 客户端
- Host 层可以自由更换实现

### W6. 替换 `rax` 为更清晰的 Host facade

目标：

- 不直接搬运 `rax`，而是消化其价值后重构为更清晰的外观层

任务：

- 识别 `rax` 中值得保留的抽象：
  - capability registry
  - compatibility profile
  - facade API surface
  - skill / mcp / websearch 统一入口思想
- 明确哪些不该进入 Core：
  - provider payload 形状
  - native MCP compose 细节
  - provider-specific managed skill lifecycle
- 在 Swift 侧重建：
  - `PraxisFacade`
  - `ProviderRouter`
  - `McpHost`
  - `SkillHost`

完成标准：

- 新 facade 能覆盖老 `rax` 的主要调用面
- 但 Core 与 facade 严格分层

### W7. 重建 Swift CLI / TUI / SwiftUI 宿主

目标：

- 用 Swift 接管当前临时 CLI harness

任务：

- 以 `live-agent-chat.ts` 的行为为参考，重建：
  - 交互主循环
  - direct / full 两种显示模式
  - 历史、状态、事件、CMP/TAP 视图
- 区分两类宿主：
  - `PraxisCLI` / `PraxisTUI`
  - `PraxisApp` (SwiftUI)
- UI 层只读 Core 暴露的 ViewModel / state snapshot，不直接访问内部对象拼接字符串

完成标准：

- Swift 宿主可以跑通最小单 agent 对话
- 终端 UI 不再依赖 Node readline / ANSI 手工拼装

### W8. 设计可导出的 Core ABI

目标：

- 满足未来 Windows / Linux UI 或其它语言宿主复用 Core 的需求

任务：

- 选定导出策略：
  - C ABI
  - 或极薄的 FFI bridge
- 先导出最小稳定面：
  - goal compile
  - run tick
  - capability plan build
  - TAP governance decision
  - CMP section / delivery planning
- 定义错误码、版本号、数据编解码格式

完成标准：

- 其它宿主可以在不依赖 SwiftUI 的情况下复用 Core

### W9. 渐进切换与 TS 退役

目标：

- 允许一段时间内 TS 与 Swift 并行验证，而不是一次性翻盘

任务：

- 先做双跑对照：
  - TS goal vs Swift goal
  - TS run transition vs Swift run transition
  - TS TAP governance vs Swift TAP governance
  - TS CMP routing vs Swift CMP routing
- 逐步把 live 流量切到 Swift 宿主
- 最后才考虑退役以下层：
  - `live-agent-chat`
  - `agent_core/runtime.ts`
  - `rax` 中已被新 facade 覆盖的部分

完成标准：

- 新旧实现有明确对照结果
- TS 退役按模块进行，不做大爆炸式删除

## 7. 迁移优先级建议

推荐顺序：

1. `types / goal / state / transition / run / session`
2. `capability-* / port / checkpoint / journal`
3. `ta-pool-* / tap-availability`
4. `cmp-types / cmp-runtime 纯规则 / cmp-five-agent 协议`
5. `cmp-git / cmp-db / cmp-mq` 的模型层
6. provider / skill / mcp / tooling adapters
7. Swift CLI / SwiftUI 宿主
8. FFI / library export

不推荐的顺序：

- 先重写 UI
- 先把 `live-agent-chat` 原样翻译成 Swift
- 先碰 provider payload builder
- 先碰完整 live 联调

## 8. 哪些东西不要原样迁移

- `src/agent_core/live-agent-chat/ui.ts` 的 ANSI/终端绘制细节
- `src/agent_core/runtime.ts` 的超大总装结构
- `rax` 的目录结构本身
- `docs/ability/*` 的任务包层级
- `dist/`
- `node_modules/`
- 任何 provider SDK 的当前 JSON payload 细节

应该迁移的是：

- 业务规则
- 状态机
- 角色职责
- capability 语义
- TAP / CMP 的对象模型
- 行为验证样本

## 9. 本工单对应的首批落地建议

如果下一轮就开始动手，建议先做下面四件事：

1. 建立 Swift Package 骨架，但先只放纯 Core 模块，不放 UI。
2. 先迁 `types + goal + state + transition + run + session`。
3. 从 `agent_core/runtime.ts` 中抽一份“最小总编排依赖图”，作为拆分路线图。
4. 把 `live-agent-chat` 仅作为行为参考，不作为代码迁移目标。

## 9.5 当前 phase-1 SwiftPM 模块骨架

包结构不再停留在粗粒度占位，而是已经展开为“能表达职责边界、也能继续细分”的 phase-1 拓扑。

### Foundation

| Target | 角色 | 对照 TS 模块 |
| --- | --- | --- |
| `PraxisCoreTypes` | 共享基础类型与边界描述 | `types`, `cmp-types`, `ta-pool-types` 的公共底层 |
| `PraxisGoal` | goal source / normalize / compile | `goal` |
| `PraxisState` | state projection / validation | `state` |
| `PraxisTransition` | transition table / guards | `transition` |
| `PraxisRun` | run lifecycle / coordinator | `run` |
| `PraxisSession` | session header / hot-cold session | `session` |
| `PraxisJournal` | append-only journal / cursor | `journal` |
| `PraxisCheckpoint` | checkpoint / recovery snapshot | `checkpoint` |

### Capability

| Target | 角色 | 对照 TS 模块 |
| --- | --- | --- |
| `PraxisCapabilityContracts` | capability 协议与 manifest 边界 | `capability-*`, `port` 的协议层 |
| `PraxisCapabilityPlanning` | capability plan / routing / compile | `capability-*` 的 planner 部分 |
| `PraxisCapabilityResults` | normalized result envelope | `capability result` 归一化部分 |
| `PraxisCapabilityCatalog` | capability catalog / discoverability | `capability-package` 等目录的目录语义 |

### TAP

| Target | 角色 | 对照 TS 模块 |
| --- | --- | --- |
| `PraxisTapTypes` | TAP 共用对象模型 | `ta-pool-types` |
| `PraxisTapGovernance` | policy / risk / permission | `ta-pool-governance` 一类职责 |
| `PraxisTapReview` | review / human gate 决策 | `ta-pool-review` 一类职责 |
| `PraxisTapProvision` | provision / supply 语义 | `ta-pool-provision` 一类职责 |
| `PraxisTapRuntime` | TAP runtime 编排规则 | `ta-pool-runtime` 一类职责 |
| `PraxisTapAvailability` | availability / gating | `tap-availability` |

### CMP

| Target | 角色 | 对照 TS 模块 |
| --- | --- | --- |
| `PraxisCmpTypes` | CMP 共用对象模型 | `cmp-types` |
| `PraxisCmpSections` | section ownership / visibility | `cmp-section*` |
| `PraxisCmpProjection` | projection / materialize 规则 | `cmp-projection*` |
| `PraxisCmpDelivery` | package delivery / publish planner | `cmp-delivery*` |
| `PraxisCmpGitModel` | Git 相关 plan / model | `cmp-git*` |
| `PraxisCmpDbModel` | DB 相关 plan / model | `cmp-db*` |
| `PraxisCmpMqModel` | MQ 相关 plan / model | `cmp-mq*` |
| `PraxisCmpFiveAgent` | five-agent role protocol | `cmp-five-agent` |

### HostContracts

| Target | 角色 | 对照 TS 模块 |
| --- | --- | --- |
| `PraxisProviderContracts` | provider inference / embedding / MCP / skill 协议 | `integrations/*` 中应沉淀成 provider protocol 的部分 |
| `PraxisWorkspaceContracts` | workspace read / search / write 协议 | `agent_core` 中与工作区读写检索相关的宿主能力 |
| `PraxisToolingContracts` | shell / browser / git / process 协议 | `integrations/*`, `rax/*` 中工具执行接缝 |
| `PraxisInfraContracts` | checkpoint / journal / projection / bus 协议 | `cmp-service`, persistence, queue 相关宿主接缝 |
| `PraxisUserIOContracts` | user input / permission / terminal / conversation 协议 | CLI/UI 对话与权限交互接缝 |

### HostRuntime

| Target | 角色 | 对照 TS 模块 |
| --- | --- | --- |
| `PraxisRuntimeComposition` | Core 与宿主协议装配根 | `agent_core/runtime.ts`, `rax/runtime.ts` 的装配部分 |
| `PraxisRuntimeUseCases` | 高层应用用例 | runtime 对外用例层 |
| `PraxisRuntimeFacades` | 面向宿主的稳定 facade | `rax/facade.ts` 一类对外表面 |
| `PraxisRuntimePresentationBridge` | CLI / SwiftUI / FFI 展示桥 | `live-agent-chat` 与宿主展示层的边界 |

### Entry

- `PraxisCLI`
- `PraxisAppleUI`
- 未来的 `PraxisFFI`

当前这一步仍然只要求这些入口是“可编译的壳”，不要求马上搬入真实运行逻辑。

## 10. 对照入口清单

后续重构时，优先回读这些入口：

- 根入口：`src/index.ts`
- 总编排器：`src/agent_core/runtime.ts`
- CLI harness：`src/agent_core/live-agent-chat.ts`
- TAP 装配：`src/agent_core/integrations/tap-capability-family-assembly.ts`
- CMP 中枢：`src/agent_core/cmp-runtime/index.ts`
- 五 agent：`src/agent_core/cmp-five-agent/index.ts`
- Git backend：`src/agent_core/cmp-git/git-cli-backend.ts`
- Postgres adapter：`src/agent_core/cmp-db/postgresql-adapter.ts`
- Redis adapter：`src/agent_core/cmp-mq/redis-adapter.ts`
- RAX facade：`src/rax/facade.ts`
- Provider 目录说明：`src/integrations/README.md`

## 11. 一句话总判断

当前项目不是“没模块”，而是“模块太多、总装太厚、宿主与核心混在一起”。  
后续 Swift 重构最正确的方向不是重写一遍 TypeScript，而是把现在这条总装线拆成：

- 可导出的 Swift Core
- 可替换的 Host adapters
- 可演进的 Swift CLI / SwiftUI 宿主
