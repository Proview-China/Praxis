import type { CmpGitProjectRepo } from "../cmp-git/index.js";
import type { AgentLineage, CheckedSnapshot, ContextDelta, ContextEvent, ContextPackage, DispatchReceipt, PromotedProjection, SnapshotCandidate, SyncEvent } from "../cmp-types/index.js";
import type { CmpActiveLineRecord } from "./active-line.js";

export interface CmpRuntimeSnapshot {
  projectRepos: CmpGitProjectRepo[];
  lineages: AgentLineage[];
  events: ContextEvent[];
  deltas: ContextDelta[];
  activeLines: CmpActiveLineRecord[];
  snapshotCandidates: SnapshotCandidate[];
  checkedSnapshots: CheckedSnapshot[];
  promotedProjections: PromotedProjection[];
  contextPackages: ContextPackage[];
  dispatchReceipts: DispatchReceipt[];
  syncEvents: SyncEvent[];
  metadata?: Record<string, unknown>;
}

export interface CreateCmpRuntimeSnapshotInput {
  projectRepos?: readonly CmpGitProjectRepo[];
  lineages?: readonly AgentLineage[];
  events?: readonly ContextEvent[];
  deltas?: readonly ContextDelta[];
  activeLines?: readonly CmpActiveLineRecord[];
  snapshotCandidates?: readonly SnapshotCandidate[];
  checkedSnapshots?: readonly CheckedSnapshot[];
  promotedProjections?: readonly PromotedProjection[];
  contextPackages?: readonly ContextPackage[];
  dispatchReceipts?: readonly DispatchReceipt[];
  syncEvents?: readonly SyncEvent[];
  metadata?: Record<string, unknown>;
}

export function createCmpRuntimeSnapshot(
  input: CreateCmpRuntimeSnapshotInput = {},
): CmpRuntimeSnapshot {
  return {
    projectRepos: [...(input.projectRepos ?? [])],
    lineages: [...(input.lineages ?? [])],
    events: [...(input.events ?? [])],
    deltas: [...(input.deltas ?? [])],
    activeLines: [...(input.activeLines ?? [])],
    snapshotCandidates: [...(input.snapshotCandidates ?? [])],
    checkedSnapshots: [...(input.checkedSnapshots ?? [])],
    promotedProjections: [...(input.promotedProjections ?? [])],
    contextPackages: [...(input.contextPackages ?? [])],
    dispatchReceipts: [...(input.dispatchReceipts ?? [])],
    syncEvents: [...(input.syncEvents ?? [])],
    metadata: input.metadata,
  };
}
