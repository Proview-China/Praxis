# CMP Five-Agent Implementation Task Pack

状态：并行实施任务包 / 初版。

更新时间：2026-03-25

## 这包任务是干什么的

这包任务专门处理：

- `CMP` 五个 agent 本身的实现
- 五个 agent 的 runtime 边界
- 五个 agent 的主动 / 被动 / 播种链
- 五个 agent 的角色级 checkpoint / recovery

它不是：

- `CMP` 非五-agent 公共底座收口包
- `MP` 实现包
- `TAP` 生产收口包

一句白话：

- 这包任务是“把五个 agent 真正做出来”

## 开工前必须先读

所有参与本包的 agent 都必须先读：

- [44-cmp-five-agent-implementation-outline.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/44-cmp-five-agent-implementation-outline.md)
- [33-cmp-five-agent-runtime-and-active-passive-flow.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/33-cmp-five-agent-runtime-and-active-passive-flow.md)
- [29-cmp-context-management-pool-outline.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/29-cmp-context-management-pool-outline.md)
- [40-cmp-non-five-agent-closure-outline.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/40-cmp-non-five-agent-closure-outline.md)
- [memory/current-context.md](/home/proview/Desktop/Praxis_series/Praxis/memory/current-context.md)

## 当前冻结共识

- 五个 agent 都应有自己的 `Agent_Loop_Runtime`
- 第一版按强隔离、未来可进程化路线设计
- 第一条主线先做主动链：
  - `ICMA -> Iterator -> Checker -> DBAgent -> Dispatcher`
- `DBAgent` 主产物是 `ContextPackage`
- `DBAgent` 附产物是 `Task` 级 `Skill Snapshot`
- `ContextPackage` 与 `Skill Snapshot` 走：
  - package 为主
  - snapshot 为附属引用
- 同父平级可交换，但必须先经直属父节点批准
- 不同父节点子树默认硬隔离
- 被动模式第一版默认：
  - `DBAgent` 直接接单
  - `Dispatcher` 负责送回
- `active/passive` 默认混合常开
- 每个角色都允许：
  - checkpoint
  - recovery
  - human override
- human override 必须强审计
- 五个 agent 的能力面走 `TAP` 角色差异化强控

## 本轮新增冻结口子

- `ICMA` 默认按任务意图切块
- `ICMA` 的 `system fragment` 只允许：
  - 约束
  - 风险
  - 流程
- `system fragment` 默认按任务阶段持续生效
- `Iterator` 以 `commit` 作为最小可审查单元
- `Checker` 的 `checked` 与 `suggest-promote` 第一版硬分离
- 父层内部第一版默认由父 `DBAgent` 主审 promote
- `DBAgent` 产包关系固定为：
  - 现场主包
  - 时间线附包
  - 多个 task 级 snapshot
- `Dispatcher` 向子节点播种默认只进子节点 `ICMA`
- 同父平级交换默认走瘦交换包
- 同父平级交换必须先有直属父节点显式一次性批准
- checkpoint 第一版按事件级设计
- override 只允许改运行控制与裁决状态，不允许直接改 raw truth
- `debug/admin` 只开放管理动作，不开放真相写口

## 主线程编排层

这一轮仍然需要保留一个主线程独占层：

- `Program Control Layer`

职责：

- 守住高冲突文件
- 决定每一波放行
- 统一收 runtime / facade / tests
- 负责最后联调和验收

主线程单写文件默认包括：

- [src/agent_core/runtime.ts](/home/proview/Desktop/Praxis_series/Praxis/src/agent_core/runtime.ts)
- [src/agent_core/runtime.test.ts](/home/proview/Desktop/Praxis_series/Praxis/src/agent_core/runtime.test.ts)
- [src/rax/cmp-facade.ts](/home/proview/Desktop/Praxis_series/Praxis/src/rax/cmp-facade.ts)
- [src/rax/cmp-runtime.ts](/home/proview/Desktop/Praxis_series/Praxis/src/rax/cmp-runtime.ts)
- 本包总 `README`

## 超多智能体并发总原则

### 1. 总目标

把五个 agent 的实现拆成“高内聚、低冲突”的多路并发施工。

白话：

- 能并行的尽量并行
- 真会撞车的地方只留给主线程

