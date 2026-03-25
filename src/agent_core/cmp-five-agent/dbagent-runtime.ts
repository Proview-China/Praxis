import {
  createCmpFiveAgentLoopRecord,
  createCmpPackageFamilyRecord,
  createCmpPromoteReviewRecord,
  createCmpRoleCheckpointRecord,
  createCmpSkillSnapshotRecord,
} from "./shared.js";
import type {
  CmpDbAgentMaterializeInput,
  CmpDbAgentMaterializeResult,
  CmpDbAgentPassiveInput,
  CmpDbAgentRecord,
  CmpDbAgentRuntimeSnapshot,
  CmpParentPromoteReviewRecord,
  CmpRoleCheckpointRecord,
  CmpTaskSkillSnapshot,
} from "./types.js";

export function createCmpTimelinePackageRef(contextPackageRef: string): string {
  return `${contextPackageRef}:timeline`;
}

export class CmpDbAgentRuntime {
  readonly #records = new Map<string, CmpDbAgentRecord>();
  readonly #checkpoints = new Map<string, CmpRoleCheckpointRecord>();
  readonly #packageFamilies = new Map<string, ReturnType<typeof createCmpPackageFamilyRecord>>();
  readonly #taskSnapshots = new Map<string, CmpTaskSkillSnapshot>();
  readonly #parentPromoteReviews = new Map<string, CmpParentPromoteReviewRecord>();

  materialize(input: CmpDbAgentMaterializeInput): CmpDbAgentMaterializeResult {
    const taskSnapshot: CmpTaskSkillSnapshot = createCmpSkillSnapshotRecord({
      snapshotId: `${input.contextPackage.packageId}:task-state`,
      taskRef: `${input.checkedSnapshot.agentId}:${input.checkedSnapshot.snapshotId}`,
      summaryRef: input.checkedSnapshot.snapshotId,
      createdAt: input.createdAt,
      metadata: {
        source: "cmp-five-agent-dbagent",
      },
    });
    const family = createCmpPackageFamilyRecord({
      familyId: `${input.contextPackage.packageId}:family`,
      primaryPackageId: input.contextPackage.packageId,
      primaryPackageRef: input.contextPackage.packageRef,
      timelinePackageId: `${input.contextPackage.packageId}:timeline`,
      timelinePackageRef: createCmpTimelinePackageRef(input.contextPackage.packageRef),
      taskSnapshotIds: [taskSnapshot.snapshotId],
      createdAt: input.createdAt,
      metadata: {
        packageTopology: "active_plus_timeline_plus_task_snapshots",
      },
    });
    const loop: CmpDbAgentRecord = {
      ...createCmpFiveAgentLoopRecord({
        loopId: input.loopId,
        role: "dbagent",
        agentId: input.checkedSnapshot.agentId,
        projectId: input.checkedSnapshot.metadata?.projectId as string | undefined,
        stage: "attach_snapshots",
        createdAt: input.createdAt,
        updatedAt: input.createdAt,
        metadata: {
          dbWriteAuthority: "dbagent_only",
        },
      }),
      projectionId: input.projectionId,
      familyId: family.familyId,
      primaryPackageId: input.contextPackage.packageId,
      timelinePackageId: family.timelinePackageId,
      taskSnapshotIds: family.taskSnapshotIds,
    };
    this.#records.set(loop.loopId, loop);
    this.#packageFamilies.set(family.familyId, family);
    this.#taskSnapshots.set(taskSnapshot.snapshotId, taskSnapshot);
    for (const [index, stage] of ["accept_checked", "project", "materialize_package", "attach_snapshots"].entries()) {
      const checkpoint = createCmpRoleCheckpointRecord({
        checkpointId: `${input.loopId}:cp:${index}`,
        role: "dbagent",
        agentId: loop.agentId,
        stage,
        createdAt: input.createdAt,
        eventRef: input.checkedSnapshot.snapshotId,
        metadata: {
          source: "cmp-five-agent-dbagent",
        },
        loopId: input.loopId,
      });
      this.#checkpoints.set(checkpoint.checkpointId, checkpoint);
    }
    return {
      loop,
      family,
      taskSnapshots: [taskSnapshot],
    };
  }

