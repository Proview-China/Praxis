# Praxis 审计整改执行目标

> 状态：执行补充文档
>
> 作用：把当前审计报告里的判断，细化成可以排期、可以验收、可以对外交付的整改目标。
>
> 关系：当前仓库缺失 `TAKEOVER_EXECUTION_WORKFLOW.md`，因此在新的总执行手册补回前，本文件临时承担接下来整改与实现排期的计划入口。涉及 Swift 重构范围、target 职责、执行顺序和阶段边界时，需要同时对照 `README.md`、`Package.swift`、`docs/PraxisSupportMatrix.md` 与现有代码事实，不要把这里当成脱离实现现状的独立叙事文档。

## 1. 定位结论

当前 Praxis 更适合被定义为：

**一个面向 Swift / Apple 生态、可嵌入、可治理、可恢复、可审计的本地 agent runtime foundation。**

这意味着：

- 现在的主卖点不是“全平台、万能、开箱即用的通用 agent framework”。
- 现在最值得强化的是 embedding、approval、evidence、recovery、upgrade 这些工程化边界。
- macOS 本地 baseline 是当前主线；Linux 仍应诚实保持 placeholder / degraded 叙事，不提前包装成成熟交付面。
- `PraxisRuntimeKit` 继续作为默认公开入口；CLI、TUI、GUI 不是长期主产品面。

## 2. 整改总原则

这份整改按下面四条总原则执行：

1. **先让仓库说真话，再继续堆能力。**
   - README、issues、工作流、目录结构、support matrix 必须表达同一组现实。
2. **先把外部信任面补齐，再追求能力面扩张。**
   - 没有版本、CI、升级说明、examples 的 runtime，很难形成商业信任。
3. **先补低副作用价值闭环，再补高副作用执行面。**
   - 先做 thin capability、search、review、durable runtime；后做 shell、code、MCP、`computer.use`。
4. **每个目标都必须有对外工件，不接受“只有代码合了”。**
   - 至少同步留下测试、smoke、文档、support matrix、baseline 或 release 证据。

## 3. 审计整改的优先级顺序

| 优先级 | 目标 | 对应主阶段 | 结果定义 |
| --- | --- | --- | --- |
| P0 | 仓库事实层对齐 | Phase 0 | 仓库入口、issue 语言、目录现实、路线文档一致 |
| P1 | 版本与 CI 信任面 | Phase 1 / Phase 6 前置 | 至少能发布 preview，且有公开 build/test 纪律 |
| P2 | 新手上手路径 | Phase 1 | 外部开发者 5-10 分钟能跑通第一条 RuntimeKit 路径 |
| P3 | thin capability 与 search 切片闭环 | Phase 3 | 每条能力都有 registry、smoke、matrix、example |
| P4 | reviewer 上下文与真实工具收口 | Phase 3 | reviewer 不再停留在 placeholder 语义 |
| P5 | durable runtime 主链闭环 | Phase 4 | checkpoint、replay、provisioning、recovery 全接到主状态链 |
| P6 | 高风险执行能力守卫化 | Phase 5 | `shell.*`、`code.*`、MCP、Skill 在治理链内受控运行 |
| P7 | 商业化准备与外部叙事 | Phase 6 | 外部能评估兼容性、升级成本、平台边界和安全责任 |

## 4. 分目标执行说明

## Goal P0：仓库事实层对齐

### 目标

先修掉所有会伤信任的“仓库自己说了几种不同真话”的问题。

### 为什么先做

- 事实漂移会直接削弱后续所有 release、README、demo、issue 管理的可信度。
- 这类问题虽然不一定会导致编译失败，但会让外部接入者怀疑维护状态。

### 必做动作

1. 修正所有根入口里的过时路径、绝对路径和旧架构引用。
2. 回扫 open issues，把仍引用旧 `src/**`、`runtime.ts`、`docs/ability/**`、Node/TS 布局的条目改成当前 Swift 仓库语言。
3. 明确当前总执行入口，并让 README 与其他说明文档保持一致。
4. 输出一份 baseline 事实记录，覆盖：
   - 当前 package/product 结构
   - 默认公开入口
   - 当前平台边界
   - 当前 placeholder / degraded 能力
5. 建立并应用 milestone / label 体系，至少覆盖 docs、runtimekit、tap、ffi、高副作用能力、e2e。

### 必须交付的工件

- 仓库入口修正提交
- 一份 baseline 报告
- 一组对齐后的 milestone / label
- 一轮更新后的 open issues 文本

