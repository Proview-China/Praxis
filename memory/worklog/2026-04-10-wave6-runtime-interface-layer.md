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
  - `PraxisRuntimeInterfaceSnapshot`
  - `PraxisRuntimeInterfaceEvent`
  - `PraxisRuntimeInterfaceResponse`
- 公开协议：
  - `PraxisRuntimeInterfaceServing`
  - `PraxisRuntimeInterfaceCoding`
- 默认实现：
  - `PraxisRuntimeInterfaceSession`
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
  - replay 命中终态时，统一接口会暴露 `recoveredWithoutResume` 而不是伪造 `run.resumed`
- `Tests/PraxisRunTests/PraxisRunLifecycleTests.swift`
  - `PraxisRunIdentityCodec` 覆盖了新的 colon session、历史 percent-literal session、legacy dotted run 三条兼容路径

## 当前结论

- 这层统一接口已经具备最小可用框架，可以作为后续 lib/FFI 导出的正式起点。
- 现在这个起点已经包含 replay-aware resume contract，后续跨语言绑定不需要再解析英文 summary 去猜恢复语义。
- run/session identity 也已经有了单一 canonical codec，后续接口层和导出层不需要再各自复制解析逻辑。
- 之后如果继续推进，优先补：
  - neutral error envelope
  - encoded smoke tests
  - session registry / handle lifecycle
  - 再最后做真正的 FFI target
