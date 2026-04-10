# 2026-04-10 Wave6 Runtime Interface Layer

## 做了什么

- 规划并落下了一层新的 HostRuntime target：
  - `PraxisRuntimeInterface`
- 这层不是 CLI，也不是 SwiftUI，也不是 FFI ABI。
- 它负责提供宿主无关的统一 runtime interface，为未来其它语言导出 lib 提前冻结最小 contract。

## 为什么现在就加

- 当前已经有：
  - `PraxisRuntimeFacades`
  - `PraxisRuntimePresentationBridge`
- 但如果未来直接从这两层之一去做 lib 导出，会遇到两个问题：
  - facade 偏 Swift 内部对象面
  - presentation bridge 带展示语义，不够 neutral

所以新增的 `PraxisRuntimeInterface` 作为中间层：

- 建立在 facade 之上
- 比 presentation bridge 更中性
- 给未来 FFI / 跨语言绑定提供统一 request/response/event/coding surface

## 当前落下的框架

- target：`PraxisRuntimeInterface`
- 公开模型：
  - `PraxisRuntimeInterfaceRequest`
  - `PraxisRuntimeInterfaceRunGoalRequestPayload`
  - `PraxisRuntimeInterfaceResumeRunRequestPayload`
  - `PraxisRuntimeInterfaceSessionHandle`
  - `PraxisRuntimeInterfaceSnapshot`
  - `PraxisRuntimeInterfaceEvent`
  - `PraxisRuntimeInterfaceResponse`
- 公开协议：
  - `PraxisRuntimeInterfaceServing`
  - `PraxisRuntimeInterfaceCoding`
- 默认实现：
  - `PraxisRuntimeInterfaceSession`
  - `PraxisRuntimeInterfaceRegistry`
  - `PraxisJSONRuntimeInterfaceCodec`

## 本轮补充提炼

- 把 run 类响应里的生命周期来源提炼成显式结构化字段：
  - `PraxisRunLifecycleDisposition`
  - 当前枚举值：
    - `started`
    - `resumed`
    - `recoveredWithoutResume`
- 统一接口和 presentation bridge 不再依赖 summary 文本前缀来猜测 lifecycle event。
- `resumeRun` 的统一 contract 现在明确为：
  - 先 replay checkpoint 之后的 journal 真相
  - 再决定是否真的发出新的 `run.resumed`
  - 如果 replay 已经证明 run 终态成立，则返回 `recoveredWithoutResume`，并发出 `run.recovered`
- 把 run/session identity 规则从 HostRuntime use case 私有 helper 抽成了：
  - `PraxisRunIdentityCodec`
- 现在新的 run ID 编码、历史 `%3A` 字面量兼容、legacy dotted run 解析，都由同一份 codec 负责
- 把统一接口的返回值进一步收口成结构化 envelope：
  - `PraxisRuntimeInterfaceResponse.status`
  - `PraxisRuntimeInterfaceErrorEnvelope`
- `handle(...)` 现在对导出层返回 success/failure envelope，而不是把 Swift `Error` 直接抛出去
- 把 request 模型从 `kind + 多个 optional 字段` 提炼成 typed payload：
  - `runGoal(payload)`
  - `resumeRun(payload)`
- JSON codec 现在固定采用：
  - 顶层 `kind`
  - 按 command 分开的 payload key
- 这样后续其它语言绑定可以先做 command dispatch，再解析对应 payload，而不需要复刻一份“哪些 optional 字段在什么 kind 下才有效”的隐式规则
- 同时保留了 legacy flat request decoding：
  - decoder 仍接受历史 top-level `payloadSummary / goalID / goalTitle / sessionID / runID`
  - encoder 继续只输出新的 nested payload 形状
  - 这样不会把历史 FFI / 跨语言 caller 直接打成 `invalid_input`
- 当前已经补上的最小错误码包括：
  - `session_not_found`
  - `missing_required_field`
  - `checkpoint_not_found`
  - `invalid_input`
  - `dependency_missing`
  - `unsupported_operation`
  - `invalid_transition`
  - `invariant_violation`
  - `unknown_error`

## 这层当前不负责什么

- 不负责 host adapter composition
- 不负责 CLI 命令解析
- 不负责 SwiftUI view state
- 不负责 C ABI / header / symbol export
- 不负责 provider/tooling live execution 细节

