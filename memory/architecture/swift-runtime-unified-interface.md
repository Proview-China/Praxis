# Swift Runtime Unified Interface

## 目标

这层的目标是提供一个宿主无关、导出友好的统一 runtime interface。

白话一点：

- 它不是 CLI 接口
- 也不是 SwiftUI 接口
- 更不是某种 ABI/FFI 绑定实现

它只是把 HostRuntime 当前已经稳定下来的运行能力，收口成一组未来可被任何宿主或任何语言绑定复用的统一 request/response/event 面。

## 为什么需要单独一层

当前已经有：

- `PraxisRuntimeFacades`
- `PraxisRuntimePresentationBridge`

但它们各自的角色不同：

- `Facades` 负责宿主可理解的稳定应用表面
- `PresentationBridge` 负责把 facade/use case 映射为 CLI / UI / FFI 可消费的展示状态

问题在于：

- facade 仍然偏 Swift 内部对象面
- presentation bridge 仍然带有展示语义，比如 title、summary、view state、presentation events

如果未来直接从这两层之一去做 lib 导出，很容易出现两个问题：

1. 导出层被展示语义绑住
2. CLI / SwiftUI / FFI / 其它语言绑定没有一套真正共享的 neutral surface

所以需要补一层：

- `PraxisRuntimeInterface`

它的位置是：

- 建立在 `PraxisRuntimeFacades` 之上
- 保持比 `PraxisRuntimePresentationBridge` 更中性
- 给未来导出层和跨语言绑定提供统一 contract

## 这层负责什么

`PraxisRuntimeInterface` 负责：

- 统一 command/request 模型
- 统一 snapshot/response 模型
- 统一 runtime event 模型
- 统一编码接口，例如 JSON codec
- 统一事件缓冲与 drain/snapshot 语义

它不负责：

- CLI 命令解析
- SwiftUI view state 设计
- 终端渲染
- FFI ABI 细节
- C header / symbol export
- Host adapter composition

## 当前最小 contract

当前最小 contract 固定为四组对象：

### 1. Request

- `PraxisRuntimeInterfaceRequest`
- `PraxisRuntimeInterfaceRunGoalRequestPayload`
- `PraxisRuntimeInterfaceResumeRunRequestPayload`

职责：

- 表达一个宿主无关的 runtime 请求
- 避免暴露 CLI / UI 专有命名
- 对不同 command 固定 typed payload，而不是把所有字段揉进一个大而松散的 optional request bag

当前覆盖的 command：

- `inspectArchitecture`
- `runGoal`
- `resumeRun`
- `inspectTap`
- `inspectCmp`
- `inspectMp`
- `buildCapabilityCatalog`

当前 request contract 采用：

- 顶层 `kind`
- 按 command 分开的 payload key

编码默认输出 nested payload 形状，但当前 decoder 必须继续兼容历史 flat request 形状。

例如 `resumeRun` 的 JSON shape 固定为：

```json
{
  "kind": "resumeRun",
  "resumeRun": {
    "payloadSummary": "Resume this run",
    "runID": "run:session.codec:goal.codec"
  }
}
```

这样做的目的：

- 让跨语言调用方可以先按 `kind` 分发，再解析对应 payload
- 避免 `goalID` / `runID` / `sessionID` 之类字段在不同 command 间变成“有时必填、有时无意义”的 optional 组合
- 给未来 FFI / 其它语言 lib 保留稳定、可枚举的 payload schema

同时还需要保留一条兼容约束：

- 新 caller 应该发送 nested payload
- 但 decoder 仍要接受历史 top-level `payloadSummary / goalID / goalTitle / sessionID / runID` 形式
- 这是 wire-format backward compatibility，不只是内部重构细节

对 `runGoal` / `resumeRun` 这组 run-oriented command，还要额外满足一个稳定约束：

- 接口层接受的是 raw `sessionID`
- runtime 内部如果要把它折叠进 run ID，必须使用可逆编码
- 可逆编码必须带显式标记，避免把历史 `run:` ID 中本来就是字面量 `%3A` / `%25` 的 session 误当成新编码格式
- 调用方不需要也不应该自己预处理 `sessionID`

