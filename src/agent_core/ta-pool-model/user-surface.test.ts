import assert from "node:assert/strict";
import test from "node:test";

import { createTapGovernanceObject } from "./governance-object.js";
import { createTapUserSurfaceSnapshot } from "./user-surface.js";
import type {
  TapCapabilityGovernanceSnapshot,
  TapGovernanceCapabilityStage,
  TapGovernanceSnapshot,
} from "../ta-pool-runtime/governance-snapshot.js";
import { createAccessRequest, createReviewDecision } from "../ta-pool-types/index.js";
import { createTaHumanGateStateFromReviewDecision } from "../ta-pool-runtime/human-gate.js";
import { createTapGovernanceSnapshot } from "../ta-pool-runtime/governance-snapshot.js";

function createCapabilitySnapshot(
  capabilityKey: string,
  stage: TapGovernanceCapabilityStage,
): TapCapabilityGovernanceSnapshot {
  return {
    capabilityKey,
    stage,
    activeBlockers: stage === "settled" || stage === "idle" ? [] : [stage],
    requestIds: [],
    sessionIds: [],
    runIds: [],
    modes: [],
    requestedTiers: [],
    humanGates: {
      total: 0,
      waitingHuman: 0,
      approved: 0,
      rejected: 0,
    },
    pendingReplays: {
      total: 0,
      pending: 0,
      skipped: 0,
      manual: 0,
      verifyThenAuto: 0,
      reReviewThenDispatch: 0,
      none: 0,
    },
    activationAttempts: {
      total: 0,
      pending: 0,
      started: 0,
      succeeded: 0,
      failed: 0,
      rolledBack: 0,
      retryableFailures: 0,
      targetPools: [],
    },
    resumeEnvelopes: {
      total: 0,
      humanGate: 0,
      replay: 0,
      activation: 0,
    },
    toolReviewerSessions: {
      total: 0,
      open: 0,
      waitingHuman: 0,
      blocked: 0,
      completed: 0,
    },
    tmaSessions: {
      total: 0,
      inProgress: 0,
      resumable: 0,
      completed: 0,
    },
  };
}

function createSyntheticGovernanceSnapshot(input: {
  capabilities: TapCapabilityGovernanceSnapshot[];
  counts?: Partial<TapGovernanceSnapshot["counts"]>;
}): TapGovernanceSnapshot {
  return {
    counts: {
      humanGates: {
        total: 0,
        waitingHuman: 0,
        approved: 0,
        rejected: 0,
        ...(input.counts?.humanGates ?? {}),
      },
      pendingReplays: {
        total: 0,
        pending: 0,
        skipped: 0,
        manual: 0,
        verifyThenAuto: 0,
        reReviewThenDispatch: 0,
        none: 0,
        ...(input.counts?.pendingReplays ?? {}),
      },
      activationAttempts: {
        total: 0,
        pending: 0,
        started: 0,
        succeeded: 0,
        failed: 0,
        rolledBack: 0,
        retryableFailures: 0,
        ...(input.counts?.activationAttempts ?? {}),
      },
      resumeEnvelopes: {
        total: 0,
        humanGate: 0,
        replay: 0,
        activation: 0,
        ...(input.counts?.resumeEnvelopes ?? {}),
      },
      toolReviewerSessions: {
        total: 0,
        open: 0,
        waitingHuman: 0,
        blocked: 0,
        completed: 0,
        ...(input.counts?.toolReviewerSessions ?? {}),
      },
      tmaSessions: {
        total: 0,
        inProgress: 0,
        resumable: 0,
        completed: 0,
        ...(input.counts?.tmaSessions ?? {}),
      },
    },
    capabilities: input.capabilities,
    blockingCapabilityKeys: input.capabilities
      .filter((capability) => capability.activeBlockers.length > 0)
      .map((capability) => capability.capabilityKey),
  };
}

