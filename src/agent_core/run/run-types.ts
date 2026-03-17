import type { GoalFrameCompiled } from "../types/kernel-goal.js";
import type { KernelEvent } from "../types/kernel-events.js";
import type { KernelIntent } from "../types/kernel-intents.js";
import type { RunRecord } from "../types/kernel-run.js";
import type { AgentState } from "../types/kernel-state.js";
import type { RunId, SessionId } from "../types/kernel-session.js";
import type { StepTransitionDecision } from "../types/kernel-transition.js";
import type { CheckpointStore } from "../checkpoint/checkpoint-store.js";
import type { EventJournalLike, JournalReadResult } from "../journal/journal-types.js";

export interface RunCoordinatorClock {
  now(): Date;
}

export interface CreateRunInput {
  sessionId: SessionId;
  goal: GoalFrameCompiled;
  runId?: RunId;
  metadata?: Record<string, unknown>;
}

export interface ResumeRunInput {
  runId: RunId;
  checkpointId?: string;
}

export interface PauseRunInput {
  runId: RunId;
  reason: string;
}

export interface CompleteRunInput {
  runId: RunId;
  resultId?: string;
}

export interface FailRunInput {
  runId: RunId;
  code: string;
  message: string;
}

export interface TickRunInput {
  runId: RunId;
  incomingEvent?: KernelEvent;
}

export interface RunTransitionOutcome {
  run: RunRecord;
  state: AgentState;
  incomingEvent: KernelEvent;
  decision: StepTransitionDecision;
  emittedEvents: KernelEvent[];
  queuedIntent?: KernelIntent;
}

export interface RunCoordinatorOptions {
  journal: EventJournalLike;
  checkpointStore?: CheckpointStore;
  clock?: RunCoordinatorClock;
  idFactory?: () => string;
}

export interface ResolvedRunContext {
  run: RunRecord;
  state: AgentState;
  events: JournalReadResult[];
}
