import { assertNonEmpty, type CmpLineageNode } from "./runtime-types.js";
import {
  acknowledgeCmpDispatchReceipt,
  createCmpDispatchInstruction,
  createCmpDispatchReceipt,
  markCmpDispatchDelivered,
  type CmpDeliveryDirection,
  type CmpDispatchInstruction,
  type CmpDispatchReceipt,
} from "./delivery.js";
import type { CmpContextPackageRecord } from "./materialization.js";
import {
  assertCmpNonSkippingLineage,
  type CmpLineageRelation,
} from "./visibility-enforcement.js";

export interface PlanCmpDispatcherDeliveryInput {
  source: CmpLineageNode;
  target: CmpLineageNode;
  contextPackage: CmpContextPackageRecord;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface CmpDispatcherDeliveryPlan {
  relation: CmpLineageRelation;
  instruction: CmpDispatchInstruction;
  receipt: CmpDispatchReceipt;
}

function relationToDirection(relation: CmpLineageRelation): CmpDeliveryDirection {
  switch (relation) {
    case "parent":
    case "peer":
    case "child":
      return relation;
    default:
      throw new Error(`CMP dispatcher cannot map lineage relation ${relation} to delivery direction.`);
  }
}

export function planCmpDispatcherDelivery(
  input: PlanCmpDispatcherDeliveryInput,
): CmpDispatcherDeliveryPlan {
  assertNonEmpty(input.contextPackage.packageId, "CMP delivery packageId");
  const relation = assertCmpNonSkippingLineage({
    source: input.source,
    target: input.target,
  });
  if (relation === "self") {
    throw new Error("CMP dispatcher delivery should use the core-agent return path for self delivery.");
  }

  const direction = relationToDirection(relation);
  const instruction = createCmpDispatchInstruction({
    dispatchId: `${input.contextPackage.packageId}:${input.target.agentId}:${direction}`,
    packageId: input.contextPackage.packageId,
    sourceAgentId: input.source.agentId,
    targetAgentId: input.target.agentId,
    direction,
    createdAt: input.createdAt,
    metadata: input.metadata,
  });
  const prepared = createCmpDispatchReceipt({
    dispatchId: instruction.dispatchId,
    packageId: instruction.packageId,
    sourceAgentId: instruction.sourceAgentId,
    targetAgentId: instruction.targetAgentId,
    direction: instruction.direction,
    status: "prepared",
    createdAt: input.createdAt,
    metadata: input.metadata,
  });
  const delivered = markCmpDispatchDelivered({
    receipt: prepared,
    deliveredAt: input.createdAt,
    metadata: {
      relation,
      ...(input.metadata ?? {}),
    },
  });

  return {
    relation,
    instruction,
    receipt: delivered,
  };
}

export function createCmpCoreAgentReturnReceipt(input: {
  dispatchId: string;
  packageId: string;
  sourceAgentId: string;
  coreAgentHandle: string;
  createdAt: string;
  metadata?: Record<string, unknown>;
}): CmpDispatchReceipt {
  return createCmpDispatchReceipt({
    dispatchId: assertNonEmpty(input.dispatchId, "CMP core-agent dispatchId"),
    packageId: assertNonEmpty(input.packageId, "CMP core-agent packageId"),
    sourceAgentId: assertNonEmpty(input.sourceAgentId, "CMP core-agent sourceAgentId"),
    targetAgentId: assertNonEmpty(input.coreAgentHandle, "CMP core-agent handle"),
    direction: "core_agent",
    status: "delivered",
    createdAt: input.createdAt,
    deliveredAt: input.createdAt,
    metadata: input.metadata,
  });
}

export function acknowledgeCmpCoreAgentReturn(params: {
  receipt: CmpDispatchReceipt;
  acknowledgedAt: string;
  metadata?: Record<string, unknown>;
}): CmpDispatchReceipt {
  if (params.receipt.direction !== "core_agent") {
    throw new Error("CMP core-agent return acknowledgement only accepts core_agent receipts.");
  }
  return acknowledgeCmpDispatchReceipt({
    receipt: {
      ...params.receipt,
      status: params.receipt.status === "delivered" ? "delivered" : params.receipt.status,
    },
    acknowledgedAt: params.acknowledgedAt,
    metadata: params.metadata,
  });
}
