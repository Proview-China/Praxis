## 新增需求

### 需求:沙盒执行结果必须对 UI 暴露完整审计面
所有 sandbox 执行结果必须由 core 直接返回统一 JSON 结果，至少包含：执行状态、policy snapshot、执行器元数据、cwd、命令或 runtime、stdout/stderr/exit_code、产物清单以及错误原因。UI 只负责展示这些信息，禁止自己推断沙盒是否真的生效。

#### 场景:UI 展示一次 shell sandbox 结果
- **当** UI 调用 core 执行一次 shell sandbox
- **那么** core 必须返回足够用于展示和追踪的完整结果对象
- **那么** UI 不需要自行补算策略或审计字段

### 需求:绑定层必须是薄封装
Node binding 和其他绑定层在 sandbox 方向上必须保持薄封装，只做参数透传和字符串编解码。sandbox policy 的解释、资源限制、裁剪与错误分类必须在 core 中完成。

#### 场景:Node binding 触发 sandbox 执行
- **当** Node binding 调用 shell 或 code sandbox 接口
- **那么** 它必须直接返回 core 结果
- **那么** binding 层不得重新解释 timeout、interrupt 或审计裁剪逻辑

## 修改需求
无

## 移除需求
无
