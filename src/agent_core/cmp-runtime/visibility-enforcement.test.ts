import assert from "node:assert/strict";
import test from "node:test";

import {
  assertCmpNonSkippingLineage,
  assertCmpProjectionVisibleToTarget,
  evaluateCmpProjectionVisibility,
  resolveCmpLineageRelation,
} from "./visibility-enforcement.js";

const root = {
  projectId: "project-a",
  agentId: "root",
  depth: 0,
  childAgentIds: ["child-a", "child-b"],
};

const childA = {
  projectId: "project-a",
  agentId: "child-a",
  parentAgentId: "root",
  depth: 1,
  childAgentIds: ["grandchild-a1"],
  peerAgentIds: ["child-b"],
};

const childB = {
  projectId: "project-a",
  agentId: "child-b",
  parentAgentId: "root",
  depth: 1,
  peerAgentIds: ["child-a"],
};

const grandchildA1 = {
  projectId: "project-a",
  agentId: "grandchild-a1",
  parentAgentId: "child-a",
  depth: 2,
  metadata: {
    ancestorAgentIds: ["root"],
  },
};

test("CMP lineage relation resolves parent peer child and ancestor correctly", () => {
  assert.equal(resolveCmpLineageRelation({ source: childA, target: root }), "parent");
  assert.equal(resolveCmpLineageRelation({ source: root, target: childA }), "child");
  assert.equal(resolveCmpLineageRelation({ source: childA, target: childB }), "peer");
  assert.equal(resolveCmpLineageRelation({ source: grandchildA1, target: root }), "ancestor");
});

test("CMP non-skipping lineage blocks ancestor delivery but allows parent and peer", () => {
  assert.equal(assertCmpNonSkippingLineage({ source: childA, target: root }), "parent");
  assert.equal(assertCmpNonSkippingLineage({ source: childA, target: childB }), "peer");
  assert.throws(() => assertCmpNonSkippingLineage({
    source: grandchildA1,
    target: root,
  }), /not allowed for non-skipping delivery/i);
});

test("CMP projection visibility only allows local parent or downward delivery according to state", () => {
  const parentVisible = evaluateCmpProjectionVisibility({
    projection: {
      agentId: "child-a",
      visibility: "promoted_by_parent",
    },
    source: childA,
    target: root,
  });
  assert.equal(parentVisible.allowed, true);
  assert.equal(parentVisible.relation, "parent");

  const blockedPeer = evaluateCmpProjectionVisibility({
    projection: {
      agentId: "child-a",
      visibility: "promoted_by_parent",
    },
    source: childA,
    target: childB,
  });
  assert.equal(blockedPeer.allowed, false);
  assert.equal(blockedPeer.relation, "peer");

  assert.doesNotThrow(() => assertCmpProjectionVisibleToTarget({
    projection: {
      projectionId: "projection-1",
      agentId: "root",
      visibility: "dispatched_downward",
    },
    source: root,
    target: childA,
  }));
});
