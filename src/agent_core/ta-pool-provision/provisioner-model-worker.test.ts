import assert from "node:assert/strict";
import test from "node:test";

import { createModelBackedProvisionerWorkerBridge } from "./provisioner-model-worker.js";
import {
  createProvisionerWorkerEnvelope,
  createProvisionerWorkerPromptPack,
} from "./provisioner-worker-bridge.js";
import { createProvisionRequest } from "../ta-pool-types/index.js";

test("createModelBackedProvisionerWorkerBridge falls back to deterministic output when the model omits buildSummary", async () => {
  const request = createProvisionRequest({
    provisionId: "provision-model-worker-fallback",
    sourceRequestId: "req-model-worker-fallback",
    requestedCapabilityKey: "docs.read",
    reason: "Need deterministic provisioner fallback.",
    createdAt: "2026-04-07T00:00:00.000Z",
  });
  const bridge = createModelBackedProvisionerWorkerBridge({
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
              rationale: "The model returned metadata but left required fields blank.",
            },
          }),
        },
        emittedAt: "2026-04-07T00:00:00.000Z",
      },
    }),
  });

  const output = await bridge({
    request,
    lane: "bootstrap",
    promptPack: createProvisionerWorkerPromptPack(request, "bootstrap"),
    envelope: createProvisionerWorkerEnvelope(request, "bootstrap"),
  });

  const provisionerModelMetadata = output.metadata?.provisionerModelMetadata as
    | { fallback?: string }
    | undefined;
  assert.match(output.buildSummary, /generic staged package contract|ready for tool-review quality checks/u);
  assert.equal(provisionerModelMetadata?.fallback, "deterministic_summary");
});
