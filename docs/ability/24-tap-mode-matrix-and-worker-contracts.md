# TAP Mode Matrix And Worker Contracts

状态：冻结设计草案 v1，用于把 `TAP` 从“第一版控制面”推进到“可用控制面”。

更新时间：2026-03-19

## 这份文档解决什么问题

当前 `TAP` 已经证明：

- `raw_agent_core` 可以接入控制面
- capability request 可以走 review / provision / safety
- 第一版 runtime assembly 已经成立

但还没有解决下面这些真正会影响使用体验的问题：

1. 不同用户到底该用哪种模式。
2. reviewer 到底能拍什么板，不能做什么事。
3. provisioner 到底能造什么，不能越什么权。
4. 人类审批在什么模式下必须出现。
5. 风险提示怎样用白话文直接告诉用户。

一句白话：

- 这份文档不是在讨论“代码怎么写”
- 而是在冻结“谁有权做什么”

## 五种运行模式

### 1. `bapr`

全称：

- `bypass-all-permission-and-review`

推荐代号：

- `bapr`

定义：

- reviewer 不再承担审批职责
- 所有请求默认放行
- reviewer 在这个模式下只承担“向 provisioner 传话”和“记录发生了什么”的职能

说明：

- 这是一个显式高风险模式
- 必须由用户手动开启
- 必须配套免责说明和多次确认

第一版约束：

- `bapr` 不做常规审查
- 文档层明确标记为“用户自负风险”

### 2. `yolo`

定义：

- 默认高放行
- 保留高危行为拦截

目标用户：

- 高熟练开发者

行为原则：

- 增删改查默认放行
- 常规清理默认放行
- 明显危险动作才拦截

一句白话：

- `yolo` 不是没有 reviewer
- `yolo` 里的 reviewer 更像安全气囊

### 3. `permissive`

定义：

- 宽松审查模式

目标用户：

- 大多数开发者默认推荐

行为原则：

- 常规开发动作默认放行
- 厚能力和高外部性行为进入 review
- reviewer 可以自动批准一部分请求

### 4. `standard`

定义：

- 标准审查模式

目标用户：

- 非科班用户默认推荐

行为原则：

- baseline 之外的大多数非只读行为都进入 review
- reviewer 可以批准
- 风险较高时默认转人工确认

### 5. `restricted`

定义：

- 严格审查模式

目标用户：

- 高安全、低信任、强治理场景

行为原则：

- baseline 之外的行为默认进入 review
- reviewer 不直接放行执行
- 需要人类批准后才能继续

设计要求：

- 等待状态必须留在 `TAP` 内部
- 不入侵 `core-agent loop`
- `agent loop` 只看到 `deferred` 或 `waiting_human`

## 风险等级

第一版统一三档：

- `normal`
- `risky`
- `dangerous`

### 1. `normal`

白话：

- 正常开发和正常读取

典型例子：

- 读代码
- 读文档
- repo 内小范围新建或修改
- 运行常规测试
- 运行常规构建
- 使用已存在的低风险 capability

### 2. `risky`

白话：

- 可能有明显副作用，但通常还能解释清楚

典型例子：

- 新装工具
- 更新已有 capability
- 配置 MCP
- 外网下载依赖
- repo 内大范围改写
- 大规模删除工作区内容
- 工作区外读写
- 需要更高 shell 权限的动作

### 3. `dangerous`

白话：

- 一旦执行错，后果可能很重

典型例子：

- 毁灭性删除
- 对关键目录执行破坏性 shell
- 明显越界的工作区外写入
- 组合高危系统命令
- 高风险 computer use
- 已经表现出异常意图的请求

## 模式与风险矩阵

下面这张矩阵是第一版冻结语义。

| 模式 | `normal` | `risky` | `dangerous` |
| --- | --- | --- | --- |
| `bapr` | 默认放行 | 默认放行 | 默认放行 |
| `yolo` | 默认放行 | 默认放行或降权放行 | 默认拦截 |
| `permissive` | 默认放行 | reviewer 审查，可自动批准/拒绝/转人工 | 默认拒绝或转人工 |
| `standard` | baseline 直接放行，其余进入 reviewer | reviewer 审查，通常要明确用户确认 | 默认转人工 |
| `restricted` | baseline 放行，其余进入 reviewer + human gate | human gate | human gate |

## 用户侧白话提示要求

所有被 reviewer 拦下或升级人工的请求，都必须生成一段用户能立即看懂的白话说明。

