# Prompt Assembly Architecture For Praxis

状态：活文档 / 第二稿。

更新时间：2026-04-07

## 目标

把 Praxis 的九个 agent 提示词工程，做成像 Codex 一样有明确治理边界的分层系统，而不是“每个 agent 各写一篇超长 prompt”。

这个目标包含两部分：

- 把预制提示词做成可治理、可版本化、可装配的固定层
- 把动态 `user_prompt` 做成受控注入层，而不是自由拼贴层

## 先说结论

从本地 `codex-0.118` 源码看，Codex 的真实装配方式不是“单个 prompt 文件全包”。

真实结构更接近：

1. `base_instructions`
2. 模型专属增量
3. 每 turn 的 `developer` 动态增量
4. 每 turn 的 `contextual user` 动态增量

对 Praxis 的启示是：

- `system_prompt` 应对应长期底座
- `development_prompt` 应对应运行制度与控制域规则
- `user_prompt` 应对应当前任务现场与动态包

## Codex 0.118 的真实装配事实

### 一、静态底座

Codex 的长期底座来自：

- `/home/proview/Desktop/codex-0.118/codex-rust-v0.118.0/codex-rs/core/prompt.md`

它被装入：

- `base_instructions`

关键入口：

- `/home/proview/Desktop/codex-0.118/codex-rust-v0.118.0/codex-rs/core/src/models_manager/model_info.rs`

### 二、模型专属增量

Codex 会对部分模型叠加：

- `instructions_template`
- `instructions_variables`
- personality 文本增量

这说明模型层可以有“在长期底座之上的第二层固定增量”。

### 三、每 turn developer 层

Codex 在每个 turn 里，还会组装一层 `developer` 消息。

里面可能包含：

- policy / approval / sandbox 规则
- collaboration mode
- memory prompt
- apps / skills / plugins
- project docs
- commit trailer 要求

关键入口：

- `/home/proview/Desktop/codex-0.118/codex-rust-v0.118.0/codex-rs/core/src/codex.rs`

### 四、每 turn contextual user 层

Codex 还会组装一层 `contextual user` 消息。

里面可能包含：

- user instructions
- environment context
- 当前工作目录与运行环境信息

关键入口：

- `/home/proview/Desktop/codex-0.118/codex-rust-v0.118.0/codex-rs/core/src/context_manager/updates.rs`
- `/home/proview/Desktop/codex-0.118/codex-rust-v0.118.0/codex-rs/core/src/codex.rs`

## Praxis 的正式分层

Praxis 现在应明确采用四层治理模型，而不是模糊三层口头描述。

### Layer 0：Model Profile Layer

这一层不是 prompt 正文，而是模型配置层。

承载内容：

- 模型型号
- reasoning effort
- verbosity
- 角色级默认模型策略
- 某些模型特定的安全或输出约束开关

这一层不写业务 prompt 文本，但它决定后续 prompt 解释环境。

### Layer 1：System Prompt Layer

这是最稳定、最少变、最长期的文本层。

承载内容：

- agent 的长期身份
- 长期职责
- 长期禁止项
- 与外部控制面的根本关系
- 长期工作哲学

这一层应该尽量避免：

- 当前任务
- 当前路径
- 当前审批状态
- 当前上下文包
- 当前环境细节

一句白话：

- `system_prompt` 是宪法

### Layer 2：Development Prompt Layer

这是运行制度层。

承载内容：

- 当前运行制度
- 当前上下文纪律
- 当前验证纪律
- 当前能力/治理调用纪律
- 当前主链推进方式
- 当前阻塞处理动作树
- 与控制面交互的工作规程

这一层不是长期人格层，而是“这一代 runtime 的正式操作规程”。

一句白话：

- `development_prompt` 是制度和操作手册

### Layer 3：Contextual User Prompt Layer

这是动态注入层。

承载内容：

- 用户当前目标
- 当前仓库/路径/运行现场
- 当前 `CMP` 提供的任务包、背景包、时间线、checked snapshot
- 当前 `TAP` 提供的治理结论、能力状态、审批状态、handoff 状态
- 当前 `MP` 提供的拓扑信息或协作结构
- 当前具体要解决的问题与约束

