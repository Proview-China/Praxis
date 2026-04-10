# 2026-04-10 Wave 3 TAP Scope And Isolation

## 这次确认的目标

- 熟悉 Swift 重构总计划里 `Wave 3` 的正式范围。
- 把旧 TypeScript TAP 代码按 “直接属于 wave3” 和 “只是相邻宿主桥接” 两层切开。
- 确认这些旧范围在当前 Swift phase-1 target 里的正式落点。
- 在真正开始重构前，先把容易误搬进 Core 的部分隔离出来。

## 当前 Swift 进度结论

- `SWIFT_REFACTOR_PLAN.md` 已把 `Wave 3` 固定为 TAP 域，不是泛指“第三阶段工作”。
- 当前 Swift phase-1 target 骨架已完成，TAP 对应 6 个 target：
  - `PraxisTapTypes`
  - `PraxisTapGovernance`
  - `PraxisTapReview`
  - `PraxisTapProvision`
  - `PraxisTapRuntime`
  - `PraxisTapAvailability`
- `2026-04-10` 前后的 worklog 已确认：
  - Swift skeleton split complete
  - TAP 相关模型名词层已补齐到源码骨架
  - `RuntimeComposition -> RuntimeUseCases -> RuntimeFacades -> RuntimePresentationBridge` 最小 inspection 链路已接通
- 但当前 Swift 还停留在“类型 + 服务骨架 + 架构守卫”阶段。
- `Tests/PraxisTapArchitectureTests/TapTopologyTests.swift` 目前只守 six-way split，还没有进入真实规则等价验证。

## 旧代码直接范围

以下目录是 wave3 旧实现的直接参考面：

| TS 目录 | 文件数 | 约行数 | 说明 |
| --- | ---: | ---: | --- |
| `src/agent_core/ta-pool-types` | 6 | 1884 | TAP 共用类型、profile、review、provision、TMA 契约 |
| `src/agent_core/ta-pool-model` | 19 | 3076 | 风险分类、mode policy、governance object、user surface |
| `src/agent_core/ta-pool-context` | 4 | 1084 | context aperture、plain-language risk |
| `src/agent_core/ta-pool-safety` | 3 | 410 | safety interception 规则 |
| `src/agent_core/ta-pool-review` | 14 | 3057 | review decision、routing、reviewer runtime shell |
| `src/agent_core/ta-pool-tool-review` | 9 | 3103 | tool review contract、session、runtime、model hook |
| `src/agent_core/ta-pool-provision` | 20 | 3868 | registry、asset index、planner、provision runtime、worker bridge |
| `src/agent_core/ta-pool-runtime` | 27 | 4968 | control plane、activation lifecycle、replay、recovery、human gate |
| `src/agent_core/tap-availability` | 26 | 3956 | availability audit、gating、failure taxonomy、family checks |

一句话：

- wave3 的旧 TAP 主体范围大约是 2.2 万行 TS，不是一个小目录迁移，而是一组已经彼此联动的控制面子系统。

## 旧目录到 Swift target 的正式映射

| 旧 TS 范围 | Swift target | 备注 |
| --- | --- | --- |
| `ta-pool-types` | `PraxisTapTypes` | 共享对象模型直接落这里 |
| `ta-pool-model` | `PraxisTapGovernance` | 风险、mode、governance、user surface 归治理层 |
| `ta-pool-context` | `PraxisTapGovernance` | context aperture / plain-language risk 归治理输入，不单独设 target |
| `ta-pool-safety` | `PraxisTapGovernance` | safety interception 是治理规则，不应被理解成宿主执行器 |
| `ta-pool-review` | `PraxisTapReview` | reviewer decision / routing / review trail 归这里 |
| `ta-pool-tool-review` | `PraxisTapReview` | tool-review 不再单独建 target，而是 review 子域的一部分 |
| `ta-pool-provision` | `PraxisTapProvision` | 仅承接 registry / asset index / planner / provision 计划模型 |
| `ta-pool-runtime` | `PraxisTapRuntime` | control plane、human gate、replay、recovery 等运行期语义 |
| `tap-availability` | `PraxisTapAvailability` | family audit、gate、failure taxonomy 独立成域 |

## 不应直接并入 wave3 Core 的相邻范围

以下代码虽然和 TAP 强相关，但不应在 wave3 里被当成 Swift Core 直接迁移目标：