### 完成标准

- 新进入仓库的人，不需要猜“哪个文档才是现在有效的”。
- 根目录、README、workflow、issues 对当前 Swift 主线的描述一致。
- 不再出现本机绝对路径或旧 TS 主线被误写成当前实现的情况。

### 明确不要做

- 不要在这个阶段顺手扩功能。
- 不要新建第二套 roadmap 文档家族。
- 不要为了修 issue 文案而回流旧 TS 目录结构。

## Goal P1：版本与 CI 信任面

### 目标

让 Praxis 至少具备一个“外部可以开始评估接入”的最小版本化信号。

### 为什么现在做

- 没有 tag / preview release、没有 build/test CI 的 runtime，商业说服力会明显打折。
- 版本和 CI 不是装饰，它们决定外部是否敢试用、是否敢升级。

### 必做动作

1. 定义第一个预发布目标，建议 `v0.1.0-alpha` 或 `v0.1.0-preview`。
2. 把 `CHANGELOG.md`、migration notes、release policy 串成一条真实可执行的发布链。
3. 新增公开可见的 build/test CI workflow，至少覆盖：
   - `swift test`
   - 关键 examples
   - `PraxisRuntimeKitSmoke` 的基础 suite
4. 为 CI 结果定义最小失败处理纪律：
   - 哪些检查必须 blocking
   - 哪些 smoke 可以临时允许手动说明后跳过
5. 在 README 或 release 说明中明确当前支持范围与限制，不把 placeholder 包装成 stable。

### 必须交付的工件

- 第一个 preview 版本
- 可追溯的 release note
- 一条公开 CI 流水线
- 与版本对应的 changelog / migration 更新

### 完成标准

- 外部用户能看到“这个仓库如何验证自己是可用的”。
- 任一预发布版本都能对应到明确的文档、例子和验证结果。
- 版本语义与当前 exported surface 的兼容说明能互相印证。

### 明确不要做

- 不要等所有能力补完才第一次发版。
- 不要只做 deploy，不做 build/test 质量门。

## Goal P2：新手上手路径

### 目标

把文档从“内部工程说明”推进到“外部开发者能启动接入”的状态。

### 为什么现在做

- 当前文档诚实，但术语密度高；对新用户来说，缺少低认知负担的入口。
- 如果推荐入口已经是 `PraxisRuntimeKit`，那 onboarding 必须围绕它展开，而不是围绕内部模块展开。

### 必做动作

1. 提供一页 5 分钟 Quick Start。
2. 单独写清楚三类入口怎么选：
   - `PraxisRuntimeKit`
   - `PraxisFFI`
   - `PraxisHostRuntime`
3. 写一页平台状态说明，显式区分：
   - macOS ready baseline
   - Linux placeholder / degraded paths
4. 建立术语表，至少覆盖：
   - TAP
   - CMP
   - MP
   - TMA
   - FFI
   - support matrix
   - placeholder / degraded / stable
5. 在 README 开头附近直接声明四级成熟度语义，避免用户读完整份 support matrix 才知道真实成熟度。

### 必须交付的工件

- Quick Start 文档
- “入口选择”文档
- 平台状态说明
- 术语表

### 完成标准

- 一个第一次接触 Praxis 的 Swift 开发者，在 5-10 分钟内能跑通第一条调用。
- 新手不需要先理解所有内部 target 才知道该从哪开始。
- 支持范围和占位范围在文档前部就能被看见。

### 明确不要做

- 不要让 README 继续承担全部 onboarding 负担。
- 不要把内部 facade / FFI 细节写成第一推荐入口。

## Goal P3：thin capability 与 search 切片闭环

### 目标

先把低副作用、可解释、可演示的能力面做成“可接入 SDK 等级”的完整切片。

### 为什么先于高风险执行面

- 这是最容易形成安全、可嵌入、可治理叙事的能力层。
- 这部分做完整后，外部用户即使还不用 shell/code，也能感知到 RuntimeKit 的价值。

### 建议顺序

1. thin capability baseline
   - `generate.create`
   - `generate.stream`
   - `embed.create`
   - `tool.call`
   - `file.upload`
   - `batch.submit`
   - `session.open`
2. search chain
   - `search.web`
   - `search.fetch`
   - `search.ground`

### 每条能力必须同时完成的四件事

1. registry / surface 已接通
2. support matrix 已更新
3. 至少一条 smoke 路径可跑
4. 至少一个 example 或 README 用法已补

