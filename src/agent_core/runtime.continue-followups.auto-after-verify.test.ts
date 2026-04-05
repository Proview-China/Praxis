import assert from "node:assert/strict";
import test from "node:test";

import { createGoalSource } from "./goal/goal-source.js";
import { createAgentCoreRuntime } from "./runtime.js";
import { createAgentCapabilityProfile, createProvisionRequest } from "./ta-pool-types/index.js";
import { createTaPendingReplay, createTaResumeEnvelope } from "./ta-pool-runtime/index.js";

test("AgentCoreRuntime continueTaProvisioning can continue auto-after-verify replay once activation is ready", async () => {
  const runtime = createAgentCoreRuntime({
    taProfile: createAgentCapabilityProfile({
      profileId: "profile.runtime.continue-provisioning-auto-after-verify",
      agentClass: "main-agent",
      baselineCapabilities: ["docs.read"],
      allowedCapabilityPatterns: ["computer.*"],
    }),
  });
  const session = runtime.createSession();
  const goal = runtime.createCompiledGoal(
    createGoalSource({
      goalId: "goal-runtime-continue-provisioning-auto-after-verify",
      sessionId: session.sessionId,
      userInput: "Continue auto-after-verify replay from runtime continue driver.",
    }),
  );
  const created = await runtime.createRun({
    sessionId: session.sessionId,
    goal,
  });

  const provisionBundle = await runtime.provisionerRuntime?.submit(createProvisionRequest({
    provisionId: "provision-auto-after-verify-continue",
    sourceRequestId: "request-auto-after-verify-continue-1",
    requestedCapabilityKey: "computer.use",
    reason: "Auto-after-verify replay should keep a resumable runtime path.",
    replayPolicy: "auto_after_verify",
    createdAt: "2026-03-25T21:30:00.000Z",
  }));
  assert.equal(provisionBundle?.status, "ready");

  const replay = createTaPendingReplay({
    replayId: "replay:auto-after-verify-continue",
    request: {
      requestId: "request-auto-after-verify-continue-1",
      requestedCapabilityKey: "computer.use",
    },
    provisionBundle: provisionBundle!,
    createdAt: "2026-03-25T21:30:02.000Z",
    metadata: {
      sessionId: session.sessionId,
      runId: created.run.runId,
      mode: "balanced",
      requestedTier: "B2",
      taskContext: {
        source: "runtime-test",
      },
    },
  });
  runtime.hydrateRecoveredTapRuntimeSnapshot({
    humanGates: [],
    humanGateEvents: [],
    pendingReplays: [replay],
    activationAttempts: [],
    resumeEnvelopes: [createTaResumeEnvelope({
      envelopeId: "resume:replay:replay:auto-after-verify-continue",
      source: "replay",
      requestId: "request-auto-after-verify-continue-1",
      sessionId: session.sessionId,
      runId: created.run.runId,
      capabilityKey: "computer.use",
      requestedTier: "B2",
      mode: "balanced",
      reason: "Resume auto-after-verify replay from continue driver.",
      intentRequest: {
        requestId: "request-auto-after-verify-continue-1",
        intentId: "intent-auto-after-verify-continue-1",
        capabilityKey: "computer.use",
        input: {
          task: "continue auto-after-verify replay",
        },
        priority: "normal",
      },
      metadata: {
        replayId: replay.replayId,
        provisionId: "provision-auto-after-verify-continue",
        agentId: "agent-main",
        taskContext: {
          source: "runtime-test",
        },
      },
    })],
  });
  assert.equal(runtime.getTaReplayResumeEnvelope(replay.replayId)?.envelopeId, "resume:replay:replay:auto-after-verify-continue");

  runtime.registerTaActivationFactory("factory:computer.use", () => ({
    id: "adapter.computer.use.continue-auto-after-verify",
    runtimeKind: "tool",
    supports(plan) {
      return plan.capabilityKey === "computer.use";
    },
    async prepare(plan, lease) {
      return {
        preparedId: `${plan.planId}:prepared`,
        leaseId: lease.leaseId,
        capabilityKey: plan.capabilityKey,
        bindingId: lease.bindingId,
        generation: lease.generation,
        executionMode: "direct",
      };
    },
    async execute(prepared) {
      return {
        executionId: `${prepared.preparedId}:execution`,
        resultId: `${prepared.preparedId}:result`,
        status: "success",
        output: {
          answer: "continue-auto-after-verify-ok",
        },
        completedAt: "2026-03-25T21:30:04.000Z",
      };
    },
  }));

  const continued = await runtime.continueTaProvisioning("provision-auto-after-verify-continue");

  assert.equal(continued.status, "dispatched");
  assert.equal(continued.activationResult?.status, "activated");
  assert.equal(continued.dispatchResult?.grant?.capabilityKey, "computer.use");
  assert.equal(runtime.listTaResumeEnvelopes().some((entry) => entry.source === "replay"), false);
});
