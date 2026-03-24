import type {
  CheckedSnapshot,
  ContextPackage,
  DispatchReceipt,
} from "../cmp-types/index.js";
import {
  type CmpDbContextPackageRecord,
  type CmpDbDeliveryRegistryRecord,
  type CmpProjectionRecord,
} from "./cmp-db-types.js";
import {
  advanceCmpProjectionRecord,
  createCmpProjectionRecordFromCheckedSnapshot,
} from "./projection-state.js";
import {
  advanceCmpDbContextPackageRecord,
  createCmpDbContextPackageRecordFromContextPackage,
  createCmpDbDeliveryRegistryRecordFromDispatchReceipt,
} from "./delivery-registry.js";

export interface CmpDbAgentRuntimeSyncState {
  projections: Map<string, CmpProjectionRecord>;
  packages: Map<string, CmpDbContextPackageRecord>;
  deliveries: Map<string, CmpDbDeliveryRegistryRecord>;
}

export function createCmpDbAgentRuntimeSyncState(): CmpDbAgentRuntimeSyncState {
  return {
    projections: new Map(),
    packages: new Map(),
    deliveries: new Map(),
  };
}

export function syncCmpDbProjectionFromCheckedSnapshot(input: {
  state: CmpDbAgentRuntimeSyncState;
  snapshot: CheckedSnapshot;
  projectionId?: string;
  metadata?: Record<string, unknown>;
}): CmpProjectionRecord {
  const projection = createCmpProjectionRecordFromCheckedSnapshot({
    projectionId: input.projectionId ?? `projection:${input.snapshot.snapshotId}`,
    snapshot: input.snapshot,
    updatedAt: input.snapshot.checkedAt,
    metadata: input.metadata,
  });
  input.state.projections.set(projection.projectionId, projection);
  return projection;
}

export function promoteCmpDbProjectionForParent(input: {
  state: CmpDbAgentRuntimeSyncState;
  projectionId: string;
  submittedAt?: string;
  acceptedAt: string;
  promotedAt?: string;
}): CmpProjectionRecord {
  const projection = input.state.projections.get(input.projectionId);
  if (!projection) {
    throw new Error(`CMP DB projection ${input.projectionId} was not found.`);
  }
  const submitted = advanceCmpProjectionRecord({
    record: projection,
    to: "submitted_to_parent",
    updatedAt: input.submittedAt ?? input.acceptedAt,
  });
  const accepted = advanceCmpProjectionRecord({
    record: submitted,
    to: "accepted_by_parent",
    updatedAt: input.acceptedAt,
  });
  const promoted = advanceCmpProjectionRecord({
    record: accepted,
    to: "promoted_by_parent",
    updatedAt: input.promotedAt ?? input.acceptedAt,
  });
  input.state.projections.set(promoted.projectionId, promoted);
  return promoted;
}

export function syncCmpDbPackageFromContextPackage(input: {
  state: CmpDbAgentRuntimeSyncState;
  contextPackage: ContextPackage;
  projection: Pick<CmpProjectionRecord, "projectionId" | "snapshotId" | "agentId">;
  metadata?: Record<string, unknown>;
}): CmpDbContextPackageRecord {
  const record = createCmpDbContextPackageRecordFromContextPackage({
    contextPackage: input.contextPackage,
    sourceProjection: input.projection,
    metadata: input.metadata,
  });
  input.state.packages.set(record.packageId, record);
  return record;
}

export function syncCmpDbDeliveryFromDispatchReceipt(input: {
  state: CmpDbAgentRuntimeSyncState;
  receipt: DispatchReceipt;
  metadata?: Record<string, unknown>;
}): {
  packageRecord?: CmpDbContextPackageRecord;
  deliveryRecord: CmpDbDeliveryRegistryRecord;
} {
  const deliveryRecord = createCmpDbDeliveryRegistryRecordFromDispatchReceipt({
    receipt: input.receipt,
    metadata: input.metadata,
  });
  input.state.deliveries.set(deliveryRecord.deliveryId, deliveryRecord);

  const packageRecord = input.state.packages.get(input.receipt.packageId);
  if (!packageRecord) {
    return {
      deliveryRecord,
    };
  }

  let updatedPackageRecord = packageRecord;
  if (input.receipt.status === "delivered" || input.receipt.status === "acknowledged") {
    if (updatedPackageRecord.state === "materialized") {
      updatedPackageRecord = advanceCmpDbContextPackageRecord({
        record: updatedPackageRecord,
        nextState: "delivered",
        updatedAt: input.receipt.deliveredAt ?? new Date().toISOString(),
        metadata: input.metadata,
      });
    }
    if (input.receipt.status === "acknowledged" && updatedPackageRecord.state === "delivered") {
      updatedPackageRecord = advanceCmpDbContextPackageRecord({
        record: updatedPackageRecord,
        nextState: "acknowledged",
        updatedAt: input.receipt.acknowledgedAt ?? input.receipt.deliveredAt ?? new Date().toISOString(),
        metadata: input.metadata,
      });
    }
  }
  input.state.packages.set(updatedPackageRecord.packageId, updatedPackageRecord);

  return {
    packageRecord: updatedPackageRecord,
    deliveryRecord,
  };
}