### 必须交付的工件

- thin capability baseline 对外样例
- search chain 样例与 smoke
- 更新后的 capability support matrix

### 完成标准

- 任意一条标记为可用的能力，都能从文档找到入口、从 smoke 找到验证、从 matrix 找到边界。
- “能调用”与“能稳定交付”的差别被文档和验证明确区分。

### 明确不要做

- 不要只补 registry，不补 smoke 和 example。
- 不要跳过 search 链直接冲高副作用能力。

## Goal P4：reviewer 上下文与真实工具收口

### 目标

把 reviewer / review workbench 从“有接口”推进到“能在真实项目态下提供可信上下文”。

### 为什么重要

- 这是治理、审批、证据链叙事能不能成立的关键一环。
- 如果 README 与 backlog 对 reviewer 成熟度的表达不一致，会伤害可信度。

### 必做动作

1. 统一 reviewer 上下文的事实表述，修掉 README、issue、实现状态之间的漂移。
2. 为 reviewer 接入第一批真实工作能力，至少覆盖：
   - code read
   - docs read
   - project summary
   - memory summary
   - 至少一组受控测试或 shell 读面能力
3. 让 `tap.inspect()` 与 `reviewWorkbench()` 的输出能稳定引用真实 status、history、checkpoint、project summary，而不是 placeholder 摘要。
4. 为 reviewer 上下文补 architecture / unit / smoke 级验证。

### 必须交付的工件

- reviewer 上下文状态说明
- 第一批真实 reviewer tools
- 对应 smoke / tests
- 对外示例或文档更新

### 完成标准

- reviewer 的高层上下文不再依赖“内部人知道仓库现状”的隐含知识。
- 文档、issue 和实现对于 reviewer 当前成熟度的说法一致。

### 明确不要做

- 不要让 reviewer 继续停留在只会拼 placeholder 文本的状态。
- 不要在这里偷渡高风险写能力而不补审批和证据链。

## Goal P5：durable runtime 主链闭环

### 目标

把 durable checkpoint、provisioning、activation、replay、recovery 接成正式主链，而不是 helper collection。

### 为什么这是高风险能力前置条件

- 没有持久化恢复链，高副作用执行面就只能依赖进程内连续性，治理和审计都站不住。
- durable runtime 是 approval、evidence、replay 可信的基础设施，而不是可选优化项。

### 必做动作

1. 将 durable checkpoint 自动写入接入主状态变化点。
2. 将 TMA planner / executor / bundle assembly 接成 provisioner runtime 正式流水线。
3. 为 provisioning、activation、pending replay、recovery 建立独立 smoke/e2e 路径。
4. 保证 TAP inspection / reviewWorkbench 能读到 durable provisioning 与 replay evidence。
5. 收口 provider / AI request seam，避免以后抽独立 SDK 时回拆上层调用方。

### 必须交付的工件

- durable checkpoint 自动写入
- TMA 主链接通
- smoke / e2e 入口
- recovery 证据读面

### 完成标准

- recovery 不依赖内存连续性。
- provisioning 与 activation 是正式 runtime 流水线的一部分。
- reviewer / TAP inspection 能看到 durable 证据，而不只是 approval 读面。

### 明确不要做

- 不要把 checkpoint 只留在手动 helper API。
- 不要在 recovery 主链未稳时扩大高副作用执行范围。

## Goal P6：高风险执行能力守卫化

### 目标

在治理、审批、证据、恢复链到位之后，再补 `shell.*`、`code.*`、MCP、Skill、`computer.use`。

### 建议顺序

1. `shell.run`
2. `shell.approve`
3. `code.run`
4. `code.patch`
5. `code.sandbox`
6. MCP / Skill
7. `computer.use` / observe / act

### 进入开发前必须满足的守卫条件

- 已有 approval path
- 已有 evidence path
- 已有 replay / recovery path
- 已有 bounded smoke path
- 已有 side-effect 风险标记

### 必做动作

1. 为每条高风险能力定义边界、平台条件、失败语义和占位语义。
2. 把 `code.sandbox` 的对外表述从“容易被误解成强隔离”改成“execution contract / declared sandbox boundary”。
3. 给 `shell` / `code` / MCP / Skill 分别补最小 bounded happy path 与 failure path smoke。
4. 把 approval、evidence、replay、recovery 读面挂到这些能力的对外说明里。
5. 最后再评估 `computer.use`，不要让它提前占用主路径资源。

### 必须交付的工件

