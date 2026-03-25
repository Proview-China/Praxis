import assert from "node:assert/strict";
import test from "node:test";

import { createInitialAgentState } from "../state/state-types.js";
import {
  createAccessRequest,
  createReviewDecision,
} from "../ta-pool-types/index.js";
import { createTaActivationAttemptRecord } from "../ta-pool-runtime/activation-types.js";
import { createTaHumanGateStateFromReviewDecision } from "../ta-pool-runtime/human-gate.js";
import { createTapPoolRuntimeSnapshot } from "../ta-pool-runtime/runtime-snapshot.js";
import type { RunRecord } from "../types/index.js";
import {
  checkpointHasPendingTapGovernanceWork,
  readTapGovernanceSnapshotFromCheckpoint,
} from "./pool-runtime-governance.js";

function createRunRecord(): RunRecord {
  return {
    runId: "run-checkpoint-governance-1",
    sessionId: "session-checkpoint-governance-1",
    status: "deciding",
    phase: "decision",
    goal: {
      goalId: "goal-checkpoint-governance-1",
      instructionText: "Review pending governance work",
      successCriteria: [],
      failureCriteria: [],
      constraints: [],
      inputRefs: [],
      cacheKey: "goal-checkpoint-governance-1",
    },
    currentStep: 1,
    pendingIntentId: undefined,
    lastEventId: undefined,
    lastResult: undefined,
    lastCheckpointRef: undefined,
    startedAt: "2026-03-25T12:00:00.000Z",
    endedAt: undefined,
    metadata: undefined,
  };
}

test("readTapGovernanceSnapshotFromCheckpoint summarizes pending governance from checkpoint snapshots", () => {
  const request = createAccessRequest({
    requestId: "req-checkpoint-governance-1",
    sessionId: "session-checkpoint-governance-1",
    runId: "run-checkpoint-governance-1",
    agentId: "agent-1",
    requestedCapabilityKey: "computer.use",
    requestedTier: "B2",
    reason: "Need computer.use after restart.",
    mode: "restricted",
    createdAt: "2026-03-25T12:00:01.000Z",
  });
  const decision = createReviewDecision({
    decisionId: "decision-checkpoint-governance-1",
    requestId: request.requestId,
    decision: "escalated_to_human",
    mode: request.mode,
    reason: "A human must approve this capability.",
    escalationTarget: "human-review",
    createdAt: "2026-03-25T12:00:02.000Z",
  });
  const gate = createTaHumanGateStateFromReviewDecision({
    gateId: "gate-checkpoint-governance-1",
    request,
    reviewDecision: decision,
    plainLanguageRisk: {
      plainLanguageSummary: "Human approval is required.",
      requestedAction: "run computer.use",
      riskLevel: "risky",
      whyItIsRisky: "This may change the environment.",
      possibleConsequence: "Unexpected side effects are possible.",
      whatHappensIfNotRun: "The run remains paused.",
      availableUserActions: [
        {
          actionId: "approve",
          label: "Approve",
          kind: "approve",
        },
      ],
    },
    createdAt: "2026-03-25T12:00:03.000Z",
  });
  const attempt = {
    ...createTaActivationAttemptRecord({
      attemptId: "attempt-checkpoint-governance-1",
      provisionId: "provision-checkpoint-governance-1",
      capabilityKey: "repo.write",
      targetPool: "ta-governance-pool",
      activationMode: "activate_after_verify",
      registrationStrategy: "register_or_replace",
      startedAt: "2026-03-25T12:00:04.000Z",
    }),
    status: "failed" as const,
    updatedAt: "2026-03-25T12:00:05.000Z",
    completedAt: "2026-03-25T12:00:05.000Z",
    failure: {
      attemptId: "attempt-checkpoint-governance-1",
      provisionId: "provision-checkpoint-governance-1",
      capabilityKey: "repo.write",
      failedAt: "2026-03-25T12:00:05.000Z",
      code: "activation_failed",
      message: "Activation adapter factory missing.",
      retryable: true,
    },
  };
  const checkpoint = {
    record: {
      checkpointId: "cp-checkpoint-governance-1",
      sessionId: "session-checkpoint-governance-1",
      runId: "run-checkpoint-governance-1",
      tier: "fast" as const,
      reason: "manual" as const,
      createdAt: "2026-03-25T12:00:06.000Z",
    },
    snapshot: {
      run: createRunRecord(),
      state: createInitialAgentState(),
      poolRuntimeSnapshots: {
        tap: createTapPoolRuntimeSnapshot({
          humanGates: [gate],
          activationAttempts: [attempt],
        }),
      },
    },
  };

  const summary = readTapGovernanceSnapshotFromCheckpoint(checkpoint);

  assert.deepEqual(summary?.blockingCapabilityKeys, [
    "computer.use",
    "repo.write",
  ]);
  assert.equal(summary?.counts.humanGates.waitingHuman, 1);
  assert.equal(summary?.counts.activationAttempts.failed, 1);
  assert.equal(checkpointHasPendingTapGovernanceWork(checkpoint), true);
});

test("checkpoint governance helpers stay empty when checkpoint carries no TAP snapshot", () => {
  const checkpoint = {
    record: {
      checkpointId: "cp-checkpoint-governance-empty",
      sessionId: "session-checkpoint-governance-empty",
      runId: "run-checkpoint-governance-empty",
      tier: "fast" as const,
      reason: "manual" as const,
      createdAt: "2026-03-25T12:10:00.000Z",
    },
    snapshot: {
      run: createRunRecord(),
      state: createInitialAgentState(),
    },
  };

  assert.equal(readTapGovernanceSnapshotFromCheckpoint(checkpoint), undefined);
  assert.equal(checkpointHasPendingTapGovernanceWork(checkpoint), false);
});
