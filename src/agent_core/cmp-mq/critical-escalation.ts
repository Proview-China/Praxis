import {
  type CmpCriticalEscalationEnvelope,
  validateCmpCriticalEscalationEnvelope,
} from "./cmp-mq-types.js";

export function createCmpCriticalEscalationEnvelope(
  input: Omit<CmpCriticalEscalationEnvelope, "deliveryMode" | "redactionLevel">,
): CmpCriticalEscalationEnvelope {
  const envelope: CmpCriticalEscalationEnvelope = {
    ...input,
    escalationId: input.escalationId.trim(),
    projectId: input.projectId.trim(),
    sourceAgentId: input.sourceAgentId.trim(),
    targetAncestorId: input.targetAncestorId.trim(),
    reason: input.reason.trim(),
    evidenceRef: input.evidenceRef.trim(),
    deliveryMode: "alert_envelope",
    redactionLevel: "summary_only",
  };
  validateCmpCriticalEscalationEnvelope(envelope);
  return envelope;
}

export function assertCmpCriticalEscalationAllowed(params: {
  envelope: CmpCriticalEscalationEnvelope;
  knownAncestorIds: readonly string[];
  parentReachability: "healthy" | "degraded" | "unavailable";
}): void {
  validateCmpCriticalEscalationEnvelope(params.envelope);

  if (!params.knownAncestorIds.includes(params.envelope.targetAncestorId)) {
    throw new Error(
      `CMP critical escalation target ${params.envelope.targetAncestorId} is not a known ancestor.`,
    );
  }

  if (params.parentReachability !== "unavailable") {
    throw new Error(
      `CMP critical escalation requires unavailable parent reachability, got ${params.parentReachability}.`,
    );
  }
}

