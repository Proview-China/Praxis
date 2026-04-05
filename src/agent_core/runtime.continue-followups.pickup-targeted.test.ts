import assert from "node:assert/strict";
import test from "node:test";

import { createAgentCoreRuntime } from "./runtime.js";
import { createAgentCapabilityProfile, createProvisionRequest } from "./ta-pool-types/index.js";
import { createToolReviewGovernanceTrace } from "./ta-pool-tool-review/index.js";
import { createTaPendingReplay, createTaResumeEnvelope } from "./ta-pool-runtime/index.js";

test("AgentCoreRuntime pickupToolReviewerReadyHandoffs can target one provision session without draining another ready handoff", async () => {
  const runtime = createAgentCoreRuntime({
    taProfile: createAgentCapabilityProfile({
      profileId: "profile.runtime.pickup-tool-reviewer-targeted",
      agentClass: "main-agent",
      baselineCapabilities: ["docs.read"],
      allowedCapabilityPatterns: ["computer.*"],
    }),
  });
  const session = runtime.createSession({ sessionId: "session-pickup-targeted" });
  const runId = "run-pickup-targeted";

  const provisionIds = [
    "provision-pickup-target-1",
    "provision-pickup-target-2",
  ] as const;
  const replays = [];
  const envelopes = [];
  const continuedProvisionIds: string[] = [];

  for (const provisionId of provisionIds) {
    const bundle = await runtime.provisionerRuntime?.submit(createProvisionRequest({
      provisionId,
      sourceRequestId: `request-${provisionId}`,
      requestedCapabilityKey: "computer.use",
      reason: `Need staged replay for ${provisionId}.`,
      replayPolicy: "re_review_then_dispatch",
      createdAt: "2026-03-31T14:00:00.000Z",
    }));
    assert.equal(bundle?.status, "ready");

    const replay = createTaPendingReplay({
      replayId: `replay:${provisionId}`,
      request: {
        requestId: `request-${provisionId}`,
        requestedCapabilityKey: "computer.use",
      },
      provisionBundle: bundle!,
      createdAt: "2026-03-31T14:00:01.000Z",
      metadata: {
        sessionId: session.sessionId,
        runId,
        mode: "balanced",
        requestedTier: "B2",
      },
    });
    replays.push(replay);
    envelopes.push(createTaResumeEnvelope({
      envelopeId: `resume:replay:${replay.replayId}`,
      source: "replay",
      requestId: `request-${provisionId}`,
      sessionId: session.sessionId,
      runId,
      capabilityKey: "computer.use",
      requestedTier: "B2",
      mode: "balanced",
      reason: `Resume ${provisionId}.`,
      intentRequest: {
        requestId: `request-${provisionId}`,
        intentId: `intent-${provisionId}`,
        capabilityKey: "computer.use",
        input: {
          task: `resume ${provisionId}`,
        },
        priority: "normal",
      },
      metadata: {
        replayId: replay.replayId,
        provisionId,
        agentId: "agent-main",
      },
    }));
    await runtime.toolReviewerRuntime?.submit({
      sessionId: `tool-review:provision:${provisionId}`,
      governanceAction: {
        kind: "delivery",
        trace: createToolReviewGovernanceTrace({
          actionId: `action-delivery-${provisionId}`,
          actorId: "tool-reviewer",
          reason: `Ready bundle is waiting for runtime pickup for ${provisionId}.`,
          createdAt: "2026-03-31T14:00:02.000Z",
          request: {
            requestId: `request-${provisionId}`,
            sessionId: session.sessionId,
            runId,
            requestedCapabilityKey: "computer.use",
            requestedTier: "B2",
            mode: "permissive",
            canonicalMode: "permissive",
          },
        }),
        provisionId,
        capabilityKey: "computer.use",
        receipt: runtime.provisionerRuntime?.getBundleHistory(provisionId).at(-1)?.metadata?.tmaDeliveryReceipt as never,
      },
    });
  }

  (runtime as unknown as {
    continueTaProvisioning: (provisionId: string) => Promise<{ status: "dispatched"; provisionId: string }>;
  }).continueTaProvisioning = async (provisionId: string) => {
    continuedProvisionIds.push(provisionId);
    const replayId = `replay:${provisionId}`;
    const envelopeId = `resume:replay:${replayId}`;
    const pendingReplay = runtime.getTaPendingReplay(replayId);
    assert.ok(pendingReplay);
    runtime.hydrateRecoveredTapRuntimeSnapshot({
      ...runtime.createTapRuntimeSnapshot(),
      pendingReplays: runtime.listTaPendingReplays().filter((entry) => entry.replayId !== replayId),
      resumeEnvelopes: runtime.listTaResumeEnvelopes().filter((entry) => entry.envelopeId !== envelopeId),
    });
    return {
      status: "dispatched",
      provisionId,
    };
  };

  runtime.hydrateRecoveredTapRuntimeSnapshot({
    ...runtime.createTapRuntimeSnapshot(),
    pendingReplays: replays,
    resumeEnvelopes: envelopes,
  });

  const picked = await runtime.pickupToolReviewerReadyHandoffs({
    sessionId: "tool-review:provision:provision-pickup-target-1",
  });

  assert.equal(picked.length, 1);
  assert.equal(picked[0]?.status, "continued");
  assert.equal(picked[0]?.provisionId, "provision-pickup-target-1");
  assert.equal(picked[0]?.continueResult?.status, "dispatched");
  assert.deepEqual(continuedProvisionIds, ["provision-pickup-target-1"]);
  assert.equal(runtime.getTaReplayResumeEnvelope("replay:provision-pickup-target-1"), undefined);
  assert.ok(runtime.getTaReplayResumeEnvelope("replay:provision-pickup-target-2"));
});
