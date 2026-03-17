import type {
  CapabilityResultReceivedEvent,
  CheckpointCreatedEvent,
  IntentDispatchedEvent,
  IntentQueuedEvent,
  KernelEvent,
  RunCompletedEvent,
  RunCreatedEvent,
  RunFailedEvent,
  RunPausedEvent,
  RunResumedEvent,
  StateDeltaAppliedEvent
} from "../types/kernel-events.js";
import type { AgentStatus } from "../types/kernel-state.js";
import type { TransitionRule, TransitionEvaluationContext } from "./transition-types.js";
import { resolveNextAction } from "./transition-guards.js";

function hasStatus(
  currentStatus: AgentStatus,
  allowed: readonly AgentStatus[]
): boolean {
  return allowed.includes(currentStatus);
}

const defaultRules: TransitionRule[] = [
  {
    name: "run.created",
    path: "hot",
    eventTypes: ["run.created"],
    matches({ currentState, incomingEvent }) {
      return incomingEvent.type === "run.created" && hasStatus(currentState.control.status, ["created", "idle"]);
    },
    decide({ currentState, incomingEvent, goalFrame }) {
      const event = incomingEvent as RunCreatedEvent;
      return {
        fromStatus: currentState.control.status,
        toStatus: "acting",
        nextPhase: "execution",
        reason: `Run ${event.runId} created and entering first execution step.`,
        stateDelta: {
          control: {
            status: "acting",
            phase: "execution"
          }
        },
        nextAction: resolveNextAction({
          state: currentState,
          event,
          goalFrame
        }),
        eventId: event.eventId
      };
    }
  },
  {
    name: "run.resumed",
    path: "hot",
    eventTypes: ["run.resumed"],
    matches({ currentState, incomingEvent }) {
      return incomingEvent.type === "run.resumed" && hasStatus(currentState.control.status, ["paused", "waiting", "failed"]);
    },
    decide({ currentState, incomingEvent }) {
      const event = incomingEvent as RunResumedEvent;
      return {
        fromStatus: currentState.control.status,
        toStatus: "acting",
        nextPhase: "recovery",
        reason: event.payload.checkpointId
          ? `Run ${event.runId} resumed from checkpoint ${event.payload.checkpointId}.`
          : `Run ${event.runId} resumed without a specific checkpoint pointer.`,
        stateDelta: {
          control: {
            status: "acting",
            phase: "recovery"
          },
          recovery: {
            lastCheckpointRef: event.payload.checkpointId
          }
        },
        nextAction: {
          kind: "internal_step",
          intent: {
            intentId: `${event.eventId}:resume`,
            sessionId: event.sessionId,
            runId: event.runId,
            kind: "internal_step",
            createdAt: event.createdAt,
            priority: "high",
            correlationId: event.correlationId ?? event.eventId,
            instruction: event.payload.checkpointId
              ? `Resume run from checkpoint ${event.payload.checkpointId} and re-enter the kernel loop.`
              : "Resume run and re-enter the kernel loop."
          },
          metadata: {
            path: "resume-recovery"
          }
        },
        eventId: event.eventId
      };
    }
  },
  {
    name: "state.delta_applied",
    path: "hot",
    eventTypes: ["state.delta_applied"],
    matches({ currentState, incomingEvent }) {
      return incomingEvent.type === "state.delta_applied" && hasStatus(currentState.control.status, ["deciding", "acting"]);
    },
    decide({ currentState, incomingEvent, goalFrame }) {
      const event = incomingEvent as StateDeltaAppliedEvent;
      return {
        fromStatus: currentState.control.status,
        toStatus: "acting",
        nextPhase: "execution",
        reason: "State delta applied; evaluate next executable action.",
        stateDelta: {
          control: {
            status: "acting",
            phase: "execution"
          }
        },
        nextAction: resolveNextAction({
          state: currentState,
          event,
          goalFrame
        }),
        eventId: event.eventId
      };
    }
  },
  {
    name: "intent.queued",
    path: "hot",
    eventTypes: ["intent.queued"],
    matches({ currentState, incomingEvent }) {
      return incomingEvent.type === "intent.queued" && hasStatus(currentState.control.status, ["acting", "deciding"]);
    },
    decide({ currentState, incomingEvent }) {
      const event = incomingEvent as IntentQueuedEvent;
      return {
        fromStatus: currentState.control.status,
        toStatus: "waiting",
        nextPhase: "execution",
        reason: `Intent ${event.payload.intentId} queued for asynchronous execution.`,
        stateDelta: {
          control: {
            status: "waiting",
            phase: "execution",
            pendingIntentId: event.payload.intentId
          }
        },
        nextAction: {
          kind: "wait",
          metadata: {
            pendingIntentId: event.payload.intentId
          }
        },
        eventId: event.eventId
      };
    }
  },
  {
    name: "intent.dispatched",
    path: "hot",
    eventTypes: ["intent.dispatched"],
    matches({ currentState, incomingEvent }) {
      return incomingEvent.type === "intent.dispatched" && hasStatus(currentState.control.status, ["waiting"]);
    },
    decide({ currentState, incomingEvent }) {
      const event = incomingEvent as IntentDispatchedEvent;
      return {
        fromStatus: currentState.control.status,
        toStatus: "waiting",
        nextPhase: "execution",
        reason: `Intent ${event.payload.intentId} dispatched to ${event.payload.dispatchTarget}; run remains waiting.`,
        nextAction: {
          kind: "wait",
          metadata: {
            dispatchTarget: event.payload.dispatchTarget
          }
        },
        eventId: event.eventId
      };
    }
  },
  {
    name: "capability.result_received",
    path: "hot",
    eventTypes: ["capability.result_received"],
    matches({ currentState, incomingEvent }) {
      return incomingEvent.type === "capability.result_received" && hasStatus(currentState.control.status, ["waiting", "acting"]);
    },
    decide({ currentState, incomingEvent, goalFrame }) {
      const event = incomingEvent as CapabilityResultReceivedEvent;
      const isFinalModelResult = event.metadata?.resultSource === "model" && event.metadata?.final === true;
      if (isFinalModelResult) {
        return {
          fromStatus: currentState.control.status,
          toStatus: "completed",
          nextPhase: "commit",
          reason: `Model result ${event.payload.resultId} completed the run.`,
          stateDelta: {
            control: {
              status: "completed",
              phase: "commit",
              pendingIntentId: undefined
            },
            observed: {
              lastResultId: event.payload.resultId,
              lastResultStatus: event.payload.status
            }
          },
          nextAction: {
            kind: "complete",
            metadata: {
              resultId: event.payload.resultId,
              source: "model"
            }
          },
          eventId: event.eventId
        };
      }
      return {
        fromStatus: currentState.control.status,
        toStatus: "deciding",
        nextPhase: "decision",
        reason: `Capability result ${event.payload.resultId} received; return to decision phase.`,
        stateDelta: {
          control: {
            status: "deciding",
            phase: "decision",
            pendingIntentId: undefined
          },
          observed: {
            lastResultId: event.payload.resultId,
            lastResultStatus: event.payload.status
          }
        },
        nextAction: resolveNextAction({
          state: currentState,
          event,
          goalFrame
        }),
        eventId: event.eventId
      };
    }
  },
  {
    name: "run.paused",
    path: "rare",
    eventTypes: ["run.paused"],
    matches({ currentState, incomingEvent }) {
      return incomingEvent.type === "run.paused" && hasStatus(currentState.control.status, ["waiting", "acting", "deciding"]);
    },
    decide({ currentState, incomingEvent }) {
      const event = incomingEvent as RunPausedEvent;
      return {
        fromStatus: currentState.control.status,
        toStatus: "paused",
        nextPhase: "recovery",
        reason: event.payload.reason,
        stateDelta: {
          control: {
            status: "paused",
            phase: "recovery"
          }
        },
        nextAction: {
          kind: "pause",
          metadata: {
            pauseReason: event.payload.reason
          }
        },
        eventId: event.eventId
      };
    }
  },
  {
    name: "run.failed",
    path: "rare",
    eventTypes: ["run.failed"],
    matches({ currentState, incomingEvent }) {
      return incomingEvent.type === "run.failed" && !hasStatus(currentState.control.status, ["completed", "cancelled"]);
    },
    decide({ currentState, incomingEvent }) {
      const event = incomingEvent as RunFailedEvent;
      return {
        fromStatus: currentState.control.status,
        toStatus: "failed",
        nextPhase: "recovery",
        reason: event.payload.message,
        stateDelta: {
          control: {
            status: "failed",
            phase: "recovery"
          },
          recovery: {
            lastErrorCode: event.payload.code,
            lastErrorMessage: event.payload.message
          }
        },
        nextAction: {
          kind: "fail",
          metadata: {
            code: event.payload.code
          }
        },
        eventId: event.eventId
      };
    }
  },
  {
    name: "run.completed",
    path: "rare",
    eventTypes: ["run.completed"],
    matches({ currentState, incomingEvent }) {
      return incomingEvent.type === "run.completed" && !hasStatus(currentState.control.status, ["failed", "cancelled"]);
    },
    decide({ currentState, incomingEvent }) {
      const event = incomingEvent as RunCompletedEvent;
      return {
        fromStatus: currentState.control.status,
        toStatus: "completed",
        nextPhase: "commit",
        reason: `Run ${event.runId} completed.`,
        stateDelta: {
          control: {
            status: "completed",
            phase: "commit"
          },
          observed: {
            lastResultId: event.payload.resultId
          }
        },
        nextAction: {
          kind: "complete",
          metadata: {
            resultId: event.payload.resultId
          }
        },
        eventId: event.eventId
      };
    }
  },
  {
    name: "checkpoint.created",
    path: "rare",
    eventTypes: ["checkpoint.created"],
    matches({ currentState, incomingEvent }) {
      return incomingEvent.type === "checkpoint.created" && !hasStatus(currentState.control.status, ["cancelled"]);
    },
    decide({ currentState, incomingEvent }) {
      const event = incomingEvent as CheckpointCreatedEvent;
      return {
        fromStatus: currentState.control.status,
        toStatus: currentState.control.status,
        nextPhase: currentState.control.phase,
        reason: `Checkpoint ${event.payload.checkpointId} recorded at tier ${event.payload.tier}.`,
        stateDelta: {
          recovery: {
            lastCheckpointRef: event.payload.checkpointId
          }
        },
        nextAction: {
          kind: "checkpoint",
          metadata: {
            checkpointId: event.payload.checkpointId,
            tier: event.payload.tier
          }
        },
        eventId: event.eventId
      };
    }
  }
];

const registry = [...defaultRules];

export function registerTransitionRule(rule: TransitionRule): void {
  registry.push(rule);
}

export function listTransitionRules(): readonly TransitionRule[] {
  return registry;
}

export function matchTransitionRule(
  context: TransitionEvaluationContext
): TransitionRule | undefined {
  return registry.find((rule) => rule.matches(context));
}

export function resetTransitionRules(): void {
  registry.splice(0, registry.length, ...defaultRules);
}
