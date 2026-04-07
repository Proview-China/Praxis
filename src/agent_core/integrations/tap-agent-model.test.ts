import assert from "node:assert/strict";
import test from "node:test";

import {
  executeTapAgentStructuredOutput,
  parseTapAgentStructuredText,
} from "./tap-agent-model.js";

test("parseTapAgentStructuredText extracts the first JSON object from fenced model output", () => {
  const result = parseTapAgentStructuredText<{ summary: string }>([
    "Sure, here is the object.",
    "```json",
    "{\"summary\":\"stable\"}",
    "```",
  ].join("\n"));

  assert.deepEqual(result, { summary: "stable" });
});

test("executeTapAgentStructuredOutput defaults TAP structured workers to responses", async () => {
  let capturedVariant: unknown;

  const result = await executeTapAgentStructuredOutput<{ summary: string }>({
    executor: async ({ intent }) => {
      capturedVariant = intent.frame.metadata?.variant;
      return {
        provider: "openai",
        model: "gpt-5.4",
        layer: "api",
        raw: {},
        result: {
          resultId: `${intent.intentId}:result`,
          sessionId: intent.sessionId,
          runId: intent.runId,
          source: "model",
          status: "success",
          output: {
            text: "{\"summary\":\"stable\"}",
          },
          evidence: [],
          emittedAt: "2026-04-07T00:00:00.000Z",
          correlationId: intent.correlationId,
          metadata: {},
        },
      };
    },
    sessionId: "tap-session",
    runId: "tap-run",
    workerKind: "tap-tool-reviewer",
    systemPrompt: "Return JSON.",
    userPrompt: "Return summary.",
  });

  assert.equal(capturedVariant, "responses");
  assert.deepEqual(result, { summary: "stable" });
});
