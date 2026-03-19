import type {
  AccessRequest,
  PlainLanguageRiskPayload,
  ReviewDecision,
} from "../ta-pool-types/index.js";

export const TA_HUMAN_GATE_STATUSES = [
  "waiting_human",
  "approved",
  "rejected",
] as const;
export type TaHumanGateStatus = (typeof TA_HUMAN_GATE_STATUSES)[number];

export const TA_HUMAN_GATE_EVENT_TYPES = [
  "human_gate.requested",
  "human_gate.approved",
  "human_gate.rejected",
] as const;
export type TaHumanGateEventType = (typeof TA_HUMAN_GATE_EVENT_TYPES)[number];

export interface TaHumanGateState {
  gateId: string;
  requestId: string;
  sessionId: string;
  runId: string;
  capabilityKey: string;
  requestedTier: AccessRequest["requestedTier"];
  mode: AccessRequest["mode"];
  status: TaHumanGateStatus;
  reason: string;
  plainLanguageRisk: PlainLanguageRiskPayload;
  escalationTarget?: string;
  sourceDecisionId?: string;
  createdAt: string;
  updatedAt: string;
  metadata?: Record<string, unknown>;
}

export interface CreateTaHumanGateStateInput {
  gateId: string;
  request: AccessRequest;
  plainLanguageRisk: PlainLanguageRiskPayload;
  reason: string;
  createdAt: string;
  escalationTarget?: string;
  sourceDecisionId?: string;
  metadata?: Record<string, unknown>;
}

export interface TaHumanGateEvent {
  eventId: string;
  gateId: string;
  requestId: string;
  type: TaHumanGateEventType;
  createdAt: string;
  actorId?: string;
  note?: string;
  metadata?: Record<string, unknown>;
}

export interface CreateTaHumanGateEventInput {
  eventId: string;
  gateId: string;
  requestId: string;
  type: TaHumanGateEventType;
  createdAt: string;
  actorId?: string;
  note?: string;
  metadata?: Record<string, unknown>;
}

function assertNonEmpty(value: string, label: string): string {
  const normalized = value.trim();
  if (!normalized) {
    throw new Error(`${label} requires a non-empty string.`);
  }
  return normalized;
}

export function createTaHumanGateState(
  input: CreateTaHumanGateStateInput,
): TaHumanGateState {
  return {
    gateId: assertNonEmpty(input.gateId, "Human gate gateId"),
    requestId: input.request.requestId,
    sessionId: input.request.sessionId,
    runId: input.request.runId,
    capabilityKey: input.request.requestedCapabilityKey,
    requestedTier: input.request.requestedTier,
    mode: input.request.mode,
    status: "waiting_human",
    reason: assertNonEmpty(input.reason, "Human gate reason"),
    plainLanguageRisk: input.plainLanguageRisk,
    escalationTarget: input.escalationTarget?.trim() || undefined,
    sourceDecisionId: input.sourceDecisionId?.trim() || undefined,
    createdAt: input.createdAt,
    updatedAt: input.createdAt,
    metadata: input.metadata,
  };
}

export function createTaHumanGateEvent(
  input: CreateTaHumanGateEventInput,
): TaHumanGateEvent {
  return {
    eventId: assertNonEmpty(input.eventId, "Human gate eventId"),
    gateId: assertNonEmpty(input.gateId, "Human gate event gateId"),
    requestId: assertNonEmpty(input.requestId, "Human gate event requestId"),
    type: input.type,
    createdAt: input.createdAt,
    actorId: input.actorId?.trim() || undefined,
    note: input.note?.trim() || undefined,
    metadata: input.metadata,
  };
}

export function applyTaHumanGateEvent(params: {
  gate: TaHumanGateState;
  event: TaHumanGateEvent;
}): TaHumanGateState {
  if (params.gate.gateId !== params.event.gateId) {
    throw new Error(
      `Human gate event ${params.event.eventId} targets ${params.event.gateId}, expected ${params.gate.gateId}.`,
    );
  }

  switch (params.event.type) {
    case "human_gate.requested":
      return {
        ...params.gate,
        updatedAt: params.event.createdAt,
      };
    case "human_gate.approved":
      return {
        ...params.gate,
        status: "approved",
        updatedAt: params.event.createdAt,
      };
    case "human_gate.rejected":
      return {
        ...params.gate,
        status: "rejected",
        updatedAt: params.event.createdAt,
      };
  }
}

export function createTaHumanGateStateFromReviewDecision(params: {
  gateId: string;
  request: AccessRequest;
  reviewDecision: Pick<ReviewDecision, "decisionId" | "reason" | "escalationTarget">;
  plainLanguageRisk: PlainLanguageRiskPayload;
  createdAt: string;
  metadata?: Record<string, unknown>;
}): TaHumanGateState {
  return createTaHumanGateState({
    gateId: params.gateId,
    request: params.request,
    plainLanguageRisk: params.plainLanguageRisk,
    reason: params.reviewDecision.reason,
    createdAt: params.createdAt,
    escalationTarget: params.reviewDecision.escalationTarget,
    sourceDecisionId: params.reviewDecision.decisionId,
    metadata: params.metadata,
  });
}
