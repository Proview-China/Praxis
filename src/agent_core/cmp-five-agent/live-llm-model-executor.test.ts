import assert from "node:assert/strict";
import test from "node:test";

import { createCmpRoleLiveLlmModelExecutor } from "./live-llm-model-executor.js";
import type { CmpRoleLiveLlmRequest } from "./types.js";

function createDispatcherRequest(requestId: string): CmpRoleLiveLlmRequest<Record<string, unknown>> {
  return {
    requestId,
    role: "dispatcher",
    agentId: "dispatcher-agent",
    mode: "llm_required",
    stage: "route",
    createdAt: "2026-04-07T00:00:00.000Z",
    promptPackId: "prompt-pack",
    profileId: "profile",
    prompt: {
      system: "dispatcher system",
      user: "Return dispatcher routing JSON.",
      systemPrompt: "dispatcher system prompt",
      systemPurpose: "test",
      mission: "route child seed bundles",
      guardrails: [],
      inputContract: [],
      outputContract: ["routeRationale", "bodyStrategy", "scopePolicy"],
      handoffContract: "none",
    },
    input: {},
    metadata: {
      promptText: "Return dispatcher routing JSON.",
    },
  };
}

test("createCmpRoleLiveLlmModelExecutor extracts the first JSON object from mixed text output", async () => {
  const executor = createCmpRoleLiveLlmModelExecutor({
    executor: async ({ intent }) => ({
      provider: "openai",
      model: "gpt-5.4",
      layer: "api",
      raw: { text: "ok" },
      result: {
        resultId: `${intent.intentId}:result`,
        sessionId: intent.sessionId,
        runId: intent.runId,
        source: "model",
        status: "success",
        output: {
          text: [
            "Here is the routing decision.",
            "```json",
            "{\"routeRationale\":\"child only\",\"bodyStrategy\":\"child_seed_full\",\"scopePolicy\":\"child_seed_only_enters_child_icma\"}",
            "```",
          ].join("\n"),
        },
        emittedAt: "2026-04-07T00:00:00.000Z",
      },
    }),
  });

  const result = await executor(createDispatcherRequest("cmp-live-json-extract-1"));

  assert.deepEqual(result.output, {
    routeRationale: "child only",
    bodyStrategy: "child_seed_full",
    scopePolicy: "child_seed_only_enters_child_icma",
  });
});

test("createCmpRoleLiveLlmModelExecutor rejects output without any JSON object", async () => {
  const executor = createCmpRoleLiveLlmModelExecutor({
    executor: async ({ intent }) => ({
      provider: "openai",
      model: "gpt-5.4",
      layer: "api",
      raw: { text: "ok" },
      result: {
        resultId: `${intent.intentId}:result`,
        sessionId: intent.sessionId,
        runId: intent.runId,
        source: "model",
        status: "success",
        output: {
          text: "routing decision unavailable",
        },
        emittedAt: "2026-04-07T00:00:01.000Z",
      },
    }),
  });

  await assert.rejects(
    () => executor(createDispatcherRequest("cmp-live-json-extract-2")),
    /did not contain a JSON object/u,
  );
});

test("createCmpRoleLiveLlmModelExecutor rejects provider response envelopes even when they are valid JSON", async () => {
  const executor = createCmpRoleLiveLlmModelExecutor({
    executor: async ({ intent }) => ({
      provider: "openai",
      model: "gpt-5.4",
      layer: "api",
      raw: { text: "ok" },
      result: {
        resultId: `${intent.intentId}:result`,
        sessionId: intent.sessionId,
        runId: intent.runId,
        source: "model",
        status: "success",
        output: {
          text: JSON.stringify({
            id: "resp_1",
            object: "response",
            output: [],
            usage: { total_tokens: 42 },
          }),
        },
        emittedAt: "2026-04-07T00:00:02.000Z",
      },
    }),
  });

  await assert.rejects(
    () => executor(createDispatcherRequest("cmp-live-json-extract-3")),
    /provider response envelope/u,
  );
});
