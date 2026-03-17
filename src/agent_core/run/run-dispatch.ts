import { randomUUID } from "node:crypto";

import type {
  IntentQueuedEvent,
  KernelEvent,
  StateDeltaAppliedEvent
} from "../types/kernel-events.js";
import type { KernelIntent } from "../types/kernel-intents.js";
import type { RunRecord } from "../types/kernel-run.js";
import type { StepTransitionDecision } from "../types/kernel-transition.js";
import type { RunCoordinatorClock } from "./run-types.js";

export function createStateDeltaAppliedEvent(
  run: RunRecord,
  decision: StepTransitionDecision,
  incomingEvent: KernelEvent,
  clock: RunCoordinatorClock,
  eventIdFactory: () => string
): StateDeltaAppliedEvent | undefined {
  if (!decision.stateDelta) {
    return undefined;
  }

  return {
    eventId: eventIdFactory(),
    type: "state.delta_applied",
    sessionId: run.sessionId,
    runId: run.runId,
    createdAt: clock.now().toISOString(),
    correlationId: incomingEvent.correlationId ?? incomingEvent.eventId,
    causationId: incomingEvent.eventId,
    payload: {
      delta: decision.stateDelta,
      previousStatus: decision.fromStatus,
      nextStatus: decision.toStatus
    }
  };
}

export function createIntentQueuedEvent(
  run: RunRecord,
  intent: KernelIntent,
  clock: RunCoordinatorClock,
  eventIdFactory: () => string
): IntentQueuedEvent {
  return {
    eventId: eventIdFactory(),
    type: "intent.queued",
    sessionId: run.sessionId,
    runId: run.runId,
    createdAt: clock.now().toISOString(),
    correlationId: intent.correlationId ?? intent.intentId,
    payload: {
      intentId: intent.intentId,
      kind: intent.kind,
      priority: intent.priority
    }
  };
}

export function defaultIdFactory(): string {
  return randomUUID();
}