test("tap user surface summarizes current layer and blocking counts", () => {
  const request = createAccessRequest({
    requestId: "req-user-surface",
    sessionId: "session-user-surface",
    runId: "run-user-surface",
    agentId: "agent-main",
    requestedCapabilityKey: "computer.use",
    requestedTier: "B2",
    reason: "Need browser automation.",
    mode: "restricted",
    createdAt: "2026-03-29T10:00:00.000Z",
  });
  const gate = createTaHumanGateStateFromReviewDecision({
    gateId: "gate-user-surface",
    request,
    reviewDecision: createReviewDecision({
      decisionId: "decision-user-surface",
      requestId: request.requestId,
      decision: "escalated_to_human",
      mode: request.mode,
      reason: "Needs approval.",
      escalationTarget: "human-review",
      createdAt: "2026-03-29T10:00:01.000Z",
    }),
    plainLanguageRisk: {
      plainLanguageSummary: "Needs human approval.",
      requestedAction: "browser automation",
      riskLevel: "risky",
      whyItIsRisky: "It can affect the browser session.",
      possibleConsequence: "Unexpected page interaction.",
      whatHappensIfNotRun: "The task stays blocked.",
      availableUserActions: [],
    },
    createdAt: "2026-03-29T10:00:02.000Z",
  });

  const snapshot = createTapUserSurfaceSnapshot({
    governance: createTapGovernanceObject({
      workspaceMode: "restricted",
    }),
    governanceSnapshot: createTapGovernanceSnapshot({
      humanGates: [gate],
    }),
  });

  assert.equal(snapshot.currentLayer, "reviewer");
  assert.equal(snapshot.pendingHumanGateCount, 1);
  assert.match(snapshot.summary, /waiting for 1 human approval/i);
});

test("tap user surface routes tool-review waiting state to the tool reviewer layer", () => {
  const snapshot = createTapUserSurfaceSnapshot({
    governance: createTapGovernanceObject({
      workspaceMode: "standard",
    }),
    governanceSnapshot: createSyntheticGovernanceSnapshot({
      counts: {
        toolReviewerSessions: {
          total: 1,
          open: 0,
          waitingHuman: 1,
          blocked: 0,
          completed: 0,
        },
      },
      capabilities: [
        createCapabilitySnapshot("mcp.playwright", "waiting_human"),
      ],
    }),
  });

  assert.equal(snapshot.currentLayer, "tool_reviewer");
  assert.equal(snapshot.pendingHumanGateCount, 1);
  assert.deepEqual(snapshot.activeCapabilityKeys, []);
  assert.match(snapshot.summary, /Tool review is waiting for 1 human decision/i);
  assert.match(snapshot.summary, /mcp\.playwright/);
});

test("tap user surface exposes runtime-active lanes without treating settled lanes as active", () => {
  const snapshot = createTapUserSurfaceSnapshot({
    governance: createTapGovernanceObject({
      workspaceMode: "permissive",
    }),
    governanceSnapshot: createSyntheticGovernanceSnapshot({
      counts: {
        activationAttempts: {
          total: 1,
          pending: 0,
          started: 1,
          succeeded: 0,
          failed: 0,
          rolledBack: 0,
          retryableFailures: 0,
        },
        pendingReplays: {
          total: 1,
          pending: 1,
          skipped: 0,
          manual: 1,
          verifyThenAuto: 0,
          reReviewThenDispatch: 0,
          none: 0,
        },
      },
      capabilities: [
        createCapabilitySnapshot("shell.exec", "activation_pending"),
        createCapabilitySnapshot("skill.doc.generate", "replay_pending"),
        createCapabilitySnapshot("docs.read", "settled"),
      ],
    }),
  });

  assert.equal(snapshot.currentLayer, "runtime");
  assert.deepEqual(snapshot.activeCapabilityKeys, ["shell.exec", "skill.doc.generate"]);
  assert.match(snapshot.summary, /Runtime is activating 1 capability lane/i);
  assert.match(snapshot.summary, /shell\.exec/);
});

test("tap user surface sends TMA work to the tma layer", () => {
  const snapshot = createTapUserSurfaceSnapshot({
    governance: createTapGovernanceObject({
      workspaceMode: "restricted",
    }),
    governanceSnapshot: createSyntheticGovernanceSnapshot({
      counts: {
        tmaSessions: {
          total: 1,
          inProgress: 1,
          resumable: 0,
          completed: 0,
        },
      },
      capabilities: [
        createCapabilitySnapshot("repo.write", "tma_pending"),
      ],
    }),
  });

  assert.equal(snapshot.currentLayer, "tma");
  assert.deepEqual(snapshot.activeCapabilityKeys, ["repo.write"]);
  assert.match(snapshot.summary, /TMA is still working on 1 capability lane/i);
  assert.match(snapshot.summary, /repo\.write/);
});
