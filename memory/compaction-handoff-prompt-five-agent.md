# CMP Five-Agent Handoff Prompt

下面是一份给压缩上下文后的新会话直接使用的 handoff prompt。

你可以在压缩后把下面整段直接发给新的模型：

---

当前唯一目标是继续在 `/home/proview/Desktop/Praxis_series/Praxis` 的 `cmp/mp` 分支上推进 `CMP` 五个 agent 的设计与实施准备。

请先读取并对齐下面这些文件：

- [memory/current-context.md](/home/proview/Desktop/Praxis_series/Praxis/memory/current-context.md)
- [docs/ability/44-cmp-five-agent-implementation-outline.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/44-cmp-five-agent-implementation-outline.md)
- [docs/ability/cmp-five-agent-implementation-task-pack/README.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/cmp-five-agent-implementation-task-pack/README.md)
- [docs/ability/cmp-five-agent-implementation-task-pack/part0-program-control/README.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/cmp-five-agent-implementation-task-pack/part0-program-control/README.md)
- [docs/ability/cmp-five-agent-implementation-task-pack/part1-icma-and-ingress-runtime/README.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/cmp-five-agent-implementation-task-pack/part1-icma-and-ingress-runtime/README.md)
- [docs/ability/cmp-five-agent-implementation-task-pack/part2-iterator-and-checker-runtime/README.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/cmp-five-agent-implementation-task-pack/part2-iterator-and-checker-runtime/README.md)
- [docs/ability/cmp-five-agent-implementation-task-pack/part3-dbagent-and-package-runtime/README.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/cmp-five-agent-implementation-task-pack/part3-dbagent-and-package-runtime/README.md)
- [docs/ability/cmp-five-agent-implementation-task-pack/part4-dispatcher-and-lineage-delivery/README.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/cmp-five-agent-implementation-task-pack/part4-dispatcher-and-lineage-delivery/README.md)
- [docs/ability/cmp-five-agent-implementation-task-pack/part5-passive-flow-checkpoint-and-override/README.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/cmp-five-agent-implementation-task-pack/part5-passive-flow-checkpoint-and-override/README.md)
- [docs/ability/cmp-five-agent-implementation-task-pack/part6-final-integration-and-five-agent-gates/README.md](/home/proview/Desktop/Praxis_series/Praxis/docs/ability/cmp-five-agent-implementation-task-pack/part6-final-integration-and-five-agent-gates/README.md)

当前已经确认的关键设计结论：

1. 五个 agent 为：
   - `ICMA`
   - `Iterator`
   - `Checker`
   - `DBAgent`
   - `Dispatcher`
2. 五个 agent 第一版按“强隔离、未来可进程化”路线设计。
3. 五个 agent 都应有自己的 `Agent_Loop_Runtime`。
4. 第一条正式主线先做主动链：
   - `ICMA -> Iterator -> Checker -> DBAgent -> Dispatcher`
5. `ICMA` 是输入内容管理 agent，默认做中等语义块整理，可挂受控 `system fragment`，走规则生成片段路线。
6. `Iterator` 负责推进到可审查状态，不负责最终 truth 裁决。
7. `Checker` 负责增删拆合并裁决，优先看任务相关性；跨层 promote 默认由直属父节点拍板。
8. `DBAgent` 主产物是 `ContextPackage`，附产物是 `Task` 级 `Skill Snapshot`；二者关系是 package 为主、snapshot 为附属引用。
9. `Dispatcher` 负责主 agent 回填、子 agent 播种、同父平级受控交换，delivery 回执至少做到：
   - `delivered`
   - `acknowledged`
10. 同父平级可交换，但必须先经直属父节点批准，且走高信噪比可消费通道。
11. 不同父节点子树默认硬隔离。
12. active/passive 默认混合常开；被动请求第一版默认由 `DBAgent` 直接接单，再由 `Dispatcher` 送回。
13. 每个角色都允许 checkpoint / recovery。
14. 每个角色都允许 human override，但必须强审计。
15. debug/admin 直达角色时默认允许：
   - `pause`
   - `resume`
   - `retry`
   - `rebuild`
16. 五个 agent 的能力面走 `TAP` 角色差异化强控。

当前仓库状态补充：

- `CMP` 非五-agent 公共底座已经基本收口。
- `core_agent -> rax.cmp -> cmp-runtime -> shared infra` 主链已经可运行。
- `section-first`、`DB-first + git rebuild fallback`、`MQ delivery truth`、`recovery reconciliation` 都已进入主链。
- 当前还有 TAP 侧未提交文档在工作区里，不要误卷入五-agent提交。
- `.parallel-worktrees/` 是临时目录，提交前必须排除。

接下来的工作顺序应当是：

1. 继续问答，把剩余五-agent细节钉死
2. 持续补 `44-cmp-five-agent-implementation-outline.md`
3. 基于 task pack 拆细正式任务清单
4. 再开始五个 agent 的正式代码实现

要求：

- 使用中文
- 不要跳回 `CMP` 非五-agent 公共底座
- 不要把 TAP 文档脏改动误当成五-agent主线代码
- 优先维持五个角色的强隔离和未来可进程化边界

---
