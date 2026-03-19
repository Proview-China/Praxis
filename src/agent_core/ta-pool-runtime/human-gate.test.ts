import assert from "node:assert/strict";
import test from "node:test";

import { createAccessRequest, createReviewDecision } from "../ta-pool-types/index.js";
import {
  applyTaHumanGateEvent,
  createTaHumanGateEvent,
  createTaHumanGateStateFromReviewDecision,
} from "./human-gate.js";

test("human gate state transitions through requested and approved events", () => {
  const request = createAccessRequest({
    requestId: "req-human-gate-1",
    sessionId: "session-1",
    runId: "run-1",
    agentId: "agent-1",
    requestedCapabilityKey: "search.ground",
    requestedTier: "B1",
    reason: "Need grounded search.",
    mode: "restricted",
    createdAt: "2026-03-19T10:00:00.000Z",
  });
  const reviewDecision = createReviewDecision({
    decisionId: "decision-human-gate-1",
    requestId: request.requestId,
    decision: "escalated_to_human",
    mode: request.mode,
    reason: "Restricted mode requires a human gate.",
    escalationTarget: "human-review",
    createdAt: "2026-03-19T10:00:01.000Z",
  });

  const gate = createTaHumanGateStateFromReviewDecision({
    gateId: "gate-1",
    request,
    reviewDecision,
    plainLanguageRisk: {
      plainLanguageSummary: "This waits for a human before dispatch.",
      requestedAction: "run search.ground",
      riskLevel: "risky",
      whyItIsRisky: "Restricted mode should not auto-run this capability.",
      possibleConsequence: "A human is needed to confirm the request.",
      whatHappensIfNotRun: "The run pauses inside TAP.",
      availableUserActions: [
        {
          actionId: "approve",
          label: "Approve",
          kind: "approve",
        },
      ],
    },
    createdAt: "2026-03-19T10:00:02.000Z",
  });

  const requested = applyTaHumanGateEvent({
    gate,
    event: createTaHumanGateEvent({
      eventId: "event-requested-1",
      gateId: gate.gateId,
      requestId: request.requestId,
      type: "human_gate.requested",
      createdAt: "2026-03-19T10:00:03.000Z",
    }),
  });
  const approved = applyTaHumanGateEvent({
    gate: requested,
    event: createTaHumanGateEvent({
      eventId: "event-approved-1",
      gateId: gate.gateId,
      requestId: request.requestId,
      type: "human_gate.approved",
      createdAt: "2026-03-19T10:00:04.000Z",
    }),
  });

  assert.equal(requested.status, "waiting_human");
  assert.equal(approved.status, "approved");
  assert.equal(approved.mode, "restricted");
});
