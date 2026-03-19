import assert from "node:assert/strict";
import test from "node:test";

import { createInitialAgentState } from "../state/state-types.js";
import type { RunRecord } from "../types/index.js";
import { createTaActivationAttemptRecord } from "./activation-types.js";
import { createTaHumanGateEvent, createTaHumanGateStateFromReviewDecision } from "./human-gate.js";
import { createTaPendingReplay } from "./replay-policy.js";
import {
  createTapPoolRuntimeSnapshot,
  createTaResumeEnvelope,
} from "./runtime-snapshot.js";
import {
  createTapRuntimeSnapshotFromState,
  mergeTapRuntimeSnapshotIntoCheckpoint,
  readPoolRuntimeSnapshotsFromCheckpoint,
  readTapRuntimeSnapshotFromCheckpoint,
} from "./runtime-checkpoint.js";
import {
  createAccessRequest,
  createProvisionArtifactBundle,
  createReviewDecision,
} from "../ta-pool-types/index.js";

function createRunRecord(overrides: Partial<RunRecord> = {}): RunRecord {
  return {
    runId: overrides.runId ?? "run-1",
    sessionId: overrides.sessionId ?? "session-1",
    status: overrides.status ?? "deciding",
    phase: overrides.phase ?? "decision",
    goal: overrides.goal ?? {
      goalId: "goal-1",
      instructionText: "Do the thing",
      successCriteria: [],
      failureCriteria: [],
      constraints: [],
      inputRefs: [],
      cacheKey: "compiled-goal-1",
    },
    currentStep: overrides.currentStep ?? 1,
    pendingIntentId: overrides.pendingIntentId,
    lastEventId: overrides.lastEventId,
    lastResult: overrides.lastResult,
    lastCheckpointRef: overrides.lastCheckpointRef,
    startedAt: overrides.startedAt ?? "2026-03-19T16:00:00.000Z",
    endedAt: overrides.endedAt,
    metadata: overrides.metadata,
  };
}

function createTapFixtures() {
  const request = createAccessRequest({
    requestId: "req-runtime-checkpoint-1",
    sessionId: "session-1",
    runId: "run-1",
    agentId: "agent-1",
    requestedCapabilityKey: "computer.use",
    requestedTier: "B2",
    reason: "Need computer use after restart.",
    mode: "restricted",
    createdAt: "2026-03-19T16:00:00.000Z",
  });
  const reviewDecision = createReviewDecision({
    decisionId: "decision-runtime-checkpoint-1",
    requestId: request.requestId,
    decision: "escalated_to_human",
    mode: request.mode,
    reason: "Human gate required.",
    escalationTarget: "human-review",
    createdAt: "2026-03-19T16:00:01.000Z",
  });
  const gate = createTaHumanGateStateFromReviewDecision({
    gateId: "gate-runtime-checkpoint-1",
    request,
    reviewDecision,
    plainLanguageRisk: {
      plainLanguageSummary: "Human approval is required.",
      requestedAction: "run computer.use",
      riskLevel: "risky",
      whyItIsRisky: "Restricted mode needs confirmation.",
      possibleConsequence: "Computer use may change the environment.",
      whatHappensIfNotRun: "The runtime remains deferred.",
      availableUserActions: [
        {
          actionId: "approve",
          label: "Approve",
          kind: "approve",
        },
      ],
    },
    createdAt: "2026-03-19T16:00:02.000Z",
  });
  const gateEvent = createTaHumanGateEvent({
    eventId: "event-runtime-checkpoint-1",
    gateId: gate.gateId,
    requestId: gate.requestId,
    type: "human_gate.requested",
    createdAt: "2026-03-19T16:00:03.000Z",
  });
  const bundle = createProvisionArtifactBundle({
    bundleId: "bundle-runtime-checkpoint-1",
    provisionId: "provision-runtime-checkpoint-1",
    status: "ready",
    toolArtifact: { artifactId: "tool-1", kind: "tool", ref: "tool:1" },
    bindingArtifact: { artifactId: "binding-1", kind: "binding", ref: "binding:1" },
    verificationArtifact: { artifactId: "verification-1", kind: "verification", ref: "verification:1" },
    usageArtifact: { artifactId: "usage-1", kind: "usage", ref: "usage:1" },
    replayPolicy: "manual",
    completedAt: "2026-03-19T16:00:04.000Z",
  });
  const replay = createTaPendingReplay({
    replayId: "replay-runtime-checkpoint-1",
    request,
    provisionBundle: bundle,
    createdAt: "2026-03-19T16:00:05.000Z",
  });
  const activationAttempt = createTaActivationAttemptRecord({
    attemptId: "attempt-runtime-checkpoint-1",
    provisionId: bundle.provisionId,
    capabilityKey: request.requestedCapabilityKey,
    targetPool: "ta-capability-pool",
    activationMode: "activate_after_verify",
    registrationStrategy: "register_or_replace",
    startedAt: "2026-03-19T16:00:06.000Z",
  });
  const resumeEnvelope = createTaResumeEnvelope({
    envelopeId: "resume-runtime-checkpoint-1",
    source: "human_gate",
    requestId: request.requestId,
    sessionId: request.sessionId,
    runId: request.runId,
    capabilityKey: request.requestedCapabilityKey,
    requestedTier: request.requestedTier,
    mode: request.mode,
    reason: request.reason,
  });

  return { gate, gateEvent, replay, activationAttempt, resumeEnvelope };
}

