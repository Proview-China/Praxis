## 1. 运行时模型与契约

- [x] 1.1 为注册工具与执行记录补齐 `tool_kind`，并在序列化、provider wrapper 与查回路径中保持一致
- [x] 1.2 为执行请求与策略模型补齐 hook 生命周期、POSIX 沙盒与 fixture adapter 所需字段

## 2. Builtin 执行器

- [x] 2.1 实现 macOS / Linux 的 `shell` POSIX 执行器，返回 `stdout/stderr/exit_code` 与审计证据
- [x] 2.2 实现 macOS / Linux 的 `code` POSIX 执行器，支持最小运行时选择、临时文件与产物返回
- [x] 2.3 实现 `web/computer/skills/mcp/hooks` 的最小 builtin / fixture 执行路径与结构化不支持错误

## 3. Hook 生命周期与接口接入

- [x] 3.1 在主工具执行前后接入 `before_tool` / `after_tool` hook 链，并加入递归保护与阻断语义
- [x] 3.2 如有需要，补充或调整 C API 与 Node binding，使统一工具执行路径能够暴露新增字段与行为

## 4. 验证

- [x] 4.1 为不同 `tool_kind`、fixture 执行器、POSIX 沙盒路径与平台不支持分支补单元测试
- [x] 4.2 为 hook 放行、hook 阻断、after hook 失败保留主结果、hook 递归保护补单元测试