| 范围 | 原因 | 未来落点倾向 |
| --- | --- | --- |
| `src/agent_core/integrations/tap-tooling/**` | 直接依赖 `node:child_process`、文件读写、Playwright、`rax` 类型 | `PraxisToolingContracts` + Host adapters |
| `src/agent_core/integrations/tap-tooling-adapter.ts` | 属于 tooling 注册和宿主接入，不是 Core 规则 | HostContracts / HostRuntime |
| `src/agent_core/integrations/tap-agent-model.ts` | 直接连接模型执行器 | `PraxisProviderContracts` + HostRuntime |
| `src/agent_core/runtime.ts` 中 TAP 装配段 | 这是总装线，不允许原样搬进 Swift | `PraxisRuntimeComposition` / `PraxisRuntimeUseCases` |
| `src/agent_core/live-agent-chat/**` | 是 CLI harness / 展示层行为参考，不是 TAP Core | `PraxisRuntimePresentationBridge` / `PraxisCLI` |
| `src/agent_core/cmp-five-agent/**`、`src/agent_core/mp-five-agent/**` 中 TAP bridge/profile | 这是 CMP/MP 通过 TAP 的接缝，不是 TAP 自身核心定义 | `PraxisCmpFiveAgent` 或 HostRuntime bridge |

## 当前最需要防守的混合点

以下位置最容易把 Core 和宿主副作用又揉回一起：

1. `ta-pool-review/reviewer-worker-bridge.ts`
   这里已经不是单纯 review rule，而是 worker prompt pack、输入输出 schema、runtime contract。
   迁 Swift 时，纯 decision / route 可以进 `PraxisTapReview`，worker envelope 和模型交互要留给 Host。

2. `ta-pool-provision/provisioner-worker-bridge.ts`
   这里混合了 lane semantics、allowed side effects、artifact envelope、activation payload。
   其中 registry / asset index / plan 可以进 `PraxisTapProvision`，但 worker bridge 和 side-effect boundary 不应直接进 Core。

3. `ta-pool-provision/provisioner-model-worker.ts`
   直接依赖 `integrations/tap-agent-model.ts`。
   这说明“模型辅助 provisioner”不是 wave3 Core 本体，而是后续 Provider contract + runtime assembly 问题。

4. `tap-availability/availability-audit.ts`
   虽然大部分是 availability 规则，但它现在还读取 `tap-capability-family-assembly` audit 结果和 pool health。
   Swift 迁移时要保留 availability 规则层，同时把 live evidence 采集改成 Host 提供的 observation 输入。

5. `integrations/tap-tooling/shared.ts`
   同时连着 `node:*`、`rax`、`ta-pool-runtime`。
   这是典型宿主桥，不应被误当成 TAP runtime 核心的一部分。

## wave3 重构前的隔离准则

真正开始写 Swift 实现时，先按下面口径隔离：

1. 先迁名词和纯规则
   先处理 type、risk、mode policy、review decision、route、planner、replay、gate、taxonomy。

2. 所有 worker bridge / model hook / tooling adapter 先判为宿主侧
   只要出现 prompt pack、executor、tool artifact、child process、Playwright、provider route，就先不要放进 TAP Core。

3. `PraxisTapProvision` 只收“该供应什么”
   不收真实执行器，不收模型 worker，不收安装或文件写入动作本身。

4. `PraxisTapRuntime` 只收运行期语义
   可以承接 control plane state、human gate、replay、recovery。
   不应该知道具体 adapter 工厂、进程执行、provider SDK 或文件系统副作用。

5. `PraxisTapAvailability` 保留规则，证据由外部注入
   family audit / gating / failure taxonomy 可以留在 Core。
   live registration、binding audit、health probe 应通过 Host contracts 输入。

6. `CMP -> TAP bridge` 延后处理
   先把 TAP 自己的领域规则收干净，再接 `PraxisCmpFiveAgent` 的 role protocol 和 tap bridge。

## 本轮补充修正

- Swift 边界说明已统一为：
  - `PraxisTapGovernance` 负责 `ta-pool-model + ta-pool-context + ta-pool-safety`
  - `PraxisTapRuntime` 只对齐 `ta-pool-runtime`
- 这样可以避免后续把 `safety interception` 一半理解成治理规则、一半理解成 runtime 执行壳。

## 建议的 wave3 开工顺序

1. `PraxisTapTypes`
2. `PraxisTapGovernance`
3. `PraxisTapReview`
4. `PraxisTapProvision`
5. `PraxisTapRuntime`
6. `PraxisTapAvailability`

原因：

- 这是从共享类型 -> 治理规则 -> 审查 -> 供应计划 -> 运行期协调 -> availability gate 的单向依赖顺序。
- 这样能最大限度避免从 `runtime.ts` 或 `integrations/` 倒推设计。
