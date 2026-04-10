# Swift Object Design Rules

## 长期有效结论

- 这次 Swift 重构虽然继续下钻到“类级”设计，但不接受“万物 class”。
- 纯领域真相优先 `struct`，共享流程与外部依赖优先 `final class`，并发可变状态优先 `actor`。
- 继承只建议用于 Apple 平台桥接和极少数模板方法式宿主适配器。
- 业务层默认使用 `protocol + composition`，不使用抽象基类树。

## 依赖注入规则

- 统一使用 initializer injection。
- 只有 `PraxisRuntimeComposition` 可以知道具体 adapter 实现类。
- 不允许在 use case、facade、bridge、view model 中直接 new provider/git/db/mq adapter。

## HostRuntime 规则

- `PraxisRuntimeUseCases` 默认用 `final class` 承载多依赖编排，但不重新实现领域规则。
- `PraxisRuntimePresentationBridge` 只做宿主桥接，不持有 CLI/SwiftUI 特定业务。
- `PraxisRuntimeComposition` 是唯一 composition root，不得退化为 service locator 散落全仓。

## Entry 规则

- CLI / SwiftUI 页面数据优先 `struct`。
- 只有观察对象、会话控制器、宿主协调器才进入 `@MainActor final class` 或 `actor`。

## 测试规则

- 所有宿主协议都要准备 fake/stub/spy。
- 共享测试双对象只有在跨多个 test target 复用时才抽离。
