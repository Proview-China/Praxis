# ADR-0002: Swift 重构必须采用 Core / Host / Entry 分层

## 状态

已接受

## 背景

Praxis 当前 TypeScript 主线已经形成了较完整的功能面，但运行时现实问题也很明显：

- `src/agent_core/runtime.ts` 形成了超大总编排器
- `agent_core`、`rax`、`integrations`、CLI harness 边界交叠
- 领域规则与 Git / DB / MQ / provider SDK / CLI 输入输出混在一起

后续希望把 core 和 Apple 端 UI/TUI 转向 Swift，同时还保留未来跨平台复用核心库的可能性。

如果这次 Swift 重构只是把当前目录结构或文件职责原样搬过去，结果只会是再造一个 Swift 版本的“屎山”。

## 决策

我们接受下面这套重构分层为硬约束：

1. `PraxisCore`
   - 只承接纯领域模型、状态机、编排协议和规则
2. `PraxisHostContracts`
   - 只定义 Core 所需的宿主能力协议
   - phase-1 固定拆成 `Provider / Workspace / Tooling / Infra / UserIO` 五个协议族 target
3. `PraxisHostRuntime`
   - 负责装配 Core 与宿主适配器，并暴露高层用例
   - phase-1 固定拆成 `Composition / UseCases / Facades / PresentationBridge` 四个 target
4. 宿主入口层
   - `PraxisCLI`
   - `PraxisAppleUI`
   - 未来 `PraxisFFI`

同时接受以下约束：

- Core 不得依赖 provider SDK、Git CLI、数据库客户端、消息队列客户端、SwiftUI、终端 I/O。
- CLI 和 SwiftUI 只能通过 `PraxisRuntimePresentationBridge` 调用系统能力。
- Git / DB / MQ / provider 相关能力必须拆成“Core planner/model”与“Host executor”两层。
- `runtime.ts`、`rax facade/runtime`、`live-agent-chat` 都不能作为未来 Swift 结构模板原样迁移。

## 原因

- 只有先冻结层次，后续模块迁移才不会继续长成新的总装器。
- 只有 Core 纯化，未来才可能导出稳定 ABI / FFI。
- 只有 Host 接口化，后续 Apple UI、CLI、跨平台宿主才能复用同一核心。
- 只有入口层退位，UI 才不会重新绑死业务逻辑。

## 后果

- 后续所有 Swift 模块设计都必须先回答“它属于 Core、Host 接口、Host 装配，还是 Entry”。
- 一旦某个模块同时包含规则与副作用实现，默认继续拆分，而不是接受混合状态。
- 当前已创建的 SwiftPM target 骨架，只能在这套分层约束下继续细化。
- 后续实现速度可能会比直接硬写慢一些，但可以显著降低再次形成大总装器的风险。
