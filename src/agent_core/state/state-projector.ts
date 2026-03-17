import type {
  AgentState,
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
} from "../types/index.js";
import { applyStateDelta } from "./state-delta.js";
import { createInitialAgentState } from "./state-types.js";

function applyRunCreatedEvent(
  state: AgentState,
  _event: RunCreatedEvent
): AgentState {
  return {
    ...state,
    control: {
      ...state.control,
      status: "created",
      phase: "decision",
      retryCount: 0
    }
  };
}

function applyRunResumedEvent(
  state: AgentState,
  event: RunResumedEvent
): AgentState {
  return {
    ...state,
    control: {
      ...state.control,
      status: "deciding",
      phase: "recovery"
    },
    recovery: {
      ...state.recovery,
      lastCheckpointRef:
        event.payload.checkpointId ?? state.recovery.lastCheckpointRef,
      resumePointer: event.eventId
    }
  };
}

function applyRunPausedEvent(
  state: AgentState,
  event: RunPausedEvent
): AgentState {
  return {
    ...state,
    control: {
      ...state.control,
      status: "paused"
    },
    recovery: {
      ...state.recovery,
      lastErrorMessage: event.payload.reason
    }
  };
}

function applyRunCompletedEvent(
  state: AgentState,
  event: RunCompletedEvent
): AgentState {
  return {
    ...state,
    control: {
      ...state.control,
      status: "completed",
      pendingIntentId: undefined
    },
    observed: {
      ...state.observed,
      lastResultId: event.payload.resultId ?? state.observed.lastResultId
    }
  };
}

function applyRunFailedEvent(
  state: AgentState,
  event: RunFailedEvent
): AgentState {
  return {
    ...state,
    control: {
      ...state.control,
      status: "failed",
      pendingIntentId: undefined
    },
    recovery: {
      ...state.recovery,
      lastErrorCode: event.payload.code,
      lastErrorMessage: event.payload.message
    }
  };
}

function applyIntentQueuedEvent(
  state: AgentState,
  event: IntentQueuedEvent
): AgentState {
  return {
    ...state,
    control: {
      ...state.control,
      pendingIntentId: event.payload.intentId
    }
  };
}

function applyIntentDispatchedEvent(
  state: AgentState,
  event: IntentDispatchedEvent
): AgentState {
  return {
    ...state,
    control: {
      ...state.control,
      pendingIntentId: event.payload.intentId,
      phase: "execution"
    }
  };
}

function applyCapabilityResultReceivedEvent(
  state: AgentState,
  event: CapabilityResultReceivedEvent
): AgentState {
  return {
    ...state,
    control: {
      ...state.control,
      pendingIntentId: undefined,
      phase: "commit"
    },
    observed: {
      ...state.observed,
      lastResultId: event.payload.resultId,
      lastResultStatus: event.payload.status
    }
  };
}

function applyCheckpointCreatedEvent(
  state: AgentState,
  event: CheckpointCreatedEvent
): AgentState {
  return {
    ...state,
    recovery: {
      ...state.recovery,
      lastCheckpointRef: event.payload.checkpointId,
      resumePointer: event.eventId
    }
  };
}

export function applyEventToState(
  state: AgentState,
  event: KernelEvent
): AgentState {
  switch (event.type) {
    case "run.created":
      return applyRunCreatedEvent(state, event);
    case "run.resumed":
      return applyRunResumedEvent(state, event);
    case "run.paused":
      return applyRunPausedEvent(state, event);
    case "run.completed":
      return applyRunCompletedEvent(state, event);
    case "run.failed":
      return applyRunFailedEvent(state, event);
    case "state.delta_applied":
      return applyStateDelta(state, (event as StateDeltaAppliedEvent).payload.delta);
    case "intent.queued":
      return applyIntentQueuedEvent(state, event);
    case "intent.dispatched":
      return applyIntentDispatchedEvent(state, event);
    case "capability.result_received":
      return applyCapabilityResultReceivedEvent(state, event);
    case "checkpoint.created":
      return applyCheckpointCreatedEvent(state, event as CheckpointCreatedEvent);
  }
}

export function projectStateFromEvents(
  events: readonly KernelEvent[],
  initialState: AgentState = createInitialAgentState()
): AgentState {
  return events.reduce((state, event) => applyEventToState(state, event), initialState);
}