  servePassive(input: CmpDbAgentPassiveInput): CmpDbAgentMaterializeResult {
    const family = createCmpPackageFamilyRecord({
      familyId: `${input.contextPackage.packageId}:family`,
      primaryPackageId: input.contextPackage.packageId,
      primaryPackageRef: input.contextPackage.packageRef,
      timelinePackageId: `${input.contextPackage.packageId}:timeline`,
      timelinePackageRef: createCmpTimelinePackageRef(input.contextPackage.packageRef),
      taskSnapshotIds: [`${input.contextPackage.packageId}:task-state`],
      createdAt: input.createdAt,
      metadata: {
        passiveDefaultPayload: "ContextPackage",
      },
    });
    const taskSnapshot: CmpTaskSkillSnapshot = createCmpSkillSnapshotRecord({
      snapshotId: `${input.contextPackage.packageId}:task-state`,
      taskRef: `${input.request.requesterAgentId}:${input.snapshot.snapshotId}`,
      summaryRef: input.snapshot.snapshotId,
      createdAt: input.createdAt,
      metadata: {
        source: "cmp-five-agent-dbagent-passive",
      },
    });
    const loop: CmpDbAgentRecord = {
      ...createCmpFiveAgentLoopRecord({
        loopId: input.loopId,
        role: "dbagent",
        agentId: input.request.requesterAgentId,
        projectId: input.request.projectId,
        stage: "serve_passive",
        createdAt: input.createdAt,
        updatedAt: input.createdAt,
        metadata: {
          passiveDefaultPayload: "ContextPackage",
        },
      }),
      projectionId: input.contextPackage.sourceProjectionId,
      familyId: family.familyId,
      primaryPackageId: input.contextPackage.packageId,
      timelinePackageId: family.timelinePackageId,
      taskSnapshotIds: family.taskSnapshotIds,
      passiveReplyPackageId: input.contextPackage.packageId,
    };
    this.#records.set(loop.loopId, loop);
    this.#packageFamilies.set(family.familyId, family);
    this.#taskSnapshots.set(taskSnapshot.snapshotId, taskSnapshot);
    const checkpoint = createCmpRoleCheckpointRecord({
      checkpointId: `${input.loopId}:cp:passive`,
      role: "dbagent",
      agentId: loop.agentId,
      stage: "serve_passive",
      createdAt: input.createdAt,
      eventRef: input.request.requesterAgentId,
      metadata: {
        source: "cmp-five-agent-dbagent-passive",
      },
      loopId: input.loopId,
    });
    this.#checkpoints.set(checkpoint.checkpointId, checkpoint);
    return {
      loop,
      family,
      taskSnapshots: [taskSnapshot],
    };
  }

  reviewPromote(input: {
    sourceAgentId: string;
    parentAgentId: string;
    candidateId: string;
    checkedSnapshotId: string;
    reviewId: string;
    createdAt: string;
  }): CmpParentPromoteReviewRecord {
    const review = {
      ...createCmpPromoteReviewRecord({
        reviewId: input.reviewId,
        reviewerRole: "dbagent",
        sourceAgentId: input.sourceAgentId,
        targetParentAgentId: input.parentAgentId,
        candidateId: input.candidateId,
        checkedSnapshotId: input.checkedSnapshotId,
        status: "pending_parent_dbagent_review",
        createdAt: input.createdAt,
        metadata: {
          source: "cmp-five-agent-dbagent-parent-review",
        },
      }),
      reviewedAt: input.createdAt,
      stage: "ready" as const,
      reviewRole: "dbagent" as const,
      parentAgentId: input.parentAgentId,
      childAgentId: input.sourceAgentId,
      projectionId: `projection:${input.checkedSnapshotId}`,
    };
    this.#parentPromoteReviews.set(review.reviewId, review);
    return review;
  }

  createSnapshot(agentId?: string): CmpDbAgentRuntimeSnapshot {
    return {
      records: [...this.#records.values()].filter((record) => !agentId || record.agentId === agentId),
      checkpoints: [...this.#checkpoints.values()].filter((record) => !agentId || record.agentId === agentId),
      packageFamilies: [...this.#packageFamilies.values()],
      taskSnapshots: [...this.#taskSnapshots.values()],
      parentPromoteReviews: [...this.#parentPromoteReviews.values()].filter((record) => !agentId || record.sourceAgentId === agentId || record.targetParentAgentId === agentId),
    };
  }

  recover(snapshot?: CmpDbAgentRuntimeSnapshot): void {
    this.#records.clear();
    this.#checkpoints.clear();
    this.#packageFamilies.clear();
    this.#taskSnapshots.clear();
    this.#parentPromoteReviews.clear();
    if (!snapshot) return;
    for (const record of snapshot.records) this.#records.set(record.loopId, record);
    for (const record of snapshot.checkpoints) this.#checkpoints.set(record.checkpointId, record);
    for (const record of snapshot.packageFamilies) this.#packageFamilies.set(record.familyId, record);
    for (const record of snapshot.taskSnapshots) this.#taskSnapshots.set(record.snapshotId, record);
    for (const record of snapshot.parentPromoteReviews) this.#parentPromoteReviews.set(record.reviewId, record);
  }
}

export function createCmpDbAgentRuntime(): CmpDbAgentRuntime {
  return new CmpDbAgentRuntime();
}
