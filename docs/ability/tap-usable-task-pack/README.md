# TAP Usable Task Pack

状态：第二阶段并行编码任务包。

更新时间：2026-03-19

## 这包任务是干什么的

这一包不是做 `TAP` 第一版控制面。

第一版控制面已经完成：

- 协议层
- review shell
- provision shell
- safety shell
- runtime assembly 第一段

这一包要做的是下一阶段：

- 把 `TAP` 从“已成立控制面”推进到“可用控制面”

具体目标：

1. 把 `capability_call` 默认主路径切到 `TAP`
2. 把 reviewer 从占位 hook 升级成真正的 reviewer worker bridge
3. 把 provisioner 从 mock builder 升级成真 builder 流
4. 把 activation / replay / enforcement 三条桥补齐
5. 补齐模式矩阵、风险矩阵、白话审批说明和 end-to-end 测试

## 开工前必须先读

所有执行本包的 Codex 都必须先读：

- [20-ta-pool-control-plane-outline.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/20-ta-pool-control-plane-outline.md)
- [21-ta-pool-implementation-status.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/21-ta-pool-implementation-status.md)
- [23-ta-pool-stage-wrap-up.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/23-ta-pool-stage-wrap-up.md)
- [24-tap-mode-matrix-and-worker-contracts.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/24-tap-mode-matrix-and-worker-contracts.md)
- [25-tap-capability-package-template.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/25-tap-capability-package-template.md)
- [26-tap-runtime-migration-and-enforcement-outline.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/26-tap-runtime-migration-and-enforcement-outline.md)
- [docs/master.md](/home/proview/Desktop/Praxis_series/Praxis/docs/master.md)
- `memory/current-context.md`

## 本轮冻结共识

- 模式固定为：
  - `bapr`
  - `yolo`
  - `permissive`
  - `standard`
  - `restricted`
- 风险等级固定为：
  - `normal`
  - `risky`
  - `dangerous`
- reviewer 只审，不执行
- provisioner 只造，不批准
- `bapr` 下 reviewer 退化为传话筒
- `restricted` 等待留在 `TAP` 内部，不入侵 `core-agent loop`
- reviewer 当前上下文视角仍是 placeholder
- capability package 必须带：
  - `builder`
  - `verification`
  - `usage`

## 推荐分波顺序

### Wave 0

- `00-protocol-freeze-and-shared-types.md`

### Wave 1

- `01-mode-matrix-and-risk-policy-upgrade.md`
- `02-review-vote-and-grant-compiler.md`
- `03-context-aperture-v1-and-plain-language-risk.md`

### Wave 2

- `04-default-tap-routing-switch.md`
- `05-enforcement-token-and-execution-guard.md`
- `06-provision-activation-spec-and-asset-index.md`

### Wave 3

- `07-reviewer-worker-bridge.md`
- `08-provisioner-worker-bridge.md`
- `09-capability-package-template-sdk.md`

### Wave 4

- `10-replay-policy-and-human-gate.md`
- `11-runtime-assembly-closure.md`
- `12-end-to-end-smoke-and-multi-agent-tests.md`

## 推荐并发量

- Wave 0：`1`
- Wave 1：`3`
- Wave 2：`3`
- Wave 3：`3`
- Wave 4：`3`

建议总并发不要超过 `3-4` 个共享协议修改者同时写同一波。

如果机器性能充足，可以同时挂更多 explorer 做只读审查，但真正写 shared protocol 的 worker 不建议过多。

## 任务列表

- `00-protocol-freeze-and-shared-types.md`
- `01-mode-matrix-and-risk-policy-upgrade.md`
- `02-review-vote-and-grant-compiler.md`
- `03-context-aperture-v1-and-plain-language-risk.md`
- `04-default-tap-routing-switch.md`
- `05-enforcement-token-and-execution-guard.md`
- `06-provision-activation-spec-and-asset-index.md`
- `07-reviewer-worker-bridge.md`
- `08-provisioner-worker-bridge.md`
- `09-capability-package-template-sdk.md`
- `10-replay-policy-and-human-gate.md`
- `11-runtime-assembly-closure.md`
- `12-end-to-end-smoke-and-multi-agent-tests.md`

## 一句话收口

这一包任务不是继续“证明 TAP 能不能存在”，而是把它完善成用户真的能用、开发者真的能维护、未来别的池子真的能复用的第二阶段实施包。
