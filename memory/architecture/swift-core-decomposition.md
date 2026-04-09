# Swift Core Decomposition

## 核心结论

- `Core` 是逻辑层，不是模块名。
- phase-0 粗模块已经被拆成 phase-1 功能域 target。
- 后续真实迁移应直接落到 phase-1 子域，不再回到 phase-0 粗模块。

## 1. Foundation 层

这一层已经足够细，当前不建议再继续拆：

- `PraxisCoreTypes`
- `PraxisGoal`
- `PraxisState`
- `PraxisTransition`
- `PraxisRun`
- `PraxisSession`
- `PraxisJournal`
- `PraxisCheckpoint`

判断：

- 这些模块本身职责已经比较单一
- 后续如果继续拆，大概率只是人为增加胶水成本

## 2. Capability 域

当前 phase-1：

- `PraxisCapabilityContracts`
  - manifest
  - binding
  - invocation contract
  - pool-facing capability shape
- `PraxisCapabilityPlanning`
  - invocation plan
  - lease / queue / dispatch semantics
  - execution request lowering
- `PraxisCapabilityResults`
  - result envelope
  - result bridge
  - normalized output shape
- `PraxisCapabilityCatalog`
  - capability package
  - baseline capability sets
  - family catalog

不应继续放在 Capability 域里的内容：

- TAP review policy
- CMP five-agent dispatch policy
- provider-specific request payload

## 3. TAP 域

当前 phase-1：

- `PraxisTapTypes`
- `PraxisTapGovernance`
- `PraxisTapReview`
- `PraxisTapProvision`
- `PraxisTapRuntime`
- `PraxisTapAvailability`

### 拆分标准

#### `PraxisTapTypes`

- review / provision / TMA / human-gate 共享模型

#### `PraxisTapGovernance`

- 风险分类
- mode policy
- governance object
- user surface snapshot

#### `PraxisTapReview`

- reviewer decision
- tool reviewer decision
- review routing

#### `PraxisTapProvision`

- provision registry
- provision asset index
- planner / executor 的纯计划层

#### `PraxisTapRuntime`

- control plane semantics
- activation lifecycle
- replay policy
- governance snapshot
- runtime recovery model

#### `PraxisTapAvailability`

- family audit
- gating
- failure taxonomy

## 4. CMP 域

当前 phase-1：

- `PraxisCmpTypes`
- `PraxisCmpSections`
- `PraxisCmpProjection`
- `PraxisCmpDelivery`
- `PraxisCmpGitModel`
- `PraxisCmpDbModel`
- `PraxisCmpMqModel`
- `PraxisCmpFiveAgent`

### 拆分标准

#### `PraxisCmpTypes`

- canonical object model
- lineage / section / request / package / snapshot 基础类型

#### `PraxisCmpSections`

- ingest
- section creation
- section rules / lowering

#### `PraxisCmpProjection`

- projection record
- materialization
- visibility
- runtime snapshot / recovery model

#### `PraxisCmpDelivery`

- dispatch instruction
- delivery record
- passive / active flow
- historical fallback planning

#### `PraxisCmpGitModel`

- branch family
- checked/promoted ref lifecycle
- lineage governance
- sync intent / planning model

说明：

- 这里只保留 model/planner
- 不保留 Git CLI 执行器

#### `PraxisCmpDbModel`

- topology
- local hot tables model
- projection/package/delivery persistence plans

#### `PraxisCmpMqModel`

- topic topology
- routing
- neighborhood relation
- escalation planning

#### `PraxisCmpFiveAgent`

- five-agent role protocol
- ICMA / iterator / checker / dbagent / dispatcher 的纯职责模型

## 5. Host 层也不能变成新的兜底层

虽然这次重点是继续拆 Core，但 Host 也必须同时防守：

- HostContracts 已冻结为五个协议族 target，后续不能回并成单一大接口包
- HostRuntime 已冻结为四个 target，后续不能再长回单体 `runtime.ts`

## 6. 当前建议

下一轮如果继续做架构设计，最合理的动作不是再增加一个叫 `Core` 的抽象，而是：

1. 让 phase-1 target 保持稳定，不再回并成粗模块
2. 真实实现开始时，直接按 phase-1 子域承接迁移
3. 同步维护架构守卫测试 target

一句话：

- 当前骨架已经说明“Core 不该是一个模块”
- 下一阶段要做的就是把这个原则真正落实到 target 粒度
