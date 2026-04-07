import assert from "node:assert/strict";
import test from "node:test";

import {
  buildOpenAIProviderMetadata,
  collectOpenAIChatCompletionsStreamText,
  collectOpenAIResponsesStreamText,
  isOpenAITextResponseEmpty,
  omitResponsesMetadataForGatewayRetry,
  parseOpenAITextResponse,
  shouldRetryOpenAIResponsesOnTransientGateway,
  shouldRetryOpenAIResponsesOnRateLimit,
  shouldRetryOpenAIResponsesWithoutMetadata,
} from "./model-inference.js";

test("omitResponsesMetadataForGatewayRetry removes top-level metadata only", () => {
  const result = omitResponsesMetadataForGatewayRetry({
    model: "gpt-5.4",
    input: "hello",
    stream: false,
    metadata: {
      provider: "openai",
      variant: "responses",
    },
  });

  assert.deepEqual(result, {
    model: "gpt-5.4",
    input: "hello",
    stream: false,
  });
});

test("shouldRetryOpenAIResponsesWithoutMetadata returns true for responses metadata gateway failures", () => {
  const result = shouldRetryOpenAIResponsesWithoutMetadata({
    invocation: {
      payload: {
        surface: "responses",
        sdkMethodPath: "client.responses.create",
        params: {
          model: "gpt-5.4",
          input: "hello",
          metadata: {
            provider: "openai",
          },
        },
      },
    },
    error: {
      status: 502,
    },
  });

  assert.equal(result, true);
});

test("shouldRetryOpenAIResponsesWithoutMetadata stays false when metadata is absent or surface differs", () => {
  assert.equal(shouldRetryOpenAIResponsesWithoutMetadata({
    invocation: {
      payload: {
        surface: "responses",
        sdkMethodPath: "client.responses.create",
        params: {
          model: "gpt-5.4",
          input: "hello",
        },
      },
    },
    error: {
      status: 502,
    },
  }), false);

  assert.equal(shouldRetryOpenAIResponsesWithoutMetadata({
    invocation: {
      payload: {
        surface: "chat_completions",
        sdkMethodPath: "client.chat.completions.create",
        params: {
          model: "gpt-5.4",
          messages: [],
          metadata: {
            provider: "openai",
          },
        },
      },
    },
    error: {
      status: 403,
    },
  }), false);
});

test("shouldRetryOpenAIResponsesOnRateLimit returns true only for responses 429", () => {
  assert.equal(shouldRetryOpenAIResponsesOnRateLimit({
    invocation: {
      payload: {
        surface: "responses",
        sdkMethodPath: "client.responses.create",
        params: {
          model: "gpt-5.4",
          input: "hello",
        },
      },
    },
    error: {
      status: 429,
    },
  }), true);

  assert.equal(shouldRetryOpenAIResponsesOnRateLimit({
    invocation: {
      payload: {
        surface: "chat_completions",
        sdkMethodPath: "client.chat.completions.create",
        params: {
          model: "gpt-5.4",
          messages: [],
        },
      },
    },
    error: {
      status: 429,
    },
  }), false);
});

test("shouldRetryOpenAIResponsesOnTransientGateway returns true only for responses 503", () => {
  assert.equal(shouldRetryOpenAIResponsesOnTransientGateway({
    invocation: {
      payload: {
        surface: "responses",
        sdkMethodPath: "client.responses.create",
        params: {
          model: "gpt-5.4",
          input: "hello",
        },
      },
    },
    error: {
      status: 503,
    },
  }), true);

  assert.equal(shouldRetryOpenAIResponsesOnTransientGateway({
    invocation: {
      payload: {
        surface: "chat_completions",
        sdkMethodPath: "client.chat.completions.create",
        params: {
          model: "gpt-5.4",
          messages: [],
        },
      },
    },
    error: {
      status: 503,
    },
  }), false);
});

test("buildOpenAIProviderMetadata keeps only provider-safe flat metadata fields", () => {
  const result = buildOpenAIProviderMetadata({
    provider: "openai",
    model: "gpt-5.4-mini",
    cmpRole: "dispatcher",
    cmpLiveMode: "llm_required",
    promptText: "very long internal prompt that should not leak to provider metadata",
    schemaFields: ["routeRationale", "scopePolicy"],
    maxOutputTokens: 96,
    nested: {
      noisy: true,
    },
  });

  assert.deepEqual(result, {
    provider: "openai",
    model: "gpt-5.4-mini",
    cmpRole: "dispatcher",
    cmpLiveMode: "llm_required",
  });
});

test("parseOpenAITextResponse extracts text from responses output content arrays", () => {
  const result = parseOpenAITextResponse({
    id: "resp-1",
    output: [
      {
        type: "message",
        content: [
          {
            type: "output_text",
            text: "Praxis responses text",
          },
        ],
      },
    ],
  });

  assert.equal(result, "Praxis responses text");
});

test("parseOpenAITextResponse extracts legacy completion text fields when message content is absent", () => {
  const result = parseOpenAITextResponse({
    id: "chatcmpl-1",
    choices: [
      {
        index: 0,
        text: "Praxis completion text",
        message: {
          role: "assistant",
        },
      },
    ],
  });

  assert.equal(result, "Praxis completion text");
});

test("isOpenAITextResponseEmpty detects completed provider envelopes without text", () => {
  assert.equal(isOpenAITextResponseEmpty({
    id: "resp-empty",
    object: "response",
    status: "completed",
    output: [],
    output_text: "",
    usage: {
      total_tokens: 100,
    },
  }), true);

  assert.equal(isOpenAITextResponseEmpty({
    id: "resp-filled",
    object: "response",
    output_text: "PASS",
    usage: {
      total_tokens: 10,
    },
  }), false);
});

test("collectOpenAIResponsesStreamText rebuilds text from responses SSE events", async () => {
  async function* events() {
    yield { type: "response.output_text.delta", delta: "PA" };
    yield { type: "response.output_text.delta", delta: "SS" };
    yield { type: "response.completed", response: { id: "resp-1", object: "response" } };
  }

  const result = await collectOpenAIResponsesStreamText(events());

  assert.equal(result.output_text, "PASS");
  assert.deepEqual(result.output, [
    {
      type: "message",
      status: "completed",
      role: "assistant",
      content: [
        {
          type: "output_text",
          text: "PASS",
        },
      ],
    },
  ]);
});

test("collectOpenAIChatCompletionsStreamText rebuilds text from chat completion chunks", async () => {
  async function* events() {
    yield { id: "chunk-1", model: "gpt-5.4", choices: [{ delta: { role: "assistant" } }] };
    yield { id: "chunk-1", model: "gpt-5.4", choices: [{ delta: { content: "PA" } }] };
    yield { id: "chunk-1", model: "gpt-5.4", choices: [{ delta: { content: "SS" }, finish_reason: "stop" }] };
  }

  const result = await collectOpenAIChatCompletionsStreamText(events());

  assert.equal(result.object, "chat.completion");
  assert.deepEqual(result.choices, [
    {
      index: 0,
      message: {
        role: "assistant",
        content: "PASS",
      },
      finish_reason: "stop",
    },
  ]);
});
