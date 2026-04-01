import { randomUUID } from "node:crypto";

import {
  syncCmpGitCommitDelta,
  type CmpGitCommitSyncInput,
  type CmpGitCommitSyncResult,
} from "./commit-sync.js";
import { createCmpGitBranchRef, type CmpGitContextDeltaLike } from "./cmp-git-types.js";
import type { CmpGitSnapshotCandidateRecord } from "./cmp-git-types.js";
import {
  assertCmpGitPromotionKeepsAncestorsInvisible,
  createCmpGitPromotionPullRequest,
  mergeCmpGitPromotionPullRequest,
  promoteCmpGitMerge,
  type CmpGitMergeRecord,
  type CmpGitPromotionRecord,
  type CmpGitPullRequestRecord,
} from "./governance.js";
import {
  createCmpGitCheckedSnapshotRef,
  createCmpGitPromotedSnapshotRef,
  reconcileCmpGitBranchHeadState,
  type CmpGitBranchHeadState,
  type CmpGitCheckedSnapshotRef,
  type CmpGitPromotedSnapshotRef,
} from "./refs-lifecycle.js";
import { CmpGitLineageRegistry } from "./lineage-registry.js";

export interface CreateCmpGitOrchestratorInput {
  registry?: CmpGitLineageRegistry;
}

export class CmpGitSyncRuntimeOrchestrator {
  readonly registry: CmpGitLineageRegistry;
  readonly #bindings = new Map<string, CmpGitCommitSyncResult["binding"]>();
  readonly #candidates = new Map<string, CmpGitSnapshotCandidateRecord>();
  readonly #pullRequests = new Map<string, CmpGitPullRequestRecord>();
  readonly #merges = new Map<string, CmpGitMergeRecord>();
  readonly #promotions = new Map<string, CmpGitPromotionRecord>();
  readonly #checkedRefs = new Map<string, CmpGitCheckedSnapshotRef>();
  readonly #promotedRefs = new Map<string, CmpGitPromotedSnapshotRef>();
  readonly #branchHeads = new Map<string, CmpGitBranchHeadState>();

  constructor(input: CreateCmpGitOrchestratorInput = {}) {
    this.registry = input.registry ?? new CmpGitLineageRegistry();
  }