这一层不应承载长期身份与制度，不应反向污染上两层。

一句白话：

- `user_prompt` 是本回合真实工作现场

## 为什么 Praxis 不能直接照抄 Codex

Codex 里有很多内容是宿主专属，不适合直接搬进 Praxis。

典型例子：

- `Codex CLI` 自我描述
- `apply_patch` 等具体工具名
- sandbox / approval mode 的产品级语义
- CLI renderer 的展示规则
- review mode / plan mode / js_repl 等宿主流程说明

Praxis 应吸收的是“工程行为原则”，而不是“Codex 壳层协议名”。

换句话说：

- 可迁移的是行为准则
- 不可迁移的是宿主耦合细节

## Praxis 的预制提示词治理规则

从现在开始，Praxis 的预制提示词不应再按“散文式草案”治理，而应按以下规则治理。

### 一、每个 agent 必须有 prompt pack

每个 agent 最终都应拥有一个正式 `prompt pack`，至少包含：

- `system_prompt`
- `development_prompt`
- `user_prompt schema`

其中：

- `system_prompt` 和 `development_prompt` 是预制层
- `user_prompt schema` 是动态注入协议

### 二、固定层必须版本化

每个预制层都应有明确版本号，例如：

- `core-system/v1`
- `core-development/v1`
- `tap-reviewer-system/v1`
- `cmp-dbagent-development/v1`

只要长期语义发生明显变化，就应升级版本，而不是静默改写。

### 三、固定层应尽量只做追加式演化

对于已经进入稳定工程装配的 prompt：

- 优先小范围追加
- 避免频繁推翻重写
- 禁止在没有版本升级记录的情况下静默改变核心职责

### 四、宿主耦合必须下沉

所有具体工具名、runtime 开关、协议细节、provider 兼容 hack，不应直接写进长期 `system_prompt`。

它们应尽量：

- 下沉到 runtime
- 下沉到 capability contracts
- 下沉到 `development_prompt`
- 或者下沉到动态 `user_prompt` 注入层

### 五、控制面纪律优先写在 development 层

与 `CMP / TAP / MP` 的正式运行纪律，应优先写进 `development_prompt`，而不是塞进 `system_prompt`。

因为它们属于：

- 当前制度
- 当前运行方式
- 当前控制面契约

而不属于 agent 的永久人格。

### 六、策略变化不应默认做成 core 人格模式

从 Codex 的 `collaboration_mode` 模板可以直接借到一个重要思想：

- 运行态策略变化不应该随意污染长期 prompt 本体

但在 Praxis 当前设计里，这个思想不应直接落成 `core-execute-mode / core-plan-mode` 这类显式人格切换。

更合适的做法是：

- `core` 保持单一主工态
- 策略差异主要来自：
  - 当前任务现场
  - TAP 的审批与治理窗口
  - 已挂载 skill / usage artifact
  - CMP / MP 路由出来的上下文或记忆包装物

一句白话：

- 运行态会变
- 但 `core` 本体不切人格

### 七、记忆与压缩协议应独立治理

Codex 把 memory policy 和 compaction handoff 做成独立模板，这一点非常值得借。

Praxis 后续也应把下面两类内容独立出来：

- `memory read policy`
- `compaction / handoff summary contract`

原因：

- 它们是 continuation 机制
- 不是角色人格文本
- 也不应该临时混入 user prompt

### 八、developer 注入应支持局部更新

Codex 的一个关键工程思想是：

- 不必每个 turn 重写全部长期层
- 可以对 developer / contextual 层做差量更新

Praxis 后续也应按这个方向设计：

- 长期层尽量稳定
- policy / environment / governance / context package / mounted skill set 支持局部更新
- 避免每回合把整套固定 prompt 全量重灌

## Praxis 的 user prompt 治理规则

Praxis 需要像 Codex 一样治理动态注入层，而不是让 user prompt 变成随意堆料。

### 一、user prompt 必须模块化

动态注入应拆成可审计块，而不是混成一大段自然语言。

建议至少拆成这些块：

