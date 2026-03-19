# TAP Runtime Completion Blueprint

状态：详细设计稿 v1。

更新时间：2026-03-19

## 这份文档解决什么问题

`TAP` 现在已经是可用 runtime 控制面，但它还没有完成最后一段“真闭环”。

当前缺的不是概念，而是三段真正会影响可用性的机械链路：

1. `activation driver`
2. `real builder`
3. durable `human gate / replay`

一句白话：

- 现在系统已经会申请、会审核、也会说“去造一个能力”
- 但造完之后，还没有一个真正的安装工把能力接回池子
- 也还没有一个真正的施工队把能力稳定造出来
- 更没有一条在进程重启后还能接着跑的恢复链

这份文档的目标就是把这三段彻底设计清楚，并冻结一条能够直接进入并行编码拆解的实现主链。

## 当前真实状态

当前仓库中，下面这些事实已经成立：

- `dispatchIntent(capability_call)` 默认先走 `TAP`
- reviewer bootstrap worker bridge 已成立
- provisioner bootstrap worker bridge 已成立
- `DecisionToken` enforcement 已成立
- `restricted -> waiting_human -> approve / reject` 已成立
- replay / activation handoff skeleton 已成立

当前还没有完成的是：

- provision 结果还没有被自动激活回 `CapabilityPool`
- provisioner 还不是真正的 `toolmakeragent`
- `waiting_human` 和 `pending replay` 还不是 durable 记录

## 总体设计原则

### 1. reviewer 只审，不执行

- reviewer 只输出 vote / decision
- reviewer 不直接 dispatch grant
- reviewer 不直接写代码
- reviewer 不直接安装工具

### 2. TMA 只造，不替主 agent 完成原任务

- TMA 的目标是产出 capability package 和验证证据
- TMA 不负责替主 agent 把原始用户任务做完
- TMA 不自己批准 activation

### 3. activation driver 只做机械装配

- activation driver 不做 LLM 决策
- activation driver 不重新审 request
- activation driver 只负责把 provision 产物接回 execution plane

### 4. durable 链优先贴着现有 checkpoint / journal 骨架走

- 先尽量复用 `agent_core` 已有的 `journal` 与 `checkpoint`
- 先解决“崩掉后能恢复”
- 再考虑把 control-plane 事件进一步推广成更通用的事件层

### 5. 不过度抽象

- 当前先把 `TAP` 做成第一套完整样板
- 未来出现第二个 pool 时，再抽 shared primitives
- 现在只在文档中标出“哪些值得复用”，不在代码里提前做大而空的 shared framework

## 目标完成态

这轮不是把 `TAP` 变成“更复杂”。

这轮的目标完成态很简单：

1. 主 agent 请求一个当前缺失的能力
2. reviewer 审核后把请求转给 `TMA`
3. `TMA` 真正把能力造出来，并附 smoke / usage / rollback 信息
4. activation driver 把这个能力自动注册回 `CapabilityPool`
5. runtime 按 replay policy 决定：
   - 重新审后派发
   - 或等待人工
   - 或等待验证通过
6. 如果此时进程挂掉，重启后仍能知道：
   - 哪个 gate 在等人
   - 哪个 replay 还没跑
   - 哪个 activation 做到哪一步

一句白话：

- 要从“已经有审批单和施工图”
- 变成“真的能造、真的能装、断电后还能接着干”

## 第一部分：Activation Driver

### 当前问题

当前 runtime 已经能拿到：

- `ProvisionArtifactBundle`
- `ProvisionAssetRecord`
- `PoolActivationSpec`
- activation handoff

但真正的激活动作仍然是缺失的。

从测试上看，这个缺口已经非常清楚：

- 测试里仍然需要手工 `registerCapabilityAdapter(...)`
- 再手工把 asset 状态改成已接入

这说明现在缺的是一个真正的 activation 机械执行器，而不是更多设计讨论。

### 设计定位

`activation driver` 是 `TAP control plane -> CapabilityPool execution plane` 之间的装配层。

它不属于：

- reviewer
- provisioner / TMA
- 主 agent loop

它属于：

