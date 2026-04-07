# 2026-04-07 Live Integration And Dispatcher Fix

## 这轮工作的结论

这轮不是继续做“分支总装”，而是把总装线真正拉到一轮真实联调上。

当前最重要的新结论是：

- `integrate/dev-master-cmp` 已经在真实 OpenAI-compatible 上游上跑通了 `core + TAP + CMP`
- `dispatcher` 的关键 live 阻塞点已经查清并修复

一句白话：

- 现在不只是“主线能继续开发”
- 而是“主线已经能做真实联调”

## 这轮真实跑通了什么

### 一、`core -> TAP -> model.infer`

当前已经真实通过：

- `core` 走 `TAP`
- `TAP` 再走 `model.infer`
- 上游是 `https://gmn.chuangzuoli.com`

### 二、TAP 三 agent

当前已经真实通过：

- `reviewer`
- `tool_reviewer`
- `TMA`

### 三、`CMP role -> TAP bridge`

当前已经真实通过：

- `CMP` 角色通过 `TAP bridge` 派发 capability
- 说明 `CMP` 不再只是 facade 表面可见
- 而是已经能进当前 runtime 主链

### 四、`CMP five-agent live`

当前已经真实通过：

- `icma`
- `iterator`
- `checker`
- `dbagent`
- `dispatcher`

## 这轮真正查清的问题

### 1. `dispatcher` 之前并不是规则层坏掉

真实问题不是：

- child route 逻辑错
- bundle 结构错
- packageMode 判断错

真实问题是：

- `model.infer -> OpenAI responses`
- 把内部 metadata 一起发到了 provider
- 当前 `gmn` 路由会把这类请求拖成 `524 timeout`

### 2. 这不是 `CMP` 五角色自己“废了”

真实情况是：

- `dispatcher` rules path 能跑
- `dispatcher live` 在 provider request shape 上被拖死

一句白话：

- 坏的是“发给上游的请求形状”
- 不是 `dispatcher` 的路由原则本身

## 这轮落地的修复

### 一、收紧 OpenAI `responses` 请求形状

当前已经做了：

- 对 OpenAI `responses` 不再发送内部 metadata

### 二、收紧 `dispatcher` live prompt

当前已经做了：

- 更紧凑、更确定的 active/passive routing prompt
- 更小的输出 token 上限

### 三、补断点 smoke 能力

当前 `cmp-five-agent-live-smoke` 已支持：

- 角色级别断点
- `active / passive`
- `--no-retry`
- `--strict-live`

一句白话：

- 后面联调可以真正一步一步查
- 不用再黑盒整环硬跑

## 当前联调 smoke 的模型分级

这轮写进代码的是联调 smoke 策略：

- `core`
  - `gpt-5.4 + high`
- TAP 三 agent
  - `gpt-5.4 + medium`
- `CMP five-agent`
  - `icma`: `gpt-5.4 + medium`
  - `iterator`: `gpt-5.4 + low`
  - `checker`: `gpt-5.4 + medium`
  - `dbagent`: `gpt-5.4 + medium`
  - `dispatcher`: `gpt-5.4 + high`

## 这轮最重要的工程判断

当前最重要的新判断是：

- 总装线已经进入“真实联调阶段”
- 不是仍停在“结构总装完成但还没跑过”

也就是说：

- 后面如果继续做 `core + TAP + CMP`
- 默认直接在 `integrate/dev-master-cmp` 上继续写、继续联调

## 证据入口

当前这轮最关键的 live 证据在：

- `memory/live-reports/single-agent-live-smoke.openai.json`
- `memory/live-reports/cmp-five-agent-live-smoke.openai.json`

最新相关提交是：

- `af0cc18` `Wire model strategy and fix dispatcher live routing`
