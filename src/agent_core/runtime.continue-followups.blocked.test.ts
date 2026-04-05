import assert from "node:assert/strict";
import test from "node:test";

import { createAgentCoreRuntime } from "./runtime.js";
import { createAgentCapabilityProfile, createProvisionRequest } from "./ta-pool-types/index.js";
import { createToolReviewGovernanceTrace } from "./ta-pool-tool-review/index.js";
import { createTaPendingReplay, createTaResumeEnvelope } from "./ta-pool-runtime/index.js";

test("AgentCoreRuntime continueTaProvisioning stops when tool reviewer still marks the provision lane blocked", async () => {
  const runtime = createAgentCoreRuntime({
    taProfile: createAgentCapabilityProfile({
      profileId: "profile.runtime.continue-provisioning-blocked-by-tool-review",
      agentClass: "main-agent",
      baselineCapabilities: ["docs.read"],
      allowedCapabilityPatterns: ["computer.*"],
    }),
  });

  const provisionBundle = await runtime.provisionerRuntime?.submit(createProvisionRequest({
    provisionId: "provision-blocked-by-tool-review",
    sourceRequestId: "request-blocked-by-tool-review-1",
    requestedCapabilityKey: "computer.use",
    reason: "Tool reviewer should be able to keep the provision lane blocked.",
    replayPolicy: "re_review_then_dispatch",
    createdAt: "2026-03-25T21:40:00.000Z",
  }));
  assert.equal(provisionBundle?.status, "ready");

  const replay = createTaPendingReplay({
    replayId: "replay:blocked-by-tool-review",
    request: {
      requestId: "request-blocked-by-tool-review-1",
      requestedCapabilityKey: "computer.use",
    },
    provisionBundle: provisionBundle!,
    createdAt: "2026-03-25T21:40:01.000Z",
  });
  runtime.hydrateRecoveredTapRuntimeSnapshot({
    humanGates: [],
    humanGateEvents: [],
    pendingReplays: [replay],
    activationAttempts: [],
    resumeEnvelopes: [createTaResumeEnvelope({
      envelopeId: "resume:replay:blocked-by-tool-review",
      source: "replay",
      requestId: "request-blocked-by-tool-review-1",
      sessionId: "session-blocked-by-tool-review",
      runId: "run-blocked-by-tool-review",
      capabilityKey: "computer.use",
      requestedTier: "B2",
      mode: "balanced",
      reason: "Blocked governance should stop continueTaProvisioning before replay resumes.",
      intentRequest: {
        requestId: "request-blocked-by-tool-review-1",
        intentId: "intent-blocked-by-tool-review-1",
        capabilityKey: "computer.use",
        input: {
          task: "do not continue while tool reviewer is blocked",
        },
        priority: "normal",
      },
      metadata: {
        replayId: replay.replayId,
        provisionId: "provision-blocked-by-tool-review",
        agentId: "agent-main",
      },
    })],
  });
  await runtime.toolReviewerRuntime?.submit({
    sessionId: "tool-review:provision:provision-blocked-by-tool-review",
    governanceAction: {
      kind: "lifecycle",
      trace: createToolReviewGovernanceTrace({
        actionId: "action-tool-review-blocked-provision",
        actorId: "tool-reviewer",
        reason: "Keep the provision lane blocked until lifecycle issues are fixed.",
        createdAt: "2026-03-25T21:40:02.000Z",
      }),
      capabilityKey: "computer.use",
      lifecycleAction: "register",
      targetPool: "ta-capability-pool",
      failure: {
        code: "binding_missing",
        message: "Binding is not ready yet.",
      },
    },
  });

  const continued = await runtime.continueTaProvisioning("provision-blocked-by-tool-review");

  assert.equal(continued.status, "blocked");
  assert.equal(runtime.getTaPendingReplay(replay.replayId)?.replayId, replay.replayId);
  assert.equal(runtime.getTaReplayResumeEnvelope(replay.replayId)?.envelopeId, "resume:replay:blocked-by-tool-review");
});
