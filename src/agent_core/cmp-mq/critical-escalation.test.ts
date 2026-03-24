import assert from "node:assert/strict";
import test from "node:test";

import {
  assertCmpCriticalEscalationAllowed,
  createCmpCriticalEscalationEnvelope,
} from "./critical-escalation.js";

test("createCmpCriticalEscalationEnvelope always emits alert-only summary envelopes", () => {
  const envelope = createCmpCriticalEscalationEnvelope({
    escalationId: "esc-1",
    projectId: "praxis-main",
    sourceAgentId: "agent-level-3",
    targetAncestorId: "agent-level-1",
    severity: "critical",
    reason: "parent chain is unavailable and state corruption risk is high",
    evidenceRef: "cmp-alert:esc-1",
    createdAt: "2026-03-24T12:00:00.000Z",
  });

  assert.equal(envelope.deliveryMode, "alert_envelope");
  assert.equal(envelope.redactionLevel, "summary_only");
});

test("assertCmpCriticalEscalationAllowed only permits ancestor-targeted alerts when parent is unavailable", () => {
  const envelope = createCmpCriticalEscalationEnvelope({
    escalationId: "esc-2",
    projectId: "praxis-main",
    sourceAgentId: "agent-level-3",
    targetAncestorId: "agent-level-1",
    severity: "critical",
    reason: "parent chain is unavailable and state corruption risk is high",
    evidenceRef: "cmp-alert:esc-2",
    createdAt: "2026-03-24T12:00:00.000Z",
  });

  assert.doesNotThrow(() => assertCmpCriticalEscalationAllowed({
    envelope,
    knownAncestorIds: ["agent-level-2", "agent-level-1"],
    parentReachability: "unavailable",
  }));

  assert.throws(() => assertCmpCriticalEscalationAllowed({
    envelope,
    knownAncestorIds: ["agent-level-2", "agent-level-1"],
    parentReachability: "healthy",
  }), /unavailable/i);

  assert.throws(() => assertCmpCriticalEscalationAllowed({
    envelope,
    knownAncestorIds: ["agent-level-2"],
    parentReachability: "unavailable",
  }), /ancestor/i);
});