1. `current_objective`
2. `workspace_context`
3. `cmp_context_package`
4. `mp_routed_package`
5. `task_specific_constraints`

### 二、user prompt 只承载当前回合现场

它不应承载：

- agent 的长期身份
- 长期制度
- 永久禁止项
- 与所有回合都通用的行为准则

这些必须留在 `system / development` 层。

### 三、CMP 与 TAP 注入必须显式命名来源

动态包不应以模糊自然语言方式注入。

应尽量让 agent 清楚知道：

- 哪些内容来自 CMP
- 哪些内容来自 TAP
- 哪些内容来自 MP
- 哪些内容来自用户
- 哪些内容只是环境上下文

### 四、动态包要支持局部更新

像 Codex 一样，Praxis 未来也应支持“只更新变动部分”，而不是每次把全部动态材料重新灌进去。

因此动态包设计时就应考虑：

- 哪些块高频变化
- 哪些块低频变化
- 哪些块应支持 diff/update

### 五、动态包必须避免反向污染固定层

动态 user prompt 不能悄悄改写：

- core 的长期身份
- development 的制度定义
- 角色的长期边界

动态层只能提供现场，不应重写宪法和制度。

### 六、动态 user prompt 应支持 provenance

每个动态块都应尽量带清楚来源。

至少要能区分：

- 来自用户
- 来自 CMP
- 来自 TAP
- 来自 MP
- 来自 workspace / environment

这能直接减少“动态层互相打架时模型乱猜”的概率。

### 七、动态 user prompt 应支持最小缺省

如果某个块缺失，不应逼模型脑补。

正确做法应是：

- 允许缺省块为空
- 让 agent 在较小可信范围内继续
- 或者拉对应控制面补齐

不要把“缺块”设计成“强迫模型补想象”。

### 八、skill / capability / governance 不应被强行揉进 user_prompt

按当前 Praxis 设计，更合适的分工是：

- 当前任务现场主要进 `user_prompt`
- 已挂载 skill / usage artifact 走独立注入层
- `TAP` 的治理窗口、pending action、审批结果走独立治理视图
- runtime / contract 保持真账本

这比把所有动态对象全揉进 `user_prompt` 更贴近真实架构。

## 建议的工程落地结构

Praxis 后续应逐步进入这种目录治理方式：

- 每个 agent 一份 `system_prompt`
- 每个 agent 一份 `development_prompt`
- 每个 agent 一份 `user_prompt schema`
- 再有一份总装配文档，定义注入顺序和 ownership

建议的装配顺序：

1. model profile
2. system prompt
3. development prompt
4. contextual user prompt

## 借 Codex 可以直接学的治理机制

如果只挑最值得直接学的 6 个机制，我建议保这些：

1. 长期底座与每 turn 动态层分离
2. 运行态策略变化通过外部控制面和注入层进入，而不是直接篡改长期人格
3. project docs / workspace policy 单独作为注入来源
4. memory / compaction 独立成 continuation protocol
5. developer 与 contextual user 的职责分离
6. 动态层支持局部更新和差量思维

## 对 `core` 的直接落点

这意味着 `core` 后续应至少拥有这些正式对象：

- `core-system/v1`
- `core-development/v1`
- `core-user-schema/v1`
- `core-skill-consumption-rules/v1`
- `core-memory-policy/v1`
- `core-compaction-handoff/v1`
- `tap-runtime-view/*`
- `tap-skill-mounts/*`
- `cmp-context-package/*`
- `mp-routed-package/*`

## 当前对 `core` 的直接结论

对 `core` 来说，当前最合适的推进顺序是：

1. 先冻结 `core system_prompt`
2. 再冻结 `core development_prompt`
3. 再设计 `core user_prompt schema`
4. 再补 `core` 的 skill-consumption / memory / compaction 治理
5. 再把同样方法复制到 `TAP` 三角色
6. 再复制到 `CMP` 五角色

## 当前开放问题

1. `user_prompt schema` 是否直接固定成 XML 风格块？
2. `CMP / TAP / MP` 的动态包是否要统一使用同一种 envelope 结构？
3. 是否要为九个 agent 统一提供一个最小公共 `development_prompt substrate`，再叠角色专属增量？
