import assert from "node:assert/strict";
import test from "node:test";

import {
  createAccessRequest,
  createProvisionArtifactBundle,
  createReviewDecision,
} from "../ta-pool-types/index.js";
import {
  createToolReviewActionLedgerEntry,
  createToolReviewGovernanceTrace,
  createToolReviewSessionState,
} from "../ta-pool-tool-review/index.js";
import { createTmaSessionState } from "../ta-pool-provision/index.js";
import {
  createTaActivationAttemptRecord,
  createTaActivationFailure,
  createTaActivationReceipt,
} from "./activation-types.js";
import { createTaHumanGateStateFromReviewDecision } from "./human-gate.js";
import {
  createTapGovernanceSnapshot,
  hasPendingTapGovernanceWork,
} from "./governance-snapshot.js";
import { createTaPendingReplay } from "./replay-policy.js";
import { createTaResumeEnvelope } from "./runtime-snapshot.js";

function createRequest(params: {
  requestId: string;
  capabilityKey: string;
  sessionId?: string;
  runId?: string;
  mode?: "restricted" | "standard" | "permissive";
  requestedTier?: "B0" | "B1" | "B2" | "B3";
}) {
  return createAccessRequest({
    requestId: params.requestId,
    sessionId: params.sessionId ?? "session-1",
    runId: params.runId ?? "run-1",
    agentId: "agent-1",
    requestedCapabilityKey: params.capabilityKey,
    requestedTier: params.requestedTier ?? "B2",
    reason: `Need ${params.capabilityKey}.`,
    mode: params.mode ?? "restricted",
    createdAt: "2026-03-25T10:00:00.000Z",
  });
}

function createGate(params: {
  gateId: string;
  request: ReturnType<typeof createRequest>;
  status: "waiting_human" | "approved" | "rejected";
}) {
  const decision = createReviewDecision({
    decisionId: `${params.gateId}:decision`,
    requestId: params.request.requestId,
    decision: params.status === "rejected" ? "denied" : "escalated_to_human",
    mode: params.request.mode,
    reason: `Gate ${params.status}.`,
    escalationTarget: "human-review",
    createdAt: "2026-03-25T10:00:01.000Z",
  });
  const gate = createTaHumanGateStateFromReviewDecision({
    gateId: params.gateId,
    request: params.request,
    reviewDecision: decision,
    plainLanguageRisk: {
      plainLanguageSummary: "Human review needed.",
      requestedAction: `run ${params.request.requestedCapabilityKey}`,
      riskLevel: "risky",
      whyItIsRisky: "May change project state.",
      possibleConsequence: "Unexpected side effects.",
      whatHappensIfNotRun: "The work stays pending.",
      availableUserActions: [
        {
          actionId: "approve",
          label: "Approve",
          kind: "approve",
        },
      ],
    },
    createdAt: "2026-03-25T10:00:02.000Z",
  });

  if (params.status === "waiting_human") {
    return gate;
  }

  return {
    ...gate,
    status: params.status,
    updatedAt: "2026-03-25T10:00:03.000Z",
  };
}

function createReplay(params: {
  replayId: string;
  request: ReturnType<typeof createRequest>;
  replayPolicy?: "none" | "manual" | "auto_after_verify" | "re_review_then_dispatch";
}) {
  return createTaPendingReplay({
    replayId: params.replayId,
    request: params.request,
    provisionBundle: createProvisionArtifactBundle({
      bundleId: `${params.replayId}:bundle`,
      provisionId: `${params.replayId}:provision`,
      status: "ready",
      toolArtifact: { artifactId: "tool-1", kind: "tool", ref: "tool:1" },
      bindingArtifact: { artifactId: "binding-1", kind: "binding", ref: "binding:1" },
      verificationArtifact: { artifactId: "verification-1", kind: "verification", ref: "verification:1" },
      usageArtifact: { artifactId: "usage-1", kind: "usage", ref: "usage:1" },
      replayPolicy: params.replayPolicy ?? "manual",
      completedAt: "2026-03-25T10:00:04.000Z",
    }),
    createdAt: "2026-03-25T10:00:05.000Z",
  });
}

