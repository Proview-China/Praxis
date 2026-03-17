import type { EventJournalLike } from "../journal/journal-types.js";
import type { CapabilityCallIntent, CapabilityPortRequest, IntentPriority } from "../types/kernel-intents.js";
import type { CapabilityPortResponse, KernelResult } from "../types/kernel-results.js";
import type { SessionId, RunId } from "../types/kernel-session.js";

export type CapabilityPortHandler = (
  request: CapabilityPortRequest
) => Promise<CapabilityPortHandlerResult>;

export interface CapabilityPortHandlerResult {
  output?: unknown;
  result?: KernelResult;
  artifacts?: CapabilityPortResponse["artifacts"];
  evidence?: CapabilityPortResponse["evidence"];
  error?: CapabilityPortResponse["error"];
  metadata?: Record<string, unknown>;
}

export interface CapabilityPortDefinition {
  capabilityKey: string;
  handler: CapabilityPortHandler;
  concurrency?: number;
  timeoutMs?: number;
  metadata?: Record<string, unknown>;
}

export interface PortQueueItem {
  intent: CapabilityCallIntent;
  request: CapabilityPortRequest;
  enqueuedAt: string;
}

export interface PortInflightItem extends PortQueueItem {
  dispatchedAt: string;
}

export interface BackpressureState {
  active: boolean;
  queueDepth: number;
  inflight: number;
  reason?: "queue-threshold" | "inflight-threshold";
}

export interface BackpressureSignal extends BackpressureState {
  emittedAt: string;
}

export interface CapabilityPortBrokerOptions {
  journal?: EventJournalLike;
  maxQueueDepth?: number;
  maxInflight?: number;
  clock?: () => Date;
}

export interface CapabilityDispatchReceipt {
  response: CapabilityPortResponse;
  fromCache: boolean;
}

export interface CapabilityPortStats {
  queued: number;
  inflight: number;
  handlers: number;
  cachedResponses: number;
  preparedInvocationEntries: number;
}

export interface EnqueueCapabilityIntentInput {
  intent: CapabilityCallIntent;
}

export interface CapabilityResultCallbackPayload {
  intent: CapabilityCallIntent;
  request: CapabilityPortRequest;
  response: CapabilityPortResponse;
  fromCache: boolean;
}

export type CapabilityResultCallback = (
  payload: CapabilityResultCallbackPayload
) => void;

export interface CapabilityPreparedInvocationEntry {
  cacheKey: string;
  capabilityKey: string;
  sessionId: SessionId;
  runId: RunId;
  value: unknown;
  createdAt: string;
}

export const INTENT_PRIORITY_ORDER: Record<IntentPriority, number> = {
  critical: 0,
  high: 1,
  normal: 2,
  low: 3,
};
