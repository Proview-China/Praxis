# CMP Five-Agent Implementation Outline

状态：活文档 / 初版总纲。

更新时间：2026-03-25

## 这份文档的定位

这不是最终冻结稿。

这份文档的用途是：

- 先把 `CMP` 五个 agent 的实现骨架落下来
- 把当前已经问清楚的设计结论固定住
- 给后续继续提问、继续补充、继续改动留下稳定入口

一句白话：

- 这是一份“可以不断往里填”的总纲
- 不是一次写死的规格书

## 当前阶段结论

`CMP` 非五-agent 公共底座已经基本收口。

当前最合理的下一阶段是：

- 开始五个 `CMP` agent 本身的实现设计
- 先固定角色边界、运行时边界、主链职责
- 再拆任务清单和正式落代码

## 当前唯一目标

在不破坏现有 `core_agent -> rax.cmp -> cmp-runtime -> shared infra` 主链的前提下，
把 `CMP` 的五个 agent 设计成：

- 强隔离
- 未来可进程化
- 可 fork 二次开发
- 可通过 `TAP` 做角色差异化能力治理
- 能同时支撑：
  - 主动治理链
  - 被动历史查询链
  - 父子播种链

## 先说当前已确认的实现方向

### 1. 五个 agent 的实现形态

当前确认：

- 五个 agent 第一版按“强隔离、未来可进程化”路线设计
- 每个 agent 都应有自己的 `Agent_Loop_Runtime`
- 不把五个 agent 做成一个大 runtime 里的 if-else 角色集合

白话：

- 现在就按将来能拆出去的方式写
- 哪怕第一版仍然在同一个仓库和同一个系统里组装

### 2. 五个 agent 的名单

当前固定为：

1. `ICMA`
2. `Iterator`
3. `Checker`
4. `DBAgent`
5. `Dispatcher`

### 3. 第一条正式主线

当前确认先实现：

- 主动主线

顺序固定为：

1. `ICMA`
2. `Iterator`
3. `Checker`
4. `DBAgent`
5. `Dispatcher`

但这不表示忽略：

- 被动历史查询链
- 父子播种链

这两条链仍要在第一版保留清晰接缝。

## 本轮新增冻结决策

这一轮问答之后，下面这些点可以先视为第一版冻结共识。

### 1. `ICMA`

- 默认按“任务意图”切成中等语义块
- 默认状态机：
  - `capture -> chunk-by-intent -> attach-fragment -> emit`
- 受控 `system fragment` 只允许三类：
  - 任务约束
  - 风险提醒
  - 流程纪律
- `system fragment` 默认按任务阶段持续生效，直到显式撤销
- `ICMA` 不直接拿 `cmp/*` 线 git 写能力

### 2. `Iterator`

- 第一版以 `commit` 作为最小可审查单元
- 默认状态机：
  - `accept-material -> write-candidate-commit -> update-review-ref`
- `Iterator` 是 git 主写角色
- 第一版不以 `PR` 作为最小推进单元

### 3. `Checker`

- 默认状态机：
  - `accept-candidate -> restructure -> checked -> suggest-promote`
- `checked` 与 `suggest-promote` 第一版硬分离
- `Checker` 可以做有限 git 修正
- 但不取代 `Iterator` 的 git 主推进职责

### 4. `DBAgent`

- 默认状态机：
  - `accept-checked -> project -> materialize-package -> attach-snapshots -> serve-passive`
- `CMP DB` 的结构化写权限第一版只给 `DBAgent`
- `ContextPackage` 是主载体
- `Skill Snapshot` 走“单主包、多附属 snapshot”组织方式
- `ContextPackage` 第一版默认偏：
  - 任务现场包
- 但同时必须认真维护：
  - 历史时间线包
- 二者关系第一版固定为：
  - 现场主包 + 时间线附包

### 5. `Dispatcher`

- 默认状态机：
  - `route -> deliver -> collect-receipt -> timeout-handle`
- 子节点播种默认只进子节点 `ICMA`
- 同父平级交换默认只走瘦交换包
- 瘦交换包默认内容偏：
  - 任务相关变更
  - 依赖提示
- 同父平级交换第一版必须有直属父节点“显式一次性批准”

### 6. 主被动链与治理边界

