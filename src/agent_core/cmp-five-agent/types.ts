import type {
  CheckedSnapshot,
  CommitContextDeltaInput,
  ContextDelta,
  ContextPackage,
  DispatchContextPackageInput,
  DispatchReceipt,
  IngestRuntimeContextInput,
  PromotedProjection,
  RequestHistoricalContextInput,
  SnapshotCandidate,
} from "../cmp-types/index.js";
import type {
  CmpFiveAgentCheckpointRecord,
  CmpFiveAgentLoopRecord,
  CmpFiveAgentRole,
  CmpOverrideAuditRecord,
  CmpPackageFamilyRecord,
  CmpPeerExchangeApprovalRecord,
  CmpPromoteReviewRecord,
  CmpSkillSnapshotRecord,
} from "./shared.js";
export type { CmpFiveAgentRole, CmpPeerExchangeApprovalRecord } from "./shared.js";

export const CMP_SYSTEM_FRAGMENT_KINDS = ["constraint", "risk", "flow"] as const;
export type CmpSystemFragmentKind = (typeof CMP_SYSTEM_FRAGMENT_KINDS)[number];
export const CMP_ICMA_STAGES = ["capture", "chunk_by_intent", "attach_fragment", "emit"] as const;
export const CMP_ITERATOR_STAGES = ["accept_material", "write_candidate_commit", "update_review_ref"] as const;
export const CMP_CHECKER_STAGES = ["accept_candidate", "restructure", "checked", "suggest_promote"] as const;
export const CMP_DBAGENT_STAGES = ["accept_checked", "project", "materialize_package", "attach_snapshots", "serve_passive"] as const;
export const CMP_DISPATCHER_STAGES = ["route", "deliver", "collect_receipt", "timeout_handle"] as const;

export type CmpIcmaStage = (typeof CMP_ICMA_STAGES)[number];
export type CmpIteratorStage = (typeof CMP_ITERATOR_STAGES)[number];
export type CmpCheckerStage = (typeof CMP_CHECKER_STAGES)[number];
export type CmpDbAgentStage = (typeof CMP_DBAGENT_STAGES)[number];
export type CmpDispatcherStage = (typeof CMP_DISPATCHER_STAGES)[number];

export interface CmpRoleCheckpointRecord extends CmpFiveAgentCheckpointRecord {}
export interface CmpRoleOverrideRecord extends CmpOverrideAuditRecord {}
export type CmpTaskSkillSnapshot = CmpSkillSnapshotRecord;
export interface CmpParentPromoteReviewRecord extends CmpPromoteReviewRecord {
  reviewedAt: string;
  stage: "ready";
  reviewRole: "dbagent";
}

export interface CmpSystemFragmentRecord {
  fragmentId: string;
  agentId: string;
  kind: CmpSystemFragmentKind;
  content: string;
  createdAt: string;
  lifecycle: "task_phase";
  metadata?: Record<string, unknown>;
}

