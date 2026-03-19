# TAP Runtime Migration And Enforcement Outline

状态：冻结设计草案 v1。

更新时间：2026-03-19

## 这份文档解决什么问题

`TAP` 现在已经能跑，但还不是默认总入口。

如果不先冻结迁移策略和 enforcement 规则，后面会出现：

- 一部分 capability 走 review
- 一部分 capability 直接绕过 review
- reviewer 批出来的 scope 和 constraints 没有人真正执行

这份文档就是要把这两件事钉死：

1. `capability_call` 如何默认切到 `TAP`
2. reviewer 的 grant 如何在 execution plane 被机械强制执行

## 一、默认主路径切换策略

### 当前事实

当前 `AgentCoreRuntime` 里：

- `dispatchCapabilityIntentViaTaPool(...)` 已存在
- `dispatchIntent(...)` 默认还走旧的 `dispatchCapabilityIntent(...)`
- `runUntilTerminal()` 的 `capability_call` 也还没默认切到 `TAP`

### 目标状态

目标不是删掉旧路径，而是把语义改成：

- 普通 `capability_call` 默认先走 `TAP`
- 旧直达执行路径只保留给测试、底层调试和显式 bypass

### 迁移阶段

#### Phase A

- 保留旧路径
- 新增明确的 `tap-first` runtime 入口
- 补齐测试矩阵

#### Phase B

- `dispatchIntent(capability_call)` 默认先走 `TAP`
- 旧路径变成显式 bypass

#### Phase C

- `runUntilTerminal()` 和上层 orchestration 默认全部走 `TAP`
- reviewer 成为 capability execution 的正式总闸门

### bypass 规则

第一版允许存在显式 bypass，但必须满足：

- 只供测试或底层调试
- 不能作为普通主 agent 的默认路径
- 文档和代码中要明确标记

## 二、grant enforcement 规则

第一版 reviewer 不能只“写审批单”，execution plane 必须真正检查。

### 强制检查项

在 execution plane 进入 `prepare / dispatch` 之前，至少检查：

- `requestId` 是否匹配
- `capabilityKey` 是否与原 request 一致
- `grantedTier <= requestedTier`
- `scope` 是否没有放宽
- `mode` 是否没有被改写
- `expiry` 是否有效
- `constraints` 是否满足
- deny pattern 是否未被违反

### grant 来源规则

第一版冻结：

- reviewer 只输出 `decision vote`
- 最终 `CapabilityGrant` 由 kernel 内的 `GrantCompiler` 机械生成

白话：

- reviewer 只能说“我建议批准”
- 但真正的通行证由内核盖章

## 三、decision token

为避免 reviewer 返回的文本结果被直接当成执行授权，第一版需要冻结：

- `DecisionToken`

最少表达：

- `request_id`
- `decision_id`
- `compiled_grant_id`
- `mode`
- `issued_at`
- `expires_at`
- `signature_or_integrity_marker`

execution plane 只接受：

- 由 control-plane 内核编译并签发的 token

execution plane 不接受：

- 直接从 LLM reviewer 返回的原始 decision 文本

## 四、restricted 模式的人类审批语义

`restricted` 模式的目标是：

- baseline 之外的行为默认停在 `TAP`
- reviewer 负责解释风险
- 人类决定是否继续

### 运行要求

- 等待状态保留在 `TAP`
- `core-agent loop` 不被打断成异常流
- loop 只感知到 `deferred` 或 `waiting_human`
- 人类批复以事件形式回注

## 五、用户侧白话审批说明

被 reviewer 拒绝、延后、升级人工、或标为高风险的请求，都必须生成面向用户的白话说明。

最少字段：

- `plain_language_summary`
- `requested_action`
- `risk_level`
- `why_it_is_risky`
- `possible_consequence`
- `what_happens_if_not_run`
- `available_user_actions`

## 六、当前冻结结论

这轮冻结下面这些共识：

- `capability_call` 默认主路径必须切到 `TAP`
- reviewer 不直接返回最终 grant
- execution plane 必须做 grant mechanical enforcement
- `restricted` 的等待留在 `TAP`
- 人类审批必须有白话风险说明
