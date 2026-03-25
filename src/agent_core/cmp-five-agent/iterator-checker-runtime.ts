import { randomUUID } from "node:crypto";

import type {
  CmpCheckerEvaluateInput,
  CmpCheckerRecord,
  CmpIteratorAdvanceInput,
  CmpIteratorRecord,
  CmpPromoteRequestRecord,
  CmpRoleCheckpointRecord,
  CmpIteratorCheckerRuntimeSnapshot,
} from "./types.js";
import { createCmpRoleCheckpointRecord } from "./shared.js";

export interface CmpCheckerRuntimeResult {
  checkerRecord: CmpCheckerRecord;
  promoteRequest?: CmpPromoteRequestRecord;
}

export class CmpIteratorCheckerRuntime {
  readonly #iterator = new Map<string, CmpIteratorRecord>();
  readonly #checker = new Map<string, CmpCheckerRecord>();
  readonly #checkpoints = new Map<string, CmpRoleCheckpointRecord>();
  readonly #promoteRequests = new Map<string, CmpPromoteRequestRecord>();

  advanceIterator(input: CmpIteratorAdvanceInput): CmpIteratorRecord {
    const record: CmpIteratorRecord = {
      loopId: randomUUID(),
      role: "iterator",
      agentId: input.agentId,
      stage: "update_review_ref",
      createdAt: input.createdAt,
      updatedAt: input.createdAt,
      deltaId: input.deltaId,
      candidateId: input.candidateId,
      branchRef: input.branchRef,
      commitRef: input.commitRef,
      reviewRef: input.reviewRef,
      metadata: {
        minimumReviewUnit: "commit",
        ...(input.metadata ?? {}),
      },
    };
    this.#iterator.set(record.loopId, record);
    this.#checkpoint(record, input.createdAt, input.candidateId);
    return record;
  }

  evaluateChecker(input: CmpCheckerEvaluateInput): CmpCheckerRuntimeResult {
    const checkerRecord: CmpCheckerRecord = {
      loopId: randomUUID(),
      role: "checker",
      agentId: input.agentId,
      stage: input.suggestPromote ? "suggest_promote" : "checked",
      createdAt: input.checkedAt,
      updatedAt: input.checkedAt,
      candidateId: input.candidateId,
      checkedSnapshotId: input.checkedSnapshotId,
      suggestPromote: input.suggestPromote,
      metadata: input.metadata,
    };
    this.#checker.set(checkerRecord.loopId, checkerRecord);
    this.#checkpoint(checkerRecord, input.checkedAt, input.checkedSnapshotId);

    const promoteRequest = input.suggestPromote && input.parentAgentId
      ? {
        reviewId: randomUUID(),
        reviewerRole: "dbagent" as const,
        sourceAgentId: input.agentId,
        targetParentAgentId: input.parentAgentId,
        candidateId: input.candidateId,
        checkedSnapshotId: input.checkedSnapshotId,
        status: "pending_parent_dbagent_review" as const,
        createdAt: input.checkedAt,
        requestedAt: input.checkedAt,
        reviewRole: "dbagent" as const,
      }
      : undefined;
    if (promoteRequest) {
      this.#promoteRequests.set(promoteRequest.reviewId, promoteRequest);
    }

    return {
      checkerRecord,
      promoteRequest,
    };
  }

  createSnapshot(agentId?: string): CmpIteratorCheckerRuntimeSnapshot {
    const filter = <T extends { agentId: string }>(items: T[]) => agentId ? items.filter((item) => item.agentId === agentId) : items;
    return {
      iteratorRecords: filter([...this.#iterator.values()]),
      checkerRecords: filter([...this.#checker.values()]),
      checkpoints: filter([...this.#checkpoints.values()]),
      promoteRequests: [...this.#promoteRequests.values()].filter((item) => !agentId || item.sourceAgentId === agentId),
    };
  }

  recover(snapshot?: CmpIteratorCheckerRuntimeSnapshot): void {
    this.#iterator.clear();
    this.#checker.clear();
    this.#checkpoints.clear();
    this.#promoteRequests.clear();
    if (!snapshot) return;
    for (const record of snapshot.iteratorRecords) this.#iterator.set(record.loopId, record);
    for (const record of snapshot.checkerRecords) this.#checker.set(record.loopId, record);
    for (const record of snapshot.checkpoints) this.#checkpoints.set(record.checkpointId, record);
    for (const record of snapshot.promoteRequests) this.#promoteRequests.set(record.reviewId, record);
  }

  #checkpoint(record: CmpIteratorRecord | CmpCheckerRecord, createdAt: string, eventRef: string): void {
    const checkpoint = createCmpRoleCheckpointRecord({
      checkpointId: randomUUID(),
      role: record.role,
      agentId: record.agentId,
      stage: record.stage,
      createdAt,
      eventRef,
      loopId: record.loopId,
    });
    this.#checkpoints.set(checkpoint.checkpointId, checkpoint);
  }
}

export function createCmpIteratorCheckerRuntime(): CmpIteratorCheckerRuntime {
  return new CmpIteratorCheckerRuntime();
}