### 2. ownership 纪律

- 主线程只写高冲突装配面
- 每个 Part Lead 只写自己 Part 的主路径
- Part 内 worker 必须再按更小 ownership 切开
- 不允许两个 worker 同时改同一组状态机核心文件
- 不允许把 `.parallel-worktrees/` 或 `TAP` 脏文档带进提交

### 3. 收口纪律

- 每一波都必须先交：
  - 本 Part 自测结果
  - 契约变化说明
  - 对下游影响说明
- 主线程验收后才能进下一波

## 推荐超多智能体拓扑

### 1. 主线程

- 数量：`1`
- 模型：`gpt-5.4-high`
- 职责：
  - 守共享协议
  - 守装配层
  - 收冲突文件
  - 联调与最终验收

### 2. 二层 lead

- 数量：`6`
- 默认模型：`gpt-5.4-high`
- 每个 lead 只负责一个 Part
- lead 的职责不是包办编码，而是：
  - 切 ownership
  - 发 worker 任务
  - 收测试与契约
  - 把可合并结果交还主线程

### 3. 三层 worker

- 建议数量：`12-20`
- 默认模型：
  - 普通编码与测试：`gpt-5.4-high`
  - 轻量 schema / fixture / 文档回填：`gpt-5.4-medium`
  - 复杂状态机 / recovery / lineage 权限冲突：`gpt-5.4-xhigh`
- 每个 worker 必须有明确写集

## 建议波次与并发关系

### Wave 0 / 冻结协议

- 主线程完成 Part 0
- 其余 lead 只读准备
- 不抢写共享对象和共享事件

### Wave 1 / 先立主动链骨架

- Part 1：
  - `ICMA` ingress runtime
  - intent chunking
  - fragment policy
- Part 2：
  - `Iterator` 候选 commit 主线
  - `Checker` checked skeleton
- Part 3：
  - `DBAgent` package family object model
- 说明：
  - 这是第一批最适合大并发的波次

### Wave 2 / 接上主链中后段

- Part 2：
  - `Checker` 的重整与 `suggest-promote`
- Part 3：
  - `DBAgent` 主动物化
  - snapshot 挂接
  - 父层 promote 审理入口
- Part 4：
  - `Dispatcher` delivery / ack baseline

### Wave 3 / 打开 lineage 与被动链

- Part 4：
  - parent-child reseed
  - same-parent peer package
  - cross-parent isolation
- Part 5：
  - passive request route
  - event checkpoint
  - override audit

### Wave 4 / 总装与总验收

- Part 6：
  - role capability matrix
  - runtime assembly
  - facade / runtime / tests 集成
  - end-to-end smoke

## 六个部分

### Part 0

- 目录：
  - [part0-program-control/README.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/cmp-five-agent-implementation-task-pack/part0-program-control/README.md)
- 目标：
  - 固定角色边界、共享事件、冲突文件政策、波次放行规则

### Part 1

- 目录：
  - [part1-icma-and-ingress-runtime/README.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/cmp-five-agent-implementation-task-pack/part1-icma-and-ingress-runtime/README.md)
- 目标：
  - 实现 `ICMA` runtime、受控 `system fragment`、ingress 整形与入口治理

### Part 2

- 目录：
  - [part2-iterator-and-checker-runtime/README.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/cmp-five-agent-implementation-task-pack/part2-iterator-and-checker-runtime/README.md)
- 目标：
  - 实现 `Iterator` 与 `Checker` 的主动链推进、checked 裁决、父层 promote 提请

### Part 3

- 目录：
  - [part3-dbagent-and-package-runtime/README.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/cmp-five-agent-implementation-task-pack/part3-dbagent-and-package-runtime/README.md)
- 目标：
  - 实现 `DBAgent` 的 projection / `ContextPackage` / `Skill Snapshot` 双轨产出

### Part 4

- 目录：
  - [part4-dispatcher-and-lineage-delivery/README.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/cmp-five-agent-implementation-task-pack/part4-dispatcher-and-lineage-delivery/README.md)
- 目标：
  - 实现 `Dispatcher` 的主 agent 回填、父子播种、同父平级受控交换、delivery receipt

### Part 5

