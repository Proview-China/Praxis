import assert from "node:assert/strict";
import test from "node:test";

import { createTaActivationAttemptRecord } from "./activation-types.js";
import { createTaHumanGateEvent, createTaHumanGateStateFromReviewDecision } from "./human-gate.js";
import { createTaPendingReplay } from "./replay-policy.js";
import {
  hydratePoolRuntimeSnapshots,
  hydrateTapRuntimeSnapshot,
  serializePoolRuntimeSnapshots,
  serializeTapRuntimeSnapshot,
} from "./runtime-recovery.js";
import { createTaResumeEnvelope } from "./runtime-snapshot.js";
import {
  createAccessRequest,
  createProvisionArtifactBundle,
  createReviewDecision,
} from "../ta-pool-types/index.js";

function createFixtures() {
  const request = createAccessRequest({
    requestId: "req-runtime-recovery-1",
    sessionId: "session-1",
    runId: "run-1",
    agentId: "agent-1",
    requestedCapabilityKey: "computer.use",
    requestedTier: "B2",
    reason: "Need computer use after activation.",
    mode: "restricted",
    createdAt: "2026-03-19T13:00:00.000Z",
  });
  const reviewDecision = createReviewDecision({
    decisionId: "decision-runtime-recovery-1",
    requestId: request.requestId,
    decision: "escalated_to_human",
    mode: request.mode,
    reason: "Need a human gate before execution.",
    escalationTarget: "human-review",
    createdAt: "2026-03-19T13:00:01.000Z",
  });
  const gate = createTaHumanGateStateFromReviewDecision({
    gateId: "gate-runtime-recovery-1",
    request,
    reviewDecision,
    plainLanguageRisk: {
      plainLanguageSummary: "A human must confirm this action.",
      requestedAction: "run computer.use",
      riskLevel: "risky",
      whyItIsRisky: "Restricted mode requires manual confirmation.",
      possibleConsequence: "Browser-like computer use can produce side effects.",
      whatHappensIfNotRun: "The runtime waits inside TAP.",
      availableUserActions: [
        {
          actionId: "approve",
          label: "Approve",
          kind: "approve",
        },
      ],
    },
    createdAt: "2026-03-19T13:00:02.000Z",
  });
  const gateEvent = createTaHumanGateEvent({
    eventId: "event-runtime-recovery-1",
    gateId: gate.gateId,
    requestId: gate.requestId,
    type: "human_gate.requested",
    createdAt: "2026-03-19T13:00:03.000Z",
  });
  const bundle = createProvisionArtifactBundle({
    bundleId: "bundle-runtime-recovery-1",
    provisionId: "provision-runtime-recovery-1",
    status: "ready",
    toolArtifact: { artifactId: "tool-1", kind: "tool", ref: "tool:1" },
    bindingArtifact: { artifactId: "binding-1", kind: "binding", ref: "binding:1" },
    verificationArtifact: { artifactId: "verification-1", kind: "verification", ref: "verification:1" },
    usageArtifact: { artifactId: "usage-1", kind: "usage", ref: "usage:1" },
    replayPolicy: "manual",
    completedAt: "2026-03-19T13:00:04.000Z",
  });
  const replay = createTaPendingReplay({
    replayId: "replay-runtime-recovery-1",
    request,
    provisionBundle: bundle,
    createdAt: "2026-03-19T13:00:05.000Z",
  });
  const attempt = createTaActivationAttemptRecord({
    attemptId: "attempt-runtime-recovery-1",
    provisionId: bundle.provisionId,
    capabilityKey: request.requestedCapabilityKey,
    targetPool: "ta-capability-pool",
    activationMode: "activate_after_verify",
    registrationStrategy: "register_or_replace",
    startedAt: "2026-03-19T13:00:06.000Z",
  });
  const envelope = createTaResumeEnvelope({
    envelopeId: "resume-runtime-recovery-1",
    source: "human_gate",
    requestId: request.requestId,
    sessionId: request.sessionId,
    runId: request.runId,
    capabilityKey: request.requestedCapabilityKey,
    requestedTier: request.requestedTier,
    mode: request.mode,
    reason: request.reason,
  });

  return { gate, gateEvent, replay, attempt, envelope };
}

