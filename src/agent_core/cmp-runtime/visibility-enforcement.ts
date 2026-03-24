import type { CmpProjectionVisibility } from "./runtime-types.js";
import {
  assertNonEmpty,
  createCmpLineageNode,
  type CmpLineageNode,
} from "./runtime-types.js";
import type { CmpProjectionRecord } from "./materialization.js";

export type CmpLineageRelation =
  | "self"
  | "parent"
  | "child"
  | "peer"
  | "ancestor"
  | "descendant"
  | "distant";

export interface CmpVisibilityDecision {
  allowed: boolean;
  relation: CmpLineageRelation;
  reason: string;
}

function collectAncestors(node: CmpLineageNode): string[] {
  const ancestors = new Set<string>();
  const lineageAncestors = node.metadata?.ancestorAgentIds;
  if (Array.isArray(lineageAncestors)) {
    for (const ancestor of lineageAncestors) {
      if (typeof ancestor === "string" && ancestor.trim()) {
        ancestors.add(ancestor.trim());
      }
    }
  }
  if (node.parentAgentId) {
    ancestors.add(node.parentAgentId);
  }
  return [...ancestors];
}

export function resolveCmpLineageRelation(params: {
  source: CmpLineageNode;
  target: CmpLineageNode;
}): CmpLineageRelation {
  const source = createCmpLineageNode(params.source);
  const target = createCmpLineageNode(params.target);

  if (source.agentId === target.agentId) {
    return "self";
  }
  if (source.parentAgentId === target.agentId) {
    return "parent";
  }
  if (target.parentAgentId === source.agentId) {
    return "child";
  }
  if (source.parentAgentId && source.parentAgentId === target.parentAgentId) {
    return "peer";
  }

  const sourceAncestors = collectAncestors(source);
  const targetAncestors = collectAncestors(target);
  if (sourceAncestors.includes(target.agentId)) {
    return "ancestor";
  }
  if (targetAncestors.includes(source.agentId)) {
    return "descendant";
  }
  return "distant";
}

export function assertCmpNonSkippingLineage(params: {
  source: CmpLineageNode;
  target: CmpLineageNode;
  allowedRelations?: readonly CmpLineageRelation[];
}): CmpLineageRelation {
  const relation = resolveCmpLineageRelation(params);
  const allowedRelations = params.allowedRelations ?? ["self", "parent", "child", "peer"];
  if (!allowedRelations.includes(relation)) {
    throw new Error(
      `CMP lineage relation ${relation} is not allowed for non-skipping delivery between ${params.source.agentId} and ${params.target.agentId}.`,
    );
  }
  return relation;
}

function isProjectionVisibilityAllowed(params: {
  visibility: CmpProjectionVisibility;
  relation: CmpLineageRelation;
}): boolean {
  switch (params.visibility) {
    case "local_only":
      return params.relation === "self";
    case "submitted_to_parent":
    case "accepted_by_parent":
    case "promoted_by_parent":
      return params.relation === "self" || params.relation === "parent";
    case "dispatched_downward":
      return params.relation === "self" || params.relation === "child";
    case "archived":
      return false;
  }
}

export function evaluateCmpProjectionVisibility(params: {
  projection: Pick<CmpProjectionRecord, "agentId" | "visibility">;
  source: CmpLineageNode;
  target: CmpLineageNode;
}): CmpVisibilityDecision {
  const relation = resolveCmpLineageRelation({
    source: params.source,
    target: params.target,
  });
  const allowed = isProjectionVisibilityAllowed({
    visibility: params.projection.visibility,
    relation,
  });

  return {
    allowed,
    relation,
    reason: allowed
      ? `CMP projection visibility ${params.projection.visibility} allows relation ${relation}.`
      : `CMP projection visibility ${params.projection.visibility} blocks relation ${relation}.`,
  };
}

export function assertCmpProjectionVisibleToTarget(params: {
  projection: Pick<CmpProjectionRecord, "projectionId" | "agentId" | "visibility">;
  source: CmpLineageNode;
  target: CmpLineageNode;
}): CmpLineageRelation {
  assertNonEmpty(params.projection.projectionId, "CMP projection projectionId");
  const decision = evaluateCmpProjectionVisibility(params);
  if (!decision.allowed) {
    throw new Error(
      `CMP projection ${params.projection.projectionId} is not visible to ${params.target.agentId}: ${decision.reason}`,
    );
  }
  return decision.relation;
}
