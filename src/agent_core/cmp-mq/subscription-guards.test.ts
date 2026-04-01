import assert from "node:assert/strict";
import test from "node:test";

import {
  assertCmpSubscriptionAllowed,
  canCmpSubscribeToChannel,
  resolveCmpSubscriptionRelation,
} from "./subscription-guards.js";

const neighborhood = {
  agentId: "agent-yahoo",
  parentAgentId: "agent-parent",
  peerAgentIds: ["agent-peer-a", "agent-peer-b"],
  childAgentIds: ["agent-child-a", "agent-child-b"],
} as const;

test("resolveCmpSubscriptionRelation only resolves parent peer or child subscribers", () => {
  assert.equal(resolveCmpSubscriptionRelation({
    neighborhood,
    subscriberAgentId: "agent-parent",
  }), "parent");
  assert.equal(resolveCmpSubscriptionRelation({
    neighborhood,
    subscriberAgentId: "agent-peer-a",
  }), "peer");
  assert.equal(resolveCmpSubscriptionRelation({
    neighborhood,
    subscriberAgentId: "agent-child-a",
  }), "child");
  assert.equal(resolveCmpSubscriptionRelation({
    neighborhood,
    subscriberAgentId: "agent-root",
  }), undefined);
});

test("canCmpSubscribeToChannel keeps subscription rights inside the neighborhood contract", () => {
  assert.equal(canCmpSubscribeToChannel({
    relation: "parent",
    channel: "to_parent",
  }), true);
  assert.equal(canCmpSubscribeToChannel({
    relation: "peer",
    channel: "peer",
  }), true);
  assert.equal(canCmpSubscribeToChannel({
    relation: "child",
    channel: "to_children",
  }), true);
  assert.equal(canCmpSubscribeToChannel({
    relation: "peer",
    channel: "to_parent",
  }), false);
});

test("assertCmpSubscriptionAllowed blocks ancestor skipping and parent-peer direct subscriptions", () => {
  assert.doesNotThrow(() => assertCmpSubscriptionAllowed({
    neighborhood,
    request: {
      requestId: "sub-parent-1",
      projectId: "praxis-main",
      publisherAgentId: "agent-yahoo",
      subscriberAgentId: "agent-parent",
      relation: "parent",
      channel: "to_parent",
      createdAt: "2026-03-24T12:00:00.000Z",
    },
  }));

  assert.throws(() => assertCmpSubscriptionAllowed({
    neighborhood,
    request: {
      requestId: "sub-root-1",
      projectId: "praxis-main",
      publisherAgentId: "agent-yahoo",
      subscriberAgentId: "agent-root",
      relation: "parent",
      channel: "to_parent",
      createdAt: "2026-03-24T12:00:00.000Z",
    },
    knownAncestorIds: ["agent-root"],
  }), /ancestor/i);

  assert.throws(() => assertCmpSubscriptionAllowed({
    neighborhood,
    request: {
      requestId: "sub-parent-peer-1",
      projectId: "praxis-main",
      publisherAgentId: "agent-yahoo",
      subscriberAgentId: "agent-parent-peer",
      relation: "peer",
      channel: "peer",
      createdAt: "2026-03-24T12:00:00.000Z",
    },
    parentPeerIds: ["agent-parent-peer"],
  }), /parent-peer/i);
});

test("assertCmpSubscriptionAllowed rejects channel/relation mismatches", () => {
  assert.throws(() => assertCmpSubscriptionAllowed({
    neighborhood,
    request: {
      requestId: "sub-peer-wrong-1",
      projectId: "praxis-main",
      publisherAgentId: "agent-yahoo",
      subscriberAgentId: "agent-peer-a",
      relation: "peer",
      channel: "to_parent",
      createdAt: "2026-03-24T12:00:00.000Z",
    },
  }), /cannot subscribe/i);
});