- control-plane runtime 的后段执行器

### 它负责什么

它只负责 6 件事：

1. 取出待激活的 provision asset
2. 读取并校验 `PoolActivationSpec`
3. 解析 `manifestPayload / bindingPayload / adapterFactoryRef`
4. 调目标 pool 做 `register / replace / register_or_replace`
5. 更新 asset lifecycle
6. 生成 activation receipt，交回 runtime

### 它不负责什么

- 不重新审 request
- 不直接给 grant
- 不运行原始用户任务
- 不决定 replay policy
- 不替 builder 做验证

### 最小输入

- `ProvisionAssetRecord`
- `PoolActivationSpec`
- `CapabilityPackage` 或等价 activation payload
- `adapterFactoryResolver`
- `targetPoolResolver`

### 最小输出

- `ActivationReceipt`
- 激活后的 pool registration 信息
- asset 状态更新结果
- 如失败则输出 `ActivationFailure`

### 建议状态机

`ready_for_review -> activating -> active`

失败分支：

`ready_for_review -> activating -> failed`

被替换分支：

`active -> superseded`

### 建议最小链路

1. runtime 发现 `ProvisionAssetRecord.status === ready_for_review`
2. reviewer 或 human gate 已允许进入 activation
3. activation driver 先把 asset 状态推进到 `activating`
4. 解析 `PoolActivationSpec`
5. 通过 `adapterFactoryRef` 还原真正的 adapter
6. 构造 `CapabilityManifest`
7. 调 `CapabilityPoolRegistry`
8. 成功后记下：
   - bindingId
   - generation
   - activated capability id
   - activatedAt
9. 更新 asset 为 `active`
10. 把 activation receipt 交给 replay dispatcher

### 关键边界

activation driver 不应该从 worker bridge 内部被调用。

正确链路是：

- `TMA` 造完 -> 产物进入 asset index -> runtime/activation driver 装配

错误链路是：

- `TMA` 造完后直接自己把 capability 注册进 pool

### 当前建议的模块落点

建议仍然放在：

- `src/agent_core/ta-pool-runtime/**`

原因：

- 这是 control-plane runtime 的后段，而不是 execution plane 本体
- 它需要直接读 TAP runtime 的 asset/replay/human gate 状态
- 不应放到 `capability-pool/**` 里污染 execution plane

建议后续出现：

- `activation-driver.ts`
- `activation-receipt.ts`
- `activation-factory-resolver.ts`

## 第二部分：Real Builder 与 TMA

### 当前问题

现在的 provisioner 更像：

- “一个知道怎么交 capability package 样板的人”

还不是：

- “一个真的能把工具装好、配好、测好、交付好的工具制造 agent”

当前 `worker bridge` 已经固定了两条 lane：

- `bootstrap`
- `extended`

这个方向是正确的，但现在还没有把“会写交付物”推进到“会稳定施工”。

### 新定位

从这一轮开始，建议把 provisioner 视为：

- `toolmakeragent`
- 简称 `TMA`

### 为什么要分两层

如果把 `TMA` 做成一个既思考又乱跑 shell 的 agent，很快就会出现两个问题：

1. reviewer 根本没法稳定审核
2. TMA 会偷偷完成主任务，而不是只造工具

所以建议把 `TMA` 分成两层：

### TMA Planner

负责：

- 理解缺的 capability 是什么
- 先判断是否能复用已有能力
- 产出 build plan
- 产出 artifact contract
- 产出 verification plan
- 产出 rollback plan

不负责：

- 真正执行安装
- 真正修改系统环境
- 真正完成原始用户任务

### TMA Executor

负责：

- 按批准后的 build plan 做机械执行
- 跑安装、配置、测试、文档生成
- 产出真实 artifact
- 收集 smoke / health / evidence

不负责：

- 改写 plan
- 自己扩大权限
- 自己批准 activation

### 当前与现有 lane 的关系

`bootstrap` lane 继续保留为：

- repo 内能力构建
- 限制 shell
- 跑局部测试
- 生成 usage/skill/docs

`extended` lane 继续保留为：

