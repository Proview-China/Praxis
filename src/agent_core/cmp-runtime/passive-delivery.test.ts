import assert from "node:assert/strict";
import test from "node:test";

import {
  createCmpProjectionRecord,
} from "./materialization.js";
import {
  createCmpLineageNode,
} from "./runtime-types.js";
import {
  createCmpHistoricalReplyPackage,
  resolveCmpPassiveHistoricalDelivery,
} from "./passive-delivery.js";

const root = createCmpLineageNode({
  projectId: "project-passive",
  agentId: "root",
  depth: 0,
  childAgentIds: ["child-a"],
});

const child = createCmpLineageNode({
  projectId: "project-passive",
  agentId: "child-a",
  parentAgentId: "root",
  depth: 1,
});

test("CMP passive historical delivery chooses the best visible projection and emits a package", () => {
  const localProjection = createCmpProjectionRecord({
    projectionId: "projection-local",
    checkedSnapshotRef: "checked:1",
    agentId: "root",
    visibility: "local_only",
    updatedAt: "2026-03-24T10:00:00.000Z",
  });
  const childProjection = createCmpProjectionRecord({
    projectionId: "projection-downward",
    checkedSnapshotRef: "checked:2",
    agentId: "root",
    visibility: "dispatched_downward",
    updatedAt: "2026-03-24T10:00:01.000Z",
  });

  const resolved = resolveCmpPassiveHistoricalDelivery({
    request: {
      requestId: "request-passive-1",
      requesterLineage: child,
      packageKind: "historical_reply",
      fidelityLabel: "checked_high_fidelity",
      createdAt: "2026-03-24T10:00:02.000Z",
    },
    sourceLineages: new Map([
      [root.agentId, root],
      [child.agentId, child],
    ]),
    projections: [localProjection, childProjection],
  });

  assert.equal(resolved.projection.projectionId, "projection-downward");
  assert.equal(resolved.contextPackage.targetAgentId, "child-a");
});

test("CMP passive historical delivery rejects requests that can only see raw local projections", () => {
  const localProjection = createCmpProjectionRecord({
    projectionId: "projection-local-2",
    checkedSnapshotRef: "checked:3",
    agentId: "root",
    visibility: "local_only",
    updatedAt: "2026-03-24T10:01:00.000Z",
  });

  assert.throws(() => resolveCmpPassiveHistoricalDelivery({
    request: {
      requestId: "request-passive-2",
      requesterLineage: child,
      packageKind: "historical_reply",
      fidelityLabel: "checked_high_fidelity",
      createdAt: "2026-03-24T10:01:01.000Z",
    },
    sourceLineages: new Map([
      [root.agentId, root],
      [child.agentId, child],
    ]),
    projections: [localProjection],
  }), /could not resolve a visible checked projection/i);
});

test("CMP passive historical reply helper preserves requester and projection linkage", () => {
  const projection = createCmpProjectionRecord({
    projectionId: "projection-local-3",
    checkedSnapshotRef: "checked:4",
    agentId: "root",
    visibility: "promoted_by_parent",
    updatedAt: "2026-03-24T10:02:00.000Z",
  });
  const pkg = createCmpHistoricalReplyPackage({
    request: {
      requestId: "request-passive-3",
      requesterLineage: root,
      packageKind: "historical_reply",
      fidelityLabel: "checked_high_fidelity",
      createdAt: "2026-03-24T10:02:01.000Z",
    },
    projection,
  });

  assert.equal(pkg.projectionId, projection.projectionId);
  assert.equal(pkg.targetAgentId, root.agentId);
});