test("createTapRuntimeSnapshotFromState serializes iterable runtime indexes into durable snapshot", () => {
  const fixtures = createTapFixtures();
  const humanGateEvents = new Map([[fixtures.gate.gateId, [fixtures.gateEvent] as const]]);
  const snapshot = createTapRuntimeSnapshotFromState({
    humanGates: [fixtures.gate],
    humanGateEvents,
    pendingReplays: [fixtures.replay],
    activationAttempts: [fixtures.activationAttempt],
    resumeEnvelopes: [fixtures.resumeEnvelope],
  });

  assert.equal(snapshot.humanGates.length, 1);
  assert.equal(snapshot.humanGateEvents.length, 1);
  assert.equal(snapshot.pendingReplays[0]?.replayId, fixtures.replay.replayId);
});

test("mergeTapRuntimeSnapshotIntoCheckpoint writes TAP state into poolRuntimeSnapshots", () => {
  const fixtures = createTapFixtures();
  const tap = createTapPoolRuntimeSnapshot({
    humanGates: [fixtures.gate],
    humanGateEvents: [fixtures.gateEvent],
    pendingReplays: [fixtures.replay],
    activationAttempts: [fixtures.activationAttempt],
    resumeEnvelopes: [fixtures.resumeEnvelope],
  });

  const merged = mergeTapRuntimeSnapshotIntoCheckpoint({
    run: createRunRecord(),
    state: createInitialAgentState(),
  }, tap);

  assert.equal(merged.poolRuntimeSnapshots?.tap?.humanGates[0]?.gateId, fixtures.gate.gateId);
});

test("readTapRuntimeSnapshotFromCheckpoint reads TAP sub-snapshot from checkpoint-like sources", () => {
  const fixtures = createTapFixtures();
  const checkpoint = {
    record: {
      checkpointId: "cp-1",
      sessionId: "session-1",
      runId: "run-1",
      tier: "fast" as const,
      reason: "manual" as const,
      createdAt: "2026-03-19T16:00:10.000Z",
    },
    snapshot: {
      run: createRunRecord(),
      state: createInitialAgentState(),
      poolRuntimeSnapshots: {
        tap: createTapPoolRuntimeSnapshot({
          humanGates: [fixtures.gate],
          humanGateEvents: [fixtures.gateEvent],
          pendingReplays: [fixtures.replay],
          activationAttempts: [fixtures.activationAttempt],
          resumeEnvelopes: [fixtures.resumeEnvelope],
        }),
      },
    },
  };

  assert.equal(
    readTapRuntimeSnapshotFromCheckpoint(checkpoint)?.resumeEnvelopes[0]?.envelopeId,
    fixtures.resumeEnvelope.envelopeId,
  );
  assert.equal(
    readPoolRuntimeSnapshotsFromCheckpoint(checkpoint)?.tap?.activationAttempts[0]?.attemptId,
    fixtures.activationAttempt.attemptId,
  );
});