最少包括：

- 这次想做什么
- 为什么被判为 `normal / risky / dangerous`
- 如果执行，可能造成什么后果
- 如果不执行，当前任务会受到什么影响
- 用户现在可以点什么按钮

用户不应该看到只有工程术语的风险报告。

用户应该能在几秒内看懂：

- 这事危险不危险
- 值不值得继续
- 继续了会发生什么

## Reviewer Worker Contract

### 定位

- reviewer 是 `pool worker agent`
- reviewer 不是主任务 agent
- reviewer 不是执行器
- reviewer 不是 builder

### reviewer 负责什么

- 理解 `AccessRequest`
- 结合 profile、mode、inventory、项目摘要和记忆摘要做判断
- 输出结构化 decision vote
- 在需要时把请求转给 provisioner 或人类

### reviewer 不负责什么

- 不直接执行 capability
- 不直接 dispatch grant
- 不直接写代码
- 不直接安装依赖
- 不直接修改系统
- 不直接替主 agent 继续做任务

### reviewer 输入

- `AccessRequest`
- `CapabilityProfile`
- `mode`
- `risk level`
- `inventory snapshot`
- `project summary`
- `memory summary`
- `user intent summary`
- `rule summary`

### reviewer 输出

- `decision`
- `reason`
- `risk_level`
- `risk_notes`
- `recommended_scope`
- `recommended_constraints`
- `required_followups`

### reviewer 默认能力预算

第一版 reviewer 只允许：

- 读代码
- 读文档
- 读项目摘要
- 读记忆摘要
- 可选只读搜索摘要

第一版 reviewer 不允许：

- 写文件
- 改代码
- shell 写操作
- 安装依赖
- 外部高危 MCP
- computer use

### reviewer bootstrap lane

reviewer 不能同步递归走它正在服务的同一条审批链。

第一版要求：

- reviewer 运行在独立的 bootstrap lane
- reviewer 只看序列化后的 aperture
- reviewer 只回结构化 vote

## Provisioner Worker Contract

### 定位

- provisioner 是 `pool worker agent`
- provisioner 是 builder，不是主任务 agent
- provisioner 不决定是否批准执行

### provisioner 负责什么

- 根据 `ProvisionRequest` 构建缺失 capability
- 产出标准化 artifact bundle
- 产出 smoke / health 结果
- 产出 usage 文档或 skill
- 交回 TAP 等待 activation 与后续决策

### provisioner 不负责什么

- 不直接批准自己的构建结果
- 不直接决定是否让主 agent 使用
- 不直接替主 agent 完成原任务

### provisioner 输入

- `ProvisionRequest`
- `target capability spec`
- `inventory snapshot`
- `allowed build scope`
- `allowed side effects`
- `existing sibling capabilities`
- `project constraints`
- `reviewer instructions`

### provisioner 输出

- `tool artifact`
- `binding artifact`
- `verification artifact`
- `usage artifact`
- `build summary`
- `activation payload`
- `replay recommendation`

### provisioner 默认能力预算

第一版分成两层：

- `bootstrap provisioner`
- `extended provisioner`

`bootstrap provisioner` 允许：

- 读代码
- 读文档
- repo 内写文件
- 受限 shell
- 运行测试
- 生成 skill/doc

`extended provisioner` 允许：

- 安装依赖
- 配置 MCP
- 网络下载
- 更厚的系统级能力

第一版默认：

- provisioner 默认运行在 `bootstrap` 层
- 只有 reviewer 或上层策略批准后，才能提升到 `extended`

## 当前阶段的 context 说明

当前 reviewer / provisioner 的视角，是阶段性占位，不代表最终治理视角。

第一版文档先约定：

- reviewer 默认可以看到 `agent_core` 侧提供的全部摘要上下文
- 这是当前阶段的 placeholder
- 未来将由 `memory_pool`、governance layer、packaging layer 提供更精细 aperture

## 当前冻结结论

这一版先冻结下面这些共识：

- `TAP` 使用五种模式：`bapr / yolo / permissive / standard / restricted`
- 风险等级使用三档：`normal / risky / dangerous`
- reviewer 只审，不执行
- provisioner 只造，不批准
- `bapr` 下 reviewer 退化为传话筒
- 其他四种模式下 reviewer 都可能拒绝请求
- 人类审批要给用户输出白话风险说明
- `restricted` 的等待逻辑留在 `TAP` 内部，不打断 `core-agent loop`
