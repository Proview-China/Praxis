import { assertNonEmpty, type CmpLineageNode } from "./runtime-types.js";
import {
  createCmpContextPackageRecord,
  createPassiveHistoricalPackage,
  type CmpContextPackageRecord,
  type CmpProjectionRecord,
} from "./materialization.js";
import {
  assertCmpProjectionVisibleToTarget,
} from "./visibility-enforcement.js";

export interface CmpPassiveHistoricalRequest {
  requestId: string;
  requesterLineage: CmpLineageNode;
  packageKind: string;
  fidelityLabel: string;
  createdAt: string;
  preferredProjectionId?: string;
  metadata?: Record<string, unknown>;
}

export interface ResolveCmpPassiveHistoricalDeliveryInput {
  request: CmpPassiveHistoricalRequest;
  sourceLineages: ReadonlyMap<string, CmpLineageNode>;
  projections: readonly CmpProjectionRecord[];
}

export interface ResolveCmpPassiveHistoricalDeliveryResult {
  projection: CmpProjectionRecord;
  contextPackage: CmpContextPackageRecord;
}

function rankProjection(record: CmpProjectionRecord): number {
  switch (record.visibility) {
    case "promoted_by_parent":
      return 4;
    case "accepted_by_parent":
      return 3;
    case "submitted_to_parent":
      return 2;
    case "dispatched_downward":
      return 1;
    case "local_only":
      return 0;
    case "archived":
      return -1;
  }
}

function sortProjectionCandidates(records: readonly CmpProjectionRecord[]): CmpProjectionRecord[] {
  return [...records].sort((left, right) => {
    const rankDiff = rankProjection(right) - rankProjection(left);
    if (rankDiff !== 0) {
      return rankDiff;
    }
    return right.updatedAt.localeCompare(left.updatedAt);
  });
}

export function resolveCmpPassiveHistoricalDelivery(
  input: ResolveCmpPassiveHistoricalDeliveryInput,
): ResolveCmpPassiveHistoricalDeliveryResult {
  const request = input.request;
  assertNonEmpty(request.requestId, "CMP passive requestId");
  const requester = request.requesterLineage;
  const projections = request.preferredProjectionId
    ? input.projections.filter((projection) => projection.projectionId === request.preferredProjectionId)
    : input.projections;

  const candidates = sortProjectionCandidates(
    projections.filter((projection) => projection.visibility !== "archived"),
  );
  for (const projection of candidates) {
    const source = input.sourceLineages.get(projection.agentId);
    if (!source) {
      continue;
    }
    try {
      assertCmpProjectionVisibleToTarget({
        projection: {
          projectionId: projection.projectionId,
          agentId: projection.agentId,
          visibility: projection.visibility,
        },
        source,
        target: requester,
      });
      const contextPackage = createPassiveHistoricalPackage({
        packageId: `${request.requestId}:${projection.projectionId}`,
        projection,
        requesterAgentId: requester.agentId,
        packageKind: request.packageKind,
        packageRef: `cmp-passive:${projection.projectionId}:${requester.agentId}`,
        fidelityLabel: request.fidelityLabel,
        createdAt: request.createdAt,
        metadata: request.metadata,
      });
      return {
        projection,
        contextPackage,
      };
    } catch {
      continue;
    }
  }

  throw new Error(
    `CMP passive request ${request.requestId} could not resolve a visible checked projection for ${requester.agentId}.`,
  );
}

export function createCmpHistoricalReplyPackage(input: {
  request: CmpPassiveHistoricalRequest;
  projection: CmpProjectionRecord;
}): CmpContextPackageRecord {
  return createCmpContextPackageRecord({
    packageId: `${input.request.requestId}:${input.projection.projectionId}:reply`,
    projectionId: input.projection.projectionId,
    sourceAgentId: input.projection.agentId,
    targetAgentId: input.request.requesterLineage.agentId,
    packageKind: input.request.packageKind,
    packageRef: `cmp-historical:${input.projection.projectionId}:${input.request.requesterLineage.agentId}`,
    fidelityLabel: input.request.fidelityLabel,
    createdAt: input.request.createdAt,
    metadata: input.request.metadata,
  });
}