- 高风险能力安全说明更新
- bounded smoke 路径
- 支持矩阵更新
- 对应 examples 或最小调用样例

### 完成标准

- 高副作用能力不只是“能跑”，而是“可控、可审计、可恢复、边界清楚”。
- 外部用户能在文档中看见哪些是 contract、哪些是 enforced behavior、哪些只是 placeholder。

### 明确不要做

- 不要先做 `computer.use` 再补 durable runtime。
- 不要把 `code.sandbox` 写成 OS 级隔离承诺。

## Goal P7：商业化准备与外部叙事

### 目标

把现有技术底座整理成“外部敢评估、敢试接、敢升级”的产品化材料。

### 为什么放在最后

- 商业化叙事必须建立在仓库真相、版本纪律、验证基线和能力边界都稳定之后。
- 否则对外讲得越大，越容易被 placeholder、无 release、无 CI 等事实反噬。

### 必做动作

1. 固化对外定位文案：
   - Apple / Swift 生态优先
   - embedding / governance / recovery / auditability 是主卖点
   - 不把自己讲成成熟的全平台通用 agent framework
2. 准备 demo host，优先原生 embedding host。
3. 更新 support matrix、performance baseline、migration notes、release policy，使它们形成一套完整外部信号。
4. 给 capability 和平台成熟度建立统一分级语义。
5. 准备 upgrade story：
   - schema version
   - release cadence
   - breaking change checklist
   - migration expectations

### 必须交付的工件

- 对外定位页或等价首页文案
- demo host
- 更新后的 release / migration / support / performance 材料
- 一份外部评估清单

### 完成标准

- 外部接入方可以判断：能不能接、接哪一层、平台边界在哪、升级风险多大。
- Praxis 的卖点与当前真实成熟度对齐，不靠夸大执行面来做销售。

### 明确不要做

- 不要把 Linux placeholder 包装成“很快就成熟”的默认承诺。
- 不要把商业卖点讲成 UI、跨平台执行面或万能框架。

## 5. 推荐排期节奏

这份整改建议按下面节奏推进：

- 第 1 周
  - 完成 P0：修仓库入口、绝对路径、stale issues、milestones / labels、baseline 报告
- 第 2-3 周
  - 完成 P1 + P2：预发布、CI、Quick Start、入口选择、平台状态说明、术语表
- 第 4-6 周
  - 完成 P3：thin capability baseline 和 search chain 的完整切片交付
- 第 7-8 周
  - 完成 P4 + P5：reviewer 真实上下文、durable runtime 主链、独立 smoke / e2e
- 第 9-10 周
  - 完成 P6：高风险执行能力按守卫条件推进
- 第 11-12 周
  - 完成 P7：demo host、版本叙事、性能/支持/迁移材料收口

## 6. 每个阶段都要检查的验收问题

每推进一个阶段，都至少回答下面六个问题：

1. 仓库首页、support matrix、issue 文案是否仍在讲同一组事实？
2. 新增能力是否同时补了测试、smoke、example、文档？
3. 新增对外面是否有明确的 stable / experimental / placeholder 标记？
4. approval、evidence、recovery 是否仍然能覆盖新增能力？
5. 新增材料是否降低了外部接入摩擦，而不是只增加内部术语密度？
6. 如果今天要发 preview release，这个阶段的变更是否有足够 release note 支撑？

## 7. 最近一轮最值得立即落地的动作

如果只做最小一轮整改，优先做下面十件事：

1. 修正总执行入口文档里的绝对路径引用。
2. 回扫 open issues，替换所有旧 TS/Node 布局引用。
3. 输出一份 baseline 报告，明确当前主线、入口、平台边界、placeholder 能力。
4. 建立 milestones / labels，并把现有 open issues 重挂到新结构。
5. 新增公开 build/test CI workflow。
6. 准备第一个 preview release。
7. 补 5 分钟 Quick Start。
8. 补 `PraxisRuntimeKit` / `PraxisFFI` / `PraxisHostRuntime` 入口选择说明。
9. 先把 thin capability + search 做成完整切片，再决定高风险能力节奏。
10. 统一 reviewer 当前成熟度的文档、issue 和实现表述。

## 8. 维护约束

- 本文是审计整改目标清单，不替代总执行手册。
- 如果仓库现实发生变化，先更新事实，再更新这里的目标，不保留“叙事上更好看”的过时描述。
- 如果某个结论已经稳定，应把可复用部分回写到 `memory/`，不要只停留在一次性文档。