- 目录：
  - [part5-passive-flow-checkpoint-and-override/README.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/cmp-five-agent-implementation-task-pack/part5-passive-flow-checkpoint-and-override/README.md)
- 目标：
  - 实现被动查询链、角色级 checkpoint/recovery、human override 强审计、debug/admin 管理动作

### Part 6

- 目录：
  - [part6-final-integration-and-five-agent-gates/README.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/cmp-five-agent-implementation-task-pack/part6-final-integration-and-five-agent-gates/README.md)
- 目标：
  - 收五个 agent 的 runtime assembly、角色能力矩阵、联调、five-agent-ready gate

## 全局串并行顺序

### Global Wave 0

- 主线程冻结 Part 0
- 其余各 Part 只读准备，不抢写共享协议

### Global Wave 1

- Part 1：
  - `ICMA` runtime
  - ingress event shape
  - controlled system fragment
- Part 2：
  - `Iterator` push-to-review
  - `Checker` checked decision skeleton
- Part 3：
  - `DBAgent` package / snapshot object shape
- 其余 Part 只允许起协议骨架

### Global Wave 2

- Part 2：
  - parent promote request path
  - checked / suggest-promote decision path
- Part 3：
  - `ContextPackage + Skill Snapshot` dual payload
  - active materialization path
- Part 4：
  - `Dispatcher` delivery / ack baseline

### Global Wave 3

- Part 4：
  - parent-child reseed
  - same-parent peer exchange
  - cross-parent hard isolation
- Part 5：
  - passive request direct-to-DBAgent
  - role checkpoint / recovery
  - override audit

### Global Wave 4

- Part 6：
  - role capability matrix
  - mixed proxy interface
  - runtime assembly
  - end-to-end integration

## 主线程联调检查清单

- 检查 Part 1 输出是否真的只把材料推进到 `Iterator` 可接状态
- 检查 Part 2 是否坚持：
  - `commit` 为最小可审查单元
  - `checked` 与 `suggest-promote` 分离
- 检查 Part 3 是否坚持：
  - `DBAgent` 单点主写 `CMP DB`
  - 现场主包 + 时间线附包 + 多 snapshot
  - 父 `DBAgent` promote 主审
- 检查 Part 4 是否坚持：
  - 子代播种只进 `ICMA`
  - 同父交换必须显式批准
  - 不同父节点子树硬隔离
- 检查 Part 5 是否坚持：
  - event-level checkpoint
  - override 不改 raw truth
  - debug/admin 不开放真相写口
- 检查 Part 6 是否把：
  - `core_agent -> rax.cmp -> cmp-runtime -> five runtimes`
  真正串起来

## 不建议做的事情

- 不要让 worker 直接改主线程独占文件
- 不要把同父平级交换写成“默认互通”
- 不要把时间线附包退化成纯 git readback
- 不要为了省事，把所有 checkpoint 做成粗粒度角色快照
- 不要把五个 agent 做回一个大 runtime 里的角色分支

## 推荐多智能体拓扑

### 主线程

- 数量：`1`
- 模型：`gpt-5.4-high`
- 责任：
  - 高冲突文件集成
  - 跨 Part 依赖仲裁
  - 最终联调、验收、回归

### 二层 lead

- 数量：`6`
- 默认模型：`gpt-5.4-high`
- ownership：
  - `Part1 Lead`
  - `Part2 Lead`
  - `Part3 Lead`
  - `Part4 Lead`
  - `Part5 Lead`
  - `Part6 Lead`

### 三层 worker

- 建议：`8-16`
- 默认模型：
  - 普通编码 / 测试 / 协议实现：`gpt-5.4-high`
  - 轻量文档 / fixture / readback：`gpt-5.4-medium`
  - 复杂状态机 / recovery / lineage 权限冲突：`gpt-5.4-xhigh`

## 联调义务

任何 Part 都不能只交“单文件完成”。

最低要求：

- 单 Part 自测
- 跨 Part 契约回读
- 至少一次联调
- 一次 end-to-end smoke

## 一句话收口

这包任务不是去“补五个 prompt”。

它是要把五个 agent 真正变成：

- 有 runtime
- 有状态
- 有 checkpoint
- 有角色边界
- 有交付链
- 能被后续 fork / 拆分 / 定制