function createActivationAttempt(params: {
  attemptId: string;
  capabilityKey: string;
  status: "pending" | "started" | "succeeded" | "failed";
  retryable?: boolean;
  targetPool?: string;
}) {
  const base = createTaActivationAttemptRecord({
    attemptId: params.attemptId,
    provisionId: `${params.attemptId}:provision`,
    capabilityKey: params.capabilityKey,
    targetPool: params.targetPool ?? "ta-capability-pool",
    activationMode: "activate_after_verify",
    registrationStrategy: "register_or_replace",
    startedAt: "2026-03-25T10:00:06.000Z",
  });

  if (params.status === "pending" || params.status === "started") {
    return {
      ...base,
      status: params.status,
      updatedAt: "2026-03-25T10:00:07.000Z",
    };
  }

  if (params.status === "succeeded") {
    const receipt = createTaActivationReceipt({
      attemptId: base.attemptId,
      provisionId: base.provisionId,
      capabilityKey: base.capabilityKey,
      targetPool: base.targetPool,
      capabilityId: `${params.attemptId}:capability`,
      bindingId: `${params.attemptId}:binding`,
      generation: 1,
      registrationStrategy: "register",
      activatedAt: "2026-03-25T10:00:08.000Z",
    });
    return {
      ...base,
      status: "succeeded" as const,
      updatedAt: "2026-03-25T10:00:08.000Z",
      completedAt: "2026-03-25T10:00:08.000Z",
      receipt,
    };
  }

  const failure = createTaActivationFailure({
    attemptId: base.attemptId,
    provisionId: base.provisionId,
    capabilityKey: base.capabilityKey,
    failedAt: "2026-03-25T10:00:08.000Z",
    code: "activation_failed",
    message: "Factory resolver missing.",
    retryable: params.retryable,
  });
  return {
    ...base,
    status: "failed" as const,
    updatedAt: "2026-03-25T10:00:08.000Z",
    completedAt: "2026-03-25T10:00:08.000Z",
    failure,
  };
}

