import assert from "node:assert/strict";
import test from "node:test";

import { createDefaultToolReviewerLlmHook } from "./tool-review-model-hook.js";
import { createToolReviewGovernanceTrace } from "./tool-review-contract.js";

test("createDefaultToolReviewerLlmHook falls back to deterministic summary when the model omits summary", async () => {
  const hook = createDefaultToolReviewerLlmHook({
    executor: async ({ intent }) => ({
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
          text: JSON.stringify({
            metadata: {
              rationale: "The model returned metadata but no summary.",
            },
          }),
        },
        emittedAt: "2026-04-07T00:00:00.000Z",
      },
    }),
  });

  const result = await hook({
    sessionId: "tool-review-hook-fallback",
    governanceAction: {
      kind: "lifecycle",
      trace: createToolReviewGovernanceTrace({
        actionId: "action-tool-review-hook-fallback",
        actorId: "tool-reviewer",
        reason: "Fallback should preserve deterministic summary.",
        createdAt: "2026-04-07T00:00:00.000Z",
      }),
      capabilityKey: "docs.read",
      lifecycleAction: "register",
      targetPool: "ta-capability-pool",
    },
    defaultOutput: {
      kind: "lifecycle",
      actionId: "action-tool-review-hook-fallback",
      status: "ready_for_lifecycle_handoff",
      capabilityKey: "docs.read",
      lifecycleAction: "register",
      targetPool: "ta-capability-pool",
      summary: "Lifecycle register is staged for docs.read in ta-capability-pool.",
    },
  });

  assert.equal(result?.summary, "Lifecycle register is staged for docs.read in ta-capability-pool.");
  assert.equal(result?.metadata?.fallback, "deterministic_summary");
});
