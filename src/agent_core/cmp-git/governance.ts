import { randomUUID } from "node:crypto";

import {
  createCmpGitBranchRef,
  type CmpGitBranchRef,
  type CmpGitLineageNode,
  type CmpGitSnapshotCandidateRecord,
} from "./cmp-git-types.js";
import { CmpGitLineageRegistry } from "./lineage-registry.js";

export const CMP_GIT_PULL_REQUEST_STATUSES = [
  "open",
  "merged",
  "rejected",
] as const;
export type CmpGitPullRequestStatus = (typeof CMP_GIT_PULL_REQUEST_STATUSES)[number];

export const CMP_GIT_MERGE_STATUSES = [
  "merged_to_parent",
  "superseded",
] as const;
export type CmpGitMergeStatus = (typeof CMP_GIT_MERGE_STATUSES)[number];

export const CMP_GIT_PROMOTION_VISIBILITIES = [
  "parent_only",
  "parent_promoted",
] as const;
export type CmpGitPromotionVisibility = (typeof CMP_GIT_PROMOTION_VISIBILITIES)[number];

export const CMP_GIT_PROMOTION_STATUSES = [
  "pending_promotion",
  "promoted",
  "archived",
] as const;
export type CmpGitPromotionStatus = (typeof CMP_GIT_PROMOTION_STATUSES)[number];