- 安装依赖
- 配置 MCP
- 网络下载
- 更厚的系统准备工作

但两者都要遵守一条边界：

- 只能造 capability
- 不能替主 agent 直接把原任务做完

### TMA 需要的最小基础能力

#### bootstrap TMA

- `code.read`
- `docs.read`
- `repo.write`
- `shell.restricted`
- `test.run`
- `skill.doc.generate`

#### extended TMA

在 bootstrap 基础上额外增加：

- `dependency.install`
- `mcp.configure`
- `network.download`
- `system.write`

### reviewer 需要的最小基础能力

reviewer 不需要厚能力，它只需要信息能力：

- `code.read`
- `docs.read`
- `project summary read`
- `inventory snapshot read`
- `memory summary read`
- 必要时的只读搜索

reviewer 不应该拥有：

- `repo.write`
- `shell.write`
- `dependency.install`
- `mcp.configure`
- `dispatch execution`

### Real Builder 的最小交付物

一个真正的 builder 不只交四个 artifact ref。

它还必须补齐下面这些真实信息：

1. `BuildPlan`
2. `BuildExecutionReport`
3. `VerificationEvidence`
4. `UsageDoc / Skill`
5. `RollbackHandle`

### 建议链路

1. runtime 组装 `ProvisionRequest`
2. reviewer 决定转 provisioning
3. `TMA planner` 产出 build plan
4. 审核通过后，`TMA executor` 机械执行
5. executor 收集证据
6. 生成标准 capability package
7. provisioner runtime 产出 `ready bundle`
8. 交给 activation driver

### 为什么这里必须补基础 capability

因为如果没有这些基础能力：

- reviewer 看不见真实项目态
- `TMA` 不能读写 repo
- `TMA` 不能跑测试
- `TMA` 不能安装依赖
- `TMA` 不能配置 MCP

那么 reviewer 和 `TMA` 就都只是空壳。

## 第三部分：Durable Human Gate / Replay

### 当前问题

现在 human gate 和 replay 这两块都已经“有语义”了，但都还是 runtime 内存态。

也就是说：

- 当前进程里它们能工作
- 进程挂掉后，它们不能稳定恢复

### 这块真正要解决什么

不是先做 UI。

先要解决的是：

- 系统重启后还知道自己卡在哪
- 并且知道下一步该继续什么

### 建议最小 durable 对象

先不要扩大范围。

第一版 durable 化只做 4 个对象：

1. `TaHumanGateState`
2. `TaHumanGateEvent[]`
3. `TaPendingReplay`
4. `TaActivationAttemptRecord`

### 为什么 activation attempt 也要持久化

因为 activation driver 进入 `activating` 之后，如果进程这时挂掉：

- 你必须知道这次 activation 到底成功了没有
- 是否需要回滚
- 是否可以重试

### 建议持久化策略

第一版不强求重构整个 kernel event 系统。

更稳的做法是：

#### Phase 1

先走 checkpoint-first durable 方案：

- gate/replay/activation 状态一旦变化
- 就写入 durable checkpoint snapshot

#### Phase 2

再考虑把这些状态抽成更正式的 pool event 体系。

### 为什么先走 checkpoint-first

因为现有 `CheckpointSnapshotData` 已经存在：

- `run`
- `state`
- `sessionHeader`

这说明我们只需要给它增加一层 control-plane snapshot 扩展，而不是现在就重构整个 `KernelEventType`。

### 建议新增的 snapshot 形状

建议不要直接写死成 `tapSnapshot`。

建议留成更可复用的结构：

- `poolRuntimeSnapshots`

第一版里面再挂：

- `tap`

例如：

- `poolRuntimeSnapshots.tap.humanGates`
- `poolRuntimeSnapshots.tap.pendingReplays`
- `poolRuntimeSnapshots.tap.activationAttempts`

这样以后出现 `mp` / `cmp` 时，可以自然挂第二个、第三个 pool 的恢复状态。

### 恢复时要做什么

runtime 恢复时，最小只做两步：

1. 从 checkpoint 恢复 pool runtime snapshot
2. 重新把这些状态装回 runtime 内存索引

