import assert from "node:assert/strict";
import test from "node:test";

import {
  createTaActivationAttemptRecord,
  createTaActivationFailure,
  createTaActivationReceipt,
} from "./activation-types.js";
import {
  createTapPoolRuntimeSnapshot as createSnapshot,
  createTaResumeEnvelope as createEnvelope,
} from "./runtime-snapshot.js";

test("activation protocol types freeze attempt, receipt, and failure records", () => {
  const attempt = createTaActivationAttemptRecord({
    attemptId: "attempt-1",
    provisionId: "provision-1",
    capabilityKey: "computer.use",
    targetPool: "ta-capability-pool",
    activationMode: "activate_after_verify",
    registrationStrategy: "register_or_replace",
    startedAt: "2026-03-19T12:00:00.000Z",
  });
  const receipt = createTaActivationReceipt({
    attemptId: attempt.attemptId,
    provisionId: attempt.provisionId,
    capabilityKey: attempt.capabilityKey,
    targetPool: attempt.targetPool,
    capabilityId: "capability-1",
    bindingId: "binding-1",
    generation: 2,
    registrationStrategy: attempt.registrationStrategy,
    activatedAt: "2026-03-19T12:00:02.000Z",
  });
  const failure = createTaActivationFailure({
    attemptId: attempt.attemptId,
    provisionId: attempt.provisionId,
    capabilityKey: attempt.capabilityKey,
    failedAt: "2026-03-19T12:00:03.000Z",
    code: "activation_failed",
    message: "Adapter factory is missing.",
  });

  assert.equal(attempt.status, "pending");
  assert.equal(receipt.generation, 2);
  assert.equal(failure.retryable, true);
});

test("tap runtime snapshot freezes resumable control-plane state shape", () => {
  const resumeEnvelope = createEnvelope({
    envelopeId: "resume-1",
    source: "human_gate",
    requestId: "request-1",
    sessionId: "session-1",
    runId: "run-1",
    capabilityKey: "computer.use",
    requestedTier: "B2",
    mode: "restricted",
    reason: "Resume after a human approval decision.",
    intentRequest: {
      requestId: "request-1",
      intentId: "intent-1",
      capabilityKey: "computer.use",
      input: {
        task: "capture screenshot",
      },
      priority: "normal",
    },
  });

  const snapshot = createSnapshot({
    humanGates: [],
    humanGateEvents: [],
    pendingReplays: [],
    activationAttempts: [],
    resumeEnvelopes: [resumeEnvelope],
  });

  assert.equal(snapshot.resumeEnvelopes.length, 1);
  assert.equal(snapshot.resumeEnvelopes[0]?.source, "human_gate");
});
