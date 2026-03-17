import type { GoalId } from "./kernel-goal.js";
import type { KernelIntentKind } from "./kernel-intents.js";
import type { CheckpointTier } from "./kernel-checkpoint.js";
import type { KernelResultStatus } from "./kernel-results.js";
import type { AgentStateDelta, AgentStatus } from "./kernel-state.js";
import type { RunId, SessionId } from "./kernel-session.js";

export const KERNEL_EVENT_TYPES = [
  "run.created",
  "run.resumed",
  "run.paused",
  "run.completed",
  "run.failed",
  "state.delta_applied",
  "intent.queued",
  "intent.dispatched",
  "capability.result_received",
  "checkpoint.created"
] as const;
export type KernelEventType = (typeof KERNEL_EVENT_TYPES)[number];

export interface KernelEventBase<
  TType extends KernelEventType,
  TPayload extends Record<string, unknown>
> {
  eventId: string;
  type: TType;
  sessionId: SessionId;
  runId: RunId;
  createdAt: string;
  correlationId?: string;
  causationId?: string;
  payload: TPayload;
  metadata?: Record<string, unknown>;
}

export type RunCreatedEvent = KernelEventBase<"run.created", {
  goalId: GoalId;
}>;

export type RunResumedEvent = KernelEventBase<"run.resumed", {
  checkpointId?: string;
}>;

export type RunPausedEvent = KernelEventBase<"run.paused", {
  reason: string;
}>;

export type RunCompletedEvent = KernelEventBase<"run.completed", {
  resultId?: string;
}>;

export type RunFailedEvent = KernelEventBase<"run.failed", {
  code: string;
  message: string;
}>;

export type StateDeltaAppliedEvent = KernelEventBase<"state.delta_applied", {
  delta: AgentStateDelta;
  previousStatus?: AgentStatus;
  nextStatus?: AgentStatus;
}>;

export type IntentQueuedEvent = KernelEventBase<"intent.queued", {
  intentId: string;
  kind: KernelIntentKind;
  priority: string;
}>;

export type IntentDispatchedEvent = KernelEventBase<"intent.dispatched", {
  intentId: string;
  dispatchTarget: string;
}>;

export type CapabilityResultReceivedEvent = KernelEventBase<"capability.result_received", {
  requestId: string;
  resultId: string;
  status: KernelResultStatus;
}>;

export type CheckpointCreatedEvent = KernelEventBase<"checkpoint.created", {
  checkpointId: string;
  tier: CheckpointTier;
}>;

export type KernelEvent =
  | RunCreatedEvent
  | RunResumedEvent
  | RunPausedEvent
  | RunCompletedEvent
  | RunFailedEvent
  | StateDeltaAppliedEvent
  | IntentQueuedEvent
  | IntentDispatchedEvent
  | CapabilityResultReceivedEvent
  | CheckpointCreatedEvent;