- 被动请求默认：
  - `DBAgent` 直接接单
  - `Dispatcher` 负责送回
- 被动返回默认以：
  - `ContextPackage`
  为主载荷
- 五个角色第一版都允许：
  - checkpoint
  - recovery
  - human override
- checkpoint 第一版按：
  - 事件级
  实现
- human override 默认只能改：
  - 运行控制态
  - 裁决状态
- 不允许直接改 raw truth
- `debug/admin` 默认只开放：
  - `pause`
  - `resume`
  - `retry`
  - `rebuild`
- 不开放真相写口

### 7. 与 `TAP` 的关系

- 五个角色都允许直接向 `TAP` 申请额外能力
- 但必须按角色差异化最小权限面严格审批
- 这部分实现非常依赖：
  - 角色级提示词工程
  - role-specific capability contract

## 五个 agent 的当前职责初稿

### 1. `ICMA`

全称：

- 输入内容管理 agent

当前职责初稿：

- 直接接住 `core_agent` 的上下文输入和运行历史
- 把原始材料整理成“可进入下一步”的中等语义块
- 作为 `CMP` 的 ingress controller
- 负责：
  - 初步上下文整形
  - 受控 `system fragment`
  - `assistant/context` 装配层输入

当前明确不做：

- 不负责最终历史裁决
- 不负责最终 DB projection
- 不负责最终 promote 拍板
- 不负责重度增删拆合

当前确认的权限边界：

- `ICMA` 可以挂受控 `system fragment`
- 不默认全权重写根 `system`
- `system fragment` 第一版走“规则生成片段”路线
- 默认只生成：
  - 任务约束
  - 风险提醒
  - 流程纪律
- 默认按任务阶段持续生效，直到显式撤销
- 默认按任务意图切块

当前状态机初稿：

- `capture`
- `chunk-by-intent`
- `attach-fragment`
- `emit`

### 2. `Iterator`

当前职责初稿：

- 把 `ICMA` 整理好的材料推进成 git 工作流动作
- 负责：
  - `commit`
  - `branch`
  - `PR`
  - `merge`
  - `ref` 推进
- 把材料推进到“可审查”状态

当前明确不做：

- 不负责最终 truth 裁决
- 不负责 DB 物化
- 不负责 package 分发

当前已确认边界：

- `Iterator` 的边界是“推进到可审查”
- 不只是机械写 git
- 但也不一路串到 `DBAgent`
- 第一版以 `commit` 作为最小可审查单元
- `Iterator` 是 `cmp/*` 线 git 主写角色

当前状态机初稿：

- `accept-material`
- `write-candidate-commit`
- `update-review-ref`

### 3. `Checker`

当前职责初稿：

- 对 git 侧 candidate / checked-ready 状态做治理
- 允许做：
  - 增删拆合
  - checked 裁决
  - 是否建议向父层提请 promote
- 负责判断：
  - 哪一版现在能信
  - 哪一版可进入 checked
  - 哪一版值得提交父层拍板

当前已确认标准：

- 第一排序标准更偏 `任务相关性`
- 不是纯静态去噪器
- 但仍然必须保留：
  - 可追溯性
  - 可复现性

当前 promote 纪律：

- 子节点可以治理自己这一层
- 但跨层 promote 默认由直属父节点拍板
- 父节点内部可以再委托自己的治理角色处理
- 这属于父层内部再分工，不属于子节点越级

当前状态机初稿：

- `accept-candidate`
- `restructure`
- `checked`
- `suggest-promote`

当前父层内部委托结论：

- 第一版默认由父层 `DBAgent` 主审 promote
- 不是父层 `Checker` 主审
- 这表示父层 `Checker` 更偏：
  - 候选重整
  - checked 辅助裁决
  - promote 取证协助

### 4. `DBAgent`

当前职责初稿：

- 消费 `Checker` 已认可的结果
- 负责：
  - projection 维持
  - `ContextPackage` 物化
  - `Skill Snapshot` 生成
  - 高信噪比状态缩影输出

当前主产物：

- `ContextPackage`

当前附产物：

- `Task` 级 `Skill Snapshot`

当前确定的关系：

- `ContextPackage` 是主载体
- `Skill Snapshot` 作为附属对象或引用挂在 package 上
- 一个 package 默认允许挂多个 `Task` 级 snapshot

