# 11 Runtime Assembly Closure

## 任务目标

把前面几波的协议、worker bridge、activation、replay 真正组装进 runtime，形成第二阶段闭环。

## 必须完成

- reviewer worker bridge 接入 runtime
- provisioner worker bridge 接入 runtime
- 默认主路径走 TAP
- provision ready 后可进入 activation / review / replay
- mode matrix 与 risk matrix 真正进入主链

## 允许修改范围

- `src/agent_core/runtime.ts`
- `src/agent_core/ta-pool-runtime/**`
- 配套测试

## 验收标准

- baseline / review / provision / activation / replay / human gate 全部可组装
- 代码层没有留下旧的默认绕行主路径
