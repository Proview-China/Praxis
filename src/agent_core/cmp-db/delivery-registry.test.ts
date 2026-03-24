import assert from "node:assert/strict";
import test from "node:test";

import {
  advanceCmpDbContextPackageRecord,
  createCmpDbContextPackageRecordFromContextPackage,
  createCmpDbDeliveryRegistryRecordFromDispatchReceipt,
} from "./index.js";

test("cmp delivery registry keeps package records and dispatch receipts separated", () => {
  const packageRecord = createCmpDbContextPackageRecordFromContextPackage({
    contextPackage: {
      packageId: "package-1",
      sourceProjectionId: "projection-1",
      targetAgentId: "child-1",
      packageKind: "child_seed",
      packageRef: "cmp-package:1",
      fidelityLabel: "checked_high_fidelity",
      createdAt: "2026-03-24T10:00:00.000Z",
    },
    sourceProjection: {
      projectionId: "projection-1",
      snapshotId: "snapshot-1",
      agentId: "main",
    },
  });

  const deliveryRecord = createCmpDbDeliveryRegistryRecordFromDispatchReceipt({
    receipt: {
      dispatchId: "dispatch-1",
      packageId: "package-1",
      sourceAgentId: "main",
      targetAgentId: "child-1",
      status: "delivered",
      deliveredAt: "2026-03-24T10:01:00.000Z",
    },
  });

  assert.equal(packageRecord.packageId, "package-1");
  assert.equal(packageRecord.state, "materialized");
  assert.equal(deliveryRecord.dispatchId, "dispatch-1");
  assert.equal(deliveryRecord.state, "delivered");
});

test("cmp package record only advances along the frozen delivery lifecycle", () => {
  const materialized = createCmpDbContextPackageRecordFromContextPackage({
    contextPackage: {
      packageId: "package-2",
      sourceProjectionId: "projection-2",
      targetAgentId: "peer-1",
      packageKind: "peer_exchange",
      packageRef: "cmp-package:2",
      fidelityLabel: "high_signal",
      createdAt: "2026-03-24T10:00:00.000Z",
    },
    sourceProjection: {
      projectionId: "projection-2",
      snapshotId: "snapshot-2",
      agentId: "main",
    },
  });

  const delivered = advanceCmpDbContextPackageRecord({
    record: materialized,
    nextState: "delivered",
    updatedAt: "2026-03-24T10:02:00.000Z",
  });
  const acknowledged = advanceCmpDbContextPackageRecord({
    record: delivered,
    nextState: "acknowledged",
    updatedAt: "2026-03-24T10:03:00.000Z",
  });

  assert.equal(acknowledged.state, "acknowledged");
  assert.throws(() => advanceCmpDbContextPackageRecord({
    record: materialized,
    nextState: "acknowledged",
    updatedAt: "2026-03-24T10:03:00.000Z",
  }), /cannot transition/i);
});