恢复后的行为：

- `waiting_human` 继续等待
- `pending_manual` 继续等待人工
- `pending_after_verify` 继续等待验证触发
- `pending_re_review` 继续等待重新审查
- `activating` 状态可以根据 activation receipt 决定是重试还是回滚

### replay dispatcher 的第一版目标

当前 replay 还只是 handoff。

第一版真正可用化时，不需要一次做成全自动大脑。

它只需要变成一个清晰的 dispatcher：

- `none` -> 什么都不做
- `manual` -> 维持 gate
- `auto_after_verify` -> 验证通过后推给 activation/replay trigger
- `re_review_then_dispatch` -> 回 reviewer 主链

### 关键边界

durable human gate / replay 仍然要留在 `TAP` 内部。

不要把这些等待语义塞回 `core-agent loop` 去打断状态机。

`core-agent loop` 只应该看到：

- `deferred`
- `waiting_human`

其余细节继续由 `TAP` runtime 自己持有。

## 第四部分：建议的实现总链路

### 缺失 capability 时

1. 主 agent 发起 `capability_call`
2. `TAP` 审核
3. reviewer 判断：
   - 已有并可批 -> dispatch
   - 缺失 -> redirect_to_provisioning
4. `TMA planner` 产出 plan
5. `TMA executor` 真正构建
6. provisioner runtime 产出 `ready bundle`
7. activation driver 装回 `CapabilityPool`
8. replay dispatcher 根据 policy 做：
   - re-review
   - manual wait
   - after verify
9. 继续进入主 runtime 链

### 被卡住时

1. `waiting_human`
2. durable snapshot 写入
3. 进程挂掉也能恢复
4. 人类回来批准/拒绝
5. 再继续 activation / replay / dispatch

## 第五部分：对下一个 Pool 的复用边界

### 当前已经足够通用、值得以后抽 shared 的部分

- `Request`
- `ReviewDecision`
- `Grant`
- `DecisionToken`
- `ProvisionRequest`
- `ArtifactBundle`
- `ActivationSpec`
- `ReplayPolicy`
- `HumanGateRecord`
- `ContextAperture`
- `WorkerPromptPack`
- `PoolRuntimeSnapshot`

这些东西的共同点是：

- 不依赖 capability 执行语义
- 换成 memory/context/governance 仍然说得通

### 当前不要过早抽 shared 的部分

- `TaCapabilityTier`
- capability package 七件套的具体字段名
- `CapabilityPool` 的 adapter 注册与执行语义
- capability-specific risk 例子
- `capabilityKey / capabilityKind / routeHints`

这些是 `TAP` 的 specialization layer，不应该提前抽成全局通用层。

### 最稳的复用策略

不是：

- 现在就把 `TAP` 全抽成 shared framework

而是：

1. 先把 `TAP` 做成第一套完整样板
2. 当 `mp` / `cmp` 真开始落地时
3. 再从两个 pool 的共同部分里抽 shared primitives

一句白话：

- 先做出两台真机器
- 再决定哪几个零件真的值得标准化

## 第六部分：这轮之后的拆任务原则

下一轮拆编码任务时，建议严格按下面的顺序：

1. `activation driver`
2. `real builder / TMA`
3. durable `human gate / replay`
4. end-to-end 联调

### 为什么不能先做 durable

因为如果 activation driver 还没做，durable replay 只能 durable 地卡着。

### 为什么不能先大规模补 reviewer

因为 reviewer 现在真正缺的不是“再聪明一点”，而是后面这条链还没接实。

### 为什么 `TMA` 必须在 activation 之前设计清楚

因为 activation driver 要接的不是抽象概念，而是 builder 交出的真实能力包。

## 当前冻结结论

这轮详细设计冻结下面这些共识：

- `activation driver` 是 control-plane 后段机械装配器
- provisioner 将继续收口成 `TMA`
- `TMA` 分 planner / executor 两层
- reviewer 继续只读、只审、只投票
- durable 先走 checkpoint-first，再考虑更广义的 pool events
- 当前先把 `TAP` 做成第一套完整样板，不提前抽 shared framework