test("serializeTapRuntimeSnapshot preserves the durable TAP control-plane shape", () => {
  const { gate, gateEvent, replay, attempt, envelope } = createFixtures();
  const snapshot = serializeTapRuntimeSnapshot({
    humanGates: [gate],
    humanGateEvents: [gateEvent],
    pendingReplays: [replay],
    activationAttempts: [attempt],
    resumeEnvelopes: [envelope],
  });

  assert.equal(snapshot.humanGates[0]?.gateId, gate.gateId);
  assert.equal(snapshot.pendingReplays[0]?.replayId, replay.replayId);
  assert.equal(snapshot.activationAttempts[0]?.attemptId, attempt.attemptId);
  assert.equal(snapshot.resumeEnvelopes[0]?.envelopeId, envelope.envelopeId);
});

test("hydrateTapRuntimeSnapshot restores TAP control-plane records into keyed in-memory indexes", () => {
  const { gate, gateEvent, replay, attempt, envelope } = createFixtures();

  const hydrated = hydrateTapRuntimeSnapshot({
    humanGates: [gate],
    humanGateEvents: [gateEvent],
    pendingReplays: [replay],
    activationAttempts: [attempt],
    resumeEnvelopes: [envelope],
  });

  assert.equal(hydrated.humanGates.get(gate.gateId)?.status, "waiting_human");
  assert.equal(hydrated.humanGateEvents.get(gate.gateId)?.length, 1);
  assert.equal(hydrated.pendingReplays.get(replay.replayId)?.nextAction, "manual");
  assert.equal(hydrated.activationAttempts.get(attempt.attemptId)?.targetPool, "ta-capability-pool");
  assert.equal(hydrated.resumeEnvelopes.get(envelope.envelopeId)?.source, "human_gate");
});

test("hydratePoolRuntimeSnapshots rebuilds TAP state from checkpoint-level snapshot wrapper", () => {
  const { gate, gateEvent, replay, attempt, envelope } = createFixtures();
  const snapshots = serializePoolRuntimeSnapshots({
    tap: {
      humanGates: [gate],
      humanGateEvents: [gateEvent],
      pendingReplays: [replay],
      activationAttempts: [attempt],
      resumeEnvelopes: [envelope],
    },
  });

  const hydrated = hydratePoolRuntimeSnapshots(snapshots);
  assert.equal(hydrated.tap.humanGates.get(gate.gateId)?.requestId, gate.requestId);
  assert.equal(hydrated.tap.pendingReplays.get(replay.replayId)?.provisionId, replay.provisionId);
});

test("hydrateTapRuntimeSnapshot rejects duplicate durable identities", () => {
  const { gate, replay, attempt, envelope } = createFixtures();

  assert.throws(() => hydrateTapRuntimeSnapshot({
    humanGates: [gate, gate],
    humanGateEvents: [],
    pendingReplays: [],
    activationAttempts: [],
    resumeEnvelopes: [],
  }), /Duplicate human gate key/);

  assert.throws(() => hydrateTapRuntimeSnapshot({
    humanGates: [],
    humanGateEvents: [],
    pendingReplays: [replay, replay],
    activationAttempts: [],
    resumeEnvelopes: [],
  }), /Duplicate pending replay key/);

  assert.throws(() => hydrateTapRuntimeSnapshot({
    humanGates: [],
    humanGateEvents: [],
    pendingReplays: [],
    activationAttempts: [attempt, attempt],
    resumeEnvelopes: [],
  }), /Duplicate activation attempt key/);

  assert.throws(() => hydrateTapRuntimeSnapshot({
    humanGates: [],
    humanGateEvents: [],
    pendingReplays: [],
    activationAttempts: [],
    resumeEnvelopes: [envelope, envelope],
  }), /Duplicate resume envelope key/);
});
