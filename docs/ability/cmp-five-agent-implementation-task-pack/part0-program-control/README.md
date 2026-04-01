# Part 0 / Program Control

状态：五-agent 实施编排层。

## 当前目标

- 冻结五个角色边界
- 定义共享事件和共享对象
- 固定高冲突文件政策
- 定义放行顺序

## 这一部分为什么必须主线程独占

这里决定的是：

- 五个 agent 的共享协议
- 跨 Part 契约
- 高冲突写集
- 总装配入口

白话：

- 这部分一旦乱了，后面的并发编码就会互相撞坏

## 主线程必须守住

- `runtime.ts`
- `runtime.test.ts`
- `cmp-facade.ts`
- `cmp-runtime.ts`
- 总包 `README`

## 推荐子任务

### P0-1 / 冻结共享事件与共享对象

- 固定五个 agent 之间的事件命名与主对象边界
- 至少冻结：
  - ingress material
  - candidate commit / review ref
  - checked result
  - promote request
  - context package family
  - delivery receipt
  - checkpoint record
  - override audit

### P0-2 / 冻结冲突文件与 ownership

- 明确主线程独占文件
- 明确每个 Part 的默认写集
- 明确 worker 不得碰的高冲突入口

### P0-3 / 冻结波次放行规则

- 固定 Wave 0-4 的依赖关系
- 明确什么条件下能从一波进入下一波

### P0-4 / 冻结总验收门

- 固定 five-agent-ready gate
- 固定联调回归最小集合

## 建议多智能体编组

- `Part0 Lead`
  - 模型：`gpt-5.4-high`
- `Protocol Reviewer`
  - 模型：`gpt-5.4-xhigh`
  - 只做协议冲突审阅，不直接改主线程文件

## 输出物

- 冻结后的共享协议文档
- 主线程写集与 Part 写集表
- 波次放行表
- 最终验收门说明

## 本部分最低完成定义

- 五个 agent 的边界说明无冲突
- 三条运行流无冲突
- 跨父隔离、同父平级交换纪律固定
- role checkpoint / override 审计策略固定
- 父 `DBAgent` promote 主审这一点被全包共享采用

## 本部分验收检查

- Part 1-6 的 lead 都能据此切出不冲突写集
- 主线程能够据此拒绝越界改动
- 后续 Part 文档与这里没有互相矛盾