  syncCommitDelta(input: CmpGitCommitSyncInput): CmpGitCommitSyncResult {
    const result = syncCmpGitCommitDelta(input);
    this.#bindings.set(result.binding.bindingId, result.binding);
    this.#candidates.set(result.candidate.candidateId, result.candidate);
    this.#branchHeads.set(result.candidate.branchRef.fullRef, reconcileCmpGitBranchHeadState({
      branchRef: result.candidate.branchRef,
      headCommitSha: result.candidate.commitSha,
      updatedAt: result.candidate.createdAt,
    }));
    return result;
  }

  markCandidateChecked(params: {
    candidateId: string;
    snapshotId?: string;
    checkedAt?: string;
  }): CmpGitCheckedSnapshotRef {
    const candidate = this.#requireCandidate(params.candidateId);
    const checkedRef = createCmpGitCheckedSnapshotRef({
      candidate,
      snapshotId: params.snapshotId ?? `${candidate.candidateId}:checked`,
      updatedAt: params.checkedAt ?? new Date().toISOString(),
    });
    this.#checkedRefs.set(checkedRef.refId, checkedRef);
    this.#branchHeads.set(candidate.branchRef.fullRef, reconcileCmpGitBranchHeadState({
      branchRef: candidate.branchRef,
      headCommitSha: candidate.commitSha,
      checkedRef,
      updatedAt: checkedRef.updatedAt,
    }));
    return checkedRef;
  }

  openPullRequest(params: {
    candidateId: string;
    targetAgentId: string;
    createdAt?: string;
  }): CmpGitPullRequestRecord {
    const candidate = this.#requireCandidate(params.candidateId);
    const pullRequest = createCmpGitPromotionPullRequest({
      registry: this.registry,
      candidate,
      targetAgentId: params.targetAgentId,
      createdAt: params.createdAt,
    });
    this.#pullRequests.set(pullRequest.pullRequestId, pullRequest);
    return pullRequest;
  }

  mergePullRequest(params: {
    pullRequestId: string;
    actorAgentId: string;
    mergedAt?: string;
  }): CmpGitMergeRecord {
    const pullRequest = this.#requirePullRequest(params.pullRequestId);
    const candidate = this.#requireCandidate(pullRequest.candidateId);
    const merge = mergeCmpGitPromotionPullRequest({
      pullRequest,
      candidate,
      actorAgentId: params.actorAgentId,
      mergedAt: params.mergedAt,
    });
    this.#pullRequests.set(pullRequest.pullRequestId, {
      ...pullRequest,
      status: "merged",
    });
    this.#merges.set(merge.mergeId, merge);
    const targetBranchRef = createCmpGitBranchRef({
      kind: "cmp",
      agentId: merge.targetAgentId,
    });
    this.#branchHeads.set(targetBranchRef.fullRef, reconcileCmpGitBranchHeadState({
      branchRef: targetBranchRef,
      headCommitSha: merge.sourceCommitSha,
      updatedAt: merge.mergedAt,
    }));
    return merge;
  }

  promoteMerge(params: {
    mergeId: string;
    promoterAgentId: string;
    promotedAt?: string;
  }): {
    promotion: CmpGitPromotionRecord;
    promotedRef: CmpGitPromotedSnapshotRef;
    branchHead: CmpGitBranchHeadState;
  } {
    const merge = this.#requireMerge(params.mergeId);
    const pullRequest = this.#requirePullRequest(merge.pullRequestId);
    const candidate = this.#requireCandidate(pullRequest.candidateId);
    const promotion = promoteCmpGitMerge({
      merge,
      candidate,
      promoterAgentId: params.promoterAgentId,
      promotedAt: params.promotedAt,
    });
    this.#promotions.set(promotion.promotionId, promotion);
    assertCmpGitPromotionKeepsAncestorsInvisible({
      promotion,
      ancestorAgentId: pullRequest.targetAgentId,
    });
    const targetBranchRef = createCmpGitBranchRef({
      kind: "cmp",
      agentId: promotion.targetAgentId,
    });
    const promotedRef = createCmpGitPromotedSnapshotRef({
      promotion,
      targetBranchRef,
      updatedAt: promotion.promotedAt,
    });
    this.#promotedRefs.set(promotedRef.refId, promotedRef);
    const branchHead = reconcileCmpGitBranchHeadState({
      branchRef: targetBranchRef,
      headCommitSha: promotion.checkedCommitSha,
      promotedRef,
      updatedAt: promotedRef.updatedAt,
    });
    this.#branchHeads.set(targetBranchRef.fullRef, branchHead);
    return {
      promotion,
      promotedRef,
      branchHead,
    };
  }

  getBranchHead(branchRef: string): CmpGitBranchHeadState | undefined {
    return this.#branchHeads.get(branchRef);
  }

  listPullRequests(): readonly CmpGitPullRequestRecord[] {
    return [...this.#pullRequests.values()];
  }

  listCandidates(): readonly CmpGitSnapshotCandidateRecord[] {
    return [...this.#candidates.values()];
  }

  listMerges(): readonly CmpGitMergeRecord[] {
    return [...this.#merges.values()];
  }

  listPromotions(): readonly CmpGitPromotionRecord[] {
    return [...this.#promotions.values()];
  }

  listCheckedRefs(): readonly CmpGitCheckedSnapshotRef[] {
    return [...this.#checkedRefs.values()];
  }

  listPromotedRefs(): readonly CmpGitPromotedSnapshotRef[] {
    return [...this.#promotedRefs.values()];
  }

  #requireCandidate(candidateId: string): CmpGitSnapshotCandidateRecord {
    const candidate = this.#candidates.get(candidateId);
    if (!candidate) {
      throw new Error(`CMP git snapshot candidate ${candidateId} was not found.`);
    }
    return candidate;
  }

  #requirePullRequest(pullRequestId: string): CmpGitPullRequestRecord {
    const pullRequest = this.#pullRequests.get(pullRequestId);
    if (!pullRequest) {
      throw new Error(`CMP git pull request ${pullRequestId} was not found.`);
    }
    return pullRequest;
  }

  #requireMerge(mergeId: string): CmpGitMergeRecord {
    const merge = this.#merges.get(mergeId);
    if (!merge) {
      throw new Error(`CMP git merge ${mergeId} was not found.`);
    }
    return merge;
  }
}

export function createCmpGitSyncRuntimeOrchestrator(
  input: CreateCmpGitOrchestratorInput = {},
): CmpGitSyncRuntimeOrchestrator {
  return new CmpGitSyncRuntimeOrchestrator(input);
}