test("createTapGovernanceSnapshot groups TAP governance backlog by capability stage", () => {
  const gateRequest = createRequest({
    requestId: "req-gate",
    capabilityKey: "computer.use",
  });
  const replayRequest = createRequest({
    requestId: "req-replay",
    capabilityKey: "skill.doc.generate",
    sessionId: "session-2",
    runId: "run-2",
  });
  const activationFailRequest = createRequest({
    requestId: "req-activation-fail",
    capabilityKey: "repo.write",
  });
  const activationPendingRequest = createRequest({
    requestId: "req-activation-pending",
    capabilityKey: "shell.exec",
  });
  const resumeOnlyRequest = createRequest({
    requestId: "req-resume",
    capabilityKey: "web.search",
  });
  const settledRequest = createRequest({
    requestId: "req-settled",
    capabilityKey: "docs.read",
    mode: "standard",
    requestedTier: "B1",
  });

  const summary = createTapGovernanceSnapshot({
    humanGates: [
      createGate({
        gateId: "gate-waiting",
        request: gateRequest,
        status: "waiting_human",
      }),
      createGate({
        gateId: "gate-approved",
        request: settledRequest,
        status: "approved",
      }),
    ],
    pendingReplays: [
      createReplay({
        replayId: "replay-1",
        request: replayRequest,
        replayPolicy: "manual",
      }),
    ],
    activationAttempts: [
      createActivationAttempt({
        attemptId: "attempt-failed",
        capabilityKey: activationFailRequest.requestedCapabilityKey,
        status: "failed",
        retryable: true,
        targetPool: "ta-governance-pool",
      }),
      createActivationAttempt({
        attemptId: "attempt-started",
        capabilityKey: activationPendingRequest.requestedCapabilityKey,
        status: "started",
      }),
      createActivationAttempt({
        attemptId: "attempt-succeeded",
        capabilityKey: settledRequest.requestedCapabilityKey,
        status: "succeeded",
      }),
    ],
    resumeEnvelopes: [
      createTaResumeEnvelope({
        envelopeId: "resume-1",
        source: "activation",
        requestId: resumeOnlyRequest.requestId,
        sessionId: resumeOnlyRequest.sessionId,
        runId: resumeOnlyRequest.runId,
        capabilityKey: resumeOnlyRequest.requestedCapabilityKey,
        requestedTier: resumeOnlyRequest.requestedTier,
        mode: resumeOnlyRequest.mode,
        reason: resumeOnlyRequest.reason,
      }),
    ],
    toolReviewerSessions: [{
      session: {
        ...createToolReviewSessionState({
          sessionId: "tool-review:provision:resume-1",
          createdAt: "2026-03-25T10:00:03.000Z",
        }),
        status: "blocked",
        latestActionId: "action-tool-review-blocked",
        actionIds: ["action-tool-review-blocked"],
      },
      actions: [
        createToolReviewActionLedgerEntry({
          reviewId: "review-tool-review-blocked",
          sessionId: "tool-review:provision:resume-1",
          input: {
            kind: "lifecycle",
            trace: createToolReviewGovernanceTrace({
              actionId: "action-tool-review-blocked",
              actorId: "tool-reviewer",
              reason: "Lifecycle blocked should stay visible in governance backlog.",
              createdAt: "2026-03-25T10:00:03.000Z",
            }),
            capabilityKey: "mcp.playwright",
            lifecycleAction: "register",
            targetPool: "ta-capability-pool",
            failure: {
              code: "binding_missing",
              message: "Binding not ready.",
            },
          },
          output: {
            kind: "lifecycle",
            actionId: "action-tool-review-blocked",
            status: "lifecycle_blocked",
            capabilityKey: "mcp.playwright",
            lifecycleAction: "register",
            targetPool: "ta-capability-pool",
            summary: "Lifecycle blocked for governance snapshot coverage.",
            failure: {
              code: "binding_missing",
              message: "Binding not ready.",
            },
          },
          status: "blocked",
          recordedAt: "2026-03-25T10:00:03.000Z",
        }),
      ],
    }],
    tmaSessions: [
      createTmaSessionState({
        sessionId: "tma:repo.write:planner",
        provisionId: "provision-tma-1",
        planId: "plan-repo-write",
        requestedCapabilityKey: "repo.write",
        lane: "bootstrap",
        phase: "planner",
        status: "resumable",
        createdAt: "2026-03-25T10:00:09.000Z",
        resumeSummary: "Planner can resume repo.write bundle generation.",
      }),
    ],
    metadata: {
      checkpointId: "cp-governance-1",
    },
  });

  assert.deepEqual(summary.counts.humanGates, {
    total: 2,
    waitingHuman: 1,
    approved: 1,
    rejected: 0,
  });
  assert.deepEqual(summary.counts.pendingReplays, {
    total: 1,
    pending: 1,
    skipped: 0,
    manual: 1,
    verifyThenAuto: 0,
    reReviewThenDispatch: 0,
    none: 0,
  });
  assert.deepEqual(summary.counts.activationAttempts, {
    total: 3,
    pending: 0,
    started: 1,
    succeeded: 1,
    failed: 1,
    rolledBack: 0,
    retryableFailures: 1,
  });
  assert.deepEqual(summary.counts.resumeEnvelopes, {
    total: 1,
    humanGate: 0,
    replay: 0,
    activation: 1,
  });
  assert.deepEqual(summary.counts.toolReviewerSessions, {
    total: 1,
    open: 0,
    waitingHuman: 0,
    blocked: 1,
    completed: 0,
  });
  assert.deepEqual(summary.counts.tmaSessions, {
    total: 1,
    inProgress: 0,
    resumable: 1,
    completed: 0,
  });
  assert.deepEqual(summary.blockingCapabilityKeys, [
    "computer.use",
    "mcp.playwright",
    "repo.write",
    "shell.exec",
    "skill.doc.generate",
    "web.search",
  ]);
  assert.deepEqual(
    summary.capabilities.map((entry) => [entry.capabilityKey, entry.stage]),
    [
      ["computer.use", "waiting_human"],
      ["mcp.playwright", "tool_review_blocked"],
      ["repo.write", "activation_failed"],
      ["shell.exec", "activation_pending"],
      ["skill.doc.generate", "replay_pending"],
      ["web.search", "resume_pending"],
      ["docs.read", "settled"],
    ],
  );
  assert.deepEqual(
    summary.capabilities.find((entry) => entry.capabilityKey === "repo.write")?.activationAttempts.targetPools,
    ["ta-governance-pool"],
  );
  assert.equal(
    summary.capabilities.find((entry) => entry.capabilityKey === "mcp.playwright")?.toolReviewerSessions.blocked,
    1,
  );
  assert.equal(
    summary.capabilities.find((entry) => entry.capabilityKey === "repo.write")?.tmaSessions.resumable,
    1,
  );
  assert.deepEqual(summary.metadata, {
    checkpointId: "cp-governance-1",
  });
  assert.equal(hasPendingTapGovernanceWork(summary), true);
});

test("hasPendingTapGovernanceWork stays false when TAP snapshot only contains settled lifecycle records", () => {
  const settledRequest = createRequest({
    requestId: "req-settled-only",
    capabilityKey: "docs.read",
    mode: "standard",
    requestedTier: "B1",
  });

  const summary = createTapGovernanceSnapshot({
    humanGates: [
      createGate({
        gateId: "gate-approved-only",
        request: settledRequest,
        status: "approved",
      }),
    ],
    activationAttempts: [
      createActivationAttempt({
        attemptId: "attempt-succeeded-only",
        capabilityKey: settledRequest.requestedCapabilityKey,
        status: "succeeded",
      }),
    ],
  });

  assert.deepEqual(summary.blockingCapabilityKeys, []);
  assert.equal(summary.capabilities[0]?.stage, "settled");
  assert.equal(hasPendingTapGovernanceWork(summary), false);
  assert.equal(hasPendingTapGovernanceWork(undefined), false);
});
