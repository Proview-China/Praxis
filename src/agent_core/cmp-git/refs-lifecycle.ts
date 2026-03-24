import { randomUUID } from "node:crypto";

import type {
  CmpGitBranchRef,
  CmpGitSnapshotCandidateRecord,
} from "./cmp-git-types.js";
import type { CmpGitPromotionRecord } from "./governance.js";

export const CMP_GIT_CHECKED_REF_STATUSES = [
  "active",
  "superseded",
] as const;
export type CmpGitCheckedRefStatus = (typeof CMP_GIT_CHECKED_REF_STATUSES)[number];

export const CMP_GIT_PROMOTED_REF_STATUSES = [
  "active",
  "superseded",
] as const;
export type CmpGitPromotedRefStatus = (typeof CMP_GIT_PROMOTED_REF_STATUSES)[number];

export interface CmpGitCheckedSnapshotRef {
  refId: string;
  projectId: string;
  agentId: string;
  branchRef: CmpGitBranchRef;
  snapshotId: string;
  commitSha: string;
  refName: string;
  status: CmpGitCheckedRefStatus;
  updatedAt: string;
  metadata?: Record<string, unknown>;
}

export interface CmpGitPromotedSnapshotRef {
  refId: string;
  projectId: string;
  sourceAgentId: string;
  targetAgentId: string;
  targetBranchRef: CmpGitBranchRef;
  sourceSnapshotId: string;
  commitSha: string;
  refName: string;
  status: CmpGitPromotedRefStatus;
  updatedAt: string;
  metadata?: Record<string, unknown>;
}

export interface CmpGitBranchHeadState {
  branchRef: CmpGitBranchRef;
  headCommitSha: string;
  checkedRefName?: string;
  promotedRefName?: string;
  updatedAt: string;
  metadata?: Record<string, unknown>;
}

function assertNonEmpty(value: string, label: string): string {
  const normalized = value.trim();
  if (!normalized) {
    throw new Error(`${label} requires a non-empty string.`);
  }
  return normalized;
}

export function createCmpGitCheckedSnapshotRef(params: {
  candidate: CmpGitSnapshotCandidateRecord;
  snapshotId: string;
  updatedAt?: string;
  metadata?: Record<string, unknown>;
}): CmpGitCheckedSnapshotRef {
  return {
    refId: randomUUID(),
    projectId: params.candidate.projectId,
    agentId: params.candidate.agentId,
    branchRef: params.candidate.branchRef,
    snapshotId: assertNonEmpty(params.snapshotId, "CMP git checked snapshotId"),
    commitSha: params.candidate.commitSha,
    refName: `refs/cmp/checked/${params.candidate.agentId}`,
    status: "active",
    updatedAt: params.updatedAt ?? params.candidate.createdAt,
    metadata: params.metadata,
  };
}

export function createCmpGitPromotedSnapshotRef(params: {
  promotion: CmpGitPromotionRecord;
  targetBranchRef: CmpGitBranchRef;
  updatedAt?: string;
  metadata?: Record<string, unknown>;
}): CmpGitPromotedSnapshotRef {
  return {
    refId: randomUUID(),
    projectId: params.promotion.projectId,
    sourceAgentId: params.promotion.sourceAgentId,
    targetAgentId: params.promotion.targetAgentId,
    targetBranchRef: params.targetBranchRef,
    sourceSnapshotId: params.promotion.candidateId,
    commitSha: params.promotion.checkedCommitSha,
    refName: `refs/cmp/promoted/${params.promotion.targetAgentId}/${params.promotion.sourceAgentId}`,
    status: "active",
    updatedAt: params.updatedAt ?? params.promotion.promotedAt ?? new Date().toISOString(),
    metadata: params.metadata,
  };
}

export function reconcileCmpGitBranchHeadState(params: {
  branchRef: CmpGitBranchRef;
  headCommitSha: string;
  checkedRef?: CmpGitCheckedSnapshotRef;
  promotedRef?: CmpGitPromotedSnapshotRef;
  updatedAt: string;
  metadata?: Record<string, unknown>;
}): CmpGitBranchHeadState {
  if (params.checkedRef && params.checkedRef.branchRef.fullRef !== params.branchRef.fullRef) {
    throw new Error("CMP git checked ref must belong to the same branch head.");
  }
  if (params.promotedRef && params.promotedRef.targetBranchRef.fullRef !== params.branchRef.fullRef) {
    throw new Error("CMP git promoted ref must target the same branch head.");
  }
  if (params.checkedRef && params.checkedRef.commitSha !== params.headCommitSha) {
    throw new Error("CMP git checked ref commit must equal branch head commit.");
  }
  if (params.promotedRef && params.promotedRef.commitSha !== params.headCommitSha) {
    throw new Error("CMP git promoted ref commit must equal branch head commit.");
  }

  return {
    branchRef: params.branchRef,
    headCommitSha: assertNonEmpty(params.headCommitSha, "CMP git branch head commit"),
    checkedRefName: params.checkedRef?.refName,
    promotedRefName: params.promotedRef?.refName,
    updatedAt: params.updatedAt,
    metadata: params.metadata,
  };
}

export function supersedeCmpGitCheckedSnapshotRef(
  ref: CmpGitCheckedSnapshotRef,
  updatedAt: string,
): CmpGitCheckedSnapshotRef {
  return {
    ...ref,
    status: "superseded",
    updatedAt,
  };
}

export function supersedeCmpGitPromotedSnapshotRef(
  ref: CmpGitPromotedSnapshotRef,
  updatedAt: string,
): CmpGitPromotedSnapshotRef {
  return {
    ...ref,
    status: "superseded",
    updatedAt,
  };
}
