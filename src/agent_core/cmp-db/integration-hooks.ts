import type {
  CheckedSnapshot,
  ContextPackage,
  DispatchReceipt,
} from "../cmp-types/index.js";
import type { CmpGitPromotionRecord } from "../cmp-git/index.js";
import type {
  CmpDbContextPackageRecord,
  CmpDbDeliveryRegistryRecord,
  CmpProjectionRecord,
} from "./cmp-db-types.js";
import {
  type CmpDbAgentRuntimeSyncState,
  promoteCmpDbProjectionForParent,
  syncCmpDbDeliveryFromDispatchReceipt,
  syncCmpDbPackageFromContextPackage,
  syncCmpDbProjectionFromCheckedSnapshot,
} from "./dbagent-sync.js";

export interface SyncCmpDbProjectionFromGitPromotionInput {
  state: CmpDbAgentRuntimeSyncState;
  snapshot: CheckedSnapshot;
  promotion?: Pick<CmpGitPromotionRecord, "promotionId" | "promotedAt">;
  projectionId?: string;
  metadata?: Record<string, unknown>;
}

export function syncCmpDbProjectionFromGitPromotion(
  input: SyncCmpDbProjectionFromGitPromotionInput,
): CmpProjectionRecord {
  const projection = syncCmpDbProjectionFromCheckedSnapshot({
    state: input.state,
    snapshot: input.snapshot,
    projectionId: input.projectionId,
    metadata: {
      ...(input.metadata ?? {}),
      gitPromotionId: input.promotion?.promotionId,
    },
  });

  if (!input.promotion) {
    return projection;
  }

  return promoteCmpDbProjectionForParent({
    state: input.state,
    projectionId: projection.projectionId,
    acceptedAt: input.promotion.promotedAt ?? input.snapshot.checkedAt,
    promotedAt: input.promotion.promotedAt ?? input.snapshot.checkedAt,
  });
}

export interface SyncCmpDbDeliveryPipelineInput {
  state: CmpDbAgentRuntimeSyncState;
  contextPackage: ContextPackage;
  projection: Pick<CmpProjectionRecord, "projectionId" | "snapshotId" | "agentId">;
  receipt: DispatchReceipt;
  metadata?: Record<string, unknown>;
}

export interface SyncCmpDbDeliveryPipelineResult {
  packageRecord: CmpDbContextPackageRecord;
  deliveryRecord: CmpDbDeliveryRegistryRecord;
}

export function syncCmpDbDeliveryPipeline(
  input: SyncCmpDbDeliveryPipelineInput,
): SyncCmpDbDeliveryPipelineResult {
  const packageRecord = syncCmpDbPackageFromContextPackage({
    state: input.state,
    contextPackage: input.contextPackage,
    projection: input.projection,
    metadata: input.metadata,
  });
  const deliverySync = syncCmpDbDeliveryFromDispatchReceipt({
    state: input.state,
    receipt: input.receipt,
    metadata: input.metadata,
  });

  return {
    packageRecord: deliverySync.packageRecord ?? packageRecord,
    deliveryRecord: deliverySync.deliveryRecord,
  };
}
