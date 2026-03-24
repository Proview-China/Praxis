import type {
  CmpGitBranchHeadState,
  CmpGitCheckedSnapshotRef,
  CmpGitPromotedSnapshotRef,
} from "./refs-lifecycle.js";
import type {
  CmpGitMergeRecord,
  CmpGitPromotionRecord,
  CmpGitPullRequestRecord,
} from "./governance.js";
import type { CmpGitLineageNode, CmpGitSnapshotCandidateRecord } from "./cmp-git-types.js";
import type { CmpGitSyncRuntimeOrchestrator } from "./orchestrator.js";

export interface CmpGitLineageHook {
  projectId: string;
  agentId: string;
  parentAgentId?: string;
  depth: number;
  cmpBranchRef: string;
  workBranchRef: string;
  mpBranchRef: string;
  tapBranchRef: string;
  childAgentIds: string[];
  metadata?: Record<string, unknown>;
}

export interface CmpGitSyncReceipt {
  candidate: CmpGitSnapshotCandidateRecord;
  checkedRef?: CmpGitCheckedSnapshotRef;
  pullRequest?: CmpGitPullRequestRecord;
  merge?: CmpGitMergeRecord;
  promotion?: CmpGitPromotionRecord;
  promotedRef?: CmpGitPromotedSnapshotRef;
  branchHead?: CmpGitBranchHeadState;
}

export interface CmpGitProjectionSourceAnchor {
  candidateId: string;
  checkedRefName?: string;
  promotedRefName?: string;
  branchHeadRef: string;
  commitSha: string;
}

export interface CmpGitRuntimeHooks {
  getLineageHook(agentId: string): CmpGitLineageHook | undefined;
  listChildHooks(parentAgentId: string): readonly CmpGitLineageHook[];
  listPeerHooks(agentId: string): readonly CmpGitLineageHook[];
  getCandidate(candidateId: string): CmpGitSnapshotCandidateRecord | undefined;
  getBranchHead(branchRef: string): CmpGitBranchHeadState | undefined;
}

export function createCmpGitLineageHook(node: CmpGitLineageNode): CmpGitLineageHook {
  return {
    projectId: node.projectId,
    agentId: node.agentId,
    parentAgentId: node.parentAgentId,
    depth: node.depth,
    cmpBranchRef: node.branchFamily.cmp.fullRef,
    workBranchRef: node.branchFamily.work.fullRef,
    mpBranchRef: node.branchFamily.mp.fullRef,
    tapBranchRef: node.branchFamily.tap.fullRef,
    childAgentIds: [...node.childAgentIds],
    metadata: node.metadata,
  };
}

export function createCmpGitProjectionSourceAnchor(input: {
  candidate: CmpGitSnapshotCandidateRecord;
  checkedRef?: CmpGitCheckedSnapshotRef;
  promotedRef?: CmpGitPromotedSnapshotRef;
  branchHead?: CmpGitBranchHeadState;
}): CmpGitProjectionSourceAnchor {
  return {
    candidateId: input.candidate.candidateId,
    checkedRefName: input.checkedRef?.refName,
    promotedRefName: input.promotedRef?.refName,
    branchHeadRef: input.branchHead?.branchRef.fullRef ?? input.candidate.branchRef.fullRef,
    commitSha: input.branchHead?.headCommitSha ?? input.candidate.commitSha,
  };
}

export function createCmpGitSyncReceipt(input: CmpGitSyncReceipt): CmpGitSyncReceipt {
  return input;
}

export function createCmpGitRuntimeHooks(
  orchestrator: CmpGitSyncRuntimeOrchestrator,
): CmpGitRuntimeHooks {
  return {
    getLineageHook(agentId: string) {
      const node = orchestrator.registry.get(agentId);
      return node ? createCmpGitLineageHook(node) : undefined;
    },
    listChildHooks(parentAgentId: string) {
      return orchestrator.registry.listChildren(parentAgentId).map(createCmpGitLineageHook);
    },
    listPeerHooks(agentId: string) {
      return orchestrator.registry.listPeers(agentId).map(createCmpGitLineageHook);
    },
    getCandidate(candidateId: string) {
      return orchestrator.listCandidates().find((candidate) => candidate.candidateId === candidateId);
    },
    getBranchHead(branchRef: string) {
      return orchestrator.getBranchHead(branchRef);
    },
  };
}
