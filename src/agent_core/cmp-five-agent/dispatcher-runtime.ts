import {
  createCmpFiveAgentLoopRecord,
  createCmpPeerExchangeApprovalRecord,
  createCmpRoleCheckpointRecord,
} from "./shared.js";
import type {
  CmpDispatcherDispatchInput,
  CmpDispatcherPassiveReturnInput,
  CmpDispatcherRecord,
  CmpDispatcherRuntimeSnapshot,
  CmpPeerExchangeApprovalRecord,
  CmpRoleCheckpointRecord,
} from "./types.js";

function inferPackageMode(input: CmpDispatcherDispatchInput): CmpDispatcherRecord["packageMode"] {
  if (input.dispatch.targetKind === "core_agent") {
    return "core_return";
  }
  if (input.dispatch.targetKind === "child") {
    return "child_seed_via_icma";
  }
  if (input.dispatch.targetKind === "peer") {
    return "peer_exchange_slim";
  }
  return "lineage_delivery";
}

export interface CmpDispatcherRuntimeResult {
  loop: CmpDispatcherRecord;
  peerApproval?: CmpPeerExchangeApprovalRecord;
}

export class CmpDispatcherRuntime {
  readonly #records = new Map<string, CmpDispatcherRecord>();
  readonly #checkpoints = new Map<string, CmpRoleCheckpointRecord>();
  readonly #peerApprovals = new Map<string, CmpPeerExchangeApprovalRecord>();

  dispatch(input: CmpDispatcherDispatchInput): CmpDispatcherRuntimeResult {
    const packageMode = inferPackageMode(input);
    const peerApproval = input.dispatch.targetKind === "peer"
      ? createCmpPeerExchangeApprovalRecord({
        approvalId: `${input.loopId}:approval`,
        parentAgentId: String(input.dispatch.metadata?.parentAgentId ?? "unknown-parent"),
        sourceAgentId: input.dispatch.sourceAgentId,
        targetAgentId: input.dispatch.targetAgentId,
        packageId: input.contextPackage.packageId,
        createdAt: input.createdAt,
        mode: "explicit_once",
        metadata: {
          approvalStatus: "pending",
        },
      })
      : undefined;
    const loop: CmpDispatcherRecord = {
      ...createCmpFiveAgentLoopRecord({
        loopId: input.loopId,
        role: "dispatcher",
        agentId: input.dispatch.sourceAgentId,
        stage: "collect_receipt",
        createdAt: input.createdAt,
        updatedAt: input.createdAt,
        metadata: {
          approvalStatus: peerApproval ? "pending" : undefined,
          childSeedsEnterIcmaOnly: input.dispatch.targetKind === "child",
        },
      }),
      dispatchId: input.receipt.dispatchId,
      packageId: input.contextPackage.packageId,
      targetAgentId: input.dispatch.targetAgentId,
      targetKind: input.dispatch.targetKind,
      packageMode,
    };
    this.#records.set(loop.loopId, loop);
    for (const [index, stage] of ["route", "deliver", "collect_receipt"].entries()) {
      const checkpoint = createCmpRoleCheckpointRecord({
        checkpointId: `${input.loopId}:cp:${index}`,
        role: "dispatcher",
        agentId: loop.agentId,
        stage,
        createdAt: input.createdAt,
        eventRef: input.receipt.dispatchId,
        metadata: {
          source: "cmp-five-agent-dispatcher",
        },
        loopId: input.loopId,
      });
      this.#checkpoints.set(checkpoint.checkpointId, checkpoint);
    }
    if (peerApproval) {
      this.#peerApprovals.set(peerApproval.approvalId, peerApproval);
    }
    return {
      loop,
      peerApproval,
    };
  }

  deliverPassiveReturn(input: CmpDispatcherPassiveReturnInput): CmpDispatcherRecord {
    const loop: CmpDispatcherRecord = {
      ...createCmpFiveAgentLoopRecord({
        loopId: input.loopId,
        role: "dispatcher",
        agentId: input.request.requesterAgentId,
        stage: "collect_receipt",
        createdAt: input.createdAt,
        updatedAt: input.createdAt,
        metadata: {
          passiveReturned: true,
        },
      }),
      dispatchId: `${input.loopId}:passive`,
      packageId: input.contextPackage.packageId,
      targetAgentId: input.request.requesterAgentId,
      targetKind: "core_agent",
      packageMode: "historical_reply_return",
    };
    this.#records.set(loop.loopId, loop);
    const checkpoint = createCmpRoleCheckpointRecord({
      checkpointId: `${input.loopId}:cp:passive`,
      role: "dispatcher",
      agentId: loop.agentId,
      stage: "collect_receipt",
      createdAt: input.createdAt,
      eventRef: loop.dispatchId,
      metadata: {
        source: "cmp-five-agent-dispatcher-passive",
      },
      loopId: input.loopId,
    });
    this.#checkpoints.set(checkpoint.checkpointId, checkpoint);
    return loop;
  }

  createSnapshot(agentId?: string): CmpDispatcherRuntimeSnapshot {
    return {
      records: [...this.#records.values()].filter((record) => !agentId || record.agentId === agentId),
      checkpoints: [...this.#checkpoints.values()].filter((record) => !agentId || record.agentId === agentId),
      peerApprovals: [...this.#peerApprovals.values()].filter((record) => !agentId || record.sourceAgentId === agentId || record.targetAgentId === agentId),
    };
  }

  recover(snapshot?: CmpDispatcherRuntimeSnapshot): void {
    this.#records.clear();
    this.#checkpoints.clear();
    this.#peerApprovals.clear();
    if (!snapshot) return;
    for (const record of snapshot.records) this.#records.set(record.loopId, record);
    for (const record of snapshot.checkpoints) this.#checkpoints.set(record.checkpointId, record);
    for (const record of snapshot.peerApprovals) this.#peerApprovals.set(record.approvalId, record);
  }
}

export function createCmpDispatcherRuntime(): CmpDispatcherRuntime {
  return new CmpDispatcherRuntime();
}
