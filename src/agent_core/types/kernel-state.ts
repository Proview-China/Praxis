import type { CheckpointId } from "./kernel-session.js";

export type StateScalar = string | number | boolean | null;
export type StateValue =
  | StateScalar
  | { [key: string]: StateValue }
  | StateValue[];

export type StateRecord = Record<string, StateValue>;

export const AGENT_STATUSES = [
  "created",
  "idle",
  "deciding",
  "acting",
  "waiting",
  "paused",
  "completed",
  "failed",
  "cancelled"
] as const;
export type AgentStatus = (typeof AGENT_STATUSES)[number];

export const AGENT_PHASES = [
  "decision",
  "execution",
  "commit",
  "recovery"
] as const;
export type AgentPhase = (typeof AGENT_PHASES)[number];

export interface AgentControlState {
  status: AgentStatus;
  phase: AgentPhase;
  retryCount: number;
  pendingIntentId?: string;
  pendingCheckpointReason?: string;
}

export interface AgentObservedState {
  lastObservationRef?: string;
  lastResultId?: string;
  lastResultStatus?: string;
  artifactRefs: string[];
}

export interface AgentRecoveryState {
  lastCheckpointRef?: CheckpointId;
  resumePointer?: string;
  lastErrorCode?: string;
  lastErrorMessage?: string;
}

export interface AgentState {
  control: AgentControlState;
  working: StateRecord;
  observed: AgentObservedState;
  recovery: AgentRecoveryState;
  derived?: StateRecord;
}

export interface AgentStateDelta {
  control?: Partial<AgentControlState>;
  working?: StateRecord;
  clearWorkingKeys?: string[];
  observed?: Partial<AgentObservedState>;
  recovery?: Partial<AgentRecoveryState>;
  derived?: StateRecord;
  clearDerivedKeys?: string[];
}
