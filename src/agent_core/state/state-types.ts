import type {
  AgentControlState,
  AgentObservedState,
  AgentRecoveryState,
  AgentState,
  AgentStateDelta,
  AgentStatus,
  StateRecord,
  StateValue
} from "../types/index.js";

export type {
  AgentControlState,
  AgentObservedState,
  AgentRecoveryState,
  AgentState,
  AgentStateDelta,
  AgentStatus,
  StateRecord,
  StateValue
};

export const FORBIDDEN_STATE_TOP_LEVEL_KEYS = [
  "history",
  "messages",
  "events",
  "journal",
  "transcript",
  "sdkClient",
  "providerClient"
] as const;

export type ForbiddenStateTopLevelKey =
  (typeof FORBIDDEN_STATE_TOP_LEVEL_KEYS)[number];

export const DEFAULT_AGENT_STATUS: AgentStatus = "created";

export function createInitialControlState(): AgentControlState {
  return {
    status: "created",
    phase: "decision",
    retryCount: 0
  };
}

export function createInitialObservedState(): AgentObservedState {
  return {
    artifactRefs: []
  };
}

export function createInitialRecoveryState(): AgentRecoveryState {
  return {};
}

export function createInitialAgentState(): AgentState {
  return {
    control: createInitialControlState(),
    working: {},
    observed: createInitialObservedState(),
    recovery: createInitialRecoveryState()
  };
}
