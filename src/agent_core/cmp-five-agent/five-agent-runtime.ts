import { createCmpDbAgentRuntime, type CmpDbAgentRuntime } from "./dbagent-runtime.js";
import { createCmpDispatcherRuntime, type CmpDispatcherRuntime } from "./dispatcher-runtime.js";
import { createCmpIcmaRuntime, type CmpIcmaRuntime } from "./icma-runtime.js";
import { createCmpIteratorCheckerRuntime, type CmpIteratorCheckerRuntime } from "./iterator-checker-runtime.js";
import type {
  CmpFiveAgentRuntimeSnapshot,
  CmpFiveAgentSummary,
  CmpFiveAgentRole,
} from "./types.js";

export interface CmpFiveAgentRuntimeOptions {
  icma?: CmpIcmaRuntime;
  iteratorChecker?: CmpIteratorCheckerRuntime;
  dbagent?: CmpDbAgentRuntime;
  dispatcher?: CmpDispatcherRuntime;
}

export class CmpFiveAgentRuntime {
  readonly icma: CmpIcmaRuntime;
  readonly iteratorChecker: CmpIteratorCheckerRuntime;
  readonly dbagent: CmpDbAgentRuntime;
  readonly dispatcher: CmpDispatcherRuntime;

  constructor(options: CmpFiveAgentRuntimeOptions = {}) {
    this.icma = options.icma ?? createCmpIcmaRuntime();
    this.iteratorChecker = options.iteratorChecker ?? createCmpIteratorCheckerRuntime();
    this.dbagent = options.dbagent ?? createCmpDbAgentRuntime();
    this.dispatcher = options.dispatcher ?? createCmpDispatcherRuntime();
  }

  createSnapshot(agentId?: string): CmpFiveAgentRuntimeSnapshot {
    const icma = this.icma.createSnapshot(agentId);
    const iteratorChecker = this.iteratorChecker.createSnapshot(agentId);
    const dbagent = this.dbagent.createSnapshot(agentId);
    const dispatcher = this.dispatcher.createSnapshot(agentId);
    return {
      icmaRecords: icma.records,
      iteratorRecords: iteratorChecker.iteratorRecords,
      checkerRecords: iteratorChecker.checkerRecords,
      dbAgentRecords: dbagent.records,
      dispatcherRecords: dispatcher.records,
      checkpoints: [
        ...icma.checkpoints,
        ...iteratorChecker.checkpoints,
        ...dbagent.checkpoints,
        ...dispatcher.checkpoints,
      ],
      overrides: [],
      intentChunks: icma.intentChunks,
      fragments: icma.fragments,
      packageFamilies: dbagent.packageFamilies,
      taskSnapshots: dbagent.taskSnapshots,
      promoteRequests: iteratorChecker.promoteRequests,
      parentPromoteReviews: dbagent.parentPromoteReviews,
    };
  }

  recover(snapshot?: CmpFiveAgentRuntimeSnapshot): void {
    this.icma.recover(snapshot ? {
      records: snapshot.icmaRecords,
      intentChunks: snapshot.intentChunks,
      fragments: snapshot.fragments,
      checkpoints: snapshot.checkpoints.filter((item) => item.role === "icma"),
    } : undefined);
    this.iteratorChecker.recover(snapshot ? {
      iteratorRecords: snapshot.iteratorRecords,
      checkerRecords: snapshot.checkerRecords,
      checkpoints: snapshot.checkpoints.filter((item) => item.role === "iterator" || item.role === "checker"),
      promoteRequests: snapshot.promoteRequests,
    } : undefined);
    this.dbagent.recover(snapshot ? {
      records: snapshot.dbAgentRecords,
      checkpoints: snapshot.checkpoints.filter((item) => item.role === "dbagent"),
      packageFamilies: snapshot.packageFamilies,
      taskSnapshots: snapshot.taskSnapshots,
      parentPromoteReviews: snapshot.parentPromoteReviews,
    } : undefined);
    this.dispatcher.recover(snapshot ? {
      records: snapshot.dispatcherRecords,
      checkpoints: snapshot.checkpoints.filter((item) => item.role === "dispatcher"),
      peerApprovals: [],
    } : undefined);
  }

  createSummary(agentId?: string): CmpFiveAgentSummary {
    const snapshot = this.createSnapshot(agentId);
    const roleCounts: Record<CmpFiveAgentRole, number> = {
      icma: snapshot.icmaRecords.length,
      iterator: snapshot.iteratorRecords.length,
      checker: snapshot.checkerRecords.length,
      dbagent: snapshot.dbAgentRecords.length,
      dispatcher: snapshot.dispatcherRecords.length,
    };
    return {
      agentId,
      roleCounts,
      latestStages: {
        icma: snapshot.icmaRecords.at(-1)?.stage,
        iterator: snapshot.iteratorRecords.at(-1)?.stage,
        checker: snapshot.checkerRecords.at(-1)?.stage,
        dbagent: snapshot.dbAgentRecords.at(-1)?.stage,
        dispatcher: snapshot.dispatcherRecords.at(-1)?.stage,
      },
      checkpointCount: snapshot.checkpoints.length,
      overrideCount: snapshot.overrides.length,
      peerExchangePendingApprovalCount: snapshot.dispatcherRecords.filter((record) => record.metadata?.approvalStatus === "pending").length,
      parentPromoteReviewCount: snapshot.parentPromoteReviews.length,
    };
  }
}

export function createCmpFiveAgentRuntime(options: CmpFiveAgentRuntimeOptions = {}): CmpFiveAgentRuntime {
  return new CmpFiveAgentRuntime(options);
}
