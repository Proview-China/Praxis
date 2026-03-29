import assert from "node:assert/strict";
import test from "node:test";

import { createTapGovernanceObject } from "./governance-object.js";
import { createTapUserSurfaceSnapshot } from "./user-surface.js";
import { createTapGovernanceSnapshot } from "../ta-pool-runtime/governance-snapshot.js";
import { createAccessRequest, createReviewDecision } from "../ta-pool-types/index.js";
import { createTaHumanGateStateFromReviewDecision } from "../ta-pool-runtime/human-gate.js";

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
