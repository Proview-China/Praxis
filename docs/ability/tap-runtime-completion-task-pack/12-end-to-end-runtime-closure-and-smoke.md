# 12 End-To-End Runtime Closure And Smoke

## 任务目标

把这轮所有链路联调成一个真实可跑的 end-to-end 闭环。

## 必须完成

- 缺失 capability -> review -> provisioning -> activation -> replay/re-review -> dispatch
- restricted -> waiting_human -> approve / reject -> continue / stop
- activation failure -> rollback / retry path
- durable 恢复后继续 human gate / replay / activation
- 至少一条真实基础 capability 的 live/smoke 验证

## 允许修改范围

- `src/agent_core/runtime.ts`
- `src/agent_core/**/*.test.ts`
- 必要时少量改 `package.json` 的 smoke 脚本

## 依赖前置

- `04`
- `05`
- `07`
- `08`
- `09`
- `10`
- `11`

## 不要做的事

- 不要只补单元测试，不补链路测试
- 不要把 activation / replay 继续留在手工模拟状态

## 验收标准

- 不再需要在测试中手工补注册动作才能证明激活成功
- 中断恢复后能继续 TAP 控制面链路
- 至少一条真实基础能力通过 smoke
