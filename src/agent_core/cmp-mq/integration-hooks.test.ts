import assert from "node:assert/strict";
import test from "node:test";

import { createAgentLineage, createCmpBranchFamily } from "../cmp-types/index.js";
import {
  assertCmpCriticalEscalationAllowed,
  assertCmpValidatedNeighborhoodPublishPlan,
  createCmpCriticalEscalationEnvelope,
  createCmpIcmaPublishEnvelope,
  createCmpSubscriptionRequestsForEnvelope,
} from "./index.js";

const rootLineage = createAgentLineage({
  agentId: "root",
  depth: 0,
  projectId: "cmp-project-e2e",
  branchFamily: createCmpBranchFamily({
    workBranch: "work/root",
    cmpBranch: "cmp/root",
    mpBranch: "mp/root",
    tapBranch: "tap/root",
  }),
  childAgentIds: ["parent"],
});

const parentLineage = createAgentLineage({
  agentId: "parent",
  parentAgentId: "root",
  depth: 1,
  projectId: "cmp-project-e2e",
  branchFamily: createCmpBranchFamily({
    workBranch: "work/parent",
    cmpBranch: "cmp/parent",
    mpBranch: "mp/parent",
    tapBranch: "tap/parent",
  }),
  childAgentIds: ["child-a", "child-b"],
  metadata: {
    ancestorAgentIds: ["root"],
  },
});

const childNeighborhood = {
  agentId: "child-a",
  parentAgentId: "parent",
  peerAgentIds: ["child-b"],
  childAgentIds: ["grandchild-a"],
} as const;

test("cmp-mq cross-part hook lowers ICMA envelopes into validated neighborhood subscriptions only", () => {
  const parentEnvelope = createCmpIcmaPublishEnvelope({
    envelopeId: "env-parent",
    projectId: "cmp-project-e2e",
    sourceAgentId: "child-a",
    neighborhood: childNeighborhood,
    direction: "parent",
    granularityLabel: "checked-snapshot-delta",
    payloadRef: "git:cmp/child-a@abc123",
    createdAt: "2026-03-24T18:00:00.000Z",
  });
  const peerEnvelope = createCmpIcmaPublishEnvelope({
    envelopeId: "env-peer",
    projectId: "cmp-project-e2e",
    sourceAgentId: "child-a",
    neighborhood: childNeighborhood,
    direction: "peer",
    granularityLabel: "peer-update",
    payloadRef: "db:projection-child-a",
    createdAt: "2026-03-24T18:00:00.000Z",
  });
  const childEnvelope = createCmpIcmaPublishEnvelope({
    envelopeId: "env-child",
    projectId: "cmp-project-e2e",
    sourceAgentId: "child-a",
    neighborhood: childNeighborhood,
    direction: "child",
    granularityLabel: "child-seed",
    payloadRef: "db:package-child-a",
    createdAt: "2026-03-24T18:00:00.000Z",
  });

  const parentRequests = assertCmpValidatedNeighborhoodPublishPlan({
    neighborhood: childNeighborhood,
    envelope: parentEnvelope,
    knownAncestorIds: ["root"],
    parentPeerIds: ["root-peer"],
  });
  const peerRequests = assertCmpValidatedNeighborhoodPublishPlan({
    neighborhood: childNeighborhood,
    envelope: peerEnvelope,
    knownAncestorIds: ["root"],
    parentPeerIds: ["root-peer"],
  });
  const childRequests = assertCmpValidatedNeighborhoodPublishPlan({
    neighborhood: childNeighborhood,
    envelope: childEnvelope,
    knownAncestorIds: ["root"],
    parentPeerIds: ["root-peer"],
  });

  assert.deepEqual(parentRequests.map((request) => request.subscriberAgentId), ["parent"]);
  assert.deepEqual(peerRequests.map((request) => request.subscriberAgentId), ["child-b"]);
  assert.deepEqual(childRequests.map((request) => request.subscriberAgentId), ["grandchild-a"]);
  assert.equal(parentRequests[0]?.channel, "to_parent");
  assert.equal(peerRequests[0]?.channel, "peer");
  assert.equal(childRequests[0]?.channel, "to_children");
});

test("cmp-mq cross-part hook blocks parent-peer direct fanout and keeps it parent-mediated", () => {
  const peerEnvelope = createCmpIcmaPublishEnvelope({
    envelopeId: "env-parent-peer",
    projectId: "cmp-project-e2e",
    sourceAgentId: "child-a",
    neighborhood: childNeighborhood,
    direction: "peer",
    granularityLabel: "peer-update",
    payloadRef: "db:projection-child-a",
    createdAt: "2026-03-24T18:10:00.000Z",
  });

  assert.throws(() => {
    assertCmpValidatedNeighborhoodPublishPlan({
      neighborhood: childNeighborhood,
      envelope: {
        ...peerEnvelope,
        targetAgentIds: ["root-peer"],
      },
      knownAncestorIds: ["root"],
      parentPeerIds: ["root-peer"],
    });
  }, /parent-peer|without parent mediation/i);
});

test("cmp-mq cross-part hook treats critical escalation as the only legal skipping exception", () => {
  const upwardEnvelope = createCmpIcmaPublishEnvelope({
    envelopeId: "env-skip-root",
    projectId: "cmp-project-e2e",
    sourceAgentId: "child-a",
    neighborhood: childNeighborhood,
    direction: "parent",
    granularityLabel: "attempted-skip",
    payloadRef: "git:cmp/child-a@danger",
    createdAt: "2026-03-24T18:20:00.000Z",
  });

  assert.throws(() => {
    assertCmpValidatedNeighborhoodPublishPlan({
      neighborhood: childNeighborhood,
      envelope: {
        ...upwardEnvelope,
        targetAgentIds: ["root"],
      },
      knownAncestorIds: ["root"],
      parentPeerIds: ["root-peer"],
    });
  }, /ancestor|skip upward/i);

  const escalation = createCmpCriticalEscalationEnvelope({
    escalationId: "esc-root",
    projectId: "cmp-project-e2e",
    sourceAgentId: "child-a",
    targetAncestorId: rootLineage.agentId,
    severity: "critical",
    reason: "direct parent is unavailable and corruption risk is high",
    evidenceRef: "cmp-alert:esc-root",
    createdAt: "2026-03-24T18:20:00.000Z",
  });

  assert.doesNotThrow(() => {
    assertCmpCriticalEscalationAllowed({
      envelope: escalation,
      knownAncestorIds: [parentLineage.agentId, rootLineage.agentId],
      parentReachability: "unavailable",
    });
  });

  const requests = createCmpSubscriptionRequestsForEnvelope({
    envelope: createCmpIcmaPublishEnvelope({
      envelopeId: "env-peer-copy",
      projectId: "cmp-project-e2e",
      sourceAgentId: "child-a",
      neighborhood: childNeighborhood,
      direction: "peer",
      granularityLabel: "peer-copy",
      payloadRef: "db:projection-child-a",
      createdAt: "2026-03-24T18:21:00.000Z",
    }),
  });
  assert.equal(requests.length, 1);
  assert.equal(requests[0]?.subscriberAgentId, "child-b");
});
