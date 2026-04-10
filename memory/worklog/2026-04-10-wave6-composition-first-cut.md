# 2026-04-10 Wave6 Composition First Cut

## 做了什么

- 为 `PraxisRuntimeComposition` 落下第一版正式装配入口：
  - `PraxisHostAdapterRegistry`
  - `PraxisRuntimeCompositionRoot`
  - `PraxisBootstrapValidator.validate(boundaries:)`
- 把 HostRuntime 最小装配链从“测试和入口层手工 new 一串对象”推进为“先建 composition root，再组 facade / bridge”。
- 在 `PraxisRuntimePresentationBridge` 新增 `PraxisRuntimeBridgeFactory`，作为当前 Wave6 期间的统一装配入口。

## 这轮明确下来的边界

- `PraxisRuntimeComposition` 只负责 boundary + adapter registry + dependency graph materialization，不直接依赖 use case / facade / presentation bridge。
- `PraxisRuntimeFacades` 可以从 `PraxisDependencyGraph` 组装默认 facade，但不拥有 host adapter registry。
- `PraxisRuntimePresentationBridge` 可以提供最上层的装配 convenience factory，因为它本来就是 Entry 唯一允许依赖的 runtime-facing target。

## 当前收益

- HostRuntime 测试不再手工拼 `DependencyGraph -> UseCases -> Facade -> Bridge`。
- CLI / AppleUI 已能通过统一工厂获取 scaffold bridge，后续替换成真实 adapter 时只需要先进入 composition root。
- Wave6 后续可以优先继续把真实 local-runtime adapter 和 inspect/run use case 接进 composition，而不是继续在测试或入口层散落装配代码。

## 还没做的

- 还没有接入真实 SQLite / git / message bus / provider adapter。
- `PraxisRuntimeUseCases` 目前仍以 placeholder / inspection snapshot 为主。
- bridge 仍主要返回 summary state，而不是完整事件流与交互状态。
