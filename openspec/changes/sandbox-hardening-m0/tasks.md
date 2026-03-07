## 1. Sandbox policy 模型

- [x] 1.1 设计并落实统一 sandbox policy JSON 合约，覆盖目录、命令/运行时、超时、网络、输出与产物限制
- [x] 1.2 在 core 内统一解释并回显 policy snapshot，确保 UI 不承载安全决策逻辑

## 2. 执行控制

- [x] 2.1 为 `shell` 与 `code` 执行器实现超时控制，并区分 `timeout` 状态
- [x] 2.2 为执行器实现中断能力与 `interrupted` 状态，保证高风险执行可中止

## 3. 资源与边界治理

- [x] 3.1 实现网络访问开关、输出大小限制与产物数量限制，并对未支持限制显式告知
- [x] 3.2 强化 cwd/路径与副作用治理，确保越权访问会被阻断或记录

## 4. 对外暴露与验证

- [x] 4.1 在 core 结果中补齐完整 sandbox 审计面，并根据需要扩展 binding 层薄封装
- [x] 4.2 补充单元测试与 Node smoke test，覆盖 timeout、interrupt、network denied、裁剪与审计输出
