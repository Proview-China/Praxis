import type {
  ContextPackage,
  DispatchReceipt,
} from "../cmp-types/index.js";
import {
  type CmpDbContextPackageRecord,
  type CmpDbContextPackageRecordState,
  type CmpDbDeliveryRecordState,
  type CmpDbDeliveryRegistryRecord,
  type CmpProjectionRecord,
  validateCmpDbContextPackageRecord,
  validateCmpDbDeliveryRegistryRecord,
  assertNonEmptyString,
} from "./cmp-db-types.js";

export function createCmpDbContextPackageRecordFromContextPackage(input: {
  contextPackage: ContextPackage;
  sourceProjection: Pick<CmpProjectionRecord, "projectionId" | "snapshotId" | "agentId">;
  state?: CmpDbContextPackageRecordState;
  updatedAt?: string;
  metadata?: Record<string, unknown>;
}): CmpDbContextPackageRecord {
  const record: CmpDbContextPackageRecord = {
    packageId: input.contextPackage.packageId,
    sourceProjectionId: input.sourceProjection.projectionId,
    sourceSnapshotId: input.sourceProjection.snapshotId,
    sourceAgentId: input.sourceProjection.agentId,
    targetAgentId: input.contextPackage.targetAgentId,
    packageKind: input.contextPackage.packageKind,
    packageRef: input.contextPackage.packageRef,
    fidelityLabel: input.contextPackage.fidelityLabel,
    state: input.state ?? "materialized",
    createdAt: input.contextPackage.createdAt,
    updatedAt: input.updatedAt ?? input.contextPackage.createdAt,
    metadata: {
      ...(input.contextPackage.metadata ?? {}),
      ...(input.metadata ?? {}),
    },
  };
  validateCmpDbContextPackageRecord(record);
  return record;
}

export function advanceCmpDbContextPackageRecord(params: {
  record: CmpDbContextPackageRecord;
  nextState: CmpDbContextPackageRecordState;
  updatedAt: string;
  metadata?: Record<string, unknown>;
}): CmpDbContextPackageRecord {
  const allowedTransitions: Record<
    CmpDbContextPackageRecordState,
    readonly CmpDbContextPackageRecordState[]
  > = {
    materialized: ["delivered", "archived"],
    delivered: ["acknowledged", "archived"],
    acknowledged: ["archived"],
    archived: [],
  };
  validateCmpDbContextPackageRecord(params.record);
  if (!allowedTransitions[params.record.state].includes(params.nextState)) {
    throw new Error(
      `CMP DB package record cannot transition from ${params.record.state} to ${params.nextState}.`,
    );
  }
  const record: CmpDbContextPackageRecord = {
    ...params.record,
    state: params.nextState,
    updatedAt: assertNonEmptyString(params.updatedAt, "CMP DB package record updatedAt"),
    metadata: {
      ...(params.record.metadata ?? {}),
      ...(params.metadata ?? {}),
    },
  };
  validateCmpDbContextPackageRecord(record);
  return record;
}

function mapDispatchStatusToDeliveryState(status: DispatchReceipt["status"]): CmpDbDeliveryRecordState {
  switch (status) {
    case "queued":
      return "pending_delivery";
    case "delivered":
      return "delivered";
    case "acknowledged":
      return "acknowledged";
    case "rejected":
      return "rejected";
    case "expired":
      return "expired";
  }
}

export function createCmpDbDeliveryRegistryRecordFromDispatchReceipt(input: {
  receipt: DispatchReceipt;
  createdAt?: string;
  metadata?: Record<string, unknown>;
}): CmpDbDeliveryRegistryRecord {
  const record: CmpDbDeliveryRegistryRecord = {
    deliveryId: input.receipt.dispatchId,
    dispatchId: input.receipt.dispatchId,
    packageId: input.receipt.packageId,
    sourceAgentId: input.receipt.sourceAgentId,
    targetAgentId: input.receipt.targetAgentId,
    state: mapDispatchStatusToDeliveryState(input.receipt.status),
    createdAt: input.createdAt ?? input.receipt.deliveredAt ?? input.receipt.acknowledgedAt ?? new Date().toISOString(),
    deliveredAt: input.receipt.deliveredAt,
    acknowledgedAt: input.receipt.acknowledgedAt,
    metadata: {
      ...(input.receipt.metadata ?? {}),
      ...(input.metadata ?? {}),
    },
  };
  validateCmpDbDeliveryRegistryRecord(record);
  return record;
}