export interface CmpIntentChunkRecord {
  chunkId: string;
  agentId: string;
  taskSummary: string;
  materialRefs: string[];
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface CmpIcmaRecord extends CmpFiveAgentLoopRecord<CmpIcmaStage> {
  chunkIds: string[];
  fragmentIds: string[];
  eventIds?: string[];
}

export interface CmpIcmaIngestInput {
  ingest: IngestRuntimeContextInput;
  createdAt: string;
  loopId: string;
}

export interface CmpIcmaEmitInput {
  recordId: string;
  eventIds: string[];
  emittedAt: string;
}

export interface CmpIcmaRuntimeSnapshot {
  records: CmpIcmaRecord[];
  intentChunks: CmpIntentChunkRecord[];
  fragments: CmpSystemFragmentRecord[];
  checkpoints: CmpRoleCheckpointRecord[];
}

export interface CmpIteratorRecord extends CmpFiveAgentLoopRecord<CmpIteratorStage> {
  deltaId: string;
  candidateId: string;
  branchRef: string;
  commitRef: string;
  reviewRef: string;
}

export interface CmpIteratorAdvanceInput {
  agentId: string;
  deltaId: string;
  candidateId: string;
  branchRef: string;
  commitRef: string;
  reviewRef: string;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface CmpCheckerRecord extends CmpFiveAgentLoopRecord<CmpCheckerStage> {
  candidateId: string;
  checkedSnapshotId: string;
  suggestPromote: boolean;
}

export interface CmpPromoteRequestRecord extends CmpPromoteReviewRecord {
  requestedAt: string;
  reviewRole: "dbagent";
}

export interface CmpCheckerEvaluateInput {
  agentId: string;
  candidateId: string;
  checkedSnapshotId: string;
  checkedAt: string;
  suggestPromote: boolean;
  parentAgentId?: string;
  metadata?: Record<string, unknown>;
}

export interface CmpIteratorCheckerRuntimeSnapshot {
  iteratorRecords: CmpIteratorRecord[];
  checkerRecords: CmpCheckerRecord[];
  checkpoints: CmpRoleCheckpointRecord[];
  promoteRequests: CmpPromoteRequestRecord[];
}

export interface CmpDbAgentRecord extends CmpFiveAgentLoopRecord<CmpDbAgentStage> {
  projectionId: string;
  familyId: string;
  primaryPackageId: string;
  timelinePackageId?: string;
  taskSnapshotIds: string[];
  passiveReplyPackageId?: string;
}

export interface CmpDbAgentMaterializeInput {
  checkedSnapshot: CheckedSnapshot;
  projectionId: string;
  contextPackage: ContextPackage;
  createdAt: string;
  loopId: string;
}

export interface CmpDbAgentMaterializeResult {
  loop: CmpDbAgentRecord;
  family: CmpPackageFamilyRecord;
  taskSnapshots: CmpTaskSkillSnapshot[];
}

export interface CmpDbAgentPassiveInput {
  request: RequestHistoricalContextInput;
  snapshot: CheckedSnapshot;
  contextPackage: ContextPackage;
  createdAt: string;
  loopId: string;
}

export interface CmpDbAgentRuntimeSnapshot {
  records: CmpDbAgentRecord[];
  checkpoints: CmpRoleCheckpointRecord[];
  packageFamilies: CmpPackageFamilyRecord[];
  taskSnapshots: CmpTaskSkillSnapshot[];
  parentPromoteReviews: CmpParentPromoteReviewRecord[];
}

export interface CmpDispatcherRecord extends CmpFiveAgentLoopRecord<CmpDispatcherStage> {
  dispatchId: string;
  packageId: string;
  targetAgentId: string;
  targetKind: DispatchContextPackageInput["targetKind"];
  packageMode: "core_return" | "child_seed_via_icma" | "peer_exchange_slim" | "historical_reply_return" | "lineage_delivery";
}

export interface CmpDispatcherDispatchInput {
  contextPackage: ContextPackage;
  dispatch: DispatchContextPackageInput;
  receipt: DispatchReceipt;
  createdAt: string;
  loopId: string;
}

export interface CmpDispatcherPassiveReturnInput {
  request: RequestHistoricalContextInput;
  contextPackage: ContextPackage;
  createdAt: string;
  loopId: string;
}

export interface CmpDispatcherRuntimeSnapshot {
  records: CmpDispatcherRecord[];
  checkpoints: CmpRoleCheckpointRecord[];
  peerApprovals: CmpPeerExchangeApprovalRecord[];
}

export interface CmpFiveAgentRuntimeSnapshot {
  icmaRecords: CmpIcmaRecord[];
  iteratorRecords: CmpIteratorRecord[];
  checkerRecords: CmpCheckerRecord[];
  dbAgentRecords: CmpDbAgentRecord[];
  dispatcherRecords: CmpDispatcherRecord[];
  checkpoints: CmpRoleCheckpointRecord[];
  overrides: CmpRoleOverrideRecord[];
  intentChunks: CmpIntentChunkRecord[];
  fragments: CmpSystemFragmentRecord[];
  packageFamilies: CmpPackageFamilyRecord[];
  taskSnapshots: CmpTaskSkillSnapshot[];
  promoteRequests: CmpPromoteRequestRecord[];
  parentPromoteReviews: CmpParentPromoteReviewRecord[];
}

export interface CmpFiveAgentSummary {
  agentId?: string;
  roleCounts: Record<CmpFiveAgentRole, number>;
  latestStages: Record<CmpFiveAgentRole, string | undefined>;
  checkpointCount: number;
  overrideCount: number;
  peerExchangePendingApprovalCount: number;
  parentPromoteReviewCount: number;
}

export function createCheckerCheckedSnapshotMetadata(input: { snapshot: CheckedSnapshot; result: { checkerRecord: CmpCheckerRecord; promoteRequest?: CmpPromoteRequestRecord } }): Record<string, unknown> {
  return {
    cmpCheckerLoopId: input.result.checkerRecord.loopId,
    cmpCheckerStage: input.result.checkerRecord.stage,
    cmpCheckerPromoteSuggested: input.result.checkerRecord.suggestPromote,
    cmpPromoteReviewId: input.result.promoteRequest?.reviewId,
    cmpReviewRole: input.result.promoteRequest?.reviewRole,
    cmpCheckedSnapshotId: input.snapshot.snapshotId,
  };
}
