import { CmpGitLineageRegistry } from "./lineage-registry.js";

export type CmpGitLineageRelation =
  | "self"
  | "parent"
  | "child"
  | "peer"
  | "ancestor"
  | "descendant"
  | "distant";

export interface CmpGitCriticalEscalationAlert {
  alertId: string;
  projectId: string;
  sourceAgentId: string;
  targetAncestorId: string;
  severity: "high" | "critical";
  reason: string;
  evidenceRef: string;
  deliveryMode: "alert_only";
  redactionLevel: "summary_only";
  createdAt: string;
  metadata?: Record<string, unknown>;
}

function assertNonEmpty(value: string, label: string): string {
  const normalized = value.trim();
  if (!normalized) {
    throw new Error(`${label} requires a non-empty string.`);
  }
  return normalized;
}

function collectAncestors(
  registry: CmpGitLineageRegistry,
  agentId: string,
): string[] {
  const ancestors: string[] = [];
  let current = registry.get(agentId);
  while (current?.parentAgentId) {
    ancestors.push(current.parentAgentId);
    current = registry.get(current.parentAgentId);
  }
  return ancestors;
}

export function resolveCmpGitLineageRelation(params: {
  registry: CmpGitLineageRegistry;
  sourceAgentId: string;
  targetAgentId: string;
}): CmpGitLineageRelation {
  const sourceAgentId = assertNonEmpty(params.sourceAgentId, "CMP git sourceAgentId");
  const targetAgentId = assertNonEmpty(params.targetAgentId, "CMP git targetAgentId");
  if (sourceAgentId === targetAgentId) {
    return "self";
  }

  const source = params.registry.get(sourceAgentId);
  const target = params.registry.get(targetAgentId);
  if (!source || !target) {
    return "distant";
  }
  if (source.parentAgentId === targetAgentId) {
    return "parent";
  }
  if (target.parentAgentId === sourceAgentId) {
    return "child";
  }
  if (source.parentAgentId && source.parentAgentId === target.parentAgentId) {
    return "peer";
  }

  const sourceAncestors = collectAncestors(params.registry, sourceAgentId);
  const targetAncestors = collectAncestors(params.registry, targetAgentId);
  if (sourceAncestors.includes(targetAgentId)) {
    return "ancestor";
  }
  if (targetAncestors.includes(sourceAgentId)) {
    return "descendant";
  }
  return "distant";
}

export function assertCmpGitNonSkippingPromotion(params: {
  registry: CmpGitLineageRegistry;
  sourceAgentId: string;
  targetAgentId: string;
}): "parent" {
  const relation = resolveCmpGitLineageRelation(params);
  if (relation !== "parent") {
    throw new Error(
      `CMP git promotion must target the direct parent only, got relation ${relation} for ${params.sourceAgentId} -> ${params.targetAgentId}.`,
    );
  }
  return relation;
}

export function assertCmpGitPeerExchangeStaysLocal(params: {
  registry: CmpGitLineageRegistry;
  sourceAgentId: string;
  targetAgentId: string;
}): "peer" {
  const relation = resolveCmpGitLineageRelation(params);
  if (relation !== "peer") {
    throw new Error(
      `CMP git peer exchange requires a peer relation, got ${relation} for ${params.sourceAgentId} -> ${params.targetAgentId}.`,
    );
  }
  return relation;
}

export function createCmpGitCriticalEscalationAlert(
  input: Omit<CmpGitCriticalEscalationAlert, "deliveryMode" | "redactionLevel">,
): CmpGitCriticalEscalationAlert {
  return {
    alertId: assertNonEmpty(input.alertId, "CMP git alertId"),
    projectId: assertNonEmpty(input.projectId, "CMP git projectId"),
    sourceAgentId: assertNonEmpty(input.sourceAgentId, "CMP git sourceAgentId"),
    targetAncestorId: assertNonEmpty(input.targetAncestorId, "CMP git targetAncestorId"),
    severity: input.severity,
    reason: assertNonEmpty(input.reason, "CMP git critical escalation reason"),
    evidenceRef: assertNonEmpty(input.evidenceRef, "CMP git critical escalation evidenceRef"),
    deliveryMode: "alert_only",
    redactionLevel: "summary_only",
    createdAt: input.createdAt,
    metadata: input.metadata,
  };
}

export function assertCmpGitCriticalEscalationAllowed(params: {
  registry: CmpGitLineageRegistry;
  alert: CmpGitCriticalEscalationAlert;
  parentReachability: "healthy" | "degraded" | "unavailable";
}): void {
  const relation = resolveCmpGitLineageRelation({
    registry: params.registry,
    sourceAgentId: params.alert.sourceAgentId,
    targetAgentId: params.alert.targetAncestorId,
  });
  if (relation !== "ancestor") {
    throw new Error(
      `CMP git critical escalation target ${params.alert.targetAncestorId} must be an ancestor, got ${relation}.`,
    );
  }
  if (params.parentReachability !== "unavailable") {
    throw new Error(
      `CMP git critical escalation requires unavailable parent reachability, got ${params.parentReachability}.`,
    );
  }
}
