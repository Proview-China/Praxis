# 12 End To End Smoke And Multi Agent Tests

## 任务目标

补齐第二阶段 TAP 的 end-to-end 验证，确保角色不串位。

## 必须完成

- 默认 capability_call 走 TAP 的测试
- reviewer 只回 vote 的测试
- forged grant / token 被拒绝的测试
- provision -> activate -> re-review -> dispatch 的测试
- restricted -> waiting_human -> approve/reject 的测试
- bapr 模式直通的测试
- reviewer / provisioner 不越权的负向测试
- 至少一条 live smoke：
  - `gmn + gpt-5.4`

## 允许修改范围

- `src/agent_core/**/*.test.ts`
- 必要时新增最小 smoke script

## 验收标准

- typecheck 通过
- agent_core 定向测试通过
- 第二阶段新增负向测试全部通过
- 至少一条 live smoke 能证明默认主路径和 TAP worker bridge 已成立