## 与现有桥层的关系

- `PraxisRuntimePresentationBridge` 现在继续作为 Entry 的正式入口。
- `PraxisRuntimeInterface` 则作为更中性的统一导出面存在。
- 为了让当前代码可立即使用，在 `PraxisRuntimeBridgeFactory` 中已经补了：
  - `makeRuntimeInterface()`
  - `makeRuntimeInterfaceRegistry()`
  - `makeFFIBridge()`
- `PraxisFFIBridge` 当前已经开始承接最小导出包装：
  - open / close runtime session handle
  - encoded request -> encoded response
  - encoded event snapshot / drain
- 但这仍然是 Swift 内部桥层，不是最终的 C ABI / symbol export。

## 文档与边界同步

- 已更新：
  - `SWIFT_REFACTOR_PLAN.md`
  - `memory/architecture/swift-dependency-matrix.md`
  - `memory/architecture/swift-host-interface-catalog.md`
- 已新增：
  - `memory/architecture/swift-runtime-unified-interface.md`

## 新增验证

- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeTopologyTests.swift`
  - HostRuntime 现在按五层校验
- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeInterfaceTests.swift`
  - 统一接口可生成 neutral run response 与 buffered events
  - JSON codec request/response roundtrip 正常
  - request JSON shape 现在有显式测试，避免 typed payload 退化回 optional bag
  - replay 命中终态时，统一接口会暴露 `recoveredWithoutResume` 而不是伪造 `run.resumed`
  - 缺少 `runID` 时会返回结构化 `missing_required_field`
  - checkpoint 不存在时会返回结构化 `checkpoint_not_found`
  - `invalid_input` / `dependency_missing` / `unsupported_operation` / `invariant_violation` / `invalid_transition` / `unknown_error` 现在都有独立 smoke coverage
  - unknown error 路径会显式标记 `retryable = true`
  - registry 现在可以分配 opaque handle、按 handle 路由请求，并隔离不同 interface session 的事件缓冲
  - 关闭 handle 后再次路由请求，会返回结构化 `session_not_found`
  - legacy flat request JSON 现在有显式回归测试，防止 decoder 只认 nested payload
- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeSurfaceTests.swift`
  - `PraxisFFIBridge` 现在可以用 encoded runtime request 驱动统一接口
  - invalid payload 和 closed handle 都会返回结构化失败，而不是把异常直接漏到桥外
  - 历史 flat runtime request 经过 `PraxisFFIBridge.handleEncodedRequest(...)` 也可继续跑通
- `Tests/PraxisRunTests/PraxisRunLifecycleTests.swift`
  - `PraxisRunIdentityCodec` 覆盖了新的 colon session、历史 percent-literal session、legacy dotted run 三条兼容路径

## 当前结论

- 这层统一接口已经具备最小可用框架，可以作为后续 lib/FFI 导出的正式起点。
- 现在这个起点已经包含 replay-aware resume contract，后续跨语言绑定不需要再解析英文 summary 去猜恢复语义。
- run/session identity 也已经有了单一 canonical codec，后续接口层和导出层不需要再各自复制解析逻辑。
- 统一接口失败路径也已经具备稳定 envelope，后续其它语言绑定不需要再做 Swift 异常桥接。
- 统一接口请求面也已经切成 typed payload，后续导出层可以直接把它映射成 enum/discriminated union，而不是一组松散参数。
- 统一接口现在也已经具备最小 session registry / opaque handle lifecycle，后续 FFI 不需要从零自造一套 session handle 约定。
- `PraxisFFIBridge` 现在也已经把这套 registry 包成最小的 encoded bridge surface，后续真正做 FFI target 时不用再回头改运行协议。
- 对当前阶段来说，这组实现已经覆盖到“接口可用性”需要的边界。
- 现在没有必要把完整 `PraxisFFI`、C ABI、内存/字符串生命周期、流式事件协议一次性做出来。
- 如果现在过早做满，反而会把未来跨语言绑定的真实行为约束提前写死，降低后续演进空间。
- 之后如果继续推进，优先补：
  - 把当前 `PraxisFFIBridge` 升格成真正的 FFI target / C ABI surface
  - 再补跨线程与流式协议细节
