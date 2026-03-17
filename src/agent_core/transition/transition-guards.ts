import type { KernelEvent } from "../types/kernel-events.js";
import type { GoalFrameCompiled } from "../types/kernel-goal.js";
import {
  INTENT_PRIORITIES,
  type CapabilityCallIntent,
  type CapabilityPortRequest,
  type InternalStepIntent,
  type IntentPriority,
  type ModelInferenceIntent
} from "../types/kernel-intents.js";
import type { StateRecord, StateValue, AgentState } from "../types/kernel-state.js";
import type { StepTransitionAction, StepActionKind } from "../types/kernel-transition.js";

export const NEXT_CAPABILITY_KEY = "nextCapabilityKey";
export const NEXT_CAPABILITY_INPUT = "nextCapabilityInput";
export const NEXT_INTERNAL_INSTRUCTION = "nextInternalInstruction";
export const NEXT_INTENT_PRIORITY = "nextIntentPriority";
export const MODEL_STATE_SUMMARY = "modelStateSummary";

export function isTerminalStatus(status: AgentState["control"]["status"]): boolean {
  return status === "completed" || status === "failed" || status === "cancelled";
}

export function isHotPath(kind: StepActionKind): boolean {
  return (
    kind === "internal_step" ||
    kind === "model_inference" ||
    kind === "capability_call" ||
    kind === "wait"
  );
}

export function isRarePath(kind: StepActionKind): boolean {
  return kind === "pause" || kind === "complete" || kind === "fail" || kind === "cancel";
}

function getStateValue(record: StateRecord, key: string): StateValue | undefined {
  return Object.prototype.hasOwnProperty.call(record, key) ? record[key] : undefined;
}

function asString(value: StateValue | undefined): string | undefined {
  return typeof value === "string" ? value : undefined;
}

function asRecord(value: StateValue | undefined): Record<string, unknown> | undefined {
  if (value === null || value === undefined || Array.isArray(value) || typeof value !== "object") {
    return undefined;
  }
  return value as Record<string, unknown>;
}

function resolvePriority(state: AgentState): IntentPriority {
  const candidate = asString(getStateValue(state.working, NEXT_INTENT_PRIORITY));
  if (candidate && INTENT_PRIORITIES.includes(candidate as IntentPriority)) {
    return candidate as IntentPriority;
  }
  return "normal";
}

export function buildModelInferenceIntent(params: {
  state: AgentState;
  event: KernelEvent;
  goalFrame: GoalFrameCompiled;
}): ModelInferenceIntent {
  const { state, event, goalFrame } = params;
  return {
    intentId: `${event.eventId}:model`,
    sessionId: event.sessionId,
    runId: event.runId,
    kind: "model_inference",
    createdAt: event.createdAt,
    priority: resolvePriority(state),
    correlationId: event.correlationId ?? event.eventId,
    idempotencyKey: `model:${goalFrame.cacheKey}:${event.eventId}`,
    frame: goalFrame,
    stateSummary:
      asRecord(getStateValue(state.derived ?? {}, MODEL_STATE_SUMMARY))
      ?? asRecord(getStateValue(state.working, MODEL_STATE_SUMMARY))
  };
}

export function buildInternalStepIntent(params: {
  state: AgentState;
  event: KernelEvent;
  instruction: string;
}): InternalStepIntent {
  const { state, event, instruction } = params;
  return {
    intentId: `${event.eventId}:internal`,
    sessionId: event.sessionId,
    runId: event.runId,
    kind: "internal_step",
    createdAt: event.createdAt,
    priority: resolvePriority(state),
    correlationId: event.correlationId ?? event.eventId,
    instruction
  };
}

export function buildCapabilityCallIntent(params: {
  state: AgentState;
  event: KernelEvent;
  capabilityKey: string;
  input: Record<string, unknown>;
}): CapabilityCallIntent {
  const { state, event, capabilityKey, input } = params;
  const intentId = `${event.eventId}:capability`;
  const request: CapabilityPortRequest = {
    requestId: `${event.eventId}:request`,
    intentId,
    sessionId: event.sessionId,
    runId: event.runId,
    capabilityKey,
    input,
    priority: resolvePriority(state),
    idempotencyKey: `${capabilityKey}:${event.eventId}`
  };

  return {
    intentId,
    sessionId: event.sessionId,
    runId: event.runId,
    kind: "capability_call",
    createdAt: event.createdAt,
    priority: request.priority,
    correlationId: event.correlationId ?? event.eventId,
    idempotencyKey: request.idempotencyKey,
    request
  };
}

export function resolveNextAction(params: {
  state: AgentState;
  event: KernelEvent;
  goalFrame: GoalFrameCompiled;
}): StepTransitionAction {
  const { state, event, goalFrame } = params;

  const capabilityKey = asString(getStateValue(state.working, NEXT_CAPABILITY_KEY));
  const capabilityInput = asRecord(getStateValue(state.working, NEXT_CAPABILITY_INPUT));
  if (capabilityKey && capabilityInput) {
    return {
      kind: "capability_call",
      intent: buildCapabilityCallIntent({
        state,
        event,
        capabilityKey,
        input: capabilityInput
      }),
      metadata: {
        path: "state-driven-capability"
      }
    };
  }

  const internalInstruction = asString(getStateValue(state.working, NEXT_INTERNAL_INSTRUCTION));
  if (internalInstruction) {
    return {
      kind: "internal_step",
      intent: buildInternalStepIntent({
        state,
        event,
        instruction: internalInstruction
      }),
      metadata: {
        path: "state-driven-internal"
      }
    };
  }

  return {
    kind: "model_inference",
    intent: buildModelInferenceIntent({
      state,
      event,
      goalFrame
    }),
    metadata: {
      path: "default-model-inference"
    }
  };
}
