import assert from "node:assert/strict";
import test from "node:test";

import {
  assertCmpCriticalEscalationAllowed,
  assertCmpSubscriptionAllowed,
  createCmpCriticalEscalationEnvelope,
} from "./index.js";

const childNeighborhood = {
  agentId: "child",
  parentAgentId: "parent",
  peerAgentIds: ["peer-a", "peer-b"],
  childAgentIds: ["grandchild-a"],
} as const;

test("part3 mq e2e only permits parent peer child neighborhood subscriptions", () => {
  assert.doesNotThrow(() => assertCmpSubscriptionAllowed({
    neighborhood: childNeighborhood,
    request: {
      requestId: "sub-parent",
      projectId: "cmp-e2e-project",
      publisherAgentId: "child",
      subscriberAgentId: "parent",
      relation: "parent",
      channel: "to_parent",
      createdAt: "2026-03-24T12:20:00.000Z",
    },
  }));
  assert.doesNotThrow(() => assertCmpSubscriptionAllowed({
    neighborhood: childNeighborhood,
    request: {
      requestId: "sub-peer",
      projectId: "cmp-e2e-project",
      publisherAgentId: "child",
      subscriberAgentId: "peer-a",
      relation: "peer",
      channel: "peer",
      createdAt: "2026-03-24T12:20:00.000Z",
    },
  }));
  assert.doesNotThrow(() => assertCmpSubscriptionAllowed({
    neighborhood: childNeighborhood,
    request: {
      requestId: "sub-child",
      projectId: "cmp-e2e-project",
      publisherAgentId: "child",
      subscriberAgentId: "grandchild-a",
      relation: "child",
      channel: "to_children",
      createdAt: "2026-03-24T12:20:00.000Z",
    },
  }));

  assert.throws(() => assertCmpSubscriptionAllowed({
    neighborhood: childNeighborhood,
    request: {
      requestId: "sub-root",
      projectId: "cmp-e2e-project",
      publisherAgentId: "child",
      subscriberAgentId: "root",
      relation: "parent",
      channel: "to_parent",
      createdAt: "2026-03-24T12:20:00.000Z",
    },
    knownAncestorIds: ["root"],
  }), /ancestor/i);

  assert.throws(() => assertCmpSubscriptionAllowed({
    neighborhood: childNeighborhood,
    request: {
      requestId: "sub-parent-peer",
      projectId: "cmp-e2e-project",
      publisherAgentId: "child",
      subscriberAgentId: "parent-peer",
      relation: "peer",
      channel: "peer",
      createdAt: "2026-03-24T12:20:00.000Z",
    },
    parentPeerIds: ["parent-peer"],
  }), /parent-peer/i);
});

test("part3 mq e2e keeps critical escalation as the only upward exception", () => {
  const escalation = createCmpCriticalEscalationEnvelope({
    escalationId: "escalation-1",
    projectId: "cmp-e2e-project",
    sourceAgentId: "child",
    targetAncestorId: "root",
    severity: "critical",
    reason: "parent is unavailable",
    evidenceRef: "alert:1",
    createdAt: "2026-03-24T12:21:00.000Z",
  });

  assert.doesNotThrow(() => assertCmpCriticalEscalationAllowed({
    envelope: escalation,
    knownAncestorIds: ["root"],
    parentReachability: "unavailable",
  }));

  assert.throws(() => assertCmpCriticalEscalationAllowed({
    envelope: escalation,
    knownAncestorIds: ["root"],
    parentReachability: "healthy",
  }), /unavailable/i);
});