当前这条 identity contract 的 canonical 实现在：

- `PraxisRunIdentityCodec`

也就是说：

- HostRuntime 不应该再在 use case、bridge、interface session 里各自维护一套 run/session 解析 helper
- 未来 FFI / 其它语言绑定如果需要做同构实现，应当以这套 codec 语义为准

### 2. Snapshot / Response

- `PraxisRuntimeInterfaceSnapshot`
- `PraxisRuntimeInterfaceResponse`
- `PraxisRuntimeInterfaceErrorEnvelope`

职责：

- 把一次调用后的当前状态压成稳定、可导出的 plain data
- 在需要时附带 run/session/checkpoint/pending intent 等 runtime 关键信息
- 对 run 类响应显式暴露 lifecycle disposition，避免调用方从 summary 文本猜测本次到底是 started、resumed，还是只根据 replay 恢复了真相
- 对失败路径提供稳定的 `status + error` envelope，而不是把 Swift `Error` 原样泄漏给导出层

### 3. Event

- `PraxisRuntimeInterfaceEvent`

职责：

- 表达跨宿主共享的运行事件
- 避免事件语义被某个 UI 的内部模型绑住
- lifecycle event 必须由结构化 disposition 驱动，而不是依赖 summary 文本前缀推断

### 4. Coding

- `PraxisRuntimeInterfaceCoding`
- `PraxisJSONRuntimeInterfaceCodec`

职责：

- 固定最小可导出编码面
- 为未来其它语言绑定先准备稳定的 JSON contract

### 5. Session Lifecycle

- `PraxisRuntimeInterfaceSessionHandle`
- `PraxisRuntimeInterfaceRegistry`

职责：

- 给统一接口提供宿主无关的 opaque handle 层
- 按 handle 路由 request / snapshot / event drain
- 隔离每个 interface session 自己的事件缓冲
- 把 session open / close 语义固定在 runtime interface 内侧，而不是让未来 FFI 自己发明一套句柄表规则

当前 registry contract 的最小语义是：

- `openSession()` 分配新的 opaque handle
- `closeSession(handle)` 释放一个 interface session
- `activeHandles()` 返回当前存活句柄
- `handle(request, on: handle)` 把请求路由到对应 session
- `snapshotEvents(for:)` / `drainEvents(for:)` 只观察该 handle 自己的事件缓冲

这里有一个边界需要明确：

- handle 隔离的是 interface session lifecycle 和 event buffer
- 不等于底层一定是独立 runtime persistence sandbox
- 多个 handle 仍然可以复用同一组 host-backed adapters 与持久化底座

这正是当前想要的行为：

- 导出层可以拿到稳定句柄
- 底层 runtime 真相仍由 HostRuntime / checkpoint / journal 统一维护
- 不会因为 future FFI 句柄表而倒逼我们复制一份假的运行态存储

## Result and error envelope contract

`PraxisRuntimeInterfaceSession.handle(...)` 对外返回的总是 `PraxisRuntimeInterfaceResponse`。

也就是说：

- 成功时：
  - `status = success`
  - `snapshot != nil`
  - `error == nil`
- 失败时：
  - `status = failure`
  - `snapshot == nil`
  - `error != nil`

当前 error envelope 最小固定字段为：

- `code`
- `message`
- `retryable`
- `missingField`
- `runID`
- `sessionID`

当前已稳定的错误码包括：

- `session_not_found`
- `missing_required_field`
- `checkpoint_not_found`
- `invalid_input`
- `dependency_missing`
- `unsupported_operation`
- `invalid_transition`
- `invariant_violation`
- `unknown_error`

这样做的目的不是把所有内部错误 taxonomy 一次性做完，而是先确保：

- 统一接口调用方不需要理解 Swift `throw`
- JSON codec 可以稳定 roundtrip 成功态和失败态
- FFI / 其它语言绑定后续只需要对接结构化 envelope，而不是做异常桥接

## Resume reconciliation contract

`resumeRun` 在统一接口层的稳定语义不是“总会发出一个新的 `run.resumed`”，而是：

