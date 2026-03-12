# Praxis Memory

这个目录是仓库内的长期记忆层，用来保存重启过程中的约束、架构结论、工作脉络和阶段性决定。

目标很简单：

- 让后续 agent 不必只靠 `AGENTS.md` 理解项目。
- 让架构思考、决策依据和执行上下文可以持续回读。
- 让多人并行协作时，能更快知道“我们为什么这么做”。

## 建议使用方式

1. 开工前先读 [current-context.md](/home/proview/Desktop/Praxis_series/Praxis/memory/current-context.md)。
2. 遇到稳定约束或平台方向，写进 `architecture/`。
3. 遇到需要长期保留的取舍，写进 `decisions/`。
4. 每完成一个阶段性动作，把执行事实记进 `worklog/`。

## 目录说明

- `current-context.md`：当前最重要的方向、约束和近期重点。
- `architecture/`：系统边界、模块关系、平台策略。
- `decisions/`：偏 ADR 风格的长期决策记录。
- `worklog/`：按时间记录的实施过程和关键变更。