当前更新策略：

- `Skill Snapshot` 随 `checked / promoted` 增量更新
- 不等批处理

当前模式确认：

- `DBAgent` 既支持主动物化
- 也支持被动按需产包
- 第一版按“双轨并行”处理
- 第一版仍以任务现场包为主
- 但必须同步维护历史时间线附包
- `CMP DB` 结构化写权限第一版只给 `DBAgent`

当前状态机初稿：

- `accept-checked`
- `project`
- `materialize-package`
- `attach-snapshots`
- `serve-passive`

### 5. `Dispatcher`

当前职责初稿：

- 把 `ContextPackage` 回填给主 agent
- 把 package 播给子 agent
- 管理交付确认
- 把粗糙任务描述翻译成可直接消费的 package

当前回执级别：

- 至少支持：
  - `delivered`
  - `acknowledged`

当前明确不做：

- 不负责下游是否继续裁剪
- 不负责下游如何二次消费
- 不应成为任意广播器

当前补充纪律：

- 子节点播种默认只进子节点 `ICMA`
- 同父平级交换默认走瘦交换包
- 同父交换必须先有直属父节点显式一次性批准

当前状态机初稿：

- `route`
- `deliver`
- `collect-receipt`
- `timeout-handle`

## 三条运行流当前草图

### 一、主动治理链

当前草图：

1. `core_agent` 正常运行
2. `ICMA` 接住上下文与历史
3. `Iterator` 推进 git 工作流
4. `Checker` 做增删拆合并给出 checked 结果
5. `DBAgent` 产出：
   - `ContextPackage`
   - `Skill Snapshot`
6. `Dispatcher` 把结果：
   - 回给主 agent
   - 或播给子 agent

### 二、被动历史查询链

当前草图：

1. 主 agent 或上层发起历史请求
2. 第一版默认由 `DBAgent` 直接接单
3. `DBAgent` 选择合适 projection / package / snapshot
4. `Dispatcher` 负责送回

当前补充纪律：

- `requestHistory` 仍受 `CMP` 总控制面约束
- 被动链不是绕开主动链的平行野路子

### 三、父子播种链

当前草图：

1. 父节点决定派生子任务
2. `DBAgent` / `Dispatcher` 形成高信噪比 package
3. 子节点 `ICMA` 接住种子
4. 子节点继续形成自己的主动治理链

当前确认：

- 第一版允许级联播种
- 但粒度必须严控
- 默认偏“高密度但任务定向”
- 不走极瘦启动
- 也不走近完整继承

## 同级交换与隔离纪律

当前确认：

- 不同父节点的子树：
  - 第一版硬隔离
  - 默认不共享 package / skill / DB 通道
- 同父平级：
  - 可以交换
  - 但必须先经直属父节点批准
  - 打开的是 `DBAgent` 的高信噪比可消费通道
  - 不是 raw history 裸连

一句白话：

- 同父可控共享
- 异父默认断开

## 五个 agent 的 runtime 与状态模型

### 1. 状态模型

当前确认：

- 五个 agent 第一版都走“长期有状态”
- 每个 agent 都有自己的 loop state
- 每个 agent 都有自己的 checkpoint / recovery 入口
- checkpoint 第一版按事件级设计

### 2. 恢复策略

当前确认：

- 第一版默认走“角色级恢复”
- 某个角色出错时，优先恢复该角色 runtime
- 不轻易对整个 `CMP` 池做全局恢复

### 3. checkpoint 纪律

当前确认：

- 每个角色都允许 checkpoint
- 但具体 checkpoint 粒度可按角色不同

## `ContextPackage` / `Skill Snapshot` 的当前原则

### 1. `ContextPackage`

第一版要求：

- 高信噪比
- 可直接消费
- 短活跃
- 可回读
- 可重建
- 主体偏任务现场包

不把它当作永久大对象长期囤积。

同时补充：

- 历史时间线也必须是正式产物
- 但第一版不把二者并成一个永远在线的大统一包

### 2. `Skill Snapshot`

第一版要求：

- 默认是 `Task` 级 snapshot
- 不追求全局百科
- 同时服务：
  - 主 agent 回填
  - 子 agent 播种

### 3. 二者关系

当前确认：

