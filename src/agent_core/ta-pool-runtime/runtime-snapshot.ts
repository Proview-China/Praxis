import type {
  AccessRequest,
  ReviewDecision,
  TaCapabilityTier,
  TaPoolMode,
} from "../ta-pool-types/index.js";
import type { TaHumanGateEvent, TaHumanGateState } from "./human-gate.js";
import type { TaActivationAttemptRecord } from "./activation-types.js";
import type { TaPendingReplay } from "./replay-policy.js";

export interface TaResumeEnvelope {
  envelopeId: string;
  source: "human_gate" | "replay" | "activation";
  requestId: string;
  sessionId: string;
  runId: string;
  capabilityKey: string;
  requestedTier: TaCapabilityTier;
  mode: TaPoolMode;
  reason: string;
  requestedScope?: AccessRequest["requestedScope"];
  reviewDecisionId?: ReviewDecision["decisionId"];
  intentRequest?: {
    requestId: string;
    intentId: string;
    capabilityKey: string;
    input: Record<string, unknown>;
    priority?: string;
    timeoutMs?: number;
    metadata?: Record<string, unknown>;
  };
  metadata?: Record<string, unknown>;
}

export interface CreateTaResumeEnvelopeInput {
  envelopeId: string;
  source: TaResumeEnvelope["source"];
  requestId: string;
  sessionId: string;
  runId: string;
  capabilityKey: string;
  requestedTier: TaCapabilityTier;
  mode: TaPoolMode;
  reason: string;
  requestedScope?: AccessRequest["requestedScope"];
  reviewDecisionId?: ReviewDecision["decisionId"];
  intentRequest?: TaResumeEnvelope["intentRequest"];
  metadata?: Record<string, unknown>;
}

export interface TapPoolRuntimeSnapshot {
  humanGates: TaHumanGateState[];
  humanGateEvents: TaHumanGateEvent[];
  pendingReplays: TaPendingReplay[];
  activationAttempts: TaActivationAttemptRecord[];
  resumeEnvelopes: TaResumeEnvelope[];
  metadata?: Record<string, unknown>;
}

export interface PoolRuntimeSnapshots {
  tap?: TapPoolRuntimeSnapshot;
  metadata?: Record<string, unknown>;
}

export interface TapPoolRuntimeSnapshotInput {
  humanGates?: readonly TaHumanGateState[];
  humanGateEvents?: readonly TaHumanGateEvent[];
  pendingReplays?: readonly TaPendingReplay[];
  activationAttempts?: readonly TaActivationAttemptRecord[];
  resumeEnvelopes?: readonly TaResumeEnvelope[];
  metadata?: Record<string, unknown>;
}

function assertNonEmpty(value: string, label: string): string {
  const normalized = value.trim();
  if (!normalized) {
    throw new Error(`${label} requires a non-empty string.`);
  }
  return normalized;
}

export function createTaResumeEnvelope(
  input: CreateTaResumeEnvelopeInput,
): TaResumeEnvelope {
  return {
    envelopeId: assertNonEmpty(input.envelopeId, "Resume envelope envelopeId"),
    source: input.source,
    requestId: assertNonEmpty(input.requestId, "Resume envelope requestId"),
    sessionId: assertNonEmpty(input.sessionId, "Resume envelope sessionId"),
    runId: assertNonEmpty(input.runId, "Resume envelope runId"),
    capabilityKey: assertNonEmpty(input.capabilityKey, "Resume envelope capabilityKey"),
    requestedTier: input.requestedTier,
    mode: input.mode,
    reason: assertNonEmpty(input.reason, "Resume envelope reason"),
    requestedScope: input.requestedScope,
    reviewDecisionId: input.reviewDecisionId?.trim() || undefined,
    intentRequest: input.intentRequest,
    metadata: input.metadata,
  };
}

export function createTapPoolRuntimeSnapshot(
  input: TapPoolRuntimeSnapshotInput = {},
): TapPoolRuntimeSnapshot {
  return {
    humanGates: [...(input.humanGates ?? [])],
    humanGateEvents: [...(input.humanGateEvents ?? [])],
    pendingReplays: [...(input.pendingReplays ?? [])],
    activationAttempts: [...(input.activationAttempts ?? [])],
    resumeEnvelopes: [...(input.resumeEnvelopes ?? [])],
    metadata: input.metadata,
  };
}

export function createPoolRuntimeSnapshots(
  input: Partial<PoolRuntimeSnapshots> = {},
): PoolRuntimeSnapshots {
  return {
    tap: input.tap ? createTapPoolRuntimeSnapshot(input.tap) : undefined,
    metadata: input.metadata,
  };
}