1. 先把 checkpoint 当成恢复基线
2. 再吸收 checkpoint 之后已经持久化的 journal events
3. 然后依据 replay 后的 run 真相决定是否继续发新的 resume 事件

这意味着：

- 如果 replay 后 run 仍然是非终态，接口会返回：
  - `lifecycleDisposition = resumed`
  - lifecycle event 名称为 `run.resumed`
- 如果 replay 已经证明 run 进入终态，例如 `.completed` 或 `.cancelled`，接口会返回：
  - `lifecycleDisposition = recoveredWithoutResume`
  - lifecycle event 名称为 `run.recovered`
  - `pendingIntentID = nil`

调用方必须假设：

- `resumeRun` 可能只是“对齐持久化真相”，而不是“重新推进生命周期”
- 不能把 `resumeRun` 和“必然拿到新的 follow-up intent”画等号
- 不能依赖 `summary` 文本前缀来判断恢复语义，必须读结构化字段
- 不能假设 run ID 会把 raw `sessionID` 原样内嵌；run ID 可以为了可逆性对内部组件做转义，但接口返回的 `sessionID` 必须始终是 raw value

## 生命周期和依赖边界

`PraxisRuntimeInterface` 必须遵守下面的依赖边界：

- 可以依赖：
  - `PraxisGoal`
  - `PraxisRun`
  - `PraxisSession`
  - `PraxisRuntimeFacades`
- 不可以依赖：
  - `PraxisRuntimeComposition`
  - `PraxisCLI`
  - `PraxisAppleUI`
  - 未来任何 FFI ABI target

原因：

- 它是统一接口层，不是装配层
- 也不是具体宿主层

## 与 PresentationBridge 的关系

关系应该是：

- `PraxisRuntimeInterface` 提供 neutral runtime surface
- `PraxisRuntimePresentationBridge` 提供 host-facing presentation surface

以后理想状态下：

- CLI 可以继续吃 presentation bridge
- Apple UI 可以继续吃 presentation bridge
- FFI / 其它语言绑定优先建立在 runtime interface 上

当前已经落下的一步是：

- `PraxisFFIBridge` 已经开始在 `PraxisRuntimePresentationBridge` 内部包装 runtime interface registry
- 它现在能提供 open / close session、encoded request -> encoded response、以及按 handle drain encoded events 的最小桥面
- 但这仍然只是 Swift 内部桥层包装，还不是最终的 C ABI / symbol export

也就是说：

- `PresentationBridge` 负责“怎么展示”
- `RuntimeInterface` 负责“系统对外稳定地说什么”

## 当前实现策略

当前只落最小框架，不提前做完整导出层：

- 已创建 `PraxisRuntimeInterface` target
- 已落下：
  - typed request / response / event 模型
  - run lifecycle disposition
  - structured result/error envelope
  - session registry / opaque handle lifecycle
  - canonical run/session identity contract documented against `PraxisRunIdentityCodec`
  - serving protocol
  - JSON codec
  - `PraxisRuntimeInterfaceSession`
  - `PraxisRuntimeInterfaceRegistry`

当前还没做：

- C ABI
- 跨线程生命周期约束
- 流式 token / partial update 协议

## 后续演进建议

下一步如果继续推进这层，建议顺序如下：

1. 先冻结 run/session/checkpoint/event 的 neutral contract
2. 再补更多 replay / terminal reconciliation / failure mapping smoke tests
3. 再把当前 `PraxisFFIBridge` 升格成真正的 FFI target / C ABI surface
4. 最后才补跨线程与流式协议细节

不建议的顺序：

- 先写 C header
- 先做 SwiftUI/CLI 反向适配
- 先把所有 provider/tooling 事件塞进统一接口

## 当前结论

`PraxisRuntimeInterface` 是一层“导出准备层”，不是新的大 runtime。

它的价值是：

- 为未来其它语言导出 lib 提前冻结稳定接口
- 不让 CLI / AppleUI / FFI 各自长出不同协议
- 让导出层建立在 neutral runtime contract 上，而不是直接绑定展示层或宿主层