- `ContextPackage` 为主
- `Skill Snapshot` 作为 package 内的附属引用或附属对象
- 包族关系第一版固定为：
  - 现场主包 + 时间线附包 + 多个 task snapshot

## 和 `core_agent` 的接口关系

当前确认走：

- 混合代理接口

含义：

- 正常外部仍然主要看到一个 `CMP` 总接口
- 但在 `debug / admin` 模式下，允许直达单个角色

当前默认开放的角色级管理动作：

- `pause`
- `resume`
- `retry`
- `rebuild`

当前明确不开放：

- 直接裸改核心真相
- 也不开放完整角色控制台

## 人工 override 当前原则

当前确认：

- 每个角色 runtime 都允许人工 override
- 但必须强审计

第一版最低审计要求：

- actor
- reason
- scope
- timestamp
- before / after state
- 关键差异摘要

## 五个 agent 与 `TAP` 的关系

当前确认：

- 五个 agent 第一版走“角色差异化强控”的能力矩阵
- 不搞统一大权限面
- 每个角色只拿最小必要能力
- 超出部分继续走 `TAP` 审批 / 供给

白话：

- 一开始就按角色差异化控权限
- 不走“先放开再收”

## 当前 DB 设计在五个 agent 里的落点

当前确认：

- `CMP` 继续使用传统数据库
- 一个项目一个 DB
- 第一版按：
  - 项目共享表
  - 角色视图
  落地

不是：

- 每个角色一套完全独立 DB
- 也不是全都挤在没有边界的共享表里

## 当前还没有问完的重点

下面这些仍应继续追问并补进本总纲：

### 1. 五个 agent 各自的状态机阶段

例如：

- `ICMA` 的 ingress stage
- `Iterator` 的 git progression stage
- `Checker` 的 checked / suggest-promote stage
- `DBAgent` 的 package / snapshot materialization stage
- `Dispatcher` 的 delivery / ack stage

### 2. 五个 agent 各自的输入 / 输出事件模型

例如：

- 谁消费 `Section`
- 谁消费 `StoredSection`
- 谁产出 `CheckedSnapshot`
- 谁产出 `ContextPackage`
- 谁更新 `Skill Snapshot`

### 3. 角色级能力矩阵

需要继续问清：

- 哪些角色默认拥有哪些只读能力
- 哪些角色默认有写仓库能力
- 哪些角色可直接申请 `TAP`
- 哪些角色默认不能碰高外部性动作

当前已经明确的一部分：

- `ICMA` 默认不拿 git 写能力
- `Iterator` 默认拿 git 主写能力
- `Checker` 默认拿有限 git 修正能力
- `DBAgent` 默认拿 `CMP DB` 结构化主写能力
- 五个角色都可经 `TAP` 申请额外能力，但要按角色最小权限面审批

### 4. `system fragment` 的规则生成边界

需要继续问清：

- 谁能生成
- 谁能审
- 谁能挂
- 哪些模板永远不可注入

当前已经明确的一部分：

- 默认只允许约束 / 风险 / 流程三类 fragment
- 不允许自由策略改写根 `system`
- 默认由 `ICMA` 生成并挂载

### 5. 父层内部委托 promote 的具体机制

需要继续问清：

- 父层委托给谁
- 是否允许父层内部二次 checker
- 是否允许委托给父层自己的 `DBAgent`
- 哪些情况下必须回到父层主治理口

当前已经明确的一部分：

- 第一版默认由父层 `DBAgent` 主审 promote
- 父层 `Checker` 仍可做取证和前置重整
- 但最终 promote 仍属于父层治理口，不属于子节点越级

## 当前最小完成定义

只有同时满足下面这些条件，才算五个 agent 的第一版设计总纲足够进入任务拆解：

1. 五个角色边界明确
2. 三条运行流明确
3. `ContextPackage / Skill Snapshot / Section` 关系明确
4. runtime / checkpoint / recovery 边界明确
5. role -> capability 矩阵至少有初版
6. human override 与 audit 纪律明确

## 当前下一步

这份总纲现在已经可以继续往里填。

后续工作顺序建议：

1. 继续问答，把剩余细节钉死
2. 把新增结论继续补进本总纲
3. 再写正式任务清单
4. 再压缩上下文
5. 然后正式开始五个 agent 的实现
