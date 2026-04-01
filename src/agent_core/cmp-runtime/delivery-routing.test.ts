import assert from "node:assert/strict";
import test from "node:test";

import {
  createCmpContextPackageRecord,
} from "./materialization.js";
import { createCmpLineageNode } from "./runtime-types.js";
import {
  acknowledgeCmpCoreAgentReturn,
  createCmpCoreAgentReturnReceipt,
  planCmpDispatcherDelivery,
} from "./delivery-routing.js";

const parent = createCmpLineageNode({
  projectId: "project-delivery",
  agentId: "parent",
  depth: 0,
  childAgentIds: ["child-a", "child-b"],
});

const childA = createCmpLineageNode({
  projectId: "project-delivery",
  agentId: "child-a",
  parentAgentId: "parent",
  depth: 1,
  peerAgentIds: ["child-b"],
});

const childB = createCmpLineageNode({
  projectId: "project-delivery",
  agentId: "child-b",
  parentAgentId: "parent",
  depth: 1,
  peerAgentIds: ["child-a"],
});

test("CMP dispatcher can plan parent-child delivery and return a delivered receipt", () => {
  const pkg = createCmpContextPackageRecord({
    packageId: "package-child-seed",
    projectionId: "projection-1",
    sourceAgentId: "parent",
    targetAgentId: "child-a",
    packageKind: "child_seed",
    packageRef: "pkg:1",
    fidelityLabel: "checked_high_fidelity",
    createdAt: "2026-03-24T11:00:00.000Z",
  });

  const plan = planCmpDispatcherDelivery({
    source: parent,
    target: childA,
    contextPackage: pkg,
    createdAt: "2026-03-24T11:00:01.000Z",
  });

  assert.equal(plan.relation, "child");
  assert.equal(plan.instruction.direction, "child");
  assert.equal(plan.receipt.status, "delivered");
});

test("CMP dispatcher can plan peer delivery without implying upward promotion", () => {
  const pkg = createCmpContextPackageRecord({
    packageId: "package-peer",
    projectionId: "projection-2",
    sourceAgentId: "child-a",
    targetAgentId: "child-b",
    packageKind: "peer_exchange",
    packageRef: "pkg:2",
    fidelityLabel: "high_signal",
    createdAt: "2026-03-24T11:01:00.000Z",
  });

  const plan = planCmpDispatcherDelivery({
    source: childA,
    target: childB,
    contextPackage: pkg,
    createdAt: "2026-03-24T11:01:01.000Z",
  });

  assert.equal(plan.relation, "peer");
  assert.equal(plan.instruction.direction, "peer");
  assert.equal(plan.receipt.metadata?.relation, "peer");
});

test("CMP dispatcher blocks non-skipping ancestor delivery and supports core-agent return acknowledgement", () => {
  const pkg = createCmpContextPackageRecord({
    packageId: "package-upward",
    projectionId: "projection-3",
    sourceAgentId: "child-a",
    targetAgentId: "parent",
    packageKind: "promotion_update",
    packageRef: "pkg:3",
    fidelityLabel: "checked_high_fidelity",
    createdAt: "2026-03-24T11:02:00.000Z",
  });

  assert.throws(() => planCmpDispatcherDelivery({
    source: createCmpLineageNode({
      projectId: "project-delivery",
      agentId: "grandchild-a1",
      parentAgentId: "child-a",
      depth: 2,
      metadata: {
        ancestorAgentIds: ["parent"],
      },
    }),
    target: parent,
    contextPackage: pkg,
    createdAt: "2026-03-24T11:02:01.000Z",
  }), /non-skipping delivery/i);

  const receipt = createCmpCoreAgentReturnReceipt({
    dispatchId: "dispatch-core-1",
    packageId: "package-core-1",
    sourceAgentId: "parent",
    coreAgentHandle: "core_agent:parent",
    createdAt: "2026-03-24T11:02:02.000Z",
  });
  const acknowledged = acknowledgeCmpCoreAgentReturn({
    receipt,
    acknowledgedAt: "2026-03-24T11:02:03.000Z",
  });
  assert.equal(acknowledged.status, "acknowledged");
});
