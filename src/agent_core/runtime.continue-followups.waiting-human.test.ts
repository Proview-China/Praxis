import assert from "node:assert/strict";
import test from "node:test";

import { createGoalSource } from "./goal/goal-source.js";
import { createAgentCoreRuntime } from "./runtime.js";
import { createAgentCapabilityProfile, createProvisionRequest } from "./ta-pool-types/index.js";
import { createTaPendingReplay, createTaResumeEnvelope } from "./ta-pool-runtime/index.js";

test("AgentCoreRuntime continueTaProvisioning keeps replay backlog when resumed replay opens a fresh human gate", async () => {
  const runtime = createAgentCoreRuntime({
    taProfile: createAgentCapabilityProfile({
      profileId: "profile.runtime.continue-provisioning-waiting-human",
      agentClass: "main-agent",
      baselineCapabilities: ["docs.read"],
      allowedCapabilityPatterns: ["computer.*"],
    }),
  });
  const session = runtime.createSession();
  const goal = runtime.createCompiledGoal(
    createGoalSource({
      goalId: "goal-runtime-continue-provisioning-waiting-human",
      sessionId: session.sessionId,
      userInput: "Continue provisioning should preserve replay backlog when a new gate opens.",
    }),
  );
  const created = await runtime.createRun({
    sessionId: session.sessionId,
    goal,
  });

  const provisionBundle = await runtime.provisionerRuntime?.submit(createProvisionRequest({
    provisionId: "provision-waiting-human-on-continue",
    sourceRequestId: "request-waiting-human-on-continue-1",
    requestedCapabilityKey: "computer.use",
    reason: "Replay resume should reopen a human gate in restricted mode.",
    replayPolicy: "re_review_then_dispatch",
    createdAt: "2026-03-25T21:50:00.000Z",
  }));
  assert.equal(provisionBundle?.status, "ready");
  const replay = createTaPendingReplay({
    replayId: "replay:waiting-human-on-continue",
    request: {
      requestId: "request-waiting-human-on-continue-1",
      requestedCapabilityKey: "computer.use",
    },
    provisionBundle: provisionBundle!,
    createdAt: "2026-03-25T21:50:01.000Z",
    metadata: {
      sessionId: session.sessionId,
      runId: created.run.runId,
      mode: "restricted",
      requestedTier: "B3",
    },
  });
  runtime.hydrateRecoveredTapRuntimeSnapshot({
    humanGates: [],
    humanGateEvents: [],
    pendingReplays: [replay],
    activationAttempts: [],
    resumeEnvelopes: [createTaResumeEnvelope({
      envelopeId: "resume:replay:waiting-human-on-continue",
      source: "replay",
      requestId: "request-waiting-human-on-continue-1",
      sessionId: session.sessionId,
      runId: created.run.runId,
      capabilityKey: "computer.use",
      requestedTier: "B3",
      mode: "restricted",
      reason: "Restricted replay should reopen a human gate instead of dropping backlog.",
      intentRequest: {
        requestId: "request-waiting-human-on-continue-1",
        intentId: "intent-waiting-human-on-continue-1",
        capabilityKey: "computer.use",
        input: {
          task: "reopen restricted gate",
        },
        priority: "normal",
      },
      metadata: {
        replayId: replay.replayId,
        provisionId: "provision-waiting-human-on-continue",
        agentId: "agent-main",
      },
    })],
  });
  runtime.registerTaActivationFactory("factory:computer.use", () => ({
    id: "adapter.computer.use.waiting-human-on-continue",
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
          answer: "should-not-run-before-human-gate",
        },
        completedAt: "2026-03-25T21:50:04.000Z",
      };
    },
  }));

  const continued = await runtime.continueTaProvisioning("provision-waiting-human-on-continue");

  assert.equal(continued.status, "waiting_human");
  assert.equal(runtime.getTaPendingReplay(replay.replayId)?.replayId, replay.replayId);
  assert.equal(runtime.getTaReplayResumeEnvelope(replay.replayId)?.envelopeId, "resume:replay:waiting-human-on-continue");
  assert.equal(runtime.listTaHumanGates().length, 1);
});
