# 2026-03-14 Websearch Native First

## 本次结论

- `search.ground` 不再按“三家各写一套规范”推进，而是明确采用 `native-first + governed-task` 设计。
- 上层当前只暴露一个便捷入口：
  - `rax.websearch.create()`
- `rax.websearch.create()` 已从 prepare-only 升级为真实执行入口。
- `rax.websearch.prepare()` 仅作为内部/测试检查位保留。
- 底层仍保留 canonical 语义：
  - `search.ground`

## 设计收口

- 路由优先尊重上游协议世界与官方 native tooling，而不是优先看模型品牌名。
- `rax` 在 search 这条线上的责任收成三层：
  - 统一任务入口
  - 治理与 compatibility gating
  - 证据外壳
- `rax` 当前不负责：
  - 自建搜索引擎
  - 自建通用抓取主链
  - 用 fallback 抹平三家原生能力差异

## 当前实现

- OpenAI:
  - `rax.websearch.create()` -> `search.ground`
  - lower 到 `Responses API + web_search`
  - 请求 `web_search_call.action.sources`
- Anthropic:
  - lower 到 `Messages API + web_search`
  - 提供 `urls` 时附加 `web_fetch`
- DeepMind / Gemini:
  - lower 到 `Interactions API + google_search`
  - 提供 `urls` 时附加 `url_context`

## compatibility 策略

- unofficial gateway 默认不承诺原生搜索能力。
- `raxLocal` 当前对以下 profile 显式阻断：
  - `openai-chat-only-gateway`
  - `anthropic-messages-only-primary`
  - `deepmind-openai-compatible-gateway`
- 结论是：
  - 不因为模型名像 GPT / Claude / Gemini，就假设它拥有对应官方 search 语义。

## 结果 contract

- 新增统一 search 结果外壳：
  - `WebSearchOutput`
  - `WebSearchCitation`
  - `WebSearchSource`
- 新增归一化 helper：
  - `normalizeWebSearchOutput()`
  - `toWebSearchCapabilityResult()`
  - `toWebSearchFailureResult()`
- 当前已补三家 raw payload 的归一化测试：
  - OpenAI-style payload
  - Anthropic-style payload
  - Gemini-style payload

## 执行闭环

- 新增 `WebSearchRuntime`：
  - 复用官方 SDK
  - 读取 `live-config`
  - 真正执行 OpenAI / Anthropic / DeepMind 的 native websearch 请求
- `createRaxFacade()` 现在允许注入自定义 `WebSearchRuntimeLike`，便于测试和后续替换执行基座。

## 本地验证

- `npm run typecheck` 通过
- `npm test` 通过
- 当前测试数：
  - `51 pass / 0 fail`
- 补做了真实 `rax.websearch.create()` smoke，当前 `.env.local` 下结论更细：
  - OpenAI route (`gmn.chuangzuoli.com/v1`):
    - `gpt-5.4` 可成功跑原生 `responses + web_search`
    - `gpt-5` 当前返回 `502 Bad gateway`
- Anthropic route:
  - `.env.local` 里的 `claude-opus-4.6-thinking` 当前返回 `503 No available channels`
  - 同一路由下 `claude-opus-4-6-thinking` 可成功跑普通 `messages.create`
  - `messages + web_search` 这条 API server-tool 路不稳定：
    - 有时直接给出防御性/偏离问题的回答
    - 有时停在 `stop_reason: "tool_use"`，search loop 未闭环
    - 因此当前 Anthropic `rax.websearch.create()` 对这类 API 返回会标记 `partial`
  - 后续改为 `agent/Claude Code` 路：
    - Anthropic `search.ground` 的 preferred layer 已切到 `agent`
    - runtime 通过本机 `claude -p --output-format json` 执行
    - 在 `viewpro.top + claude-opus-4-6-thinking` 下已实测成功
      - 简单题：`typescriptlang.org`
      - 当前信息题：能返回 NVDA 日期/价格，并带 source links
  - DeepMind / Gemini route:
    - 当前 `.env.local` 指向的 route 对 `interactions` 返回 `404 Invalid URL`
    - 用户后续切换到了官方通道形态的 endpoint：
      - `https://viewpro.top/v1beta/models/gemini-3.1-pro-preview:generateContent`
    - 实测结果：
      - 普通 `generateContent` 成功
      - `googleSearch` 成功
      - 通过 `@google/genai` SDK 调用时，当前信息题已返回 `groundingMetadata`
    - 说明：
      - `deepmind search.ground` 走 `models.generateContent + googleSearch/urlContext` 这条路是对的
      - Gemini 这条之前 citation 不漂亮，主要不是我们代码没用透，而是旧上游/旧模型组合不完整
      - 切到新的官方通道形态后，Gemini 已具备 citation-grade grounding 的基础

结论：

- 代码层的 native-first 路由与结果 contract 已接通。
- 但当前本地 live config 仍不是“三家都能稳定承接官方原生搜索”的完全官方直连组合。
- Anthropic 当前最稳的 native 面更接近 `agent/Claude Code`，而不是 `messages + web_search` server tool。
- 所以运行层下一步要么：
  - 把 search smoke 切到真正官方 upstream
  - 要么给 gateway 场景显式走 `raxLocal` / compatibility 画像，而不是拿 `rax` 官方 runtime 直撞。

## 下一步

1. 明确 `websearch.create()` 的统一结果与 evidence contract。
2. 评估是否需要直接暴露 `search.web` / `search.fetch` facade，还是继续只保留自治入口。
3. 把 live config 和 runtime 选择关系说清楚：
   - 官方 upstream -> `rax`
   - unofficial gateway -> `raxLocal` + compatibility profile
