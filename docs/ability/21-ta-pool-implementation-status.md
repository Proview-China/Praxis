# T/A Pool Implementation Status

状态：阶段性实现总结，已进入“可用控制面”阶段。

更新时间：2026-03-19

## 先说结论

`TAP` 现在已经不只是第一版控制面骨架。

它已经推进到下面这个阶段：

- 第二阶段 shared protocol 已冻结
- capability request 默认主路径已切到 `TAP`
- reviewer 已接入 bootstrap worker bridge
- provisioner 已接入 bootstrap worker bridge
- capability package template SDK 已落地
- 最小 enforcement / human gate / replay skeleton 已落地
- `AgentCoreRuntime` 已把这些东西装配进主链
- 当前类型检查、构建和 `agent_core` 定向测试都已通过

但它**还不能被叫做“完整工业级治理系统”**。

更准确的判断是：

- `TAP` 已经从“控制面已成立”推进到“可用 runtime 控制面”
- 默认 capability routing、reviewer/provisioner bridge、最小 enforcement、human gate、replay skeleton 都已真实进代码
- 但真实 activation driver、真实 builder、durable human gate / replay 恢复链仍未完成

一句白话：

- 我们已经不只是在讨论工具池
- 我们已经有了一套默认会接管 capability 调度的 `TAP`
- 但更厚的 activation / builder / durable recovery 还在后面

## 这次到底完成了什么

### 1. 第二阶段协议层

当前已落地：

- `src/agent_core/ta-pool-types/**`

这里已经冻结到第二阶段最关键的对象：

- `AgentCapabilityProfile`
- `AccessRequest`
- `ReviewDecision`
- `ReviewVote`
- `CapabilityGrant`
- `DecisionToken`
- `ProvisionRequest`
- `ProvisionArtifactBundle`
- `PoolActivationSpec`
- `ReplayPolicy`
- `PlainLanguageRiskPayload`

同时也已经固定了：

- `B0-B3`
- `bapr / yolo / permissive / standard / restricted`
- `normal / risky / dangerous`
- `approved / partially_approved / denied / deferred / escalated_to_human / redirected_to_provisioning`

这意味着：

- `TAP` 的第二阶段公共语言已经存在
- 不再只是讨论层

### 2. baseline / 模式 / 风险矩阵

当前已落地：

- `src/agent_core/ta-pool-model/**`

这里已经做成了：

- baseline profile 判定
- 旧模式到新模式的兼容映射
- mode policy matrix
- risk classifier
- `bapr / yolo / permissive / standard / restricted` 行为差异
- `normal / risky / dangerous` 风险分层

### 3. reviewer 控制面

当前已落地：

- `src/agent_core/ta-pool-review/**`

这里已经做成了：

- review decision engine
- review routing
- reviewer runtime
- reviewer worker bridge
- vote-only 输出编译
- inline grant 越权拦截
- aperture v1 输入封装

这意味着：

- reviewer 已经不是空壳 hook
- 即使现在还没接真实外部 reviewer worker，也已经有 bootstrap reviewer bridge 和 vote-only 边界

### 4. provision 控制面

当前已落地：

- `src/agent_core/ta-pool-provision/**`

这里已经做成了：

- provision registry
- provision asset index
- provisioner runtime
- provisioner worker bridge
- bootstrap / extended lane 语义
- `building -> ready_for_review / activating / active / failed / superseded` 骨架
- activation payload / replay recommendation 输出

这意味着：

- “没有就去造”这条路已经不只是 shell
- 现在已经有 worker bridge 和 asset index
- 但真实 builder 和真实 activation driver 还没接上

### 5. safety 控制面

当前已落地：

- `src/agent_core/ta-pool-safety/**`

这里已经做成了：

- `allow`
- `interrupt`
- `block`
- `downgrade`
- `escalate_to_human`

并且已经补了：

- `bapr` 全放行语义
- `yolo` 仅高危拦截
- `restricted` 风险升级到 human gate

### 6. context aperture v1

当前已落地：

- `src/agent_core/ta-pool-context/**`

这里已经做成了：

- reviewer / provisioner 的 context aperture v1
- plain-language risk formatter
- forbidden live handle / secret slot 校验

这意味着：

- project / memory 视角当前仍保持 placeholder 语义
- 但字段面和禁止输入边界已经先冻结好了

### 7. runtime assembly 第二段

当前已落地：

- `src/agent_core/ta-pool-runtime/**`
- `src/agent_core/runtime.ts`

这里已经做成了：

- control-plane gateway
- execution bridge
- enforcement guard
- human gate skeleton
- replay policy skeleton
- `resolveTaCapabilityAccess(...)`
- `dispatchTaCapabilityGrant(...)`
- `dispatchCapabilityIntentViaTaPool(...)`
- `dispatchIntent(capability_call)` 默认先走 `TAP`
- `submitTaHumanGateDecision(...)`

并且已经打通下面这些链路：

- default capability_call -> TAP
- review -> reviewer worker bridge -> dispatch
- review -> provisioning
- provisioning -> asset index -> replay handoff
- `restricted -> waiting_human -> approve / reject`
- safety -> interrupt

这意味着：

- `TAP` 已经不只是接进 runtime
- 它现在已经是 capability_call 的默认控制面入口

## 当前还没做完的部分

### 1. reviewer 还没吃真实高层上下文

当前 reviewer 还只是：

- runtime bridge + aperture v1 + placeholder 项目/记忆摘要

还没有做到：

- 读取真实项目状态镜像
- 读取真实记忆池
- 读取包装机态上下文
- 接真实外部 reviewer worker / model runtime

### 2. provisioner 还没有真实 builder / activation driver

当前已经有 provisioner worker bridge 和 asset index。

但还没有做到：

- 真正配置工具
- 真正安装依赖
- 真正驱动 activation / pool 注册
- 真正把 replay 从 skeleton 推进到自动闭环

### 3. human gate / replay 还没有 durable 恢复链

当前已经有：

- `waiting_human` 语义
- human approve / reject 回注
- pending replay skeleton

但还没有做到：

- durable journal / checkpoint 恢复
- 产品级 human approval UI
- 完整 auto-after-verify replay 执行器

### 4. safety 还没做完整细粒度执行约束

当前 safety 已经能挡第一波危险请求。

但还没有做到：

- 更细粒度的行为账本
- 对 scope / constraints / denyPatterns 的完整执行期 enforcement
- 更复杂的 downgrade / recover 流程

## 当前验证基线

当前已回读通过：

- `npm run typecheck`
- `npm run build`
- `npx tsx --test src/agent_core/**/*.test.ts`
  - `159 pass / 0 fail`
- `npm run smoke:websearch:live -- --provider=openai`
  - `gmn + gpt-5.4` 的 `native_plain / native_search / rax_websearch` 都是 `ok`

这意味着：

`TAP` 现在已经不是“控制面骨架”
- 它已经在当前 `agent_core` 基线上通过了默认路由、worker bridge、最小 enforcement、human gate、replay skeleton 的完整验证
