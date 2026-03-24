import assert from "node:assert/strict";
import test from "node:test";

import {
  createCmpDbAgentRuntimeSyncState,
  promoteCmpDbProjectionForParent,
  syncCmpDbDeliveryFromDispatchReceipt,
  syncCmpDbPackageFromContextPackage,
  syncCmpDbProjectionFromCheckedSnapshot,
} from "./index.js";

test("cmp dbagent sync consumes checked snapshots into projection records", () => {
  const state = createCmpDbAgentRuntimeSyncState();
  const projection = syncCmpDbProjectionFromCheckedSnapshot({
    state,
    snapshot: {
      snapshotId: "snapshot-1",
      agentId: "main",
      lineageRef: "project:main",
      branchRef: "cmp/main",
      commitRef: "abc123",
      checkedAt: "2026-03-24T10:00:00.000Z",
      qualityLabel: "usable",
      promotable: true,
      metadata: {
        projectId: "cmp-project",
      },
    },
  });

  assert.equal(projection.state, "local_only");
  assert.equal(state.projections.get(projection.projectionId)?.snapshotId, "snapshot-1");
});

test("cmp dbagent sync can promote a projection only through accepted then promoted", () => {
  const state = createCmpDbAgentRuntimeSyncState();
  const projection = syncCmpDbProjectionFromCheckedSnapshot({
    state,
    snapshot: {
      snapshotId: "snapshot-2",
      agentId: "main",
      lineageRef: "project:main",
      branchRef: "cmp/main",
      commitRef: "def456",
      checkedAt: "2026-03-24T10:00:00.000Z",
      qualityLabel: "usable",
      promotable: true,
    },
  });

  const promoted = promoteCmpDbProjectionForParent({
    state,
    projectionId: projection.projectionId,
    acceptedAt: "2026-03-24T10:01:00.000Z",
    promotedAt: "2026-03-24T10:02:00.000Z",
  });

  assert.equal(promoted.state, "promoted_by_parent");
});

test("cmp dbagent sync can persist package and delivery records without giving dbagent git truth authority", () => {
  const state = createCmpDbAgentRuntimeSyncState();
  const projection = syncCmpDbProjectionFromCheckedSnapshot({
    state,
    snapshot: {
      snapshotId: "snapshot-3",
      agentId: "main",
      lineageRef: "project:main",
      branchRef: "cmp/main",
      commitRef: "ghi789",
      checkedAt: "2026-03-24T10:00:00.000Z",
      qualityLabel: "usable",
      promotable: true,
    },
  });

  const packageRecord = syncCmpDbPackageFromContextPackage({
    state,
    contextPackage: {
      packageId: "package-3",
      sourceProjectionId: projection.projectionId,
      targetAgentId: "child-1",
      packageKind: "child_seed",
      packageRef: "cmp-package:3",
      fidelityLabel: "checked_high_fidelity",
      createdAt: "2026-03-24T10:01:00.000Z",
    },
    projection,
  });

  const deliverySync = syncCmpDbDeliveryFromDispatchReceipt({
    state,
    receipt: {
      dispatchId: "dispatch-3",
      packageId: "package-3",
      sourceAgentId: "main",
      targetAgentId: "child-1",
      status: "acknowledged",
      deliveredAt: "2026-03-24T10:02:00.000Z",
      acknowledgedAt: "2026-03-24T10:03:00.000Z",
    },
  });

  assert.equal(packageRecord.state, "materialized");
  assert.equal(deliverySync.packageRecord?.state, "acknowledged");
  assert.equal(deliverySync.deliveryRecord.state, "acknowledged");
  assert.equal(state.deliveries.get("dispatch-3")?.dispatchId, "dispatch-3");
});
