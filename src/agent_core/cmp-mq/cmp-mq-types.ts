export const CMP_MQ_CHANNEL_KINDS = [
  "local",
  "to_parent",
  "peer",
  "to_children",
  "promotion",
  "critical_escalation",
] as const;
export type CmpMqChannelKind = (typeof CMP_MQ_CHANNEL_KINDS)[number];

export const CMP_NEIGHBORHOOD_DIRECTIONS = [
  "parent",
  "peer",
  "child",
] as const;
export type CmpNeighborhoodDirection = (typeof CMP_NEIGHBORHOOD_DIRECTIONS)[number];

export const CMP_SUBSCRIPTION_RELATIONS = [
  "parent",
  "peer",
  "child",
] as const;
export type CmpSubscriptionRelation = (typeof CMP_SUBSCRIPTION_RELATIONS)[number];

export const CMP_CRITICAL_ESCALATION_SEVERITIES = [
  "high",
  "critical",
] as const;
export type CmpCriticalEscalationSeverity = (typeof CMP_CRITICAL_ESCALATION_SEVERITIES)[number];

export interface CmpAgentNeighborhood {
  agentId: string;
  parentAgentId?: string;
  peerAgentIds: readonly string[];
  childAgentIds: readonly string[];
}

export interface CmpMqTopicDescriptor {
  projectId: string;
  agentId: string;
  channel: CmpMqChannelKind;
  topic: string;
}

export interface CmpIcmaPublishEnvelope {
  envelopeId: string;
  projectId: string;
  sourceAgentId: string;
  direction: CmpNeighborhoodDirection;
  targetAgentIds: string[];
  granularityLabel: string;
  payloadRef: string;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface CmpSubscriptionRequest {
  requestId: string;
  projectId: string;
  publisherAgentId: string;
  subscriberAgentId: string;
  relation: CmpSubscriptionRelation;
  channel: CmpMqChannelKind;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface CmpCriticalEscalationEnvelope {
  escalationId: string;
  projectId: string;
  sourceAgentId: string;
  targetAncestorId: string;
  severity: CmpCriticalEscalationSeverity;
  reason: string;
  evidenceRef: string;
  createdAt: string;
  deliveryMode: "alert_envelope";
  redactionLevel: "summary_only";
  metadata?: Record<string, unknown>;
}

export function assertNonEmptyString(value: string, label: string): string {
  const normalized = value.trim();
  if (!normalized) {
    throw new Error(`${label} requires a non-empty string.`);
  }
  return normalized;
}

export function validateCmpAgentNeighborhood(
  neighborhood: CmpAgentNeighborhood,
): void {
  assertNonEmptyString(neighborhood.agentId, "CMP neighborhood agentId");
  for (const peerId of neighborhood.peerAgentIds) {
    assertNonEmptyString(peerId, "CMP neighborhood peerAgentId");
    if (peerId === neighborhood.agentId) {
      throw new Error("CMP neighborhood peer list cannot contain self.");
    }
  }
  for (const childId of neighborhood.childAgentIds) {
    assertNonEmptyString(childId, "CMP neighborhood childAgentId");
    if (childId === neighborhood.agentId) {
      throw new Error("CMP neighborhood child list cannot contain self.");
    }
  }
}

export function validateCmpMqTopicDescriptor(descriptor: CmpMqTopicDescriptor): void {
  assertNonEmptyString(descriptor.projectId, "CMP MQ topic projectId");
  assertNonEmptyString(descriptor.agentId, "CMP MQ topic agentId");
  assertNonEmptyString(descriptor.topic, "CMP MQ topic");
}

export function validateCmpIcmaPublishEnvelope(
  envelope: CmpIcmaPublishEnvelope,
): void {
  assertNonEmptyString(envelope.envelopeId, "CMP ICMA publish envelopeId");
  assertNonEmptyString(envelope.projectId, "CMP ICMA publish projectId");
  assertNonEmptyString(envelope.sourceAgentId, "CMP ICMA publish sourceAgentId");
  assertNonEmptyString(envelope.granularityLabel, "CMP ICMA publish granularityLabel");
  assertNonEmptyString(envelope.payloadRef, "CMP ICMA publish payloadRef");
  assertNonEmptyString(envelope.createdAt, "CMP ICMA publish createdAt");
  if (envelope.targetAgentIds.length === 0) {
    throw new Error("CMP ICMA publish requires at least one target agent.");
  }
}

export function isCmpSubscriptionRelation(value: string): value is CmpSubscriptionRelation {
  return CMP_SUBSCRIPTION_RELATIONS.includes(value as CmpSubscriptionRelation);
}

export function isCmpCriticalEscalationSeverity(
  value: string,
): value is CmpCriticalEscalationSeverity {
  return CMP_CRITICAL_ESCALATION_SEVERITIES.includes(value as CmpCriticalEscalationSeverity);
}

export function validateCmpSubscriptionRequest(
  request: CmpSubscriptionRequest,
): void {
  assertNonEmptyString(request.requestId, "CMP subscription requestId");
  assertNonEmptyString(request.projectId, "CMP subscription projectId");
  assertNonEmptyString(request.publisherAgentId, "CMP subscription publisherAgentId");
  assertNonEmptyString(request.subscriberAgentId, "CMP subscription subscriberAgentId");
  assertNonEmptyString(request.createdAt, "CMP subscription createdAt");
  if (request.publisherAgentId === request.subscriberAgentId) {
    throw new Error("CMP subscription request cannot target the publisher itself.");
  }
  if (!isCmpSubscriptionRelation(request.relation)) {
    throw new Error(`Unsupported CMP subscription relation: ${request.relation}.`);
  }
}

export function validateCmpCriticalEscalationEnvelope(
  envelope: CmpCriticalEscalationEnvelope,
): void {
  assertNonEmptyString(envelope.escalationId, "CMP critical escalation escalationId");
  assertNonEmptyString(envelope.projectId, "CMP critical escalation projectId");
  assertNonEmptyString(envelope.sourceAgentId, "CMP critical escalation sourceAgentId");
  assertNonEmptyString(envelope.targetAncestorId, "CMP critical escalation targetAncestorId");
  assertNonEmptyString(envelope.reason, "CMP critical escalation reason");
  assertNonEmptyString(envelope.evidenceRef, "CMP critical escalation evidenceRef");
  assertNonEmptyString(envelope.createdAt, "CMP critical escalation createdAt");
  if (envelope.sourceAgentId === envelope.targetAncestorId) {
    throw new Error("CMP critical escalation targetAncestorId cannot equal sourceAgentId.");
  }
  if (!isCmpCriticalEscalationSeverity(envelope.severity)) {
    throw new Error(`Unsupported CMP critical escalation severity: ${envelope.severity}.`);
  }
  if (envelope.deliveryMode !== "alert_envelope") {
    throw new Error("CMP critical escalation must use alert_envelope delivery mode.");
  }
  if (envelope.redactionLevel !== "summary_only") {
    throw new Error("CMP critical escalation must use summary_only redaction.");
  }
}