export interface CmpGitPullRequestRecord {
  pullRequestId: string;
  projectId: string;
  sourceAgentId: string;
  targetAgentId: string;
  sourceBranchRef: CmpGitBranchRef;
  targetBranchRef: CmpGitBranchRef;
  candidateId: string;
  status: CmpGitPullRequestStatus;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface CmpGitMergeRecord {
  mergeId: string;
  projectId: string;
  pullRequestId: string;
  sourceAgentId: string;
  targetAgentId: string;
  sourceCommitSha: string;
  targetBranchRef: CmpGitBranchRef;
  mergedAt: string;
  status: CmpGitMergeStatus;
  metadata?: Record<string, unknown>;
}

export interface CmpGitPromotionRecord {
  promotionId: string;
  projectId: string;
  mergeId: string;
  sourceAgentId: string;
  targetAgentId: string;
  candidateId: string;
  checkedCommitSha: string;
  visibility: CmpGitPromotionVisibility;
  status: CmpGitPromotionStatus;
  promotedAt?: string;
  metadata?: Record<string, unknown>;
}

function assertNonEmpty(value: string, label: string): string {
  const normalized = value.trim();
  if (!normalized) {
    throw new Error(`${label} requires a non-empty string.`);
  }
  return normalized;
}

function requireParentLineage(params: {
  registry: CmpGitLineageRegistry;
  sourceAgentId: string;
  targetAgentId: string;
}): CmpGitLineageNode {
  const source = params.registry.get(params.sourceAgentId);
  if (!source) {
    throw new Error(`CMP git lineage ${params.sourceAgentId} was not found.`);
  }
  if (source.parentAgentId !== params.targetAgentId) {
    throw new Error(
      `CMP git pull request target ${params.targetAgentId} is not the direct parent of ${params.sourceAgentId}.`,
    );
  }
  const parent = params.registry.get(params.targetAgentId);
  if (!parent) {
    throw new Error(`CMP git parent lineage ${params.targetAgentId} was not found.`);
  }
  return parent;
}

export function createCmpGitPromotionPullRequest(params: {
  registry: CmpGitLineageRegistry;
  candidate: CmpGitSnapshotCandidateRecord;
  targetAgentId: string;
  createdAt?: string;
  metadata?: Record<string, unknown>;
}): CmpGitPullRequestRecord {
  const parent = requireParentLineage({
    registry: params.registry,
    sourceAgentId: params.candidate.agentId,
    targetAgentId: params.targetAgentId,
  });
  return {
    pullRequestId: randomUUID(),
    projectId: params.candidate.projectId,
    sourceAgentId: params.candidate.agentId,
    targetAgentId: parent.agentId,
    sourceBranchRef: params.candidate.branchRef,
    targetBranchRef: createCmpGitBranchRef({
      kind: "cmp",
      agentId: parent.agentId,
    }),
    candidateId: params.candidate.candidateId,
    status: "open",
    createdAt: params.createdAt ?? params.candidate.createdAt,
    metadata: params.metadata,
  };
}

export function mergeCmpGitPromotionPullRequest(params: {
  pullRequest: CmpGitPullRequestRecord;
  candidate: CmpGitSnapshotCandidateRecord;
  actorAgentId: string;
  mergedAt?: string;
  metadata?: Record<string, unknown>;
}): CmpGitMergeRecord {
  if (params.pullRequest.status !== "open") {
    throw new Error(
      `CMP git pull request ${params.pullRequest.pullRequestId} must be open before merge.`,
    );
  }
  if (params.actorAgentId !== params.pullRequest.targetAgentId) {
    throw new Error(
      `CMP git pull request ${params.pullRequest.pullRequestId} can only be merged by direct parent ${params.pullRequest.targetAgentId}.`,
    );
  }
  if (params.candidate.candidateId !== params.pullRequest.candidateId) {
    throw new Error(
      `CMP git pull request ${params.pullRequest.pullRequestId} does not match candidate ${params.candidate.candidateId}.`,
    );
  }

  return {
    mergeId: randomUUID(),
    projectId: params.pullRequest.projectId,
    pullRequestId: params.pullRequest.pullRequestId,
    sourceAgentId: params.pullRequest.sourceAgentId,
    targetAgentId: params.pullRequest.targetAgentId,
    sourceCommitSha: params.candidate.commitSha,
    targetBranchRef: params.pullRequest.targetBranchRef,
    mergedAt: params.mergedAt ?? new Date().toISOString(),
    status: "merged_to_parent",
    metadata: params.metadata,
  };
}

export function promoteCmpGitMerge(params: {
  merge: CmpGitMergeRecord;
  candidate: CmpGitSnapshotCandidateRecord;
  promoterAgentId: string;
  visibility?: CmpGitPromotionVisibility;
  promotedAt?: string;
  metadata?: Record<string, unknown>;
}): CmpGitPromotionRecord {
  if (params.merge.status !== "merged_to_parent") {
    throw new Error(`CMP git merge ${params.merge.mergeId} is not promotable.`);
  }
  if (params.promoterAgentId !== params.merge.targetAgentId) {
    throw new Error(
      `CMP git promotion for merge ${params.merge.mergeId} can only be issued by parent ${params.merge.targetAgentId}.`,
    );
  }
  if (params.candidate.candidateId === "") {
    throw new Error("CMP git promotion requires a non-empty candidateId.");
  }

  return {
    promotionId: randomUUID(),
    projectId: params.merge.projectId,
    mergeId: params.merge.mergeId,
    sourceAgentId: params.merge.sourceAgentId,
    targetAgentId: params.merge.targetAgentId,
    candidateId: params.candidate.candidateId,
    checkedCommitSha: params.candidate.commitSha,
    visibility: params.visibility ?? "parent_only",
    status: "promoted",
    promotedAt: params.promotedAt ?? new Date().toISOString(),
    metadata: params.metadata,
  };
}

export function assertCmpGitPromotionKeepsAncestorsInvisible(params: {
  promotion: CmpGitPromotionRecord;
  ancestorAgentId: string;
}): void {
  const ancestorId = assertNonEmpty(params.ancestorAgentId, "CMP git ancestorAgentId");
  if (
    params.promotion.visibility === "parent_only"
    && ancestorId !== params.promotion.targetAgentId
    && ancestorId !== params.promotion.sourceAgentId
  ) {
    return;
  }

  if (
    params.promotion.visibility === "parent_promoted"
    && ancestorId !== params.promotion.targetAgentId
  ) {
    throw new Error(
      `CMP git promotion ${params.promotion.promotionId} must not directly expose raw promoted state to ancestor ${ancestorId}.`,
    );
  }
}
